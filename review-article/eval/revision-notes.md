# Review-skill revision and evaluation

This revision was prompted by the Anderson water-market and Banerjee et al. marriage-market reviews. It changes the review workflow, not the other specialist skills.

| Earlier instruction or failure mode | Revision and reason |
|---|---|
| Twelve moves treated as compulsory criticisms | Prioritize consequential tests and record support, rejected criticisms, inapplicable checks, and access limits. |
| Generic index-weighting claim | Inspect the actual index formula; standardization and gap normalization are not interchangeable. |
| Flat or insignificant exposure estimates treated as no effect | Use direct contrasts, functional-form alternatives, and uncertainty; thresholds and imprecision remain possible. |
| Cross-setting contact rates used for ITT-to-TOT arithmetic | Require a relevant treatment-receipt first stage and causal assumptions; transported fractions are scenarios, not identified compliance. |
| Cluster count treated as sufficient | Distinguish sampling, assignment, and dependence, and inspect counts, imbalance, influence, strata, and weights. |
| Randomization inference proposed by default | Require an actual assignment mechanism. |
| IV validity inferred from first-stage strength | Separate relevance, conditional strength, exclusion, independence, applicable inference, and direct-effect sensitivity. Include Lal and coauthors and Mellon. |
| A plausible alternative pathway automatically treated as upward bias | Check the direction and magnitude in the actual first-stage system. |
| One coefficient described as universal WTP | Reconstruct full alternatives with categories, ranks, interactions, decision maker, behavioral stage, and estimated-stage uncertainty. |
| Common costs used to explain a treatment difference | Identify what varies because of exposure and what blocks entry, bargaining, or substitution; distinguish revenue from profit. |
| Criticism ending in a list of caveats | Create research opportunities specifying a discriminating test, data, assumptions, feasible next step, and a result supporting the original account. |
| Conversational corrections carried into a public review | State only errors established in the paper. Do not turn the assistant's wording mistake into an arithmetic detour for an uninformed reader. |
| Review prose and agent instructions maintained independently | The installed agent resolves the versioned review skill and its conditional references; its config is symlinked to the source. |

The review now routes to empirical-problem-solving for discrepancies, design-analysis for new studies, and write-empirical-paper with on-writing and visualize-evidence for manuscripts. New R code should use descriptive snake_case names. These routes do not retroactively turn exploratory work into a preregistered analysis or authorize new data collection.

## Validation

- The skill passed the standard skill-creator validator.
- Relative Markdown links, agent TOML, interface YAML, and ten behavioral-case records were checked locally.
- Codex's local prompt renderer discovered the installed empirical-reviewer role.
- One read-only Codex run exercised all ten synthetic cases in `cases.yaml`. Manual review found the substantive logic satisfactory in nine, but the standalone-correction case unnecessarily repeated reverse-percentage arithmetic.
- The instruction and that case's criterion were tightened. A targeted second run replied: “No error in the paper has been established. The statement ‘45% higher’ does not, by itself, warrant criticism; assessing it requires the comparison, outcome, and supporting evidence.” It omitted the unwanted arithmetic detour.

These are bounded synthetic behavior checks and configuration validation, not evidence of reliability across all papers. The first income-case prompt was subsequently clarified to specify the coefficient on predicted log income; the original response already distinguished a coefficient ratio from division by an income level. The evaluation used the default configured Codex model and did not browse, alter research files, or launch subagents.


## Follow-up from village and marriage interpretation audits

Added threshold provenance and continuous-exposure checks; historical-treatment timing and geographic-crosswalk requirements; ownership, migration and settlement as possible outcomes; resource heterogeneity in money-equivalent preferences; and explicit credit for authors' own tests of cultural explanations. These are workflow instructions, not claims that the new historical or income-heterogeneity checks have already succeeded. Validation for this amendment: skill schema and local Markdown link targets; no new behavioral model evaluation was run.


## 2026-09-07: identification, reference groups and independent samples

Added concrete checks for normalization-dependent predictions despite exact numerical reproduction; outcome-specific omitted-group composition and estimability; original survey provenance versus author collection; questionnaire versus released-variable availability; and bounded dominance classification with incomplete caste shares. Added independent-audit adjudication rather than accepting a reviewer's confident denominator or causal attribution. Motivated by the tested bride-income normalization audit, selected Table8 reference counts, and IHDS/land-record feasibility inventory. These reference edits received schema/link checks; no new behavioral model evaluation is claimed.
