# Monitoring and logging a crawl that runs for weeks

## Structured progress lines

One INFO line per unit finished, with the same fields in the same order every time, because a
shell script will parse it:

```
2026-09-08 10:28:31 INFO 2109112670503518815001: 214 tried, 156 plots (1.3 req/s overall, 8 workers live)
21:36:46 INFO 1942434 records, 5794805 cells, 58214 failed, 36023 villages left, 336.5 rec/min
```

Include the **live worker count**: a pool that silently lost threads (Rajasthan, 8 Sept) looks
healthy in every other number. Log at WARNING every retry after the third and every truncated
checkpoint. Use `logging`, never `print`, in package code (ruff `T20` enforces it under the
fleet standard).

## The monitor compares against last time

Most of the ways a crawl fails do not stop the process: macOS throttles it to near zero on
battery, a DNS outage leaves it spinning, a portal change makes every request a miss. A
liveness check calls all of that healthy. `odisha-ror/monitor.sh` is the model: run from cron
every two hours, it reads the last progress line, compares with the numbers it wrote to a state
file last time, and alerts on

- the process not running,
- the log not written for 20 minutes,
- no new records since the last check, or fewer than 60 a minute,
- more than 25% of fetches failing over the window,
- being on battery.

Alerts go to a desktop notification *and* a log file; the notification needs a GUI session, the
file is the reliable half. Judge the rate only once five minutes have passed since the last
check.

## Read health off the checkpoints, not the log

`scripts/crawl_health.py` reads the JSONL checkpoints and prints requests per hour, hit and
miss shares, failure kinds and finished units. It is how the Rajasthan slowdown was diagnosed
in one run: hours at 2.5 requests a second, then seven hours at zero, and the failures in those
hours all `NameResolutionError`. Run it before changing any code.

## Keep the machine awake

`caffeinate -dims <command>` on macOS, inside the crawl script itself, not as a separate
process someone else's job happens to be holding open. Both crawls run under it now.

## Measure before tuning

Before adding workers, prove they help: one thread, N threads on one session, N threads on N
sessions, for a minute each, on a unit outside the running crawl. Before shortening a stopping
rule, measure the gap distribution it protects against from the finished units. Before blaming
the portal, check whether another crawl on the same machine kept its rate through the same
hours.
