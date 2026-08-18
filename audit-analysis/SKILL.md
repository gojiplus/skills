---
name: audit-analysis
description: Audit empirical social-science analyses for data integrity, identification, inference, robustness, and claim validity. Use for experiments, panels, causal designs, or replication packages.
---

# Audit an empirical analysis

## Standard

The bugs that change published numbers are almost never bugs a linter or a test suite can see. They are statistical: a denominator that does not match what it is compared against, a missing value recoded as a zero, a sampling weight that violates its own design identity, a table regenerated while the sentence citing it was not. Code that runs, reproduces, and is wrong is the normal case. This skill audits whether the numbers that reproduce are the *right* numbers.

Package reproduction is necessary but insufficient. Audit whether each artifact means what its label and prose claim. Treat code, data, exhibits, and manuscript as one system.

## Modes

`/audit-analysis [path] [own|package]` — mode defaults to `own`.

**own**: run code, derive alternatives, report findings, then repair approved defects and add gates.

**package**: remain read-only. Mark checks that need unavailable data untestable.

**paper**: audit the manuscript and its replication package together. Run the analysis workflow below, then the paper-claim moves in [paper-audit.md](checks/paper-audit.md).

## Workflow

1. **Map claims to estimands.** For every headline claim, record the unit, population, treatment or exposure, outcome, comparison, aggregation, weighting, time window, and uncertainty. Write the causal contrast if the claim is causal. A claim without an identified estimand is already a finding.

2. **Inventory the surface.** List every prose number, table, figure, analytical dataset, and producing script. Count them and draw the dependency chain. Mark typed analytical handoffs, manual transcription, live downloads, and outputs excluded from the build.

3. **Run the mechanical sweep.** Run `scripts/audit_data.py` on each analytical dataset and `scripts/audit_provenance.py` on a LaTeX manuscript. The scoped provenance resolver does not support Markdown citations. These tools report candidates, not verdicts.

   Know what these tools do and do not do. `audit_data.py` reports *candidates*, never verdicts — "this column is 47% missing and the rate differs by group" is a place to look, not a finding. `audit_provenance.py` localises a **paragraph** whose numbers disagree with the table it cites; it will not always flag every wrong number inside that paragraph, because a number far enough from any current value reads as an orphan rather than a near-miss. Both were validated against a manuscript before and after a known set of nineteen errors: the scoped provenance check re-found the stale paragraph unprompted and returns clean on the corrected version.

4. **Work Tier 1** ([tier1-high-yield.md](checks/tier1-high-yield.md)). Always run all five checks.

5. **Work Tier 2** ([tier2-statistical.md](checks/tier2-statistical.md)). Cover EDA, joins, construction, estimand, inference, and skew. Record a finding or an explicit inapplicable result for every section.

6. **Work Tier 3** ([tier3-design.md](checks/tier3-design.md)). Apply Gelman's design and measurement checks and Green's design-based experimental checks.

7. **Work Tier 4** ([tier4-econometric.md](checks/tier4-econometric.md)). Select every relevant design branch. Check identification before estimator choice, then check whether the standard errors correspond to the actual source of variation.

8. **Audit the paper when one exists.** Run [paper-audit.md](checks/paper-audit.md). Read the full manuscript, appendix, exhibits, and registration or analysis plan. Search primary sources for construct definitions and external benchmarks. Use `review-article` alongside this skill when it is available.

9. **Run an adversarial pass, then a validation pass.** Try to break each headline result using unit arithmetic, alternative denominators, negative controls, influence checks, external benchmarks, and the strongest plausible rival explanation. Then try to disprove every criticism. Keep only findings that survive both passes.

10. **Verify every surviving finding yourself.** A confirmed number-changing finding needs a runnable reproduction with the published and corrected values. A design limitation needs the exact claim it weakens and the identified set or alternative estimand when possible.

11. **Report, then fix.** Rank: number-changing defects, inferential changes, identification failures, robustness failures, reproducibility defects, editorial or construct errors, rejected candidates, untestable checks. Show the list before changing published numbers.

12. **Gate every repair.** Use `scripts/gates.py` where helpful. Gate row conservation, schemas, sample counts, headline estimates, prose provenance, bootstrap settings, and generated artifacts.

## Evidence rules

This is the part that separates an audit from a list of worries.

- Name the old and new number. Without both, label a numerical concern speculative.
- Distinguish a different estimand from a corrected estimate. Weighted and unweighted results can both be right.
- Do not use a residual diagnostic as a ritual. State which assumption it probes and how the result changes inference.
- Do not infer identification from controls, fixed effects, fit, balance, or a small p-value.
- Do not accept a null as evidence of no meaningful effect. Report the interval in substantive units.
- Treat generated outcomes, fitted fixed effects, imputed covariates, and machine-learned scores as estimated quantities. Propagate their uncertainty or state the conditional estimand.
- Make plausibility quantitative. Convert coefficients into implied counts, probabilities, treatment-on-treated effects, years, dollars, or population totals and compare them with physical bounds and the best external evidence.
- A surprising number is not a finding by itself. Explain which assumption, comparison, or established range it violates and validate the comparator from a primary source.
- **Re-derive every delegated claim.** Across two audits of one pipeline, several agent findings did not survive checking: "the analytic file is stale" was false against git history; "structural zeros inflate the age gap" was backwards once computed; one sampling-weight finding was real but mis-framed as the wrong error. Agents propose, you dispose.
- **Record rejected findings and why.** A false lead that is not written down gets chased again next audit.
- **After changing any artifact, grep the prose for every number it feeds.** Eight of nineteen manuscript errors in the motivating case came from fixing a table and stranding the sentence that cited it. This is the single most productive habit in the skill.
- **Fix the definition, not the call site.** If two quantities were confused once, route both through one function so they cannot be confused again.
- **Never commit before the verification finishes running.** Committing and then discovering the build fails is a self-inflicted second commit.

## Output contract

Start with the verdict. Then provide:

1. A claim-to-estimand table.
2. Ranked findings with published and corrected values.
3. A check matrix covering every tier and paper-audit move.
4. Rejected candidates and why they failed verification.
5. Untestable checks and the missing artifact.
6. Repairs and permanent gates, in dependency order.

Never bury a changed conclusion beneath general advice.

## Scaling

Small analysis, one dataset: work the tiers inline.

Large pipeline (dozens of scripts, many exhibits): fan out read-only audit agents over independent slices — core pipeline, each validity module, notebooks, provenance — each returning findings in the schema above, then verify centrally. Give every agent the calibration examples from [bug-taxonomy.md](references/bug-taxonomy.md) so "consequential" means the same thing to all of them, and tell each one explicitly that a finding without a demonstrated number change is speculation.

## Red flags you are cutting corners

- You reported a concern without computing the corrected value beside the published one.
- You accepted a `fillna(0)` because the column "should" be zero there, without checking whether the fill rate differs across groups or waves.
- You checked that a merge ran without checking that the row count survived it.
- You verified a rate's numerator and not its denominator.
- You called something robust after one alternative specification, rather than establishing where the published estimate sits in the family.
- You ran the estimator the paper ran and never asked what population its unit of observation describes.
- You trusted an agent's finding because the reproduction *looked* right, without running it.
- You fixed the table and did not grep the prose.
- You marked a check "passed" that you could not actually run, instead of "untestable".
