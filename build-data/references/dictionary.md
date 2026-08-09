# Recovering a data dictionary

The dictionary is not documentation written after the fact. It is the object that decides
whether any later number means anything. This file holds the full battery, the sentinel
catalogue, and the reconciliation moves that turn a guess into a citation.

## The per-column battery

Run all of it. The cost is seconds and the alternative is discovering a code in the referee
report.

| check | what a hit means |
|---|---|
| value counts **including NA as a printed row** | the default drops NA; the default is the bug |
| distinct count vs row count | 1 distinct = constant, useless; ≈ n = free text or an ID, not a category |
| min, max, and the five most extreme values verbatim | extremes are where sentinels live; a summary hides them |
| last-digit histogram of a numeric field | heaping at 0 and 5 = self-report or rounding; a spike elsewhere = systematic misread |
| value counts of `nchar()` on a character field | two modal lengths = two formats concatenated; a length equal to the field width = truncation |
| first and last period where non-missing | a variable that starts mid-panel manufactures a trend |
| the same, by geography or arm | a code present in one stratum is a collection artifact |
| share of values that are exactly zero | separate from missingness, and the distinction is often lost |
| `n_distinct` after `trimws()` and `tolower()` vs before | the gap is the number of spurious categories |
| type of the column vs the type it should be | a numeric ID read as double loses leading zeros and precision above 2^53 |

## Sentinel catalogue

A reserved code survives `is.na()`, survives a type check, and enters a mean. These are the ones
that recur.

### Numeric

| code | usual meaning | how it is missed |
|---|---|---|
| `-999`, `-99`, `-9` | missing | reads as a plausible negative in a signed field |
| `-1` | "not applicable" — distinct from missing | reads as a legitimate small value |
| `999`, `9999`, `99999` | missing, or a width top-code | shows up as a right tail, not a spike, if the field is wide |
| `77`, `88`, `98`, `99` | don't know / refused / not ascertained | in a 0–100 field these are inside the plausible range |
| `96`, `97` | "other", "multiple" | collapsed into a real category by a naive recode |
| `0` in a positive-support column | "not measured", sometimes "measured, none found" | indistinguishable without the codebook — say so |
| the type max (`127`, `32767`, `2147483647`) | overflow or a top-code | looks like a legitimate extreme |
| `9.96921e+36` | Stata's `.` exported to a float | reads as a huge outlier |

Stata's extended missings (`.a`–`.z`) carry *different* reasons and collapse to a single `NA`
in almost every import path. If the source is `.dta`, check whether the reasons were dropped
before you inherited the file.

### Character

`""`, `" "`, `"NA"`, `"N/A"`, `"n/a"`, `"."`, `".."`, `"-"`, `"--"`, `"NULL"`, `"None"`,
`"nan"`, `"#N/A"`, `"?"`, `"Not Available"`, `"Not Reported"`, `"Unknown"`, `"Refused"`,
`"Don't know"`. Each comes from a different export path, and a file that contains three of them
was assembled from three sources.

Also: a value identical to the column's own label (the header leaked into the data), a value
identical to a *different* column's value in the same row (one field read twice), and a value
containing the delimiter (a quoting failure that shifted every subsequent column on that row).

### Dates

`1900-01-01` (Excel epoch), `1899-12-30` (Excel's actual day zero), `1970-01-01` (Unix epoch),
`0001-01-01`, `9999-12-31`, and any date exactly equal to the extract date. Two-digit years
pivoting at 1969/2069. A date column where the day never exceeds 12 has been parsed
month-first somewhere and day-first elsewhere; the rows with day > 12 are the only ones you can
tell apart.

### How to find them without knowing them

1. **Spike detection.** Tabulate the top 20 values. A code will hold a share far above its
   neighbours, and the share will be suspiciously round.
2. **Roundness.** Flag values that are all-9s, all-0s, or the negative of a power of ten.
3. **Stability across strata.** A real value's share moves across waves and regions. A
   collection code's share moves with the *instrument*, not with the world.
4. **Bimodality at the boundary.** Mass at the extreme of the plausible range with a gap before
   it is a top-code, not a tail.
5. **Cross-column consistency.** An age of 999 next to a birth year of 1962 resolves itself.

## Universe, and why it is not "non-missing"

The universe is who is *eligible* to have a value. Write it as a sentence:

> `n_daughters`: universe is respondents with at least one child (`n_children > 0`), waves 2–6.
> Wave 1 did not ask. Structural `NA` for childless respondents; item `NA` for refusals, coded
> `-9` in the source.

That sentence tells you the denominator for every rate built from the column, which cases a
complete-case model will silently drop, and whether a zero is a real zero. Without it, a
`mean(n_daughters, na.rm = TRUE)` is a number with no referent.

Three missing kinds, one `NA`:

| kind | example | correct treatment |
|---|---|---|
| structural / not applicable | daughters of a childless respondent | outside the universe; excluded from the denominator, not imputed |
| not asked | question added in wave 3 | outside the universe *for those waves*; a wave indicator, not an imputation |
| item nonresponse | refused, don't know | inside the universe; this is the one imputation is for |

Collapsing the first into the third is how a filter question turns into an effect.

## Reconciling against the source

In order of value:

1. **The source's own documentation.** Find it before inventing anything.
2. **A sibling codebook** — the same instrument in an adjacent year, state, or country. Codes
   are usually stable across waves even when the documentation for one wave is lost.
3. **Printed control totals inside the document itself.** Summary pages, header counts, closing
   totals. These are self-validating and routinely missed: a page that prints
   `male + female + third = total` gives you exact ground truth for four columns at once. Read
   the last page before building an elaborate proxy.
4. **External benchmarks.** Census totals, official aggregates, published tables from the same
   source. A column that should reconcile and does not is a finding.

Cite the source per column. Where a meaning is inferred, write `inferred` in the provenance
field — an inferred universe that is wrong is recoverable, an undocumented one is not.

## The artifact

`data-dictionary.md`, committed alongside the data, one row per column:

```markdown
| name | source_file | type | unit | universe | values | missing codes | n_missing | miss kind | transformations | provenance |
|------|-------------|------|------|----------|--------|---------------|-----------|-----------|-----------------|------------|
| age  | roll_2024.csv | int | person | all enrolled electors | 18–120 | 999, 0 | 4,412 (2.1%) | item | none | inferred from spike at 999; ECI form 6 gives min 18 |
```

Keep an `open questions` section at the bottom listing the columns whose universe is still a
guess and what would settle each. That list is the agenda for the next call with the data
provider, and it is the part reviewers ask about.
