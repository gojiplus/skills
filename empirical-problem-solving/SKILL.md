---
name: empirical-problem-solving
description: Diagnose a broken empirical metric, model, experiment, or pipeline. Use to reproduce and shrink failures, enumerate rival causes, order tests, and stop on evidence.
---

# Diagnosing an empirical problem

## Overview

Diagnose before you look for solutions. The exception proves it: when a fix is cheap and
reversible, trying it *is* the cheapest diagnostic — give the antihistamine, see if the nose
stops running. Everything below is about the case where it is not that cheap.

The failure mode this skill exists to prevent is not failing to find a cause. It is finding one
that isn't there. A diligent analyst who slices a failure by fifteen dimensions, four metrics and
three time windows has run about 180 comparisons and will surface a striking slice from pure noise
essentially always. The story will be coherent and the fix will not hold out of sample. Most of the
machinery here exists to make that outcome detectable.

Division of labour: use this skill when you have a **symptom and no cause** — the deliverable is a
named cause, the evidence that survived, and a gated fix. Use `audit-analysis` when the question is
whether a number means what the prose claims, `audit-package` when it is whether code does what its
documentation says, and `ocr-error-triage` when you already have a measured pipeline and a candidate
fix — it owns the operational fix-validation loop and this skill deliberately does not duplicate it.

A general skill risks producing general advice, which is worthless. What is genuinely reusable
across domains is narrow — the validity gate, the pipeline-stage and distribution-shift
decompositions, the ordering rules. Everything else has to be *retrieved from a library you built*,
and [hypothesis-libraries.md](references/hypothesis-libraries.md) is mostly a method for building
one. Provenance and citations: [diff-from-paper.md](references/diff-from-paper.md),
[sources.md](references/sources.md).

## Usage

`/empirical-problem-solving <symptom> [diagnose|fix|both]` — mode defaults to `both`.

## Workflow

1. **State the deviation, and whose it is.** What differs from what was expected, for whom, since
   when, and do you actually want to solve it. Name the metric, unit and population before naming a
   method. "The model is bad" is not a deviation; "top-1 accuracy on Bengali rolls fell from 0.94 to
   0.81 after the March retrain" is. Decide here whether you are working against the topline goal or
   a metric built for the failure, and what that choice obliges you to show — section below.

2. **Check the metric is telling the truth** before diagnosing why it moved. Section below.

3. **Reproduce, then shrink.** Do not hypothesise about a failure you cannot produce on demand, then
   minimise it — [isolation-and-evidence.md](references/isolation-and-evidence.md).

4. **Specify IS and IS-NOT.** Where, when, for whom and how much it fails, each paired with where it
   plausibly could have failed and did not. The cheapest high-information step you have.

5. **Retrieve rivals, then invent them.** Walk the pre-built decompositions in
   [hypothesis-libraries.md](references/hypothesis-libraries.md) first — pipeline stage,
   distribution-shift branch, the 6M categories — then ideate for what they missed. Run the
   three-whys on each survivor until it names something you could change.

6. **Order by P(cause) / cost, then drop the ones that cannot change your action.** See
   [prioritizing-and-stopping.md](references/prioritizing-and-stopping.md). A hypothesis whose
   resolution leads to the same fix either way is worth nothing however plausible it is.

7. **Isolate — by removal *and* by injection.** Matched comparison, intervention, component metrics
   and funnels, bisection. Then the converse: create the problem where it does not exist. Removing
   the cause from a failing case tests necessity; injecting it into a working one tests sufficiency;
   a cause that passes both is as close to settled as diagnosis gets.

8. **Update on what you found, including on nothing.** A negative result is data. Section below.

9. **Decide whether to keep going.** Diagnose in proportion to how irreversible the fix is and what
   a wrong one costs — not to how interesting the mystery is.

10. **Fix, scoped narrowly; verify; gate.** Four checks, then a committed regression test. Section
    below.

## Is the metric telling the truth?

Run this before diagnosing anything, in this order — it is roughly decreasing frequency and
increasing cost to investigate. A hit here means stop and fix the data; there is nothing to
diagnose about a number that is wrong.

