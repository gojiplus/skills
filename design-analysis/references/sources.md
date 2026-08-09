# Sources

Names are routing devices, not appeals to authority. Every entry below earned its place by
supplying a check, a number, a bound, or a named failure mode — not by being well known.

## Design as the primary object

**Blair, Coppock and Humphreys, *Research Design in the Social Sciences: Declaration, Diagnosis,
and Redesign* (2023), and the `DeclareDesign` package.** The MIDA decomposition — Model, Inquiry,
Data strategy, Answer strategy — is the reason stage 1 of this skill separates the estimand from
the estimator. The operational payoff is `diagnose_design()`: bias, RMSE, power, and **coverage**
become numbers you compute for your design rather than properties you assert. This is the only
tool here that turns "the interval has 95% coverage" into a check.

**Gelman and Carlin, "Beyond Power Calculations: Assessing Type S (Sign) and Type M (Magnitude)
Errors" (*Perspectives on Psychological Science*, 2014).** Power asks whether you will detect an
effect; Type S and Type M ask what the estimate looks like conditional on detecting one. In a
noisy design the exaggeration ratio is routinely 2–4×, which is a mechanism that produces a
literature of large effects that fail to replicate without anyone doing anything wrong. The
`retrodesign()` function in `inference.md` is theirs.

**Gelman et al., "Bayesian Workflow" (2020, arXiv:2011.01808).** Cited for the workflow stance
rather than the Bayesian machinery: model building is iterative, and the discipline is recording
what you tried and why, not pretending the final model was the first.

## Identification

**Roth, Sant'Anna, Bilinski and Poe, "What's trending in difference-in-differences? A synthesis of
the recent econometrics literature" (*Journal of Econometrics* 235(2), 2023).** The map for the
staggered-DiD branch. Read it before choosing between `did`, `sunab`, `did2s`, and plain TWFE
rather than after.

**Goodman-Bacon (2021)** for the decomposition that shows which 2×2 comparisons a TWFE estimate is
actually made of, including the negatively-weighted ones. Run it first: sometimes the answer is
that the problem is small.

**Callaway and Sant'Anna (2021), `did::att_gt`**; **Sun and Abraham (2021), `fixest::sunab`**;
**de Chaisemartin and D'Haultfœuille (2020)**. The three standard replacements.

**Rambachan and Roth, "A More Credible Approach to Parallel Trends" (*ReStud* 2023), `HonestDiD`.**
Parallel trends is untestable, so the honest move is to bound the violation — by smoothness of
second differences, or as a multiple `M̄` of the observed pre-trend — and report the breakdown
value at which the conclusion changes. That number is worth more than any pre-trend p-value.

**Lin, "Agnostic notes on regression adjustments to experimental data: Reexamining Freedman's
critique" (*Annals of Applied Statistics* 7(1), 2013).** Regression adjustment in experiments
cannot hurt asymptotic precision *when the full set of treatment × covariate interactions is
included*; the uninteracted version can. This is `estimatr::lm_lin`, and it is the reason the
default for a covariate-adjusted experiment is `lm_lin` rather than `lm_robust`.

**Cinelli and Hazlett, "Making Sense of Sensitivity: Extending Omitted Variable Bias"
(*JRSS-B* 82(1), 2020), `sensemakr`.** The robustness value: how strong an unobserved confounder
would have to be, in both treatment and outcome, to overturn the estimate — benchmarked against
an observed covariate so the number is arguable rather than decorative.

**Hainmueller, "Entropy Balancing for Causal Effects" (*Political Analysis* 20(1), 2012), `ebal`.**
Solves directly for weights matching specified covariate moments while staying as close as
possible to uniform. Its value here is procedural: it removes the check-balance-then-respecify
loop that turns propensity score matching into a garden of forking paths.

**Lipsitch, Tchetgen Tchetgen and Cohen, "Negative Controls: A Tool for Detecting Confounding and
Bias in Observational Studies" (*Epidemiology* 21(3), 2010).** Negative control outcomes and
negative control exposures, and — where both exist — the double-negative-control design that can
bound confounding rather than only detect it. The source of the placebo taxonomy in stage 2.

## Inference

**Abadie, Athey, Imbens and Wooldridge, "When Should You Adjust Standard Errors for Clustering?"
(*QJE* 138(1), 2023).** The paper that settles the question this skill treats as settled:
clustering is a **design** problem — either two-stage sampling or correlated assignment — not a
response to suspected error correlation. It is also the reason "do not cluster in a completely
randomised individual-level experiment" is a rule rather than a preference.

