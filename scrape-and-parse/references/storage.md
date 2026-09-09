# Storage: thrifty, typed, and never committed

## Raw

- **Gzipped JSONL, one file per unit of work**, appended per request. Compresses 8–10x on
  portal JSON, streams, survives a kill (see `checkpoints.md`), and is greppable with `zcat`.
- **Verbatim.** Store the portal's answer as it came: the JSON object, the HTML cell, the
  bytes. Do not "tidy" on the way in; tidying is parsing and belongs downstream.
- **Many small files are a problem for the filesystem, not for gzip.** 50,000 village files are
  fine on APFS and ext4; above a million, shard by the top-level code into subdirectories, or
  pack finished units into `tar` members (uncompressed tar of already-gzipped files, so a
  member can be extracted alone). Odisha's 15,516 checkpoint files total 328 MB.
- **Images and PDFs**: one object per record in a bucket or a `tar`, named by the record key,
  plus a manifest (Parquet) of name, size, MD5, content type. `jaali` builds exactly that for
  15.85M ration-card photos and uses the MD5 column to find duplicates without a download.

## Derived

- **Parquet with an explicit schema** for anything tabular. Round-trip it once (write, read,
  compare) before trusting it; `build-data/references/storage.md` has the table of what each
  format loses.
- **Schema-versioned JSON** for small metadata that must stay human-diffable: synonym tables,
  code lists, label sets. A loader validates the version, keys and value domains.
- Codes are strings. Timestamps carry a zone. Booleans are booleans, not `"Y"`.

## The downstream contract

`local_elections_rajasthan/data/fin/` is the model: `SCHEMA.json` (column, type, meaning per
file), `*_DICTIONARY.md`, `CHECKSUMS.sha256`, and **declared row counts** that a consuming repo
asserts against, so a silently changed sibling fails loudly ("raises *the sibling changed* if
they move"). `parse_unsearchable_rolls/scripts/karnataka/recover.py` adds a
`PIPELINE_REVISION = sha256(own source)` stamped on every output, so a table can be traced to
the code that made it, and writes JSON atomically (temp file, then replace).

## Provenance on every row

`fetched_at` (UTC) and the source URL or request key on the raw line; the raw line's location
(`unit`, `line`) or `raw_cell` on the parsed row. A parsed value must be traceable to the bytes
it came from in two hops.

## What is committed

The scraper, the parser, the tests, the README with its Handling section, the schema, the
dictionary, and a `crawl.sh`. Not `raw/`, not `logs/`, not derived tables, and never a sample
of personal records "for illustration": both land-record repos publish the code and keep the
records, and `chehra`'s README says so in its second paragraph.

## Sizing before starting

Write down, before the first full run: units × requests per unit × seconds per request, and
bytes per record × records. Rajasthan: 50,109 sheets × ~300 requests × 0.7 s ≈ 120 days from
one IP; 9 KB × 30M plots ≈ 30 GB raw before compression. If the number is months, the design
question is IPs and latency, not code, and it belongs in the plan before any code is written.
