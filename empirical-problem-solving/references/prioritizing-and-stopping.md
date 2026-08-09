# Prioritising what to investigate, and when to stop

The paper offers a seven-column matrix — plausibility, impact, cost-effectiveness, speed of
investigation, speed of solution, span of control, ease of implementation — and no rule for
combining them. In practice that means the columns get filled in and the decision gets made on
vibes. This file replaces it with one ratio, two filters, and a stopping rule.

---

## 1. The ordering rule

**Order candidates by P(cause) / cost(test + fix).**

Under a single-fault assumption with independent costs, this is not a heuristic — it is the
optimal repair order. It collapses five of the seven columns: cost-effectiveness, speed of
investigation, speed of solution and ease of implementation are all *cost*; plausibility is the
numerator.

Two of the paper's columns survive as separate gates rather than as terms in the ratio:

- **Span of control.** A cause you cannot act on has no fix, so it has no cost, so the ratio is
  undefined. Handle it by filtering: if it is outside your control, the deliverable is escalation,
  not investigation.
- **Impact** belongs in the stopping rule, not the ordering. It determines *whether* to diagnose
  at all, not which hypothesis to test first.

**Cheap-and-decisive before expensive-and-decisive, always.** The whole validity gate in `SKILL.md`
sits at the top of the order for this reason: those checks cost minutes and can eliminate the
entire investigation.

---

## 2. Filter one: would the answer change what you do?

Before investigating anything, ask what you would do under each possible outcome. **If the answer
is the same either way, the investigation is worth nothing** — however plausible the hypothesis,
however interesting the question, however easy it is to run.

This kills a large share of the diagnostics people actually run. It is the sharpest single tool
in this file, and it costs one sentence.

The corollary bounds the value of the *whole* diagnosis: what you can gain by knowing the cause
for certain is capped by the difference in payoff between the fixes you would choose. If two
rival causes lead to fixes worth roughly the same, stop trying to separate them.

**The dominant-action check.** Before completing the diagnosis, ask: is there a fix that works
under *every* remaining hypothesis? Add capacity, add a retry, add a guardrail, add a fallback,
widen a tolerance, retrain on more data. If one exists and it is affordable, ship it and abandon
the diagnosis. Buying the answer is often more expensive than buying immunity to it.

---

## 3. Filter two: could you tell?

Two columns the paper's matrix is missing:

- **Detectability.** How would you even know if this were the cause? A hypothesis with no
  available observation is not a research programme, it is a mood. Either find the observation,
  instrument for it, or drop the hypothesis to the bottom.
- **Falsifiability.** What observation would refute it? Add this as a literal column. A hypothesis
  that no result could refute cannot be tested, only believed, and it will survive the entire
  investigation by construction and be there at the end looking vindicated.

---

## 4. Make "impact" measured rather than guessed

The impact column is normally a prior dressed as an estimate. Where the system decomposes into
components, you can measure it instead.

**Ceiling analysis.** Replace each component in turn with a perfect oracle — ground-truth output —
and measure end-to-end lift. That lift is the *upper bound* on the value of any work on that
component. The canonical illustration: in a face-recognition pipeline, perfecting the face
detector bought 0.1% while perfecting eye segmentation bought 5.0%. No amount of cleverness on the
detector was ever going to matter.

Two payoffs: the impact cell becomes an upper bound rather than a guess, and you get a principled
reason to **abandon** a component whose ceiling is below your target. Also attribute error to the
*earliest* component whose output diverges from the oracle — otherwise "component X is at fault"
and "component X received bad input" look identical.

---

## 5. Give the long shot its due

Order by the ratio, but do not let it bury the hypothesis that is unlikely and would explain
everything. The value of opening a box depends on its *upside*, not only on its mean — a
low-probability cause with a large, cheap, decisive test can be worth running early precisely
because of the variance.

Practically: promote any hypothesis that (a) would explain the full IS/IS-NOT grid on its own and
(b) has a cheap decisive test. Those two conditions together beat a moderately likely hypothesis
that would explain only part of it.

---

## 6. What a negative result does to the ordering

Do not simply cross the hypothesis off and move to the next row.

- Redistribute probability toward hypotheses **tested weakly** as well as untested ones. A
  hypothesis "ruled out" by a test that would have missed it half the time is not ruled out.
- Re-examine the evidence that produced your prior. An absent signal is frequently evidence about
  your instrument rather than about the world — the Air France 447 search was anchored for two
  years on beacons that never pinged; modelling that the beacons themselves may have failed
  produced the posterior that located the wreck within a week.
- Re-rank. The costs have changed: you now know more about what is cheap to test.

Record rejected hypotheses and the reason. Undocumented dead ends get re-explored.

---

## 7. The stopping rule

**Diagnose in proportion to irreversibility × the cost of a wrong fix. Not in proportion to how
interesting the mystery is.**

Ask what kind of door the fix is:

**Two-way door** — revertable behind a flag, ramped to 1%, monitored, undone in minutes. Then the
cheapest diagnostic is *the fix itself*. Try it. This is the paper's antihistamine exception, and
it is not an exception: for reversible fixes it is the general rule.

**One-way door** — retraining on modified data, deprecating a feature, changing a label
definition, a schema migration, a public policy change, anything that destroys the old state or
that users will build on. Here diagnosis is cheap relative to the mistake. Slow down.

Stop diagnosing when any of these holds:

- all live hypotheses imply the same action
- the expected gain from resolving them is less than the cost of resolving them
- a dominant fix exists and is affordable
- the fix is a two-way door and can be trialled directly

Keep going when the fix is irreversible, when the rival causes imply materially different fixes,
or when you have a cause that explains the IS but not the IS-NOT.

---

## 8. Is analytic diagnosis even the right method?

Everything above assumes the causal structure is stable and recoverable by analysis — that the
system is *complicated*, not *complex*. That assumption holds for most pipelines, services and
models, and it is why the method works.

It fails for recommender ecosystems, multi-team production systems, market dynamics, agent
behaviour, and anything with a strong feedback loop — systems where cause and effect are coherent
only in retrospect. There, the correct move is not a prioritisation matrix over hypotheses but
several small safe-to-fail probes run in parallel, amplifying whatever moves the metric. Minimise
the blast radius and treat the probes as the instrument.

Two specific structures that break the analysis:

- **The model's own past output is in the data.** Where a system's predictions shape the data it is
  next trained on — ranking, moderation, pricing, dispatch — correlating error with features is
  invalid, because the features were generated under the previous policy. You need exploration
  data or off-policy evaluation, not more slicing.
- **Drift rather than breakage.** Some systems degrade gradually through locally reasonable
  efficiency tradeoffs with no component ever failing. Asking "what broke" returns nothing because
  nothing broke. Map the control structure instead of hunting the faulty part.

Say which regime you are in before you start. Applying the analytic method to a complex system
produces a confident, well-evidenced, wrong answer.
