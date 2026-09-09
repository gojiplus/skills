# Failure modes of validation

- **A fallback that turns a visible miss into an invisible error.** This is the most dangerous
  one, because every metric says it worked. A whitespace-tolerant label matcher raised a
  relation field from 77% to 93% in-sample *and* out-of-sample, with the obvious damage metric
  flat. But the rows it filled included ones where the two lines had been *swapped* upstream,
  so the fallback wrote the elector's own name into the relation field: both fields populated,
  both plausible, nothing provably wrong, and the equality check it was guarded with cannot
  fire on a swap. Before shipping a fallback, ask **what the fallback produces on the rows
  where the primary path failed** — if the primary failed for a structural reason, the
  fallback is filling in the wrong place. Guard it with a signature the *new* failure mode
  actually produces, not the one the old failure produced.
- **Two code paths testing the same thing differently.** The swap above existed because one
  function matched labels loosely and another matched them strictly, so the same line was a
  relation line to one and not the other. When a fix loosens a test, grep for every other
  place that makes the same decision.
- **Measuring the isolated change, not the real path.** An A/B of one crop against one crop
  showed 3× faster; the production path also read a second crop the A/B never ran. Time the
  end-to-end path.
- **Timing on a machine whose load is drifting.** Two rules make a timing comparison survive a
  shared machine, and you need *both*. **Interleave** the arms so external load is a shared
  nuisance rather than a confound — running one arm to completion and then the other measures
  the machine, not the change. Then **alternate the order within each round**, because if load
  is trending, "second in the round" is worth something by itself. A threading flag measured
  interleaved-but-always-second looked 15% faster; with the order alternated it was 0.97× and
  won 5 rounds of 8, which is noise. The first number would have shipped a no-op as a win.
- **Run A/A before you believe any A/B.** Put the *same* configuration in both arms and see
  what the harness reports. That is the resolution of your instrument, and without it a
  percentage has no scale to be read against. Measured on one shared machine: an A/A pair
  reported a **0.90× "improvement" winning 5 rounds of 8**, single runs spanned 1.87× with
  nothing changed, and a median-of-8 resolved only ~10%. A threading flag that scored 0.97×
  and 5/8 was therefore indistinguishable from nothing — but so would a real 8% win have been.
  Resolution is not a fixed property of the machine either; it tracks whatever else is running,
  which swung by 10× in one evening.
- **Below the resolution, isolate the stage that differs — don't just average harder.** More
  rounds buy precision slowly. Rendering grayscale instead of colour reported "13% faster with
  byte-identical output"; timing only the render and load steps settled it immediately, because
  the output file was *the same size either way* — the source was already grey and the flag did
  nothing. Effects well above the resolution (a 2× crop change) are readable directly and need
  none of this.
- **Prefer a count to a duration when you can get one.** Timings are noisy on a shared box;
  "how many values did this recover" is not. Where a change improves both, rest the case on the
  count and treat the speedup as a bonus.
- **Write the failures down.** An optimisation that fails silently gets attempted again by the
  next person, or by you in three weeks. Record what was tried, what it measured, and why it
  was rejected, next to the ones that worked.
- **Proxy metrics that measure the wrong thing.** "Does the label still appear" said native
  resolution was as good as 2× for half the cost. Extracting the *values* showed it cost 14
  points of accuracy: labels survive coarse reads, digits do not. Measure the output you
  actually ship.
- **Checks that cannot fail.** A sequence number assigned by a counter is 1..N by
  construction; checking it for gaps reports zero forever. Ask of every check: *what input
  would make this fail?* If there isn't one, it is decoration.
- **A single-setting win.** If a fix helps at one scale/mode but not others, suspect
  coincidence. Real fixes usually hold across settings.
- **Out-of-sample gain much smaller than in-sample** means you fitted the diagnosis set.
  (Larger is fine and common when the diagnosis set happened to be easier.)
