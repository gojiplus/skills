# Sources

What each part of the checklist rests on, and where to read further.

---

## Statistical workflow and interpretation

**Gelman & Carlin (2014), "Beyond Power Calculations: Assessing Type S (Sign)
and Type M (Magnitude) Errors," *Perspectives on Psychological Science*.**
The significance filter as an exaggeration factor: conditional on clearing a
threshold, estimates from noisy designs are inflated and can have the wrong
sign. Basis for Tier 3's first check. The `retrodesign` R package implements it.

**Gelman & Loken (2013), "The Garden of Forking Paths."**
Multiple comparisons without p-hacking: if a different dataset would have
prompted a different reasonable analysis, the reported p-value is not the
procedure's p-value. `stat.columbia.edu/~gelman/research/unpublished/p_hacking.pdf`

**Gelman & Stern (2006), "The Difference Between 'Significant' and 'Not
Significant' is not Itself Statistically Significant," *The American
Statistician*.** Comparing two significance verdicts is not a test.

**Gelman, Vehtari, Simpson, et al. (2020), "Bayesian Workflow," arXiv:2011.01808.**
Iterative model building, fake-data simulation, simulation-based calibration,
predictive checking. Explicitly *not* a checklist, which is the right posture —
Tier 3 borrows the moves, not the framing. The book is in progress at
`avehtari.github.io/Bayesian-Workflow/`.

**Amrhein, Greenland & McShane (2019), "Retire Statistical Significance,"
*Nature*.** Why the threshold itself is the problem.

**McShane, Gal, Gelman, Robert & Tackett (2019), "Abandon Statistical
Significance," *The American Statistician*.**

---

## Design, experiments, and analysis defaults

**Green Lab Standard Operating Procedures (Coppock, maintained for Donald
Green's lab at Columbia).** `alexandercoppock.com/Green-Lab-SOP/`
The most directly usable document here: concrete defaults rather than
principles. Sources for Tier 3's Green section —
- estimator by sample size; covariate count capped at M/20 with interactions;
- Bell–McCaffrey standard errors as routine (per Imbens & Kolesár 2016);
- cluster **iff** multiple observations per randomisation unit, at that level;
- missing covariates: recode to mean below 10%, dummy plus constant above;
- pre-analysis verification that treatment occurred and outcomes were gathered;
- balance via heteroskedasticity-robust Wald with a permutation p-value;
- two-tailed studentised permutation test as the default, 10,000 randomisations;
- report both adjusted and unadjusted; disclose deviations.

**Gerber & Green (2012), *Field Experiments: Design, Analysis, and
Interpretation*.** Attrition (Ch. 7) is the canonical treatment of the
differential-missingness problem in its experimental form; also interference,
heterogeneous effects, and integration of findings.

**Lin (2013), "Agnostic Notes on Regression Adjustments to Experimental Data,"
*Annals of Applied Statistics*.** Why covariate adjustment with full treatment
interactions is safe.

**Abadie, Athey, Imbens & Wooldridge (2023), "When Should You Adjust Standard
Errors for Clustering?", *QJE*.** Clustering as a design property, not a
robustness reflex.

**Young (2019), "Channeling Fisher: Randomization Tests and the Statistical
Insignificance of Seemingly Significant Experimental Results," *QJE*.**
Randomisation inference overturning a large share of published results —
motivation for treating permutation as the default rather than the fallback.

**Manski (1990, 2003), partial identification and bounds.** Where the data
cannot identify the quantity, report the bounds. See also Lee (2009) bounds for
differential attrition.

---

## Reproducibility, code, and data organisation

**Gentzkow & Shapiro (2014), *Code and Data for the Social Sciences: A
Practitioner's Guide*.** Directory structure, abstraction, automation, version
control. The complement to this skill: it prevents the *mechanical* errors this
skill assumes you have already avoided.

**AEA Data Editor guidance.** `aeadataeditor.github.io/aea-de-guidance/`
Pre-publication verification of computational reproducibility; the
`reproducibility-checks` page is the operational protocol.

**BITSS / ACRE — Accelerating Computational Reproducibility.**
`bitss.org/ecosystem/acre/` and the Social Science Reproduction Platform.
Scoring rubric for how reproducible a package is.

**JASA Reproducibility Guide.** `jasa-acs.github.io/repro-guide/`

**Scott Cunningham's Referee 2 protocol** — five parallel audits (code,
cross-language replication, directory/package, output automation,
econometrics). Surfaced as a Claude skill at `lcrawfurd.github.io/claude-skills/`
alongside paper-review and code-review skills. **Use it for package mechanics;
this skill deliberately does not duplicate it.**

**Wilson, Bryan, Cranston, et al. (2017), "Good Enough Practices in Scientific
Computing," *PLOS Computational Biology*.**

**Broman & Woo (2018), "Data Organization in Spreadsheets," *The American
Statistician*.** Where the dtype and missing-value traps in Tier 2B are born.

---

## Specific technical points

**Simpson's paradox / aggregation reversal.** Stanford Encyclopedia of
Philosophy entry is the clearest treatment of when ratio comparisons reverse
under aggregation, which is the mechanism behind Tier 2C.

**Skewed and heavy-tailed outcomes.** Manning & Mullahy (2001) and the health-
economics literature on expenditure data is the best-developed source on
log-vs-GLM, retransformation bias, and the smearing correction; Koenker &
Bassett (1978) and Koenker (2005) for quantile regression as the alternative
estimand.

**Hájek and Horvitz–Thompson estimation, inclusion probabilities.** Särndal,
Swensson & Wretman, *Model Assisted Survey Sampling*. The `Σπ = n` identity used
as a falsification test in `gates.py` is elementary and, for that reason, an
unusually good gate. Note that `numpy.random.Generator.choice(replace=False,
p=...)` implements *successive sampling*, whose inclusion probabilities have no
closed form — a fact not documented where most users would look for it.

**Simmons, Nelson & Simonsohn (2011), "False-Positive Psychology,"
*Psychological Science*.** Researcher degrees of freedom; the empirical
companion to the forking-paths argument.
