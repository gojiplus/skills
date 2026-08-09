# Identification, design by design

Identification is the argument that connects the number you compute to the quantity you care
about. It is prior to the estimator and it does not come from the data. This file is the branch
table: for each design, what the estimand is, what buys it, what would break it, what the
canonical estimator and standard error are, and which sensitivity tool exists.

Pick the branch first, then read only that row plus the notes under it.

## The seven-part estimand

Write it before anything else, in one sentence:

**unit · population · treatment or exposure · outcome · contrast · aggregation and weighting ·
time window**

Two estimands differing only in weighting are different quantities, and both can be right. A
paper that reports one and describes the other is the most common finding in `audit-analysis`.

## The branch table

| design | estimand | identifying assumption | observable implication | estimator | standard error | sensitivity |
|---|---|---|---|---|---|---|
| individual RCT | ATE | randomisation | baseline balance | `lm_robust`, `lm_lin` with covariates | HC2, **no clustering** | attrition bounds (Lee, Manski) |
| cluster RCT | ATE (cluster-assigned) | randomisation of clusters | balance at cluster level | `lm_robust(clusters=)` | CR2; RI; WCB if few treated clusters | ICC, design effect |
| stratified / block RCT | ATE | randomisation within block | balance within block | block FE or block-size weights | CR2 at assignment level | — |
| encouragement / non-compliance | LATE / CACE | randomisation + exclusion + monotonicity | first stage strength; no defiers | 2SLS, `iv_robust` | HC2 or CR2 at assignment level | bounds on always/never-takers |
| DiD, 2 periods 2 groups | ATT | parallel counterfactual trends | pre-period trends (evidence, not proof) | `lm_robust` with unit + time FE | cluster on the unit that got treated | Rambachan–Roth `HonestDiD` |
| DiD, staggered adoption | group-time ATT, then an aggregate | no anticipation + parallel trends per cohort | event-study leads | `did::att_gt`, `fixest::sunab`, `did2s` | CR at unit level, bootstrap for uniform bands | `HonestDiD`; Goodman-Bacon decomposition |
| event study | path of ATT by lead/lag | as above | flat leads | `sunab` / `att_gt` aggregation | as above | pre-trend magnitude bound |
| sharp RD | ATE at the cutoff | continuity of potential outcomes at c | no density jump; covariate continuity | `rdrobust` local linear | `rdrobust` bias-corrected, cluster if assignment is clustered | bandwidth curve; donut; Cattaneo density test |
| fuzzy RD | LATE at the cutoff | continuity + monotonicity of treatment in the running variable | first stage jump | `rdrobust(fuzzy=)` | as above | as above |
| IV | LATE for compliers | relevance + exclusion + monotonicity + independence | first-stage F; reduced form | `iv_robust`, `feols(y ~ x \| fe \| d ~ z)` | same cluster as the assignment of z | Anderson–Rubin CI when weak; plausibly-exogenous bounds |
| panel FE | within-unit association | strict exogeneity conditional on FE | — (untestable) | `feols(y ~ x \| unit + time)` | cluster on unit; two-way if shocks are common | `sensemakr` |
| matching / weighting | ATT or ATE | conditional ignorability + overlap | balance after weighting; common support | entropy balancing (`ebal`, `WeightIt`), CBPS, IPW | bootstrap or M-estimation SE that accounts for estimated weights | `sensemakr`; Rosenbaum bounds |
| synthetic control | effect for one treated unit | convex-hull fit + no interference | pre-period fit (RMSPE) | `synth`, `augsynth`, `gsynth` | placebo permutation distribution | in-space and in-time placebos |
| descriptive | a population quantity | representative sampling, or none | — | survey-weighted mean / regression | design-based SE (`survey`, `srvyr`) | weight sensitivity |

## Notes the table cannot hold

### Fixed effects are not identification

Unit and time fixed effects absorb level differences along those dimensions. They do nothing
about time-varying confounding, they do not make an endogenous regressor exogenous, and they
change the estimand: the coefficient is now a within-unit comparison, weighted by each unit's
variance in the regressor. That weighting is rarely the one the claim describes.

