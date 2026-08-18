---
name: ocr-error-triage
description: Diagnose and improve OCR or document extraction. Use to measure error without full ground truth, localize failures, test repairs out of sample, and gate regressions and cost.
---

# Triaging OCR extraction errors

Extraction pipelines fail in ways that look like success. A field is populated, the value is
plausible, nothing throws — and it is wrong. This is the loop for finding that out and fixing
it without fooling yourself.

**Measure → localise → propose → validate.** Skipping any step produces a fix that works on
the page you were looking at.

## 1. Measure: a fill rate is not accuracy

The most common self-deception. `epic=83%` usually means *83% non-empty*, which is equally
consistent with 83% correct and 40% correct. Never report a fill rate as quality.

Without labelled data, **bracket** the error rate instead:

**Floor — provably wrong.** Values that cannot be right regardless of the source. These are
cheap, exact, and give a hard lower bound:

- wrong script or character class (Latin letters in a Devanagari/Bengali name; digits in a name)
- a value identical to a different field's value (one crop read twice)
- the field's own label leaking into its value
- format violations (an ID failing its regex)
- **uniqueness violations** — a supposedly unique ID repeating within a scope is provably a
  misread, and this is often the single most informative detector you have
- range violations (an age of 7 on an electoral roll)

**Ceiling — disagreement.** Read the same crop twice under different settings (scale, page
segmentation) and compare. Where two independent passes agree, the value is very likely
right; the disagreement rate bounds error from above.

**And look hard for real ground truth in the document itself.** This is worth more than
everything above and is routinely missed. Printed documents often publish their own totals —
a summary page, a control total, a count in a header. In one real case the target metric was
being compared against a *net* figure from a different page while the document's own closing
page carried the exact number, printed, self-validating (`male + female + third == total`).
Residuals collapsed from ±27 to ±1 the moment the right pair was compared. Before building
elaborate proxies, read the last page.

**Distributions catch what per-row checks cannot.** A histogram of a numeric field's *last
digit* exposes systematic digit confusion where every individual value is plausible. Category
shares (sex ratio, relation-type mix) expose bias that fill rate shows as healthy.

> A field that fails more often for one category than another does not read as missing data
> downstream. It reads as a finding. Always check error rates *by category*, not just overall.

## 2. Localise: compute the co-occurrence, do not eyeball it

Root causes are co-occurrences — a failure class lining up with an observable feature. Found
by eye they do not repeat and do not scale.

For each failure class, compute the failure rate within each value of each feature, and report
slices whose rate is well above base rate (lift ≥ ~1.5, with a minimum support so small slices
do not fire). Features worth having:

| feature | what a hit means |
|---|---|
| spatial position (column, row, region index) | the **crop** is wrong, not the OCR |
| page kind / section | that layout variant was never handled |
| another field's value | the two fields share a code path that is broken for one branch |
| page position (first/last) | partial or short pages differ structurally |

Also classify the *raw* failing reads as **empty / short / garbled**. These want opposite
fixes and look identical in a fill rate: empty means segmentation gave up (change the crop or
the mode), garbled means the recogniser tried and failed (change scale or model), and a near
miss means your parser is too strict.

Real example: of seven ID failures on a page, six returned `""` and one returned
`S 106 —, HHK3535/704`. Two different bugs — a strip too sparse for single-line segmentation,
and a regex rejecting a stray `/` inside the digits — and the shape histogram separated them
in one step.

## 3. Propose: from a signature library, not from intuition

Keep a table mapping observed signature → concrete remedy. Generic advice is worthless; each
entry should name a change with an obvious implementation.

| signature | try |
|---|---|
| failures concentrate in one column/region | compare that region's derived geometry against the ones that succeed |
| failures concentrate in one row | the row band is offset — an internal rule or header is shifting it |
| raw reads are **empty** on a wide sparse crop | crop to the field's own zone; segmentation gives up on whitespace |
| raw reads are **garbled** | vary scale before anything else |
| near-miss values rejected | loosen normalisation before matching (strip punctuation, case, spacing) |
| a label is unreadable but its neighbour is not | anchor on the durable neighbour instead |
| one category fails far more | the shared code path, not the category-specific matcher |
| supplement/appendix pages fail | they usually have a *different* layout; check the geometry assumption |

Two hard-won specifics:

- **Anchor on what survives.** When locating a line by its label, pick the label that scans
  best, not the semantically obvious one. In one case `age` was garbled beyond recognition
  while `sex` on the same line survived every scan — anchoring on the wrong one silently lost
  both fields for a whole category of rows.
- **Match by the field's own script/charset.** An ID in Latin read with a non-Latin language
  model gets mapped onto lookalike glyphs (`HHK0001471` → `1414140001471`). Read each field
  with the model for *its* script.

## 4. Validate: four gates, all required

