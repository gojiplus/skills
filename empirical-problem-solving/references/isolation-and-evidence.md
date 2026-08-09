# Isolating the cause, and what your evidence can prove

---

## 1. Reproduce, then shrink

Do not hypothesise about a failure you cannot produce on demand. Reproduction is the gate, not
the warm-up: an intermittent failure you cannot trigger will absorb unlimited diagnosis and
confirm whatever you already believed.

Once you can reproduce it, **minimise it before you theorise about it**. Shrinking collapses the
hypothesis space mechanically rather than by argument, and it is usually the highest-leverage
single move available.

**Delta debugging.** Repeatedly remove parts of the failing input and re-test; keep removing while
the failure persists. You terminate at a *1-minimal* input — one where removing any single
remaining element makes the failure disappear. Published results: a browser crash reduced from 95
user actions to 3, and 896 lines of HTML to 1. The variant that isolates the *difference* between
a passing and a failing configuration is the same algorithm applied to two inputs.

**Bisection is the same algorithm over time.** If the metric moved on a date, binary-search the
commits, the config versions, and the data snapshots. `git bisect` when the suspect is code; the
same manual procedure over daily data partitions when the suspect is data. O(log n) beats
ideation, and it does not care whether your priors were any good.

Both apply far outside software: bisect a batch of records, a set of features, a date range, a
list of upstream feeds.

---

## 2. IS and IS-NOT

The cheapest high-yield step in the whole skill, and the one most often skipped. For each cell,
record what the deviation **is**, and what it plausibly **could have been but is not**. The gap
between the two columns is where the cause lives.

| | IS | IS NOT (but could have been) |
|---|---|---|
| **What** | which object, which field, which metric | which similar objects are unaffected |
| **Where** | which region, host, page, segment | which comparable ones are clean |
| **When** | first seen, pattern, since which event | when it does *not* occur — quiet periods, prior releases |
| **Extent** | how many, how much, trend | how bad it is *not* — the ceiling it never crosses |

Then test each candidate cause against the whole grid under one rule: **if this were the cause,
how does it explain both the IS and the IS-NOT?** A cause that explains why it broke but not why
the identical neighbouring case is fine is not yet a cause.

The negative space is high-information precisely because it is constraining. "Only Bengali rolls,
only after March, only the supplement pages" eliminates more hypotheses in one line than a week
of correlation scanning.

---

## 3. Matched comparison

Compare the failure against the most similar case that succeeded. The closer the match, the
fewer differences survive, and each surviving difference is a candidate.

Where you cannot find a natural match, you can sometimes construct one — edit the input so that
exactly one feature changes and re-run. This is what makes counterfactual rewriting a genuine
test rather than a story: you can execute the counterfactual and check the prediction.

**The trap:** matched comparison is the Method of Difference, and it identifies a cause only if
the match really is matched on everything else. In practice the "similar" case usually differs in
several ways at once and you have re-created the correlation problem with n=2.

---

## 4. Intervention — differential diagnosis

Rule out a cause by acting on it, the way a course of antibiotics eliminates infection as an
option. Learn by doing something. This is mandatory rather than optional wherever people are
involved: you can simulate the effect of code, but you cannot simulate how couriers respond to a
$10 on-time bonus.

**Write the prediction down before you run the intervention.** "If cause X, then metric Y moves by
roughly Z" — recorded first. Without it you will find the result consistent with whatever you
already believed, and an intervention interpreted after the fact is a story, not a test.

**Ablations are a weak causal design unless you control three things:**

- **Equal tuning budget per arm.** Reported architecture gains have repeatedly evaporated when the
  baseline was given the same hyperparameter search — in one recommender review, eleven of twelve
  recent neural methods lost to properly tuned simple baselines.
- **Multiple seeds, with intervals.** Models with identical held-out performance can behave very
  differently under stress; a single-seed difference between two arms may be seed noise. Retrain
  each arm N times and compare distributions.
- **Entanglement.** In a jointly-optimised system, removing a component measures its contribution
  *plus* the reoptimisation of everything else. Changing anything changes everything. State which
  you are measuring.

---

## 5. Inject the cause, do not only remove it

Everything above isolates by **removal** — ablate the component, drop the suspect input, bisect
away the change. The converse move is to *create the problem where it does not exist*: take a case
that works, introduce the hypothesised cause, and see whether the symptom appears.

The two are not stylistic alternatives. They test different things, and only together do they
settle a cause:

| move | establishes | test type |
|---|---|---|
| remove the suspected cause from a failing case — does it recover? | **necessity** | **hoop** — failing it eliminates the hypothesis; passing proves little |
| inject the suspected cause into a working case — does the symptom appear? | **sufficiency** | **smoking gun** — passing it confirms strongly; failing proves little |
| both | necessity **and** sufficiency | **doubly decisive** |

This is how you construct the doubly-decisive test that §7 says you usually lack, and it is the
constructive answer to the Physicist's Method: an explanation that both accounts for the failures
*and* reproduces them on demand is unique in a way that one merely fitting all the data is not.

**Injection manufactures a reproducer when nature will not.** Section 1 assumes you can trigger the
failure. Often you cannot — it happened once, in production, three weeks ago, and never since.
Injecting the hypothesised fault into a healthy copy is then the only route to a reproducer at all.
Feedback-driven fault injection reproduced every failure in a distributed-systems benchmark by
injecting the root-cause faults, at a median of eight minutes each.

