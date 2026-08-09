# Standard errors that have the coverage they claim

A 95% interval that covers 82% of the time is not conservative or approximate. It is wrong, and
it is wrong in the direction that produces publications. This file is the decision procedure, the
escalation rule, and the code.

## The decision procedure

**1. What varies?** Clustering is a design question, not a robustness knob. Abadie, Athey, Imbens
and Wooldridge: there are exactly two justifications.

- **Sampling design.** Clusters were sampled from a population of clusters, and you want to
  generalise to the clusters you did not see. Cluster at the sampling stage.
- **Experimental design.** Assignment is correlated within a group — treatment was assigned to
  villages, schools, districts. Cluster at the assignment level.

If neither applies, do not cluster. In a completely randomised individual-level experiment,
clustering on anything is a mistake that inflates the interval for no design reason. "There might
be correlated shocks" is not one of the two justifications; if it were, you would have to cluster
on every observable grouping, including the ones nobody clusters on.

**2. Write `vcov` explicitly, always.** Even when it matches the default.

```r
# fixest: with fixed effects present the default is se = "cluster" on the FIRST fixed effect,
# and without them it is iid. Two different estimators, silently, in one table.
feols(y ~ d | district^samiti, data = df, vcov = ~district)     # say it
feols(y ~ d,                   data = df, vcov = "hetero")      # say it here too
```

In one repository audited while writing this skill: **128 `feols()` calls, 2 with an explicit
`vcov`**. Every paired No-FE / FE table therefore placed an iid column next to a cluster-robust
column, and fifteen table notes called both "heteroskedasticity-robust." Nothing was miscoded.
The rule exists because defaults are invisible and notes are written from memory.

**Generate the note from the object, never type it.** `scripts/se_ladder.R` exports `se_note()`
for this; source it in `00_utils.R` and pass its output to `aer_etable(notes = )`:

```r
source(here("scripts", "se_ladder.R"))          # provides se_note() and se_ladder()
aer_etable(models, file = here("tabs", "main.tex"),
           notes = paste(NOTES_SIGNIF, se_note(m, df$district)))
```

`se_note()` deliberately refuses to print a cluster count next to an unclustered variance — a
note reading "iid, 14 clusters" is the error the function exists to prevent, not a shorthand
for it.

**3. Pick the estimator.**

| situation | estimator | why |
|---|---|---|
| no clustering justified | `lm_robust(se_type = "HC2")` | HC2 is `estimatr`'s default and is less biased than HC1 in small samples |
| clustering justified, ≥ ~40 clusters, roughly balanced | `lm_robust(clusters = g, se_type = "CR2")` | CR2 with Bell–McCaffrey dof; the default in `estimatr` |
| experiment with covariates | `lm_lin(y ~ d, covariates = ~ x1 + x2)` | Lin (2013): full treatment × covariate interaction cannot hurt asymptotic precision |
| known assignment mechanism | randomisation inference (`ri2`, `randomizr`) | correct by construction; reuses the actual assignment |
| < ~40 clusters, or few treated clusters | wild cluster bootstrap, `fwildclusterboot::boottest` | CR2 undercovers badly here |
| many high-dimensional FE | `feols(..., vcov = ~cluster)` | speed; write the vcov out |
| two nested sources of correlation | `vcov = ~state + year` (two-way) | only when both are design justifications, not both plausible |
| spatial correlation with no natural cluster | Conley, `vcov = vcov_conley(lat, lon, cutoff)` | requires a defensible distance cutoff, reported |
| serially correlated panel outcomes | cluster on the unit, not the unit-year | Bertrand–Duflo–Mullainathan |

**4. Count treated clusters, not observations.** 80,000 observations in 6 treated districts is a
6-cluster problem, and no sample size fixes it. Report both counts in every table note where
clustering is used.

The count is a *screen*, not the criterion. What actually governs whether cluster-robust
asymptotics hold is the **effective** number of clusters, and four things drive it below the
nominal count:

