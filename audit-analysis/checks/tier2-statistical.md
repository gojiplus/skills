# Tier 2: Full Statistical Review

Six sections. Work each in order — EDA genuinely comes first, because most of
what follows is only interpretable once you know the shape of the data. Mark
each item with a concrete finding or an explicit "inapplicable, because…".

---

## A. EDA, before anything else

**Check:** The shape of every analysis dataset, before any model is fit. Most
downstream errors are visible here and nowhere else.

**How:** For each dataset — `scripts/audit_data.py` automates this:

| | What to look at | What it catches |
|---|---|---|
| Shape | rows, unique keys, duplicate keys | fan-out from a bad join |
| Missingness | per column, **and by group and period** | differential missingness |
| Distributions | min / median / max / skew / kurtosis per variable | wrong estimator downstream |
| Zeros | count of exact zeros, separately from missing | structural-zero confusion |
| Range | values outside logical bounds | shares > 1, negative counts, dates outside the window |
| Tails | max/median, share of mass in top 1% | leverage, fragile means |
| Denominators | for each ratio, the reconstructed denominator | Tier 1 check 1 |
| Leverage | DFBETA and leave-one-out on headline coefficients | a result resting on one unit |

**Specific traps:**

- **Tiny denominators.** A ratio outcome computed from two observations is
  noise, and equal weighting gives it the same standing as one computed from
  forty thousand. Count the units below any sensible threshold and check whether
  results move when they are dropped. In the motivating case, 13 units had fewer
  than ten observations and 77 fewer than a hundred — and dropping them *raised*
  the headline coefficient from 2.809 to 3.010, which was worth reporting.
- **Bounded quantities out of bounds.** A share above 1 or below 0 is a
  construction bug, always.
- **Group-wise missingness.** Overall missingness is nearly useless. The
  question is always whether it differs.

---

## B. Joins

**Check:** That the join did what its author believed, on the population they
believed.

**How:**

- Declare cardinality on every merge (`validate="1:1"`, `"m:1"`; `assert` in R).
  An undeclared merge is an untested assumption.
- Assert row conservation. Record expected rows before, actual after.
- Confirm key uniqueness on the side that must be unique, and that the key
  *transform* is injective. String keys built by substitution (`.`→`_`), case
  folding, trimming, or truncation all collide. Count distinct keys before and
  after the transform and require equality.
- **`left` vs `inner` changes the population and therefore the estimand.** An
  inner join silently redefines who the analysis is about. Say which population
  each estimate describes.
- Watch many-to-many. If neither side is unique the row count multiplies, and
  every subsequent mean is weighted by an accident.
- **Check dtypes after the merge.** Two language-specific traps that both cost
  real time:
  - In pandas, a boolean column becomes **object dtype** after a left merge that
    introduces NAs. `~` on object dtype is integer bitwise NOT, so `~True` is
    `-2` and a mask silently becomes a list of negative labels. Always
    `.astype(bool)`.
  - `pd.NA` (as opposed to `np.nan`) promotes a numeric column to object, and
    `.describe()` on object dtype returns `count/unique/top/freq` rather than
    the moment summary. A table built from that reported the *number of distinct
    values* in a column labelled "mean" — 1,120 where the true mean was 11.70.

---

## C. Construction and normalisation

**Check:** That every constructed variable means what its name says.

**How:**

- Rescalings must be visible where the number is read, not only where it is
  written. A column divided by 100 needs "(00s)" in the table header, or a
  reader compares hundreds to units. A column headed "share" that holds a count
  in hundreds is unreadable in principle.
- **Simpson's paradox and aggregation reversal.** Compute the relationship at
  both the individual and the group level and compare. If they differ in sign,
  neither is wrong but they answer different questions, and the paper must say
  which it is asking. Aggregation reversal is most likely when group sizes are
  very unequal.
- **Winsorising and trimming.** Locate where they are applied and check whether
  any *published* statistic inherits them. Winsorising inside a plotting
  function is fine and must be disclosed in the caption; winsorising upstream of
  an estimate changes the estimate. Trimming changes the population, not just
  the tail.
- **Indices.** Decompose. Which components moved, and is the component that maps
  most literally onto the claim among them? (This is where `review-article`'s
  move 1 and this skill meet.)
- Verify that a "rate" is the ratio its name implies and not a differently
  constructed quantity that happens to be on a similar scale.

---

## D. Estimand

**Check:** What population, weighted how, at what unit — asked explicitly rather
than inherited from whatever the code happened to do.

**How:**

- **Name the unit.** Person, visit, domain, dollar, household-month. Every
  headline number is about one of them and the paper should say which.
- **Weighted and unweighted are different questions, not a robustness pair.**
  Weighting units by size answers "what does the average unit of exposure look
  like"; not weighting answers "what does the average person look like".
  Reporting one as a robustness check on the other conflates them. Report both
  and label each with the question it answers.
