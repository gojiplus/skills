# Diff from Sood (2023), *Problem Solving*

Source: `gsood.com/research/papers/problem_solving.pdf`, dated 30 December 2023.

The paper is the spine of this skill. It is also four pages of correct advice with no gates, no
stopping rule, no validity check on the data it reasons over, and one step that — executed
diligently — manufactures false causes. This file records exactly where the skill departs from it
and why, so the departures are arguable rather than silent.

Three categories: **corrections** (the paper as written will mislead), **additions** (missing
steps), **kept** (carried over unchanged).

---

## A. Corrections

### A1 · §1.1 "Finding correlations" is a garden of forking paths

**Paper:** "To generate the candidate set, find variables correlated with the error… test if the
error varies by location, time of day, day of week, etc."

**Skill:** same move, run as a multiplicity-controlled procedure — log the number of slices
scanned, report adjusted q-values with a minimum support, and confirm the winner on a partition
never inspected.

**Why:** the multiple-comparisons problem does not require you to run many tests deliberately. It
requires only that, had the data come out differently, you would have sliced differently
(Gelman & Loken). Fifteen dimensions × four metrics × three windows is ~180 implicit comparisons.
This is not a theoretical concern: every system that automated this exact step — SliceFinder
(ICDE 2019), the shift-detection comparison of Rabanser et al. (NeurIPS 2019) — had to add false
discovery rate control or it returned garbage. **This is the paper's single largest hole**, and it
sits in the first substantive paragraph.

### A2 · §1.1 "Learning from failures" needs the base rate

**Paper:** "Start by selecting failures. Sample failures randomly. Or pick the worst errors; the
worst errors are often the site of the most obvious problems."

**Skill:** keep, but always compute the suspected feature's prevalence among *successes* too, and
measure any fix on a fresh draw of the slice.

**Why:** two distinct errors. First, analysing only the failure population is the base-rate
fallacy — Errudite (ACL 2019) made "analyse the full population, not a hand-picked sample of
failures" a founding principle after showing that a widely-repeated manual diagnosis of a QA model
was simply wrong once tested that way. Second, a slice selected for being *worst* regresses toward
the mean with no intervention at all (regressional Goodhart), so scoring the fix on the selecting
sample gives a false positive on the fix rather than on the diagnosis.

The paper's own caveat — "Selecting on the dependent variable is rightly frowned upon… even
correlation is not guaranteed" — is correct and then not acted on. This makes it operational.

### A3 · §1.4 maxim 2, single point of failure

**Paper:** "Generally, there is only one thing wrong rather than a few different things."

**Skill:** keep as a **prior**; reject as a **stopping rule**. Add: after you find a cause, look
for the second one.

**Why:** stopping after the first sufficient-looking explanation (premature closure, search
satisficing) is the most common documented cognitive cause of diagnostic error in medicine
(Graber et al. 2005). Cook's *How Complex Systems Fail* #3: catastrophe requires multiple
failures; single-point failures are generally not enough. And in ML the failure is measurable —
shortcuts come in multiples, and mitigating one *amplifies* reliance on the others (Li et al.,
CVPR 2023).

### A4 · §1.3 Physicist's Method

**Paper:** "Find the explanation that fits all the data. Generally, that explanation is unique."

**Skill:** uniqueness holds only when you have a doubly-decisive test. Otherwise report the
surviving set and name the test that would split it.

**Why:** three independent problems. Duhem–Quine — no hypothesis is testable in isolation, so
auxiliaries can be adjusted to accommodate recalcitrant evidence. Underspecification (D'Amour
et al. 2020) — many predictors achieve equivalent held-out performance and behave differently
under shift, so that changing *only the random seed* changes stress-test behaviour; "fits all the
data" is satisfied by an equivalence class. And Halpern's *Actual Causality* — which of several
jointly-sufficient conditions gets called "the" cause is fixed by a normality baseline the analyst
brings in, not read off the data.

Note: the paper cross-references "the section on Maxims" for this uniqueness claim, and the Maxims
section does not discuss uniqueness.

### A5 · §1.3 ablation has no stated conditions

**Paper:** "In ML, we can A/B test systems."

**Skill:** ablations are admissible causal evidence only with equal tuning budget per arm,
multiple seeds with intervals, and an explicit statement about entanglement.

