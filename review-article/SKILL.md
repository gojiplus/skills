---
name: review-article
description: Review quantitative empirical social-science papers, reproduce their central claims, diagnose inferential or economic weaknesses, and develop evidence-backed research and writing opportunities. Use for experiments, observational designs, IV, matching models, replication packages, referee reports, or critical essays.
---

# Review an empirical paper

Determine what the evidence supports, what would change that conclusion, and what research could resolve the uncertainty. A strong result surviving a serious challenge is a finding. Apply the same evidentiary standard regardless of the authors' reputation or politics.

## Scope and sources

Use the user's requested format, language, access restrictions, and authorized scope. Read downloaded papers and available data first. Search only when permitted; distinguish a full-paper reading from abstract-only access. A missing appendix is an access limitation, not proof that the analysis was not done. Never claim a full replication when only selected tables were reproduced.

Answer focused questions directly while continuing an authorized audit. Ask for missing information that changes a consequential decision; do not repeatedly ask permission to perform already authorized checks. Keep interim updates about findings and remaining uncertainty.

## Workflow

1. **Identify the claim.** Read the full article, tables, appendix, and available registration. For each central claim, record the comparison, outcome, units, population, period, decision maker, and behavioral stage. State the estimand in a sentence. Separate description, causal attribution, mechanism, and extrapolation.
2. **Trace the evidence.** Link the claim to the sample construction, variable definition, producing code, generated result, and paper location. Record model-specific observations and clusters, sample flow, strata, weights, and cluster-size imbalance. Distinguish sampling from treatment assignment and dependence. Reproduction, sensitivity checks, and independent new-data replication are different deliverables.
3. **Reproduce the decisive numbers.** Preserve original files and commands. Establish which coefficients, standard errors, samples, and reported percentages reproduce before explaining a discrepancy. Match estimator conventions; diagnose a failure before declaring the publication wrong. Use `empirical-problem-solving` for a concrete discrepancy and `audit-analysis` for deeper data and inference checks when needed.
4. **Challenge the interpretation.** Use [review-moves.md](review-moves.md). Prioritize checks capable of changing the claim; briefly mark irrelevant or unavailable checks rather than manufacturing twelve concerns. For each challenge, consider a rival explanation and a result that would support the paper. Preserve negative findings and record why analyses were added after seeing results.
5. **Apply conditional methods.** Use [iv-review.md](iv-review.md) for IV, including Lal and coauthors and Mellon. Use [structural-review.md](structural-review.md) for matching, estimated preferences, equilibrium simulations, or welfare claims. Do not apply diagnostics beyond their supported design.
6. **Write the finding and its consequence.** State what was checked, the numerical result and uncertainty, and how interpretation changes. Name assumptions and unmeasured quantities concretely. Distinguish confirmed errors, plausible but untested mechanisms, alternative estimands, and unresolved access limits. Prioritize identification and substantive magnitude over small reporting defects.
7. **Develop the research opportunity.** Follow [research-opportunities.md](research-opportunities.md). For each material criticism, identify the question, decisive test or new data, possible contribution, and a finding that would overturn the critique. Route a chosen new study to `design-analysis` and a manuscript to `write-empirical-paper`, using `on-writing` and `visualize-evidence` as appropriate. Do not invent results to complete a paper outline.

## Interpretation rules

- Reconstruct the full contrast. Interactions and category effects can make a single coefficient an incomplete answer. For WTP or equivalent-income ratios, specify both alternatives, whose decision is measured, the income construct, and uncertainty from estimated preliminary stages. Near-zero denominators may make a ratio poorly determined.
- Explain percentages with their base and direction. Do not change sales into physical yield, revenue into profit, shortlisting into marriage, or a cross-group gap into money knowingly surrendered. Keep corrections to the assistant's earlier wording out of a standalone criticism of the paper. Do not insert an unrequested arithmetic lesson about a mistake the paper did not make. If no error in the paper has been established, say so rather than manufacture a criticism.
- Test differences directly. One significant coefficient and one insignificant coefficient need not differ. Failure to reject zero does not establish no effect or negligible cost. State the range of substantive effects the interval permits.
- Explain treatment-related variation. A background cost shared by both groups cannot alone explain a treatment effect. For large claimed gains, examine entry, bargaining, substitution, and the specific obstruction. Quantify break-even scenarios without inventing prices, quantities, or recoverable profits. Check the direction of any proposed bias.
- Keep diagnostics honest. Clustering addresses dependence, not confounding. Ninety clusters do not guarantee ninety equally informative contributions. Randomization inference needs an actual assignment mechanism. Bootstrap methods and multiplicity families must be selected for the question, not for a preferred verdict.
- Match benchmarks in outcome, population, period, contrast, and units. A surprising comparison motivates investigation; it does not refute a result. Do not divide an ITT by a convenient exposure fraction from another setting and call the quotient an identified TOT.

## Code and writing

Use the user's language preference and existing project conventions. For R, use Hadley-style `snake_case`, meaningful nouns for data and estimates, and verbs for functions. Prefer `analysis_data`, `first_stage`, and `income_premium` to ambiguous objects. Preserve original variable names at the input boundary or supply a traceable mapping. Use standard packages and build commands; inspect official documentation when API behavior is uncertain. Run meaningful local tests and linting, and attempt to resolve missing dependencies.

Generate repeated numbers, tables, figures, and prose values from the analysis outputs. Follow `write-empirical-paper` for manuscript synchronization and rendering. Explanations should stand alone for a reader who has not seen the conversation. Lead with the concrete issue and its implication, not methodological shorthand or a list of vague caveats.

## Deliverables

Scale these to the request; a focused question does not need a full dossier:

- A plain-language verdict with the strongest supporting evidence, strongest unresolved challenge, and limits of completed work.
- A compact claim-to-evidence record and reproducible numerical artifacts for the claims audited.
- A review or referee report ordered by substantive importance, with confirmed errors distinguished from interpretation and identification questions.
- Research opportunities tied to the findings, including needed data and discriminating tests.
- Tests run, checks not run, and why those limits matter.
