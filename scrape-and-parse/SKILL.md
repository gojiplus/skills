---
name: scrape-and-parse
description: Build or fix a scraper and its parser. Use for government portals, ASP.NET postbacks, REST behind maps, PDF harvests, retries, checkpoints, resume, throughput diagnosis, and typed outputs.
---

# Scraping and parsing, once

## Overview

The same crawl has been written many times in this fleet, and the same failures found each
time: a retry loop that gives up in fifteen seconds on a seven-hour outage, a checkpoint keyed
on a code that repeats across districts, a regex that silently drops 39% of rows, a
`while True` downloader with TLS verification off. This skill is the distillation of the repos
that got it right, `odisha-ror` and `rajasthan-ror` above all, so the next crawl starts from
their shape instead of rediscovering it.

The shape is three programs and a ledger:

```
list   -> raw/frame.parquet          every unit of work, enumerated and asserted against the portal's totals
fetch  -> raw/<unit>.jsonl.gz        one line per request, verbatim answer, ok/reason, resumable
parse  -> raw/records.parquet        typed table + dictionary, reads only raw/, never the network
```

Fetching is expensive and unrepeatable; parsing is cheap and will be repeated. Nothing in the
fetcher interprets, nothing in the parser connects.

## Usage

`/scrape-and-parse [portal or repo]` — for a new target, run the stages below in order and show the reconnaissance findings. Resolve missing source or scope decisions
before dependent work; continue when the task already authorizes the chosen approach. For an existing crawl that is slow or failing, start
at **Diagnose** and run `scripts/crawl_health.py` before touching code.

## 1. Reconnaissance, before any code

- **Find the cheapest door.** The page you were pointed at is rarely the best one: the
  OTP-gated nakal had an unauthenticated map API underneath; the fontless PDFs had a JSON
  endpoint; the per-plot call named every other plot on the khata. Read the page's JavaScript
  for `$.post(` and `fetch(`; try the REST layer under any map or app; check whether the
  captcha ever reaches the server (Rajasthan's did not).
- **Measure the portal, not your guess.** One request's latency; then one thread, N threads on
  one session, N threads on N sessions, a minute each. If aggregate throughput barely moves,
  the portal serialises and the lever is latency or IPs, not workers.
- **Size the job in writing**: units × requests per unit × seconds per request, and bytes per
  record × records. A month is a design question (a VM near the server, several IPs) and it
  belongs here, not in week three. See `references/storage.md`.
- **Find the portal's own totals** and plan to assert your enumeration against them.
- **Show the user two raw records, unedited**, beside the page they came from. Ask about
  unresolved meanings or scope, and continue independent work while awaiting answers.

## 2. The frame

Enumerate every unit of work first (district → tehsil → village → sheet), checkpointed per
top-level code, folded into one Parquet with the full code path and the human names. **Keys
are composite until proven otherwise**: `village_code` repeats across tahsils in Odisha and
keying on district plus village merged 322 of 476 files. Assert the count against the portal's
published total and record the difference in the README.

## 3. The fetch

`references/http.md` and `references/checkpoints.md` carry the detail. The rules:

- **Three failure kinds, three responses.** Connection-level (DNS, connect, timeout): wait it
  out for hours with doubling back-off, never let a worker die. Throttle (429): honour
  `Retry-After`, then long waits, then fewer workers. Other HTTP errors: classify using the source contract and response body;
  authentication, request-shape, and temporary server failures need distinct handling. Use `stamina` or `tenacity` for the policy; do not write the loop.
- **A miss needs evidence.** Record `miss` only when the source explicitly signals no
  record. Empty 200/204 responses may be valid misses if the source contract says so.
  An HTTP 200 error page can be an expired session, malformed request, or outage: keep
  it as a failure until classified, and stop or retry under a bounded recovery policy.
- **One gzipped JSONL per unit, one line per request, flushed per line**, verbatim answer,
  `ok` and `reason`, `fetched_at` in UTC, `via` for what was inferred without a request, `done`
  written last. A failure is retried on resume; a miss is not. Tolerate `EOFError`, `OSError`
  **and `zlib.error`** when reading a checkpoint that was cut short.
- **Skip what the portal already told you.** Every answer that names other records saves their
  requests. Probe for the end of a numbered range with doubling offsets instead of a long miss
  run.
- **Order units by analytic value and breadth**, so an interrupted crawl is still a usable
  sample: the districts the question needs first, tahsils interleaved.
- **Log one structured line per unit** with the live worker count; log every retry after the
  third; log failures per record and never successes (that is the checkpoint's job).
- **`caffeinate -dims` in the crawl script**, a monitor that compares against last time, and
  `crawl_health.py` for diagnosis. `references/monitoring.md`.
- TLS verification stays on. Secrets come from the environment, never `'<PUT TOKEN HERE>'`.

## 4. The parse

`references/parsing.md`. Reads `raw/` only. Marker scan, not whole-cell regex. `raw_cell` on
every row. NFC before keys; never strip a sex or honorific suffix in a key. Output Parquet with
an explicit schema, a data dictionary (the `build-data` skill's contract), `SCHEMA.json`,
`CHECKSUMS`, and declared row counts that downstream repos assert against. The parser prints,
every run, the fill rates and the distributions that would embarrass you if wrong.

Downloads are validated by content, not by existence: `%PDF` magic and a page count, a
size-versus-advertised check, an MD5 from the store's metadata before any download. A file that
exists and is 4 KB of error page is the most common "done" that was not.

## 5. Publish

The scraper, tests, `crawl.sh`, schema and dictionary are public under the fleet standard
(`preen adopt`); the records are not, and no sample of personal records goes in the README.
The README carries: what the source is, what it measures and cannot, a **Handling** section
listing every trap and what it cost, provenance and vintage, and the run commands.

## Diagnose

For a crawl that is slow or stalled, in this order:

1. `python3 scripts/crawl_health.py raw/<units>`: requests per hour, miss share, failure kinds,
   truncated tails. Dead hours with `name resolution` failures are an outage the client should
   have slept through; a miss share above a third is a stopping rule or a wrong request shape.
2. Is another crawl on the same machine holding its rate? Then it is not the network.
3. Live worker count in the log against what was launched.
4. The concurrency ladder from reconnaissance, rerun on a unit outside the crawl.
5. Only then change code, and change the stopping rule only after measuring the gap
   distribution it protects against from finished units.

## What this skill does not cover

Spend gating for paid APIs and captcha services is `metered-runs`. Building the analysis-ready
file from the parsed table, with its dictionary and join contract, is `build-data`. OCR of
scanned rolls is `ocr-error-triage`.