| driver | why it hurts | what to look at |
|---|---|---|
| few treated clusters | the score contributions that identify the effect come from a handful of terms | count of clusters with treatment variation |
| cluster-size imbalance | one large cluster dominates the meat matrix | max/median cluster size; share of N in the largest cluster |
| high leverage | one cluster moves the estimate | leave-one-cluster-out estimates |
| little within-cluster variation in the regressor | the cluster-robust variance collapses | the within-share check in 4b |

`clubSandwich::coef_test(..., test = "Satterthwaite")` reports the Satterthwaite degrees of
freedom, which is the honest summary of all of this in one number. **When it comes back far below
the cluster count, treat the design as few-cluster regardless of how many clusters you have.**

**4b. Check that the regressor varies within cluster.** If treatment is constant within cluster —
quota assigned at the GP level, clustered at the GP level — then a fixed effect at or below the
clustering level absorbs it entirely. The cluster-robust meat matrix collapses and **the standard
error comes out absurdly small rather than erroring**. Measured on a test fixture where treatment
was district-constant with district fixed effects: HC1 gave 0.078, CR0 gave 0.0002. Nothing warned.

```r
grp_mean <- ave(df$treat, df$district, FUN = function(z) mean(z, na.rm = TRUE))
within_share <- var(df$treat - grp_mean, na.rm = TRUE) / var(df$treat, na.rm = TRUE)
stopifnot(within_share > 0.01)   # else the FE and the clustering are at odds
```

`se_ladder.R` runs this and fails the gate when the share is below 1%. When it fires, either the
fixed effects are at the wrong level or the clustering is — and deciding which is a stage-1
question, not a variance question.

**5. Escalate only when few.** Below roughly 40 clusters — or with few treated clusters at any
total — CR2 undercovers and you need the wild cluster bootstrap or randomisation inference. Above
that, the bootstrap buys runtime, not coverage. Reaching for `boottest` with 300 clusters signals
that the clustering level was never justified in the first place.

```r
# the "31" variant: WCR with the CRVE3 (jackknife) numerator and a CRVE1 bootstrap DGP.
# MacKinnon, Nielsen and Webb argue for it; it is the most reliable of the family when
# cluster sizes are unbalanced.
fwildclusterboot::boottest(
    m, clustid = "district", param = "treat", B = 9999,
    bootstrap_type = "31", impose_null = TRUE
)
```

Impose the null (`impose_null = TRUE`, the restricted bootstrap) for testing; the unrestricted
version is for confidence intervals and is less reliable under the null.

**6. Report the ladder.** `scripts/se_ladder.R` computes iid, HC1, HC2, CR0, CR2, wild cluster
bootstrap and randomisation inference for one specification, with the cluster and treated-cluster
counts, and flags whether the few-cluster threshold was crossed. The design picks the rung that
goes in the main table; the ladder goes in the SI.

**If the conclusion moves across the ladder, that is the result.** Say it. An estimate whose
interval excludes zero under CR0 and includes it under CR2 with 14 clusters has not been shown to
exclude zero; it has been shown to depend on a variance approximation that is known to fail at
that cluster count.

## Coverage is checkable

Nothing above is a proof that your interval covers. Check it:

```r
library(DeclareDesign)
design <-
    declare_model(cluster    = add_level(N = 60, u_c = rnorm(N, sd = 0.5)),
                  individual = add_level(N = 20, u_i = rnorm(N))) +
    declare_model(potential_outcomes(Y ~ 0.2 * Z + u_c + u_i)) +
    declare_inquiry(ATE = mean(Y_Z_1 - Y_Z_0)) +
    declare_assignment(Z = cluster_ra(clusters = cluster)) +
    declare_measurement(Y = reveal_outcomes(Y ~ Z)) +
    declare_estimator(Y ~ Z, clusters = cluster, se_type = "CR2", inquiry = "ATE")

diagnose_design(design, sims = 200)
#>       bias    rmse  power  coverage
#> 6.19e-05   0.157  0.325     0.925
```

