# Checkpoints: the crawl is a ledger

A crawl that can be killed at any second and resumed without loss or repetition is the whole
design. Everything below follows from that.

## The convention

One gzipped JSONL file per unit of work (a village, a sheet, a page range), under `raw/`,
appended one line per request:

```json
{"giscode": "2113223780954339273001", "plotno": "17", "fetched_at": "2026-09-08T07:12:03+00:00",
 "ok": true, "data": {...the portal's answer verbatim...}}
{"giscode": "...", "plotno": "18", "fetched_at": "...", "ok": false, "reason": "miss"}
{"giscode": "...", "plotno": "19", "fetched_at": "...", "ok": false,
 "reason": "POST rest/MapInfo/getPlotInfo: unreachable for 7200s: NameResolutionError ..."}
{"giscode": "...", "plotno": "20", "fetched_at": "...", "ok": true, "via": "17"}
{"giscode": "...", "done": true, "high": 683}
```

- **`ok: false` with a reason, never silence.** A record that yielded nothing is written with why.
  The reason is what `crawl_health.py` classifies: `miss` (the portal said no such record) is
  data; anything else is a failure to retry.
- **A failure is retried on resume; a miss is not.** `read_progress` counts a miss as tried and
  a failure as never tried. Odisha's `done_khatiyans` does the same: rows with `ok` false are
  excluded from "done" so the next pass retries them.
- **`via` records what was inferred without a request** (Rajasthan: the other plots on the same
  khata, from `ownerplots`), so the parse can expand them and the health report can separate
  requests from records.
- **`done` is written last**, after the end-of-range logic, and only then is the unit skipped
  on the next run. A unit without it resumes from its highest tried number.
- **`fetched_at` in UTC on every line.** It is the vintage of the record and the input to every
  throughput diagnosis.
- **Flush after every line.** `gzip.open(..., "at")` buffers; a killed worker loses the buffer.
  `fh.flush()` per record costs nothing at portal speeds.

## Reading a checkpoint that is being written, or was cut short

A gzip stream cut mid-block raises `EOFError`, `OSError`, **or `zlib.error`** ("invalid block
type"), depending on where the cut fell. Catch all three. Use the readable prefix and refetch the
rest; Odisha's `salvage()` rewrites the file from the readable records so the next open is
clean. Never treat an unreadable checkpoint as done.

## Keys are composite until proven otherwise

Odisha's `village_code` repeats across tahsils. Keying checkpoints on district plus village
merged 322 of 476 files and made the resume check read one village's khatiyans and skip
another's. Key on the full path from the top level down, and name the file with it.

## Finding the end of a range

When records are numbered and there is no list call, the walk needs a stopping rule, and the
naive one ("N consecutive misses") is expensive: Rajasthan's 60-miss tail was 16% of all
requests, and internal gaps of up to 57 meant it could not be shortened. Probe instead: after 20
misses, try doubling offsets (20, 40, 80, 160, 320, 640); a hit resumes the walk, six misses end
the unit. 26 requests instead of 60 and ten times the reach. Record the probes as ordinary
lines so resume needs no special case.

## Skip what you already know

Every record the portal hands you may name others (the same owner's other plots, the same
household's other members). Record them as `via` and do not request them; the parse expands
them. In Rajasthan this removed a third of requests.
