#!/usr/bin/env python3
"""Read a crawl's health off its checkpoints, without touching the crawler.

Works on the checkpoint convention this skill prescribes: one gzipped JSONL
file per unit of work, one line per request with at least ``fetched_at``
(ISO-8601), ``ok`` (bool) and, when not ok, ``reason``; optional ``via`` for
records inferred without a request and a final ``{"done": true}`` line.

Prints requests per hour, hit and miss shares, the kinds of failure, and
how many units are finished, which is enough to tell "the portal is slow"
from "our name resolution died at 2 a.m." from "half our requests are the
end-of-range tail". Stdlib only.

Usage:
    python3 crawl_health.py raw/plots            # a directory of *.jsonl.gz
    python3 crawl_health.py raw/plots --hours 48
"""

from __future__ import annotations

import argparse
import collections
import gzip
import json
import re
import sys
import zlib
from pathlib import Path

FAILURE_KINDS = (
    ("name resolution", re.compile(r"NameResolution|nodename nor servname|getaddrinfo")),
    ("timeout", re.compile(r"timed out|Timeout")),
    ("connection", re.compile(r"Connection(Error| reset| aborted)|RemoteDisconnected")),
    ("http status", re.compile(r"HTTP \d{3}")),
)


def classify(reason: str) -> str:
    for label, pattern in FAILURE_KINDS:
        if pattern.search(reason):
            return label
    return "other"


def main() -> int:
    parser = argparse.ArgumentParser(description="Crawl health from JSONL checkpoints.")
    parser.add_argument("directory", type=Path)
    parser.add_argument("--hours", type=int, default=24, help="how many trailing hours to print")
    args = parser.parse_args()

    per_hour: collections.Counter[str] = collections.Counter()
    hits_per_hour: collections.Counter[str] = collections.Counter()
    failures: collections.Counter[str] = collections.Counter()
    units = finished = requests = hits = misses = inferred = 0
    truncated = 0
    for path in sorted(args.directory.glob("*.jsonl.gz")):
        units += 1
        try:
            with gzip.open(path, "rt", encoding="utf-8") as fh:
                for line in fh:
                    record = json.loads(line)
                    if record.get("done"):
                        finished += 1
                        continue
                    if record.get("via"):
                        inferred += 1
                        continue
                    hour = str(record.get("fetched_at", ""))[:13]
                    requests += 1
                    per_hour[hour] += 1
                    if record.get("ok"):
                        hits += 1
                        hits_per_hour[hour] += 1
                    elif record.get("reason") == "miss":
                        misses += 1
                    else:
                        failures[classify(str(record.get("reason", "")))] += 1
        except (EOFError, OSError, zlib.error, json.JSONDecodeError):
            # a checkpoint still being written, or cut short by a killed worker
            truncated += 1

    print(f"units: {units} files, {finished} finished, {truncated} with a truncated tail")
    print(
        f"requests: {requests}  hits {hits} ({hits / max(requests, 1):.0%})  "
        f"misses {misses} ({misses / max(requests, 1):.0%})  "
        f"failures {sum(failures.values())}  inferred without a request {inferred}"
    )
    if failures:
        print("failure kinds:", dict(failures.most_common()))
    print("requests per hour (UTC), most recent last:")
    for hour in sorted(per_hour)[-args.hours :]:
        rate = per_hour[hour] / 3600
        flag = "  <- dead" if rate < 0.1 else ""
        print(f"  {hour}  {per_hour[hour]:6d}  {rate:5.2f}/s  hits {hits_per_hour[hour]}{flag}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