A fix is accepted only if it clears every one:

| gate | means |
|---|---|
| **in-sample** | the target metric improves on the parts it was diagnosed against |
| **out-of-sample** | it improves by a comparable margin on data never inspected |
| **no degradation** | every other field, and every ground-truth measure, stays within tolerance |
| **cost** | runtime does not rise materially |

**Fix the splits and write them down.** DIAGNOSE (may be opened and stared at), VALIDATE
(seeded, scoring only — if you open a page here to work out a fix, that item moves to
DIAGNOSE and is replaced), REGRESSION (known baselines, guards collateral damage).

**Record baselines to a file, not to memory or a docstring.** The workable pattern is two
commands: `bench --record` measures current code on all splits and stores it; make the fix;
`bench` measures again and prints the gates. This avoids needing both code versions live.

**Guard the ground-truth measures on every change**, whatever field the fix targets. A fix
that lifts an ID match rate while losing records is not a fix.

**Where position carries meaning, a repair must not change width.** In a ruled grid the
column *is* the field — ward 6 is ward 6 because of where it sits on the line. Substituting
`UR(W)` for `[URW` is one character wider and slides every cell after it by one column. This
is the most dangerous shape of fix available, because every aggregate improves: on a real run
it recovered 2,401 gender markers, cut unstated rows from 1,754 to 1,122 and moved the
women's share toward the statutory half, while silently costing one panchayat three of its
eight wards. Nothing in those numbers could show it — they went up *because* of the change
that was destroying rows. Pad the replacement, absorb following whitespace, and **decline the
repair** when there is no room, rather than let a row shift. Then read one record off the page
cell by cell, because that is the only check that sees it.

**Guard soundness, not fill.** A fill rate *falls* when a provably wrong value is correctly
cleared, so a gate guarding fill rejects the one move that unambiguously improves the data.
Guard *present and not provably wrong* per field: removing a wrong value is then neutral,
replacing it with a right one is a gain, and inventing a plausible wrong one is a loss. This
is easy to get backwards — the first version of my own gate would have rejected deleting
known-bad values.

**The bar is Pareto improvement, not completeness.** "Did this make something better while
making nothing worse" is answerable; "is this field fixed" usually is not. A fix that
recovers half a failure class and touches nothing else should ship.

**Score "closeness to target", not raw value**, for ratio metrics — otherwise a change that
overshoots registers as an improvement.

### Failure modes of the validation itself

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

## 5. Escalate rather than perfect

A cheap pass will always leave errors. Pushing it to perfection has sharply diminishing
returns; **knowing which rows it got wrong** does not. Use the floor detectors plus the
disagreement flags as a routing signal, and run an expensive engine (a VLM, a larger model, a
human) on the flagged rows only.

Measure the router before trusting it: **recall** (of rows independently known to be wrong,
how many were flagged), **precision** (of flagged rows, how many were wrong), and **volume**
(what share gets escalated — a detector that flags 40% is a re-run, not a triage).

**Do not score the router against the same detectors that feed it.** They are half the router,
so precision comes back at 100% and means nothing. Report volume and per-family contribution,
and say plainly that precision is unmeasured until a second engine has read the flagged rows.

**Count cost in the unit the second pass re-reads, not in rows.** If it can settle one field
rather than a whole record, flagging 40% of rows may cost 12% of a full re-run. Counting rows
made a precise detector look like it had destroyed the triage. Map every reason to the unit it
implicates, and enumerate that mapping *from the detectors* — a hand-written list silently
misses the reason someone added last, which then bills as a whole record.

**A detector can be falsified even where its precision cannot be measured.** If the rows it
picks are no likelier to be wrong than the rows it passes over, it is flagging at random
however sensible its reason sounds. Score it against a *distributional* property: the rate of
implausible values inside the flagged set over the rate outside it. One is chance; higher is
signal. Watch the zero-base case — dividing by an outside-rate of zero reports **perfect**
separation as the score a useless detector gets.

### Some wrong values are only visible in aggregate

A field can be individually plausible and collectively impossible. An age of 95 passes every
range check; 15% of a roll being in its nineties does not. Nothing per-row can see this, so
the error floor and any "present and not provably wrong" metric both score it as good.

When the distribution says a subset is unrecoverable, **route it rather than guess a rule**.
Test candidate rules against the part of the data that is unambiguous: if reading a
contaminated field from the left puts 15% in an impossible bucket and from the right 14%,
against 2% for the clean rows, then neither end is right and picking the better one is tuning
on a signal that does not support it.

The escalation pass goes through the same four gates. And check what the expensive model was
actually trained on before assuming it transfers: a roll-specific model with 96–98% reported
field fidelity turned out to be trained entirely on English-script rolls, which said nothing
about its behaviour on Bengali-Assamese.
