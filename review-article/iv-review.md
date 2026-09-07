# Reviewing instrumental-variable claims

Use this reference when a paper estimates an IV model or presents an IV result as stronger causal evidence. Apply the same scrutiny regardless of the authors' reputation or politics. Use downloaded sources first and respect instructions limiting web access. Distinguish reading a full paper from reading its abstract.

## State the actual causal claim

Name the outcome, each endogenous regressor, excluded instruments, controls, sample, and dependence structure. Explain why treatment is endogenous and how the proposed instrument changes it. Distinguish instrument independence, exclusion, relevance, and the assumptions needed to interpret heterogeneous treatment effects. A historical or geographic instrument is not automatically exogenous. A strong first stage establishes neither independence nor exclusion.

For generated instruments or interactions, draw the full sequence of regressions. Check which variables are treated as endogenous, which products are instrumented, and which restrictions the construction imposes. Replacing a published construction with raw instruments changes the specification; report it as a sensitivity check unless equivalence is established.

## Instrument strength and inference: Lal and coauthors

Read [Lal, Lockhart, Xu, and Zu (2024), *How Much Should We Trust Instrumental Variable Estimates in Political Science? Practical Advice Based on 67 Replicated Studies*](https://doi.org/10.1017/pan.2024.2); [author PDF](https://yiqingxu.org/papers/english/2021_iv/LLXZ_PA.pdf).

- Put OLS and IV on identical samples, outcomes, controls, and units. Report their difference with uncertainty where feasible. A large IV/OLS ratio motivates investigation; it does not prove bias, and different treatment-effect targets may matter.
- Show the actual first stages and reduced forms, with uncertainty. Report partial R-squared and appropriate robust or clustered strength diagnostics. An overall preliminary-regression F is not necessarily the excluded-instrument F. Do not substitute an ordinary clustered F for an effective F without establishing equivalence.
- Match diagnostics to the number of instruments and endogenous regressors. Their replication sample excludes specifications with multiple endogenous regressors. Separate first-stage F statistics do not establish conditional identification of several endogenous regressors. The single-treatment, single-instrument tF procedure is not a general multi-endogenous-regressor solution.
- Where appropriate, report both percentile and studentized bootstrap intervals. Resample whole clusters when required by the design, give repeated sampled clusters distinct bootstrap IDs, and repeat all estimated preliminary stages. Report failures and disagreement between intervals. Ordinary bootstrap intervals are not weak-instrument-robust confidence sets.
- Use suitable weak-instrument-robust inference, such as Anderson–Rubin, where available. State whether a test concerns one coefficient or a joint null. Do not present a joint test as an interaction-specific result. State clearly when the implemented test cannot answer the focal question.
- Examine influential observations or clusters and the source of first-stage variation. Do not manufacture randomization inference without an actual assignment mechanism.

## Alternative causal pathways: Mellon

Read [Jonathan Mellon, *Rain, rain, go away: 194 potential exclusion-restriction violations for studies using weather as an instrumental variable*](https://doi.org/10.1111/ajps.12894). Its lesson extends beyond weather: evidence that an instrument changes other determinants of the outcome bears directly on exclusion. The title does not establish that every weather IV is invalid.

Build a short table of plausible alternative pathways: instrument → other variable → outcome. For each, record the timing, evidence available in the paper or other permitted sources, whether controls actually block the path, and what remains unknown. Balance tests and overidentification tests do not establish exclusion. Do not automatically add post-instrument controls; doing so may change the target effect or introduce bias.

Quantify consequential violations when feasible. Specify a direct effect in outcome units, recompute the treatment estimate across an explicit range, and report the direct effect required to change its sign or a substantive conclusion. Distinguish that threshold from a confidence interval excluding zero. For several instruments or endogenous regressors, state the assumed vector of direct effects; a one-at-a-time calculation is not a bound allowing simultaneous violations. Check the direction of bias: a plausible positive direct effect can strengthen rather than weaken the focal estimate. Do not present an exclusion concern as an explanation for an inflated estimate without checking that implication. Seek empirical benchmarks when access permits. Without them, call the range hypothetical, not plausible by assertion. If the full Mellon paper is inaccessible, do not claim to implement its exact procedure based on the abstract alone.

## Report what changes the interpretation

For each concern, write: what the original estimate says; what was checked; the numerical result; and which claim is weakened, supported, or unresolved. Keep sampling uncertainty, exclusion sensitivity, implementation defects, and different estimands separate. Explain percentages with their base and direction. For example, 45% higher is not 45% lost. A revenue difference is not automatically a physical-yield loss or a measured willingness to pay.

When a discrepancy appears, use the empirical-problem-solving workflow if available: reproduce it, shrink to the smallest failing example, compare rival explanations, and retain negative findings. A typo affecting no analysis observations is not evidence that the substantive estimate is wrong.
