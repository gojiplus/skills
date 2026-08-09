# Hypothesis libraries

Diagnosis is a retrieval problem before it is a reasoning problem. Clinicians generate four or
five candidate diagnoses within seconds of seeing a patient, involuntarily, and do it even when
instructed not to; what separated experts from novices in the studies turned out to be
case-specific knowledge rather than any general reasoning skill. The implication for this skill is
uncomfortable and worth stating plainly: **generic method contributes less than a good library.**

So retrieve first, invent second. Free ideation is the third generator, not the first, because it
is bounded by what you happen to think of and silently omits whole branches.

---

## 1. Metric moved — differential, ordered by base rate

Work down. Each row is cheaper to check than the one below it, and more common.

| # | Hypothesis | How to check |
|---|---|---|
| 1 | The **logging or instrumentation** changed | diff the telemetry code and the metric definition across the discontinuity |
| 2 | Something **deployed** at the break | correlate the change point with deploy, config, schema, feature-flag and bot-filter history |
| 3 | The **assignment or join** is broken | sample ratio mismatch; row counts before and after each join; null rates |
| 4 | The **population mix** changed | decompose Δtotal into within-segment change and mix change before attributing anything |
| 5 | The **ground truth** is wrong | hand-audit ~50 failures for label correctness |
| 6 | The **input distribution** changed | §3 below |
| 7 | The **code or model** changed | bisect |
| 8 | The **world** changed | last, not first |

The ordering is the point. Instrumentation is the modal explanation for a discontinuous move, and
it is the cheapest to rule out. Reaching for "the world changed" first is how weeks disappear.

**Discontinuous vs. gradual is diagnostic.** A step change on a date points at rows 1–3 and 7. A
slow drift points at rows 4, 6 and 8. If your metric fell off a cliff, a story about gradually
changing user behaviour is the wrong shape.

---

## 2. Pipeline-stage decomposition

The most useful MECE cut in practice, and the one the paper leaves you to invent. Enumerate over
stages, ask what could break at each, and ask what evidence would show it broke there:

model requirements → data collection → data cleaning → labelling → feature engineering →
training → evaluation → deployment → monitoring

Two stage-specific catalogues worth having memorised:

**Where a broken split hides** (this is the sample-ratio-mismatch taxonomy, and it generalises to
any "the two arms are not comparable" problem): assignment (buggy bucketing, faulty IDs, carryover
from a previous experiment) · execution (variant-specific redirects, latency differences,
telemetry loss in one arm) · log processing (bad joins, bot filtering that differs by arm) ·
analysis (segmenting on a post-treatment variable) · interference (bots, ramping, spillover).

**Where a serving pipeline diverges from a training one**: features computed by different code in
the two paths; a join against a table whose contents changed since training; aggregates read at a
different freshness; a transform applied in one path and not the other. Log the features actually
used at serving time and train from those logs; that single practice removes most of this branch.

---

## 3. Distribution shift — the branch that is usually misdiagnosed

"The data changed" is not a diagnosis. There are five branches, and they have **different
detectors and different fixes**. Naming which one is the whole job.

| Branch | What changed | Detect | Fix |
|---|---|---|---|
| **Covariate shift** | P(x) changed, P(y\|x) stable | two-sample test on inputs; KS on classifier outputs | importance weighting; collect data from the new region |
| **Label / prior shift** | P(y) changed, P(x\|y) stable | compare predicted class marginals to expected | prior correction; recalibrate |
| **Concept shift** | P(y\|x) changed — old labels are now wrong | performance drops with inputs unchanged | relabel and retrain; the old data is a liability |
| **Training–serving skew** | *nothing* changed in the world; the two code paths disagree | compare features logged at serving against training features for the same entity | fix the code. Usually an hour |
| **Feature staleness** | same feature, different freshness in the two paths | check the age of each aggregate at read time | align refresh cadence |

The expensive misdiagnosis is treating skew as concept drift: you retrain, ship, it looks fixed,
and it recurs the following week because the bug is still there.

**A detected difference is not necessarily a malignant one.** Before chasing a shift, check whether
it actually costs you accuracy. Distributions differ constantly and most of it is irrelevant.

---

## 4. Category checklists for free-form generation

When the structured cuts are exhausted, the 6M categories are the standard net — they exist
because unstructured brainstorming reliably misses branches:

**Machine** (hardware, infrastructure) · **Method** (algorithm, logic, procedure) · **Material**
(inputs, data, upstream feeds) · **Personnel** (who did what, training, handoffs) ·
**Measurement** (the instrument itself) · **Environment** (load, network, season, region).

Note that **Measurement is a first-class branch**, not an afterthought. That is the whole
justification for the validity gate in `SKILL.md`.

**Premortem.** The best-validated generation technique available, and it takes ten minutes:
assume it is a month from now and you fixed the wrong thing — explain why. Prospective hindsight
raises the number of correctly identified causes by roughly 30% over ordinary "what could go
wrong" ideation.

---

## 5. Running the whys so they reproduce

Asking why until you reach something you can change — the five-year-old's method — is the standard
move for turning a crude explanation into a granular one, and it works. It also has a documented
failure mode: run by two different people on the same incident it produces two different root
causes, because it is a single chain and it terminates wherever the investigator already believed.
Four guardrails make it reproducible.

- **Run several chains in parallel from the same symptom, not one.** Real failures usually have
  concurrent contributors, and a single chain can represent only one of them. Branch at every level
  where more than one answer is true, and carry all the branches forward.
- **Ask "how" as well as "why."** "Why" invites attribution and stops at the first blameworthy human
  or component; "how" surfaces the conditions that made each step locally reasonable. "Why did the
  operator push the bad config" ends the investigation. "How was pushing it possible, and how did it
  look correct at the time" continues it.
- **Stop on a condition, not on a count.** Stop when you reach something you can actually change
  *and* that survives the IS/IS-NOT grid. Three, five, seven — the number has no property. Stopping
  early gives you a symptom restated; going too far gives you "because the company has a deadline
  culture", which is true and useless.
- **Every link must be a claim you could check.** If you cannot state the observation that would
  break a link, the chain is fiction from that point down. Write each link as an assertion with a
  test beside it, not as a sentence that follows plausibly from the one above.

The output is a small tree of candidate causes, not a single chain — which is exactly the input the
prioritisation step wants anyway.

## 6. Building your own signature library

The generic libraries above are thin. The valuable one is domain-specific and you have to build
it, the way `ocr-error-triage` carries a table mapping observed signature → concrete remedy.

The method:

1. **Mine your own history.** Walk closed incidents, postmortems, and fixed bugs. For each, record
   the *observable signature* — what you could see before you knew the answer — and the cause.
2. **Write signatures as observables, not as causes.** "Failures concentrate in one column" is a
   signature. "Crop geometry is wrong" is a cause. The library is indexed by the former.
3. **Each entry names a change with an obvious implementation.** If the remedy is "improve data
   quality", the entry is worthless. Delete it.
4. **Record the entries that did not pan out.** A remedy that seemed obvious and failed is worth
   as much as one that worked, and stops the next person re-running it.
5. **Add an entry every time you finish a diagnosis.** This is the compounding asset; the workflow
   is just the thing you do while the library is thin.

An entry is ready when someone who has never seen the system could match the signature and apply
the remedy without asking you what you meant.
