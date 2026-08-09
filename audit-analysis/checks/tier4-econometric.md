# Tier 4: econometric identification and inference

Work identification before estimation. Select every branch that matches the analysis. For each branch, state the identifying variation, the assumptions, the diagnostic evidence, and the conclusion that survives.

Use [econometric-reading-map.md](../references/econometric-reading-map.md) when a finding turns on a method's exact assumptions or a design-specific remedy.

## Common checks

### Design matrix and support

- Report rank, condition number, correlations, variance inflation, leverage, and effective sample size.
- Show overlap for every treatment or exposure. Regression extrapolation outside common support is not adjustment.
- Separate exact collinearity from weak independent variation. A coefficient can exist and still be identified by a handful of observations.
- Refit after dropping each high-influence unit. Report the full leave-one-unit-out range for headline coefficients and p-values.

### Standard errors follow assignment and sampling

- Name the source of independent variation. Cluster there, not at a convenient geography.
- Count clusters and treatment clusters, not only observations. Report cluster-size imbalance and leverage.
- With few clusters or few treated clusters, run a wild cluster bootstrap using a justified weight distribution and null-imposed procedure. Report bootstrap type, cluster variable, draws, seed, tail convention, and failed draws.
- When assignment is known, run randomization inference as a design-based companion. Wild-cluster and randomization p-values answer different questions; do not substitute one silently for the other.
- Test and plot heteroskedasticity when conventional OLS standard errors are used. Prefer HC3 in small cross-sections unless the design implies another covariance estimator.
- For serial or spatial dependence, justify the correlation window or distance and report sensitivity.
- Treat fixed effects as controls, not a substitute for a correct covariance estimator.

### Generated quantities and two-step estimation

- Flag fitted fixed effects, residuals, propensity scores, indices with estimated weights, imputed outcomes, embeddings, and machine-learned predictions used downstream.
- Preserve full precision in typed analytical artifacts. Never round an upstream estimate before a downstream regression.
- Propagate first-stage uncertainty with an analytic correction, joint estimation, sample splitting, or a bootstrap that reruns every estimated stage.
- Resample every independent level represented in the estimand. A country regression using country fixed effects estimated from people usually needs a hierarchical bootstrap.

### Specification and functional form

- Plot the outcome against each continuous regressor with raw and partial relationships.
- Compare the published functional form with bins, splines, logs, and scale-preserving alternatives justified by the estimand.
- For bounded outcomes, inspect predictions outside the bounds and compare an appropriate nonlinear mean model when interpretation depends on bounds.
- Report the defensible specification family. Do not call one alternative a robustness section.

### Measurement, scales, and indices

- Start with the construct map: construct, observed item, response scale, coding direction, missingness, aggregation, and claimed interpretation.
- Report item prevalence or moments, inter-item correlations, item-total correlations, and the effect of removing each item.
- For reflective multi-item scales, report Cronbach's alpha and McDonald's omega with uncertainty. Alpha is not evidence of unidimensionality or validity and rises mechanically with item count.
- Check dimensionality with an appropriate factor model. Use tetrachoric or polychoric correlations for binary or ordinal items when justified.
- Test measurement invariance across the groups or periods being compared. A changed scale can manufacture a changed outcome.
- For formative indices and union indicators, do not use alpha as a quality criterion. Decompose components, report which components drive the result, and test alternative defensible thresholds or weights.
- Preserve item-level data through the audit. A total score alone cannot reveal miscoding, differential item functioning, or component dominance.
- Separate reliability, convergent validity, discriminant validity, criterion validity, and construct validity. Passing one does not establish the others.

## Design branches

### Randomized experiments

- Verify assignment, treatment delivery, noncompliance, outcome collection, and attrition by arm.
- Reproduce the design-based ITT. Use the known assignment mechanism for inference.
- Convert ITT to plausible TOT values using measured compliance. Benchmark the implied TOT.
- Check treatment spillovers, cluster size imbalance, blocked or stratified assignment, and covariate adjustment chosen before outcome inspection.

### Observational cross-sections

- State that adjustment identifies a conditional association unless exchangeability is defended.
- Draw the causal graph or list the minimal adjustment set. Distinguish confounders from mediators and colliders.
- Quantify sensitivity to omitted confounding where a causal interpretation is attempted.
- Check selection into the analytical sample and outcome measurement. Complete-case regression changes the population.

### Panels and fixed effects

- Name the within-unit variation identifying each coefficient. Report units with no usable variation.
- Check serial correlation, dynamic adjustment, lag structure, and Nickell bias in short panels.
- Explain fixed-effect normalization when extracted effects become outcomes. An intercept absorbs a common shift, but rankings and nonlinear transformations might not.
- Do not interpret unit fixed effects as structural traits without accounting for estimation noise and shrinkage.

### Difference-in-differences and event studies

- Show treatment timing, cohort sizes, and never-treated or not-yet-treated comparisons.
- Diagnose heterogeneous-treatment contamination in two-way fixed effects.
- Use a cohort-robust estimator when treatment timing is staggered.
- Plot event-time estimates with honest simultaneous uncertainty. A null pretrend test does not establish parallel trends; report power and meaningful violations it cannot reject.
- Check anticipation, treatment reversals, composition changes, and outcome-specific trends.

### Instrumental variables

- State the population and margin represented by the LATE.
- Defend relevance, exclusion, independence, and monotonicity separately.
- Report the first stage in substantive units, weak-instrument-robust inference, reduced form, and implied scaling.
- Audit every path by which the instrument can affect the outcome. Controls do not repair a violated exclusion restriction.

### Regression discontinuity

- Verify the assignment rule and running-variable construction.
- Plot density and predetermined covariates near the cutoff.
- Use bias-corrected inference and report bandwidth, polynomial order, kernel, donut, and discrete-score sensitivity.
- Do not extrapolate the local effect away from the cutoff without a separate design.

### Selection, attrition, and missing outcomes

- Report missingness and attrition by exposure, outcome predictors, group, and period.
- Distinguish measured zero, structural zero, censored value, and unmeasured value.
- Use Lee, Manski, or other defensible bounds when point identification fails.
- Treat conditioning on post-treatment observables as selection unless justified.

### Prediction and causal machine learning

- Separate predictive performance from causal identification.
- Use honest sample splitting or cross-fitting for nuisance models.
- Check calibration, subgroup support, tuning leakage, and repeated analyst search.
- For heterogeneous effects, report policy-relevant summaries and uncertainty, not only the most extreme leaves or groups.

## Robustness standards

- A robustness result must locate the published estimate inside a defensible family.
- A null must be translated into the largest substantively important effect the interval still permits.
- A sensitivity estimator that changes the target population or weighting is a different estimand. Label it.
- Prefer specification curves, leave-one-unit-out plots, and multiverse summaries to a list of selected alternatives.
- Use fake-data simulation when the pipeline is complex: plant parameters, run the actual code, and verify recovery and interval coverage.