| check | what a hit means |
|---|---|
| did the logging or instrumentation change | the metric moved, the world did not |
| did anything deploy at the discontinuity | including a config, a schema, a bot filter, a dashboard definition |
| sample ratio mismatch (χ² on assignment counts) | the assignment, execution, or join is broken; **discard the result, do not interpret it** |
| does the metric decompose into within-group and mix effects | a top-line fall with every segment rising is a mix shift, not a regression |
| hand-audit ~50 of the "failures" for label correctness | you may be diagnosing a model that was right |
| is the metric a valid measure of the thing you care about | and does it still measure it after the intervention |

Two are worth their cost on frequency alone. Sample ratio mismatch turns up in about 6% of online
experiments and its violation is almost never benign. Label error runs ≥3.3% across ten canonical
ML benchmarks and ≥6% in the ImageNet validation set — enough to flip model rankings, and enough
that "look at the worst failures" will hand you examples the model got right and the label got
wrong. This is Twyman's law made operational: the more interesting the number, the higher the prior
that it is an artifact.

**You can only correlate over dimensions you kept.** If telemetry is pre-aggregated over whatever
dimensions someone thought of in advance, the true cause is unrepresentable and everything below
converges confidently on the best available wrong answer. Then the first move is to instrument, not
to hypothesise — and note that this is a one-way door, because you cannot retroactively log.

## A true metric can still be blind

Validity and **sensitivity** are different properties, and everything below silently assumes both.
A metric can measure exactly the right thing and still be unable to see your fix. There are two
legitimate ways to resolve this and they owe you different things.

| route | what it costs you | what it owes you |
|---|---|---|
| **Build a metric aimed at the failure** — per-slice error rate, field-level accuracy, a diagnostic measure | it is a proxy, so it can move while the goal does not | construct validity and reliability: show it moves the right way on historical changes you already know were good or bad. An unvalidated proxy is a hypothesis about the business, not a measurement |
| **Use the topline goal metric** | no construct gap — it *is* the goal | power. State the effect size you expect and check the metric can detect it at the sample and horizon you have |

**These pull against the scoping rule, and the tension is the useful part.** Scoping the cause
narrowly is what makes a Pareto improvement attainable — and a narrow fix is precisely what a
topline metric cannot see. Verify a 2%-of-traffic fix on the topline and you have designed a test
that cannot succeed, then concluded the diagnosis was wrong.

The resolution is to use both, for different jobs: **the local metric detects the improvement, the
topline and guardrails detect the damage.** In-sample and out-of-sample gains are measured where
the fix acts; no-regression is measured everywhere else. Absence of topline movement is then not
evidence the fix failed — but a topline *decline* still blocks it.

## Finding a correlate is not finding a cause

The paper's first generator — find variables correlated with the error, test whether it varies by
location, time of day, day of week — is a garden of forking paths. It does not require you to
p-hack; it requires only that, had the data come out differently, you would have sliced
differently. Every system that automated this step had to add false-discovery-rate control or it
returned garbage.

So when you scan slices:

- **Log how many slices you scanned**, including those you looked at and discarded. A finding
  reported without its denominator is not interpretable.
- **Report adjusted q-values**, with a minimum support so tiny slices cannot fire.
- **Split the failures in two.** Explore freely on the first half, write the hypothesis down, test
  it once on the second. This converts an unbounded search into one pre-specified test, for free.
- **Compute the base rate among successes.** A feature present in 80% of failures is not a cause if
  it is present in 80% of successes. Inspecting only the failure population is the base-rate
  fallacy, and it is how confident wrong diagnoses get made.
- **Expect the worst slice to improve on its own.** A slice selected for being worst regresses to
  the mean with no intervention. Measure the fix on a *fresh* draw of it or you will score noise.

Ask of every check: *what result would have made me abandon this hypothesis?* If there isn't one,
you have not tested anything.

This is measured, not argued. `scripts/test_slice_discipline.py` simulates 20,000 rows with fifteen
dimensions and no cause at all: scanning ~280 slices and reporting the striking one fires on **97%**
of runs, every one of them false. The discipline above fires on **0%**, and both methods find a
planted cause 100% of the time. Re-run it with `--quick` after changing any threshold in this
section.

## One cause is a prior, not a stopping rule

Keep the maxim — usually there is one thing wrong, and the obvious explanation is underrated;
configuration and operator error dominate hardware faults in real outage data. But do not let it
terminate the search. Stopping at the first sufficient-looking explanation is the most common
documented diagnostic error, and in ML shortcuts come in multiples, where mitigating one measurably
*amplifies* reliance on the others. After you find a cause, look for the second one.