| domain | how to inject |
|---|---|
| data | splice the malformed value, duplicate key, or null into a clean batch |
| code | apply the suspect commit onto a known-healthy branch |
| config | set the suspect flag or limit on one healthy host |
| infrastructure | kill the dependency, add the latency, drop the packets |
| ML | add the shortcut cue to clean examples; corrupt a label; serve a stale feature |
| pipeline | replay a clean batch through the suspect stage only |

**Then apply the fix to the injected case.** Inject → confirm symptom → fix → confirm resolution is
the cleanest validation available, and it *produces* the regression test rather than requiring you
to find one. This matters because the usual reason a diagnosis ships without a permanent gate is
that no naturally occurring failing case was available to build one from.

Three cautions, without which this becomes a confirmation-bias engine:

- **Sufficiency is not operation.** Reproducing the symptom shows the mechanism *can* produce it,
  not that it *did*. Go back and confirm the cause was actually present in the real failures — a
  plausible mechanism you injected yourself is evidence about physics, not about this incident.
- **Check magnitude, not just direction.** If injecting the cause moves the metric 0.5% and you
  observed 13%, it is not the cause, or not the whole cause. This is the most useful half of the
  technique and the half routinely skipped, because a directional match feels like confirmation.
- **Bound the blast radius.** Injection is a deliberate fault. Decide in advance what fraction of
  traffic, which host, and how you abort.

Note the symmetry with §8. The null test asks whether your *instrument* stays silent when there is
no cause; injection asks whether the *system* breaks when there is one. Same discipline, opposite
direction, and a diagnosis that has passed both is about as well established as they get.

---

## 6. Which parts of the system are working

Keep a metric for every component essential to the output — latency and throughput for services,
input validity for feeds, per-stage counts for pipelines. This is what lets you eliminate rather
than speculate. Learn how the cookie is baked: what data flows where, what decision is made at
which point, on what assumptions, for what purpose.

**Funnels.** Start at 100% and draw where it goes. Funnels capture two things at once: how much is
lost at each step, and where the losses come from. Three standing cautions:

- they present correlation as causation
- they are vulnerable to Simpson's paradox under aggregation
- **coarseness drives the conclusion** — with a continuous variable, do not chop into arbitrary
  buckets. Plot the outcome against the variable first and cut where the slope changes.

**Scoring candidate slices.** When many dimensions could explain a move, rank explanations by
three criteria rather than by eye: *explanatory power* (what share of the total deviation this
slice accounts for), *succinctness* (fewest dimension-values — Occam), and *surprise* (how far the
observed distribution is from the forecast one). And treat **derived** measures carefully: a ratio
like cost-per-click does not decompose the way its numerator does.

---

## 7. What a test can actually establish

Before running a test, know which of these it is. This is the vocabulary that dissolves most
arguments about whether a diagnosis is proven.

| Type | Passing it | Failing it |
|---|---|---|
| **Straw in the wind** | weakly suggestive | weakly suggestive |
| **Hoop** — necessary, not sufficient | proves little; the hypothesis stays alive | **eliminates** the hypothesis |
| **Smoking gun** — sufficient, not necessary | **confirms** strongly | proves little; hypothesis survives |
| **Doubly decisive** — both | confirms | eliminates |

Two consequences:

- **"The explanation fits all the data" only establishes uniqueness if you had a doubly decisive
  test.** Otherwise several explanations fit and you have selected among them on grounds you have
  not stated. Report the surviving set and name the test that would split it. When no such test
  exists naturally, build one: removal plus injection (§5) is a doubly decisive test you can
  construct.
- **Do not run tests with no discriminating power.** If a result is roughly equally likely under
  every live hypothesis, it will not move your beliefs, and running it feels like progress while
  producing none. Prefer the test that most nearly halves the hypothesis space over the test most
  likely to confirm your favourite.

**Select on inconsistency, not on support.** Evidence consistent with many hypotheses has no
diagnostic value; the hypothesis to prefer is the one with the fewest *inconsistencies*, not the
one with the most confirmations. Also list evidence that is **absent but should be present** if a
hypothesis were true — its absence is a hoop test you get for free.

---

## 8. Run the null on your instrument

Before an analysis method's output counts as evidence, establish that it can come back empty.

Saliency maps are the cautionary case: some widely used methods produce visually compelling,
essentially *identical* attributions from a trained model and from a randomly initialised one.
They were edge detectors — invariant to the model and invariant to the data — and were being read
as explanations for years.

So for any diagnostic instrument you rely on, whether a slice finder, an attribution method, an
anomaly detector or an LLM grader:

1. **Plant a known cause** and confirm the instrument recovers it.
2. **Run it on a system with no cause** — scrambled labels, randomised model, A/A split — and
   confirm it reports nothing.

An instrument that always returns an answer is returning noise. This is the diagnostic analogue of
an A/A test, and it is the same rule as `ocr-error-triage`'s "checks that cannot fail": ask what
input would make this come back clean, and if there isn't one, it is decoration.

Post-hoc explanation methods are legitimate **hypothesis generators** and illegitimate
**hypothesis confirmers**. The output is a claim about an intervention; go run the intervention.