A specification that becomes "more robust" as fixed effects are added is usually one whose
identifying variation you have not located. Ask which comparisons remain after the absorption,
and whether those comparisons are the ones the claim is about. `fixest`'s `fixef.rm = "singleton"`
drops units with one observation; report how many, because they were contributing nothing to
identification and their inclusion inflated the apparent N.

### Bad controls

Three kinds, all of which make things worse:

- **Post-treatment.** Anything measured after treatment that treatment could affect. Conditioning
  on it removes part of the effect and induces selection bias in the rest.
- **Colliders.** A variable caused by both the treatment and the outcome (or by their unobserved
  causes). Conditioning opens a path that was closed.
- **Mediators**, when the estimand is the total effect. Conditioning gives the direct effect,
  which is a different and usually harder-to-identify quantity.

The test is temporal and causal, not statistical. A control that changes the coefficient a lot is
not thereby important; it may be the collider.

### Staggered DiD: what went wrong and what to do

Two-way fixed effects with staggered adoption and heterogeneous effects does not estimate a
sensible average. Already-treated units serve as controls for later-treated ones, and the implicit
weights on some 2×2 comparisons are **negative**. Goodman-Bacon's decomposition shows you which
comparisons your TWFE estimate is actually made of; run it before anything else, because sometimes
the answer is that the problem is small and you can move on.

When it is not small: `did::att_gt` (Callaway–Sant'Anna) estimates group-time ATTs against
not-yet-treated or never-treated comparisons and then aggregates the way you choose;
`fixest::sunab` (Sun–Abraham) does the interaction-weighted version inside a familiar regression;
`did2s` and `didimputation` are the imputation-based alternatives. Roth, Sant'Anna, Bilinski and
Poe's survey is the map when the choice is not obvious.

### Parallel trends is untestable

Pre-trends are evidence about the assumption, not a test of it. Two specific failures worth
naming: a pre-trend test that is *underpowered* passes for the wrong reason, and conditioning on
having passed a pre-trend test distorts the distribution of the post-period estimate. Report the
power of your pre-trend test, not just its p-value.

`HonestDiD` (Rambachan–Roth) is the honest replacement: instead of asserting parallel trends,
bound the post-period violation either by a smoothness restriction on second differences or as a
multiple `M̄` of the observed pre-trend, and report the breakdown value of `M̄` at which your
conclusion changes. That number is more informative than any pre-trend p-value.

### IV

The exclusion restriction is a substantive argument, not a specification. Nothing in the data
tests it. Write the sentence "z affects y only through d because…" and if you cannot finish it,
you do not have an instrument.

First-stage F above 10 is a rule of thumb that does not survive contact with heteroskedasticity
or clustering; use the effective F (Montiel Olea–Pflueger) and report Anderson–Rubin confidence
sets, which are valid regardless of instrument strength. A 2SLS point estimate with a weak
instrument is biased toward OLS, which is the direction that makes it look reassuring.

### Matching and weighting

Balance after weighting is the check; overlap is the assumption people skip. Report the propensity
score distribution by arm and how many units lie outside common support — if trimming them changes
the population, the estimand changed with it.

Entropy balancing (Hainmueller) solves for weights that exactly match specified covariate moments
while staying as close as possible to uniform, which removes the balance-check-then-respecify loop
that makes propensity score matching a garden of forking paths. Whatever the method, the weights
are **estimated**, and standard errors that ignore that are too small.

### `sensemakr`, and what a robustness value means

For any OLS estimate under conditional ignorability, `sensemakr` reports the **robustness value**:
the minimum share of residual variance in both treatment and outcome that an unobserved confounder
would need to explain in order to move the estimate to zero (or out of significance). Then
benchmark it — "a confounder as strong as *observed covariate X* would move the estimate to Y."
That benchmarking is what makes the number arguable rather than decorative.

### When you cannot identify

Say so. Downgrade the claim to description, state the association with its interval, name the
confounders you cannot rule out, and stop. A descriptive claim made honestly is publishable; a
causal claim made hopefully is a retraction with a lag.
