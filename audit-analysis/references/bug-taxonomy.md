# Bug Taxonomy: Real Findings, Real Numbers

Every entry below reached a compiled manuscript, was verified against data, and
moved a published number. Use them to calibrate what "consequential" means —
especially when briefing audit agents, who otherwise report style opinions as
findings.

Two facts about the distribution are worth stating up front, because they shape
where to look:

1. **None of these was catchable by a linter, a type checker, or a unit test.**
   The code ran, reproduced, and was wrong.
2. **Eight of nineteen were introduced by earlier *correct* fixes** — a table
   was regenerated and the sentence citing it was not, or one consumer of a
   variable was fixed and another was not. Fixing is itself a bug-generating
   operation. Audit after fixing.

---

## Class 1 — Denominator and unit mismatch (3 instances)

| | |
|---|---|
| **Symptom** | A comparison between two quantities built on different bases |
| **Why invisible** | Each quantity is correct in isolation; the error exists only in the comparison |
| **Detection** | Reconstruct the denominator: `numerator / rate`. If it is not what you expected, you have found it |

**1a. Mixed units inside one regression.** Tracking per *visit* regressed on
flagged domains per *domain*. Reported: −3.069 (SE 0.817, p < .001). With
matched denominators: −10.905 (SE 7.344, **p = .138**). The finding was the
mismatch.

**1b. Counterfactual against the wrong baseline.** A residual-after-blocking
measure counted unblocked *domains*; the published baseline counted *cookies*.
Blocking efficacy **84.3% → 70.2%**; age ratio 1.79 → 1.98; Δ log-ratio −0.406 →
−0.508. The source file carried a comment saying the two were not comparable and
built the matched column — and every consumer used the wrong one anyway.

**1c. One denominator differing from all others.** A share divided by the
unfiltered frame (60,547 rows with no attributable key) where every other rate
divided by the filtered count. 963 of 1,134 units affected; mean 0.5503 → 0.5573.

---

## Class 2 — Missing coded as zero (3 instances)

| | |
|---|---|
| **Symptom** | "Not measured" recorded as "measured, and it was zero" |
| **Why lethal** | If the *rate* of missingness changes across waves or groups, the fill manufactures a trend that is entirely artifact |
| **Detection** | Fill rate by group and by period. The level is nearly useless; the change is the finding |

**2a. The original.** A rank-capped extract meant most units were never queried;
the code filled 0. Coverage 58% → 66% across waves, and that growing gap alone
produced an apparent decline. Over half the reported drift was artifact.

**2b. The resurrection.** After 2a was fixed to leave unqueried values `NaN`, a
downstream notebook tested `NaN > 0` — `False` — and restored the artifact
exactly. Coverage 45.2% → 36.3%; published **−8.7pp against a true −3.1pp**.
*Fixing a fill at its source does nothing if a consumer re-implements it.*

**2c. One row, two populations.** The same `NaN > 0` made prevalence run over
all 6,902 units (never-asked counted as absent) while the rank correlation on
the same table row dropped those pairs and ran on 2,490. Agreement 49.1% on the
wrong population, **74.2%** on the right one.

---

## Class 3 — Silent row loss

**3a. Differential deletion by groupby.** A measures table was built by grouping
a *filtered* frame (third-party requests only). Units with no rows in the filter
vanished — not as unmeasured but as measured-and-zero. 288 of 13,711 in one
wave, 472 of 12,748 in the next (2.1% vs 3.7%), and they were exactly the
"lost everything" cases. A headline stability claim moved **−0.1pp → −0.8pp**.

Verify any such fix is *purely additive*: rows added, every pre-existing row
numerically identical including its NA pattern.

---

## Class 4 — Provenance drift (8 instances)

**4a. Prose quoting the previous version of its own table.** Values in the text
were byte-identical to the pre-fix table: 2.28 / 4.57 / 7.42 where the current
table said 2.86 / 7.31 / 9.08.

**4b. A section contradicting its own paper.** Limitations said "race **and
age** are not [indistinguishable]"; the cited table reported age χ²(4) = 3.1,
**p = .55**, and the methods section said the opposite. Stranded by an earlier
correct fix to the age brackets.

