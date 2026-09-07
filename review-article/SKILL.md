---
name: review-article
description: Review a quantitative empirical social-science paper. Use to assess experiments, difference-in-differences, RD, IV, natural experiments, inference, and causal claims.
---

# Reviewing Quantitative Social Science Papers

## Overview

A review is a chain of plausibility checks, not a summary with caveats. The question is never "is the design clever?" but "do the paper's own numbers, mechanism, and magnitudes survive contact with each other and with the outside literature?" Every check must end in a concrete finding (a number, a table, a named comparator), not a vague concern.

## Usage

`/review-article <pdf|url|citation> [essay|referee]` — format defaults to `essay`.

## Workflow

1. **Intake.** Read the full paper, all tables, the supplementary material/appendix, and the pre-registration if one exists. Record: journal, year, setting, and model-specific N. Distinguish sampling, treatment assignment, and dependence: report cluster counts by group, household or observation counts per cluster, strata, and weights where relevant. Do not describe observational exposure as randomly assigned. Cluster counts and their imbalance both matter for inference.

2. **Claims inventory.** List each headline claim with (a) the exact outcome measured, (b) the effect size in SD units and in raw units, (c) the causal mechanism the paper asserts. Name the exact comparison group, decision maker, and stage of behavior. For interactions or willingness-to-pay ratios, reconstruct the full contrast, including category effects, rather than interpreting one coefficient as a universal trade-off. Bootstrap estimated preliminary stages when calculating uncertainty. This anchors every later check.

3. **Run the review moves.** Work through all twelve moves in [review-moves.md](review-moves.md). For each, write down the concrete finding or explicitly mark it inapplicable/untestable. Do not skip a move because the paper looks clean — the moves exist because clean-looking papers fail them.

4. **Replication pass (conditional).** Search for a replication package: journal supplementary materials, Dataverse, OSF, ICPSR, authors' sites. If a package URL is found, download it and re-run: index decomposition, wild cluster bootstrap when warranted by cluster counts or imbalance, and randomization inference only when an actual assignment mechanism supports it, Bonferroni and Benjamini-Hochberg across the family of primary outcomes, and leave-one-cluster-out. Report which results survive. If no package exists, state that explicitly and mark these checks untestable.

5. **Benchmark effect sizes.** Use available papers first; search for additional comparators when permitted. Compare magnitude and intensity while preserving outcomes, units, populations, and treatment contrasts. Large estimates warrant scrutiny, not rejection merely because they seem surprising. State when a comparator measures a different outcome or comes from a different population.

6. **IV claims (conditional).** For instrumental-variable analyses, follow [iv-review.md](iv-review.md): Lal and coauthors for instrument strength, comparable OLS/IV estimates, and inference; Mellon for alternative causal pathways and quantified exclusion sensitivity. Identify which checks apply to the actual number of endogenous regressors. Report what each finding changes about the causal interpretation.

7. **Write the review** in the requested format.

## Output formats

**essay** (default): prose argument ordered claims → decomposition → dose-response → mechanism → implementation → benchmarking → fragility → generalizability verdict. Every paragraph advances the argument with specific numbers; the verdict states what a reader should believe and at what confidence.

**referee**: summary (1 paragraph, neutral) → major concerns (numbered, each with the evidence) → minor concerns → recommendation.

## Red flags you are cutting corners

- You summarized the abstract's effect sizes without rebuilding the component table yourself.
- You wrote "small sample" without counting clusters in each treatment cell.
- You flagged multiple testing without running (or requesting) a correction.
- You accepted the mechanism because it is plausible rather than because the paper measured exposure.
- You skipped the replication-package search because re-analysis "is out of scope" — the search itself takes two minutes.