**Why:** reported gains have repeatedly turned out to be tuning budget rather than the manipulated
component (Melis et al. ICLR 2018 on language models; Dacrema et al. RecSys 2019, where eleven of
twelve neural recommenders lost to properly tuned baselines). And CACE — *changing anything
changes everything* (Sculley et al. 2015) — means that in a jointly-optimised system, ablating a
component measures its contribution plus the reoptimisation of everything else.

### A6 · §1.2 the seven-column prioritisation matrix

**Paper:** "plausibility, impact, cost-effectiveness, speed of investigation (but plausibly also
the speed with which we can implement a solution), whether or not the cause is within the span of
control, and ease of implementation of solutions."

**Skill:** order by **P(cause) / cost(test + fix)**; filter by decision relevance; treat span of
control as a gate and impact as an input to the stopping rule; add detectability and
falsifiability as columns.

**Why:** the paper lists the columns and gives no combining rule, so the decision is made on
impression. Heckerman, Breese & Rommelse (CACM 1995) show that under a single-fault assumption
with independent costs, that ratio *is* the optimal repair order — and it absorbs four of the
seven columns, all of which are cost. Howard's information value theory supplies the filter: an
investigation whose outcome would not change your action has zero value. Ceiling analysis (Ng)
converts the guessed impact column into a measured upper bound. Detectability comes from FMEA,
where it is a scored axis alongside severity and occurrence.

---

## B. Additions

| # | Addition | One-line justification |
|---|---|---|
| **B1** | **Validity gate before diagnosis** — instrumentation change, deploy, sample ratio mismatch, mix shift, label audit, construct validity | SRM appears in ~6% of online experiments and its violation is almost never benign; label error runs ≥3.3% across ten canonical benchmarks, ≥6% in ImageNet val. Twyman's law becomes a procedure with a default ordering instead of a maxim |
| **B2** | **Reproduce, then shrink** | Delta debugging terminates at a 1-minimal failing input — 896 lines of HTML to 1. Bisection is the same algorithm over time. Collapses the hypothesis space mechanically; the paper never mentions minimal reproducers |
| **B3** | **IS / IS-NOT specification** (Kepner-Tregoe) | The negative space is the highest-information data in a diagnosis and the cheapest to collect. Entirely absent from the paper |
| **B4** | **Stopping rule** — diagnose in proportion to irreversibility × cost of a wrong fix; dominant-action check | The paper can diagnose forever. This also generalises the paper's own opening exception: the antihistamine test stops being a carve-out and becomes the rule for two-way doors |
| **B5** | **What a negative result buys** — redistribute toward weakly-tested hypotheses; re-examine the evidence behind the prior | AF447 was unfound for two years because the search trusted beacons that never pinged; modelling that the beacons may have failed produced the posterior that found it in a week. The paper is silent on the empty investigation, which is where most diagnostic time goes |
| **B6** | **Retrieve before you invent** — pipeline-stage, distribution-shift taxonomy, 6M, premortem | Elstein et al. (1978): clinicians generate 4–5 hypotheses in seconds and expertise proved to be case-specific knowledge, not general method. Klein's premortem raises correctly-identified causes ~30%. "The data changed" is not a diagnosis — five branches, five detectors, five fixes |
| **B7** | **Run the null on your instrument** | Guided Backprop yields near-identical saliency from a trained and a randomly-initialised model (Adebayo et al. 2018) — an edge detector read as an explanation for years. A diagnostic that always returns an answer is returning noise |
| **B8** | **Observability as a precondition** | You can only correlate over dimensions you retained. Pre-aggregated telemetry makes the true cause unrepresentable and the method converges on the best available wrong answer. A one-way door: you cannot retroactively log |
| **B9** | **Domain gate** (Cynefin) | Diagnose-before-solve is a *complicated*-domain method. In complex domains — feedback loops, multi-team systems, agent behaviour — cause is coherent only in retrospect and the move is parallel safe-to-fail probes. The paper assumes analysis recovers the structure |
| **B10** | **Four verification checks + flip matrix** | Aggregate improvement is not verification: negative flips are routine at improved overall accuracy (Yan et al., CVPR 2021), and an aggregate delta hides them by construction. The near-misses, not a random sample, are where a narrow fix does its damage |
| **B11** | **Scope the cause narrowly enough that Pareto is attainable** | A second and stronger reason for granular hypotheses than §1.1's actionability argument: a vague cause forces a broad fix, and a broad fix guarantees collateral damage |
| **B12** | **A third explanation for a failed fix** | §2 offers two — wrong diagnosis, bad solution. Add: the metric was never a valid measure of the outcome, or the effect was novelty and decayed (construct validity; novelty/primacy). Resolves the ambiguity the paper closes on |
| **B13** | **Every diagnosis ends in a committed regression test** | Otherwise the diagnosis is unfalsifiable and the fix silently regresses |
| **B14** | **Isolate by injection as well as by removal** — create the problem where it does not exist and see whether the symptom appears | Every isolation technique in §1.3 works by removal, which tests only *necessity*. Injection tests *sufficiency*; the pair is a doubly-decisive test, which is the constructive answer A4 was missing — an explanation that reproduces the failure on demand is unique in a way that one merely fitting the data is not. It also yields a reproducer when the failure will not recur naturally (feedback-driven fault injection reproduced every failure in a distributed-systems benchmark at a median of eight minutes), and it manufactures the B13 regression test when no natural failing case exists. Precedent: fault seeding (DeMillo, Lipton & Sayward 1978) and chaos engineering |
| **B15** | **Guardrails on the whys** — parallel chains rather than one, "how" as well as "why", stop on a condition rather than a count, every link a checkable claim | The paper's three-whys is kept (section C), but as written it inherits the documented defects of 5-whys: linear where failures have concurrent contributors, and non-reproducible — different facilitators reach different root causes from the same incident (Card 2017). The technique is worth keeping; it needed the repair rather than only the citation |
| **B16** | **Choose the measurement strategy explicitly, and price it** — a metric built for the failure owes construct validity and reliability; the topline goal metric owes power. Use the local metric to detect the improvement and the topline plus guardrails to detect the damage | The paper says "the ETA prediction model is failing" and proceeds, assuming a metric exists that can both diagnose and verify. Validity and *sensitivity* are different properties: a metric can measure exactly the right thing and be unable to see the fix. This also resolves a live tension with B11 — narrow scoping is what makes Pareto attainable, and a narrow fix is exactly what a topline metric cannot detect, so verifying one on the other is a test designed to fail. Metrics need validating against historical cases with known answers before they are trusted (Deng & Shi 2016) |