- **Joint vs marginal.** "All three" is a joint probability and is bounded above
  by the smallest marginal. Reading it off the marginals is a real and common
  error.
- **Mean vs median.** Check the label against the computation, in both
  directions.
- **Decompositions must reconcile.** A shift-share or Oaxaca decomposition's
  "total" must equal the headline quantity it claims to decompose. If the
  decomposition is visit-weighted and the paper's estimand is person-averaged,
  the shares may still be informative but the total is a different number, and a
  gate that only checks the components sum to the total will not notice.
- Ask whether the estimand is conditional on something that is itself an
  outcome — "among those who responded", "among domains still reachable" — and
  say so where it is.

---

## E. Inference

**Check:** That the uncertainty reported is the uncertainty that exists.

**How:**

- **SE type against the error structure.** Under real heteroskedasticity,
  classical and robust standard errors can differ enough to flip a conclusion:
  one severely heteroskedastic outcome (mean 0.010, max 0.99) gave p = .287
  classically and p = .001 under HC1. Whichever is used, it should be used
  consistently across the paper.
- **Clustering at the unit of variation, and no higher.** Cluster if and only if
  there are multiple observations per unit of independent variation, at that
  level. Clustering higher than the design costs power for nothing; not
  clustering when the design demands it understates uncertainty.
- **Bootstrap.** Resample the unit of independent variation, not the row. Build
  the RNG *inside* the function — a module-level generator is consumed across
  calls, so re-running a cell without re-running its predecessor produces
  different published intervals. Count and report draws that fail to converge;
  a standard error built on the draws that happened to work is not the standard
  error you think.
- **Randomisation inference.** Use `(k + 1) / (B + 1)`. The observed assignment
  is itself one draw from the randomisation distribution; excluding it makes the
  test anti-conservative by `1/(B+1)` and lets a p-value of exactly zero be
  reported from finitely many draws. `B` also sets a **floor**: with B = 200 the
  smallest attainable p is .005, so "p < .001" is not a claim that design can
  make. In one case the correction moved a headline p from **.050 to .055**.
- **Multiplicity.** Declare the family, and check that the declared family
  matches the statistic actually reported. A Bonferroni count computed over
  *level* coefficients says nothing about claims made on *changes*.
- **Sampling weights.** Weights must be design-consistent, and designs have
  identities you can test. Any fixed-size-`n` design satisfies **Σπ = n** — one
  line that falsifies a wrong formula immediately. `π = min(n·p, 1)` is correct
  for Poisson/with-replacement-style reasoning but *not* for successive sampling
  (`numpy.choice(replace=False, p=...)`), where inclusion probabilities have no
  closed form. Simulate π under the design that actually ran.
- **Numerical.** Check the optimiser reached the optimum, especially for
  quantile regression, GMM, and anything iteratively reweighted. Re-solve by a
  second method and compare *objectives* rather than coefficients — with
  collinear regressors the argmin need not be unique, but its value is.
- Keep **identification uncertainty and sampling uncertainty separate.** Report
  as `point [ID bounds] (sampling CI)`, never merged into one interval.

---

## F. Skew and heavy tails

**Check:** Whether the estimator matches the distribution — and, before that,
which summary the paper actually wants.

**How:**

1. **Diagnose.** Skew, kurtosis, max/median, share of mass in the top 1%, and a
   plot. In the motivating case cumulative outcomes had skew ≈ 4 with max/median
   ≈ 53, which rules several defaults out immediately.
2. **Ask the estimand question before the method question.** Do you want the
   mean or the median? A right-skewed outcome has a mean driven by the tail; if
   the tail is the phenomenon (total exposure, total spend) the mean is correct
   and needs robust inference. If the tail is a nuisance, the median is the
   target and quantile regression estimates it directly.
3. **Then choose, knowing the cost:**

| Option | Use when | Cost |
|---|---|---|
| Report the median / quantile regression | the typical unit is the question | different estimand; no closed-form SEs, bootstrap them |
| Log or asinh transform | multiplicative process, no true zeros (asinh handles zeros) | retransformation bias — `E[log Y] ≠ log E[Y]`; back-transformed means need a smearing correction |
| GLM with log link | want `E[Y]` on the original scale | distributional assumptions still bite |
| Robust / clustered SEs, keep the mean | mean is the estimand, tails inflate variance | does not fix leverage |
| Winsorise | a few implausible extremes | changes the estimate; must be disclosed, with the threshold |
| Trim | genuinely out-of-population units | changes the population; report both |

4. **Heavy tails make asymptotic inference optimistic.** Prefer bootstrap or
   permutation, and check leverage explicitly — DFBETA and leave-one-out on the
   headline coefficient. If dropping one observation moves the result, say so.
5. **Ratio outcomes with variable denominators** are the specific skew trap
   worth naming: precision varies enormously across units, and equal weighting
   ignores that. See Tier 2A on tiny denominators.