Note the shape: `add_level()` calls cannot be mixed with plain assignments inside one
`declare_model()`, so the levels go in the first call and the potential outcomes in a second.

`coverage` is the fraction of simulations where the 95% interval contained the true ATE. Here it
is 0.925 with 60 clusters — already below nominal, and it degrades fast as the cluster count
falls. If yours comes back 0.87, the interval is not a 95% interval for this design, and the fix
is the estimator or the design, not the prose.

The same machinery answers the design-analysis questions below without a separate tool.

## Design analysis, not just power

Power asks "will I detect it." That is the wrong question when the design is noisy, because the
interesting failure is not a missed effect but a published one that is too big and possibly
backwards.

For a plausible true effect `d` and a standard error `s` (Gelman–Carlin):

- **Type S rate** — conditional on reaching significance, the probability the estimate has the
  wrong sign.
- **Type M rate (exaggeration ratio)** — conditional on reaching significance, the expected ratio
  of `|estimate|` to `|d|`.

```r
retrodesign <- function(d, s, alpha = 0.05, df = Inf, n_sims = 1e5) {
    z <- qt(1 - alpha / 2, df)
    est <- d + s * rt(n_sims, df)
    sig <- abs(est) > s * z
    list(power       = mean(sig),
         type_s      = mean(sign(est[sig]) != sign(d)),
         exaggeration = mean(abs(est[sig])) / abs(d))
}
retrodesign(d = 0.02, s = 0.02)   # power .17, type S .010, exaggeration 2.5
```

An exaggeration ratio of 2.5 means that if the true effect is 2pp, the *significant* estimates
average 5pp. That is a mechanism for a literature of large effects that fail to replicate, and it
operates without anyone doing anything wrong.

Run this whenever an apparently strong effect turns up in a small or noisy design — which is
exactly when the temptation not to is strongest.

## Multiplicity

Decide before you look.

- **Primary outcome, one per family**, pre-specified. Nothing adjusts this.
- **Indices for secondary outcomes.** Anderson (2008): standardise each component, then weight by
  the inverse covariance matrix so outcomes that duplicate each other are down-weighted. One test
  instead of eight, and it is more powerful than any of them when the outcomes are correlated.
- **Family-wise error**: Romano–Wolf free step-down (`wyoung` in Stata, `rwolf`, `fwer`
  implementations in R). It estimates the joint distribution of the test statistics by resampling
  rather than bounding it, so it can be much less conservative than Bonferroni-Holm when the tests
  are correlated. Two things not to overclaim: the resampling gives *asymptotic*, not exact,
  control, and its validity depends on the resampling scheme matching the dependence structure —
  so under clustering you resample clusters. There is no theorem that it beats Holm in every
  finite sample; the gain is empirical and comes from the correlation.
- **False discovery rate**: Anderson's sharpened q-values, when you would rather bound the share
  of rejections that are false than the probability of any false rejection. Note sharpened
  q-values can come out *below* the unadjusted p-values when many hypotheses are rejected. That is
  correct, not a bug: with many true rejections you can tolerate some false ones and still hold
  the FDR.
- **Subgroups**: a finite list, written down. Everything not on it is exploratory and labelled as
  such in the paper, not in a footnote.

The adjustment matters far less than the pre-specification. A corrected p-value on a hypothesis
chosen after seeing the data is a corrected number that is still wrong.

## Generated regressors and estimated weights

Anything you estimated and then used as data carries uncertainty the second stage does not know
about: matching or balancing weights, propensity scores, fitted fixed effects, imputed covariates,
machine-learned scores, an index whose weights came from this sample's covariance matrix.

Either propagate the uncertainty — bootstrap the whole pipeline including the first stage, or use
a joint M-estimation variance — or state the conditional estimand explicitly ("conditional on the
estimated weights"). Reporting a second-stage analytic standard error as if the first stage were
known is the most common way a paper's intervals come out too narrow, and it is invisible in the
output.