**4c. Stale table, stale prose, correct code.** Underlying data regenerated,
notebooks not re-run: +21.0% published against +22.2% current. Simulating the
pre-fix data reproduced the committed table bit-for-bit, which is how you prove
staleness rather than assert it.

---

## Class 5 — Estimand and labelling

**5a. Joint read off a marginal.** "Over 65% met all three" — the marginals were
76.0 / 65.9 / 81.0, so 65% was the smallest marginal, an *upper bound* on the
joint. True joint: **59.1%**.

**5b. One quantity, three values.** The same interval appeared as "6.2 and 8.4",
"[6.20, 8.27]" and "6.2 and 8.3". The 8.4 paired one column's lower bound with
another column's upper bound — an interval present in no column.

**5c. A count labelled a share.** A table column headed "Top share (00s)"
regressed a visit *count*; its dependent-variable mean of 30 was 3,009 ÷ 100. A
share expressed in hundreds cannot exist.

**5d. A mean labelled a median.** 54% was the mean; the median was 56%.

**5e. Decomposition total ≠ paper's estimand.** A shift-share decomposition's
total was visit-weighted while the paper's claim was person-averaged. Components
summed to the total correctly, so an internal-consistency gate passed — but the
total was not the number being decomposed.

---

## Class 6 — Inference

**6a. Randomisation-inference p without the +1.** `k/B` instead of
`(k+1)/(B+1)`: anti-conservative by `1/(B+1)`, admits p = 0 from finitely many
draws. Headline **.050 → .055**, crossing the threshold the claim rested on. And
with B = 200 the floor is .005, so "p < .001" was unattainable by that design.

**6b. Inclusion probabilities that violate their own design.** Hájek weights
with `π = min(n·p, 1)` applied to a sample drawn by `choice(replace=False, p=)`,
which is *successive* sampling. **Σ min(n·p,1) = 91.10 for n = 100** — a
one-line falsification. The supposed certainty units had true π of 0.999 down to
0.729. Estimate 8.45 → **8.11**. Note this was a *wrong fix on top of a real
bug*: the original PPS-as-SRS diagnosis was right, the correction was not.

**6c. Multiplicity family not matching the reported statistic.** A Bonferroni
count computed over *level* coefficients, while every headline claim was about
*changes*. The correction answered a question nobody asked.

**6d. Module-level consumed RNG.** A bootstrap drawing from a generator created
in an earlier cell: re-running without re-running the predecessor produced
different published intervals. Build the RNG inside the function.

**6e. Solver stopping short.** Quantile regression by IRLS is an approximation
to a linear program; rescaling the outcome moved a coefficient ~1%. Re-solve
exactly and compare *objectives*, not coefficients — with collinear regressors
the argmin need not be unique, its value is.

---

## Class 7 — Dtype traps

**7a. Object dtype after a left merge.** A boolean column becomes object; `~` is
then integer bitwise NOT (`~True == -2`), turning a mask into negative labels.
Cost real time on three separate occasions. Always `.astype(bool)`.

**7b. `pd.NA` poisoning `.describe()`.** `pd.NA` promotes to object dtype, and
`.describe()` on object returns `count/unique/top/freq`. Every cell of an
emitted summary table was the wrong statistic: the column printed as "mean" held
**1,120**, the number of distinct values, where the true mean was **11.70**. Use
`np.nan`.

---

## Findings that did NOT survive verification

Record these too. All three came from capable agents with plausible reasoning,
and each would have wasted a fix.

- **"The analytic file is 14 months stale."** False. Checked against git
  history: the commit in question only *added* a subset, and the script that
  writes the file postdates it.
- **"Structural zeros inflate the age gap."** Backwards. The older group had
  *more* all-zero observations (0.258 vs 0.218, p = .042), so the zeros make the
  published gap conservative.
- **"The reach audit repeats the PPS-as-SRS error."** Real issue,
  mis-diagnosed. Under sampling ∝ size, the *unweighted* sample mean is the
  natural estimator of the size-weighted population mean, so the point estimate
  was approximately right for its estimand. The actual defect was the
  design-naive Wilson interval. Correct finding, wrong error.

The lesson is not that agents are unreliable — two of these three pointed at
something real. It is that **the diagnosis is a hypothesis until you compute
both versions yourself.**