---

## C. Kept unchanged

Diagnose before looking for solutions, as the default. The antihistamine exception (promoted from
carve-out to rule by B4). Three-whys to reach granular hypotheses — kept as a generator, with the
guardrails in B15 rather than the bare instruction. MECE decomposition — worth
attributing to Minto's *Pyramid Principle*, whose stricter rule is that each level must be MECE
*and* ordered by a single logic (deductive, chronological, structural, comparative). The three
generators. Similar Others, including generated counterfactuals. Dr. House differential diagnosis
by intervention, and the observation that experimentation is a sine qua non where people are
involved. Component metrics, funnels, Sankey diagrams. The three funnel pitfalls — correlation as
causation, Simpson's paradox, coarseness — and the advice to cut a continuous variable where the
slope changes rather than into arbitrary chunks. System diagrams, state machines, process tracing.
Twyman's law. Skew — opportunity concentrated in a few places. Obvious is underrated, and the
configuration-errors-beat-hardware-faults evidence behind it. Fix upstream rather than downstream.
Generate options and select between them as separate discussions (Sunstein & Hastie). And the
closing point that problem-solving as continuous improvement is rarely one-shot.

Two maxims are kept with amendments rather than intact: single point of failure (A3) and the
Physicist's Method (A4) — the latter now with a construction, since B14 supplies the doubly-decisive
test that makes a uniqueness claim defensible.

---

## D. Two drafting bugs in the source PDF

Noted for whenever the paper is revised, not carried into the skill:

1. §1.3 states "There are **five** techniques for isolating causes" and then lists four — Similar
   Others, Dr. House, Which parts of the system are working, Physicist's Method. Either MECE was
   intended to count as the fifth or a bullet was dropped.
2. §1.3's Physicist's Method says "see the section on Maxims" regarding the uniqueness of the
   fitting explanation. §1.4 does not discuss uniqueness.