"The explanation that fits all the data is unique" likewise holds only when you have a test that is
both necessary and sufficient. Usually you don't, and several explanations fit — sharpened by the
finding that models with identical held-out performance behave differently under shift, so that
changing *only the random seed* moves stress-test results. When the evidence does not separate
rivals, say so: report the surviving set and name the test that would split it. Do not pick one and
call it the root cause.

## What a negative result buys you

An empty investigation is where most diagnostic time goes, and the paper is silent on it. Do not
just cross the hypothesis off: redistribute probability toward hypotheses tested **weakly** as well
as untested ones, and re-examine the evidence behind your prior, since a missing signal is often
evidence about the instrument rather than the world. Record rejected hypotheses and why — a false
lead that is not written down gets chased again. Detail in
[prioritizing-and-stopping.md](references/prioritizing-and-stopping.md).

## Fix and verify

**Scope the cause narrowly enough that a Pareto improvement is attainable.** This is the reason to
insist on granular hypotheses, and it is stronger than actionability. A vague cause forces a broad
fix; a broad fix guarantees collateral damage. "The data is bad" licenses rewriting the loader.
"The camera has a dead pixel in the acquisition region" licenses a two-line patch you can verify.

Then four checks:

| check | means |
|---|---|
| **in-sample** | the target metric improves on the cases you diagnosed against |
| **out-of-sample** | it improves by a comparable margin on cases never inspected. A much smaller gain means you fitted the diagnosis set |
| **no regression** | what used to work still works — **especially the closely related cases** |
| **cost** | runtime, latency and spend do not rise materially |

The third is the one people get wrong. A random regression sample is weak; the damage from a narrow
fix lands on the *near misses* — cases sharing the failing feature that were already correct.
Sample those deliberately. And report the flip matrix (old-right/new-wrong, old-wrong/new-right),
not the change in the aggregate: negative flips are routine at improved overall accuracy, and an
aggregate delta hides them by construction.

Pareto is waivable for ML models, where aggregate in-sample and out-of-sample improvement is
sometimes the honest criterion and per-slice non-regression is not attainable. Waive it explicitly,
in writing, or it becomes an excuse. For the operational machinery — fixed
DIAGNOSE/VALIDATE/REGRESSION splits, recording baselines to a file rather than to memory, and the
failure modes of validation itself — use `ocr-error-triage` §4 rather than reinventing it.

**Every diagnosis ends in a committed test** that fails on the old system and passes on the new.
Watch it fail before you trust it. A repair without a gate is a repair that regresses. Where no
naturally failing case exists to build the test from — the usual reason this step gets skipped —
inject the cause into a healthy one and build it from that.

**If the fix does not work, there are three explanations, not two.** The diagnosis was wrong, the
solution was wrong, or the metric never measured the outcome and what you saw was novelty that
decayed. Check the third before re-running the first.

## Output contract

Start with the verdict — the named cause, or an explicit "no cause established." Then:

1. The deviation: metric, unit, population, magnitude, onset.
2. Validity gate results, including the checks that passed.
3. Rival hypotheses considered, where each came from, and how many slices were scanned.
4. For each: the test run, what it could have shown, what it did show.
5. Rejected hypotheses and why.
6. The surviving cause or set, with the test that would separate a set.
7. The fix, its scope, the four checks, and the committed gate.

Never present a story that fits the data as a diagnosis. Say which observation would have refuted
it and confirm you could have made that observation.

## Red flags you are cutting corners

- You started diagnosing why the metric moved without checking whether the metric moved.
- You reported the striking slice without reporting how many slices you looked at.
- You found a feature common among failures and never checked its prevalence among successes.
- You explored and confirmed on the same data.
- You measured the fix on the same slice whose extremity selected it.
- You accepted the first explanation that fit and did not look for the second.
- You only removed the suspected cause and never added it to something that worked.
- You verified a narrowly scoped fix on a topline metric that could never have detected it, and
  concluded the diagnosis was wrong.
- You tracked improvement on a metric you built for the purpose and never showed it tracks the goal.
- You injected the cause, saw the metric move the right way, and never checked it moved far enough.
- You called something the root cause when your evidence only narrowed it to three.
- You ran an ablation with one seed and one tuning budget per arm and called it causal.
- You crossed a hypothesis off after a test too weak to have detected it.
- You verified with a change in the aggregate and never looked at what got worse.
- You reported "no regression" from a random sample rather than from the near misses.
- You are still investigating a question whose answer would not change what you ship.
