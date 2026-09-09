---
name: design-analysis
description: Plan an empirical study before estimation, defining the question, identification assumptions, outcomes, inference, falsification checks, and pre-analysis plan.
---

# Design an empirical analysis

State the question and assumptions before choosing an estimator. Work with the
available design information; planning a new study does not require a dataset that
has not yet been collected. For existing data, use the dictionary, recode ledger,
and join contract, or resolve missing definitions with `build-data`.

Keep planning separate from outcome-driven analysis choices. Record what has
already been seen; do not describe a retrospective plan as prospectively blinded.
Use the project's language and tools. The references contain R examples, not a
requirement to convert Python or Stata projects.

## Identify the question

State the estimand in one sentence: unit, population, treatment/exposure, outcome,
contrast, aggregation/weighting, and time window. Describe the identifying
assumption, what would violate it, and which implications can be checked. Use a
DAG or potential-outcomes statement where it clarifies confounding, mediators,
post-treatment controls, or the relevant comparison.

Read [identification.md](references/identification.md) for the applicable design.
Locate the variation identifying the effect; controls, fixed effects, predictive
fit, or balance alone do not establish identification. Where identification is
unsupported, state the descriptive quantity the data can support.

Resolve consequential unknowns with the researcher: intended population/contrast,
assignment or sampling mechanism, primary outcomes, and accepted assumptions.
Ask with evidence and a recommendation, batching related questions. Carry prior
choices forward and continue work that does not depend on missing information.

## Specify the analysis before examining its result

Use [pre-analysis-plan.md](references/pre-analysis-plan.md) for a plan proportionate
to the study. Specify primary and secondary outcomes, sample construction,
transformations, estimator, uncertainty method, missing-data policy, and the
multiplicity family. Record expected signs and plausible magnitudes when defensible.

Choose falsification checks capable of changing the interpretation: placebo
outcomes, populations or periods, negative controls, and design-specific diagnostics.
Pre-specify subgroup or dose-response tests where warranted; later additions are
exploratory. Preserve the actual preregistration or versioned plan and the record
of prior exposure to outcomes. Do not promise blinding a git tag cannot establish.

If profiling may reveal outcomes, decide whether it can be done without treatment
labels or whether to record the unblinding. When a holdout is justified, define the
split before exploration and protect it during development.

## Match inference to the design

Read [inference.md](references/inference.md) and current official package docs for
the selected implementation. State variance and finite-sample conventions
explicitly; do not silently mix package defaults across specifications or versions.

Choose dependence and clustering assumptions from assignment, sampling, and the
estimand. Count clusters, treated clusters, and their imbalance; observation count
alone can hide weak information. Assess finite-sample performance rather than
using a universal cluster-count threshold. Randomization inference requires the
actual assignment mechanism and a clearly stated null; do not invent that
mechanism by permuting a binary regressor.

For an R specification, [se_ladder.R](scripts/se_ladder.R) compares uncertainty
methods. Use its help and documented assumptions before running it; it cannot
infer a blocked or multilevel assignment. Read meaningful differences as evidence
about assumptions, not as permission to choose the smallest standard error.
Use appropriate tools for equivalent checks in other languages.

Assess power or minimum detectable effects and, where informative, Type S/M risks
under plausible effect sizes. Simulate coverage when assumptions or small samples
make it consequential. Distinguish planned simulations from observed study results.

## Plan interpretation and review

Read [interpretation.md](references/interpretation.md). Specify how estimates and
intervals will be reported in substantive units. Name meaningful benchmarks and
what magnitudes an interval could exclude. A nonsignificant estimate alone does
not establish no meaningful effect. Keep mechanisms, causal attribution, and
extrapolation separate.

For a substantial study, audit the design/code before unblinding, using
`audit-analysis` for applicable data and inference checks. Obtain an independent
model's review of the dictionary, design, assumptions, and planned tests when
available; request rival explanations and consequential weaknesses, not style
notes. Verify findings before acting. The `release` skill's reviewer reference
can help with independent-review mechanics. Report unavailable review explicitly.
A focused design question does not require a full release-style gate sequence.

Hand implementation and manuscript production to `write-empirical-paper`, with
`visualize-evidence` for exhibits. Preserve the existing build system and layout.
When analysis follows, record deviations and their reasons, and distinguish
pre-specified results from exploratory additions.

Deliver the estimand, assumptions, plan, inference choices, design diagnostics,
review findings, and unresolved decisions needed for the requested stage.
Background sources: [sources.md](references/sources.md).
