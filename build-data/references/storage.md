# Storage formats, naming, and provenance

A file format is a contract about types. CSV declines to make one, so every reader invents its
own and they disagree. This file holds the round-trip tests that prove a format is carrying what
you think, the naming rules, and the provenance stamp that makes a cached file traceable.

## The round-trip test

Before trusting any format for a handoff, write and re-read and compare. This is three lines and
it has caught every class of loss listed below.

```r
stopifnot(identical(df, arrow::read_parquet(f <- tempfile()) ))   # after write_parquet(df, f)
waldo::compare(df, arrow::read_parquet(f))                        # when it fails, this says why
```

What each format loses on the round trip:

| format | survives | loses |
|---|---|---|
| Parquet | types, nullability, factor levels (as dictionary), int64, timestamps with tz | R attributes not in the Arrow schema; `haven` value labels |
| JSONL | nesting, ragged records, explicit `null`, string/number distinction | column order; int64 precision if a reader parses to double; no schema enforcement |
| CSV | nothing structural | leading zeros, int64 precision, `NA` vs `""`, dates, encoding, row integrity under embedded delimiters |
| `.rds` | everything R knows | portability — R-only, and serialization version couples it to an R release |
| `.dta` | value labels, extended missings | anything Stata has no type for; 32-char variable names in older versions |
| `.xlsx` | nothing you want | silently reformats IDs as numbers, dates as serials, and long strings as `#####` |

## Reading a CSV you did not write

Never infer. An inferred schema is a schema that changes when the data changes — the file that
worked last month fails on this month's extract because one column happened to contain only
digits before.

```r
readr::read_csv(
  path,
  col_types = readr::cols(
    district_code = readr::col_character(),   # leading zeros
    gp_id         = readr::col_character(),   # too long for a double
    year          = readr::col_integer(),
    turnout       = readr::col_double(),
    poll_date     = readr::col_date(format = "%Y-%m-%d"),
    .default      = readr::col_character()    # unknown columns stay text until you decide
  ),
  na = character()          # read "NA"/"" as literal strings; decide what is missing yourself
)
```

`na = character()` is the important one. Letting the reader decide which strings mean missing
destroys the distinction between an empty field, a literal `"NA"`, and a refusal code — the
exact distinction stage 1 of `build-data` exists to recover. Convert to `NA` deliberately, after
you know what each string meant, and record the mapping in the dictionary.

The same discipline in Python: `pd.read_csv(path, dtype=str, keep_default_na=False)`, then cast.

## Choosing the format

**Parquet for derived and analysis-ready tables.** Types travel with the file, so no downstream
script re-guesses. Columnar and compressed, so a 3 GB CSV is often a 200 MB parquet and reads a
column without reading the file. `arrow::write_parquet()` / `arrow::read_parquet()`; in Python,
`df.to_parquet()`. Partition by a natural key when the table is large:
`arrow::write_dataset(df, "data/raj/panel", partitioning = "year")`.

**JSONL for cached raw pulls** — scrapes, API responses, per-page or per-document extraction.
One record per line means the file is appendable during a long run, streamable, resumable after
a crash, and still greppable. Ragged records survive without inventing a union schema. Write one
JSON object per line with no trailing comma; keep the raw response body in a field rather than
parsing at collection time, so a parser bug does not cost you the crawl.

**CSV only when a human edits the file.** Crosswalks, manual coding sheets, hand-resolved match
ties. Store every identifier as character, commit a schema file next to it, and re-read it with
an explicit `col_types`.

**Never Excel inside the pipeline.** If data arrives as `.xlsx`, convert it once in a boundary
script, write the result to parquet, keep the original under `data/<source>/source/`, and record
the conversion. Excel will have already mangled long IDs into scientific notation and dates into
serial numbers; note that in the dictionary rather than pretending it did not.

## Naming

```
data/<source>/<source>_<unit>_<geo>_<yearspan>[_variant].parquet
```

`mnrega_elex_raj_05_10.parquet` · `shrug_gp_raj_05_10_block.parquet` · `source_2015_std.parquet`

Lowercase, snake_case, no spaces, no capitals, extension always present. Variant suffixes carry
meaning and are worth keeping — `_std` standardised names, `_strict` the tighter-match panel,
`_block` the block-level aggregate — and each is defined in the dictionary.

Three things that never belong in a filename:

- **A date.** `final_data_2022_01_05.csv` is version control implemented by hand, and it
  guarantees some script still reads the old one. Git holds versions; the name holds meaning.
  The exception is a cached raw pull, where the retrieval date *is* the meaning:
  `data/eci/source/roll_assam_2026-02-11.jsonl`.
- **`final`, `new`, `v2`, `clean`, `fixed`.** They all age into lies, usually within a week.
- **A person's initials or a machine name.** The file outlives both.

## The provenance stamp

Anything cached rather than recomputed needs a stamp, because the pipeline will not regenerate
it and nobody will remember where it came from. Write a sidecar next to the file:

```
data/eci/source/roll_assam_2026-02-11.jsonl
data/eci/source/roll_assam_2026-02-11.jsonl.meta.json
```

```json
{
  "source_url": "https://ceoassam.nic.in/...",
  "retrieved_at": "2026-02-11T09:14:22+05:30",
  "retrieved_by_script": "scripts/01a_scrape_rolls.R",
  "n_records": 2841077,
  "sha256": "9f2c...",
  "notes": "Rate-limited to 2 req/s. 14 ACs returned 503 and were retried on 2026-02-12."
}
```

The rule this enforces: **the pipeline recomputes everything it can, and stamps everything it
cannot.** Cache only what is expensive or impossible to re-collect — scrapes, API pulls, paid
extracts, manual coding, anything with a rate limit or a retirement date. A cached intermediate
that exists because a join was slow is a file nobody can trace, and it will drift from the code
that made it.

Check the stamp in the driver: if the hash of the file does not match the stamp, stop. A silently
edited cache is worse than a missing one.
