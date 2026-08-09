# Paper audit: claims, mechanisms, and external validity

Run this file when an analysis has a manuscript, report, slide deck, or public claim. Read the full document and appendix before judging it.

## Claim inventory

For each headline sentence, record:

- the measured outcome and unit;
- the reported raw and standardized magnitude;
- the comparison and target population;
- whether the claim is descriptive, predictive, or causal;
- the mechanism asserted;
- the exhibit and script that support it.

Flag unit substitutions such as email to politician, account to person, school to child, visit to user, or stated preference to behavior.

## Twelve moves

1. **Decompose indices.** Rebuild every component. Check whether the claim-literal component moved and whether union indicators are driven by one common component. For reflective scales, inspect alpha, omega, factor structure, and invariance; for formative or union indices, explain why internal-consistency coefficients are not the target.
2. **Inspect floors, ceilings, and baseline gaps.** Translate normalized effects back to raw units. Show which components mechanically dominate.
3. **Test dose response.** Plot every exposure level. Distinguish a smooth curve from a result isolated in one cell.
4. **Validate the mechanism.** Require measured awareness, exposure, take-up, or mediation. Plausibility is not evidence.
5. **Verify implementation.** Find audits, administrative records, manipulation checks, and later evidence about whether the treatment or measurement occurred as described.
6. **Check ITT-to-TOT arithmetic.** Divide by plausible exposure or compliance and benchmark the implied effect.
7. **Benchmark effect sizes.** Compare magnitude and intervention intensity with primary studies measuring the same outcome.
8. **Stress statistical fragility.** Count clusters and treated clusters, apply wild-cluster and randomization inference where appropriate, correct the declared outcome family, and run leave-one-cluster-out.
9. **Separate statements from behavior.** Do not let attitudes, intentions, aspirations, or self-reports stand in for actions without validation.
10. **Triangulate companion work.** Read papers using the same data, setting, team, or intervention for facts that support or contradict the mechanism.
11. **Audit selective emphasis.** List narrated and unnarrated coefficients from each cited table. Look for claim-relevant nulls omitted from prose.
12. **State generalizability honestly.** Put sites, clusters, period, selection, and implementation context next to the breadth of the title and conclusion.

## Literature and construct audit

- Verify variable definitions against the primary source or official codebook.
- Check whether a proxy is relabeled as the construct of interest. Commitment is not investment; public breach appearance is not account takeover.
- Search for the strongest external benchmark, not the most convenient citation.
- Check citations for direction, population, and magnitude, not only topic relevance.
- Keep external evidence separate from what the study itself identifies.

## Adversarial criticism and validation

For every headline result, write the strongest concrete criticism before accepting it:

- reconstruct the implied numerator, denominator, and population total;
- translate standardized effects and regression coefficients into natural units;
- compute the implied treatment-on-treated effect, elasticity, or counterfactual rate;
- compare the magnitude with physical bounds, baseline risk, prior measurements, and interventions of comparable intensity;
- search for a rival mechanism that predicts the same pattern;
- identify the single observation, component, subgroup, or specification carrying the result;
- ask what result would have been emphasized had the sign, subgroup, or outcome changed.

Then validate the criticism:

- rederive it from raw or analytical data;
- verify external comparators from primary sources and match population, period, measurement, and units;
- run the estimator or sensitivity analysis that distinguishes the criticism from the paper's account;
- record criticisms that fail and why;
- label a concern speculative if no observed number changes and no identifying assumption is demonstrably violated.

Create a short "numbers that do not make sense" table with the reported number, implied quantity, benchmark, violated expectation, and validation status. Do not use incredulity as evidence.

## Writing verdicts

Use four labels:

- **Supported:** the design and measurement identify the stated claim.
- **Supported with a narrower scope:** the estimate is credible for a smaller unit, population, contrast, or mechanism.
- **Descriptive only:** the number is credible but the causal or predictive interpretation is not.
- **Unsupported:** the reported evidence does not identify the claim or fails verified statistical checks.

Every unsupported verdict must quote or locate the exact claim and name the closest defensible replacement.