**MacKinnon, Nielsen and Webb, "Cluster-robust inference: A guide to empirical practice"
(*Journal of Econometrics* 232(2), 2023)** and **"Fast and reliable jackknife and bootstrap methods
for cluster-robust inference" (*JAE* 2023).** The source of the few-cluster threshold, of the
argument for the "31" wild-bootstrap variant, and of the finding that unbalanced cluster sizes
break the usual asymptotics well before the cluster count alone would suggest.

**Bell and McCaffrey (2002); Pustejovsky and Tipton (2018), `clubSandwich`.** CR2 with
Satterthwaite degrees of freedom — `estimatr`'s default, and the reason CR2 rather than CR1 is the
recommendation here.

**Bertrand, Duflo and Mullainathan, "How Much Should We Trust Differences-in-Differences
Estimates?" (*QJE* 2004).** Serial correlation in panel outcomes; cluster on the unit, not the
unit-year. Still the clearest demonstration that an interval can be badly wrong while every
diagnostic looks fine.

**Anderson, "Multiple Inference and Gender Differences in the Effects of Early Intervention"
(*JASA* 103(484), 2008).** Inverse-covariance-weighted summary indices and sharpened FDR q-values.
Sharpened q-values can fall below the unadjusted p-values when many hypotheses are rejected; that
is correct behaviour, not a bug.

**Romano and Wolf (2005).** Free step-down resampling for family-wise error, which computes an
exact probability rather than a bound and exploits dependence between test statistics — so it
dominates Bonferroni-Holm whenever the tests are correlated, which they are.

## Pre-specification

**Olken, "Promises and Perils of Pre-Analysis Plans" (*JEP* 29(3), 2015).** What belongs in a PAP
and what pre-specification cannot buy.

**Casey, Glennerster and Miguel, "Reshaping Institutions" (*QJE* 2012).** The "cherry-picking"
table that shows how wide the space of defensible specifications is without pre-specification.
Worth showing to anyone who thinks a PAP is bureaucracy.

**Burlig, "Improving transparency in observational social science research: A pre-analysis plan
approach" (*Economics Letters* 168, 2018).** The three cases where a PAP is credible without an
experiment — own data collection, prospective studies, restricted-access data — and, by omission,
the case where it is not: data already on your disk. The reason this skill routes that case to
sample splitting instead of registration.

**Fafchamps and Labonne, "Using Split Samples to Improve Inference on Causal Effects"
(*Political Analysis* 2017).** The mechanics of exploratory and confirmation halves, and why the
split has to be on the clustering unit rather than on rows.

**Simonsohn, Simmons and Nelson, "Specification Curve Analysis" (*Nature Human Behaviour* 2020);
Steegen, Tuerlinckx, Gelman and Vanpaemel, "Increasing Transparency Through a Multiverse Analysis"
(*PPS* 2016).** The honest version of a robustness section: define the family of specifications in
advance and locate the published estimate inside it. Del Giudice and Gangestad's "A traveler's
guide to the multiverse" (2021) is the corrective for treating the multiverse as decoration —
name the analytic choice the result hinges on.

## Reproducibility and the package

**Gentzkow and Shapiro, *Code and Data for the Social Sciences: A Practitioner's Guide* (2014).**
Directory separation, portability, and the rule that nothing a script could produce is edited by
hand.

**The Social Science Data Editors' template README**
(`https://social-science-data-editors.github.io/template_README/`), the de facto standard in
economics. Its sections — data availability and provenance statements, dataset list, computational
requirements, list of tables and programs — are appended to the reader-facing README in this
skill's layout, not substituted for it: the two have different audiences.

## In-repo precedent

The layout, the `NN[a-z]_` script scheme, `00_config.R` / `00_utils.R`, the phase-annotated
`99_run_all.R`, `aer_etable` / `custom_stargazer`, `theme_pub`, and the XeLaTeX + `latexmk` build
are codified from three of the author's own repositories rather than invented. The additions,
flagged as such in the skill, are: explicit `vcov` on every call with a generated note, a written
clustering decision, the PAP artifact, interval-first prose, the no-intermediate-files rule, and a
hand-labelled linkage-accuracy sample.
