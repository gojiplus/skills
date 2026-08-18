---
name: design-analysis
description: Design an empirical study before estimation. Use to state estimands and assumptions, freeze analyses, choose inference and clustering, plan placebos, or structure a research repository.
---

# Designing an analysis before you run it

## Overview

The order in which you learn things determines what you are allowed to conclude from them. Once
you have seen the coefficient, every subsequent choice — the control set, the sample window, the
clustering level, which placebo to run — is contaminated by it, and no amount of care afterwards
undoes that. The plan has to exist first, and the only proof that it did is that it was committed
first.

This skill needs `build-data`'s three artifacts: the data dictionary, the recode ledger, and the
join contract. Without them, stop and run `build-data` — an analysis designed on a file whose
columns are not understood is a plan for the wrong data. `audit-analysis` owns verifying an
analysis that already exists, and stage 5 hands off to it rather than duplicating its checks.

## Usage

`/design-analysis [path] [stage] [consult|auto]` — stage defaults to `auto` (resume at the first
stage whose artifact is missing); mode defaults to **`consult`**.

**`auto`** runs the stages end to end and reports once. Use it only when the user says so
outright — "do it autonomously", "don't stop and ask".

**Identify → Pre-specify → Interpret → Build → Audit.**

> No Y on X until the plan is frozen. Stages 1–3 are done blind to the headline estimate.

## Work with the user, not for them

Every stage here contains a decision that is the researcher's, not the analyst's. An estimand is a
choice about what question is being asked. An identifying assumption is a substantive claim about
the world that no diagnostic can settle. A clustering level follows from how treatment was
assigned, which is institutional knowledge you do not have. Resolving these silently and
presenting a coefficient is the failure this skill exists to prevent — the same failure as running
the regression first, arrived at more politely.

**Show the decisive slice, write the rest to a file.** Twenty tables and five pages in a terminal
is not collaboration, it is silence with more scrolling. `se_ladder.R` prints forty lines —
redirect it, and show the three that decide something:

```
treated clusters: 6 of 18  ->  few-cluster regime
CR2  0.0298 [0.0155, 0.0441]      wild bootstrap  [0.0149, 0.0436]
iid  0.0298 [0.0261, 0.0335]  <-- 4x narrower, and not this design's variance
full ladder: tabs/se_ladder.txt
```

One screen per checkpoint, the numbers that would change the decision, a path to the rest.

### Stop and ask at these five points

| checkpoint | what you show | what you ask |
|---|---|---|
| the estimand | the seven parts, filled in as best you can | is this the question? Weighted or unweighted, which population, which contrast? |
| the identifying assumption | the assumption, what would violate it, whether that is observable | do you accept this, or does the claim become descriptive? |
| the clustering level | how treatment appears to have been assigned, and the treated-cluster count | was assignment at this level? Nothing in the data can tell me |
| the primary outcome and subgroup list | the candidate outcomes and the families | which is primary? Everything else becomes secondary or exploratory |
| the ladder moving | the rungs side by side and the conclusion each supports | this turns on the variance estimator — fatal here, or reportable? |

Show the numbers, state the options and what each implies, **give your recommendation and your
reason**, then ask — via `AskUserQuestion`, so the options are selectable. Batch checkpoints
reached in the same stage into one question. Never ask "shall I proceed?"

**Do not ask what the design or this skill already settles.** Not whether to write `vcov`
explicitly, not whether to report intervals rather than stars, not whether to run the placebos you
pre-specified. Those are decided.

### The one place the two skills conflict

`build-data` tells you to check whether missingness is informative *about the outcome*. Doing that
means looking at the outcome, which unblinds you before this skill says to freeze the plan blind.
The conflict is structural, not a slip, and it resolves as a checkpoint rather than a rule: ask
whether to run that check blind to the treatment variable, or to accept the unblinding and record
it. Either way, **the PAP states what had been seen at the moment of freezing.** A plan claiming
more blinding than it had is worse than one that admits the contamination.

## 1. Identify: write the estimand and the assumption that buys it

An estimator is a choice you make after identification, not instead of it. Write the estimand
first, in one sentence with seven parts: **unit, population, treatment or exposure, outcome,
contrast, aggregation and weighting, time window.**

> The effect on the probability that a woman wins an open gram panchayat seat in 2010, among GPs
> in Rajasthan whose seat was reserved for a woman in 2005 and open in 2010, relative to GPs open
> in both years, unweighted, within district × samiti.

Then the assumption in plain words, **what would violate it**, and whether that violation is
observable. Three sentences. If the assumption cannot be stated without naming an estimator, you
do not have one yet.

Draw the DAG, or write the potential-outcomes statement. Its main job is not elegance; it is
catching **bad controls** — variables measured after treatment, colliders, mediators. Adding a
control is a causal claim, and the claim is often false in a direction that looks like
robustness.

What fixed effects do and do not buy: they absorb level differences along the dimension you
absorb, and nothing else. They do not address time-varying confounding, they do not make an
endogenous regressor exogenous, and a specification that gets more "robust" as you add them is
usually one whose identifying variation you have not located. **"We control for X" is not
identification.** The sentence has to be "identification comes from Y."

[identification.md](references/identification.md) has the design-branch table — estimand,
assumption, observable implication, canonical estimator, canonical standard error, sensitivity
tool — for RCTs, cluster-RCTs, DiD and staggered DiD, event studies, RD, IV, panel FE,
matching and weighting, synthetic control, and honest description.

Where you cannot identify, say so and downgrade the claim. A descriptive claim made honestly
beats a causal claim made hopefully, and the referee can tell the difference.

## 2. Pre-specify: expectations, placebos, and the estimator with its standard error

Produces `pap.md`, committed and tagged before any outcome model runs.
[pre-analysis-plan.md](references/pre-analysis-plan.md) has the template.

**Expectations, quantitative.** For each hypothesis, the predicted sign *and* a magnitude range
in substantive units. An effect you cannot bound in advance is one you cannot be surprised by,
and "we found an effect" is not a finding if any number would have counted.

**What else should be true.** Four families, all chosen before the main result:

- **placebo outcomes** the mechanism cannot touch;
- **placebo populations and periods** not exposed;
- **negative control exposure and negative control outcome** — an exposure that cannot affect the
  outcome, and an outcome the exposure cannot affect. Where both exist, the double-negative-
  control design can bound the confounding rather than only detect it;
- **dose–response and heterogeneity** predictions the mechanism implies. Written in advance these
  are tests; written afterwards they are stories.

Plus the falsification set the design demands: covariate balance, pre-trends, density continuity
at the cutoff. Specified now, not written alongside the results.

**Multiplicity, decided before you see anything.** One pre-specified primary outcome per family.
Secondary outcomes collapsed into inverse-covariance-weighted indices (Anderson 2008), which
weight down outcomes that duplicate each other. Romano–Wolf free step-down for family-wise error,
or Anderson's sharpened FDR q-values when you would rather control the false discovery rate — and
note that sharpened q-values can fall *below* the unadjusted p-values when many hypotheses are
rejected, which is a feature, not an error. The subgroup list is finite and written down;
everything not on it is labelled exploratory in the paper.

### Inference: the design picks the estimator, then you stress-test it

**Clustering is a design question, not a robustness knob.** Abadie, Athey, Imbens and Wooldridge
settle this: you cluster because of how units were *sampled* or how treatment was *assigned*, not
because errors might be correlated somewhere. Cluster at the level treatment was assigned or
sampling was clustered. In a completely randomised individual-level experiment, do not cluster at
all. If you cannot say which of the two justifications applies, you have not finished stage 1.

**Never accept a package default silently.** Write `vcov` on every estimation call, even when it
matches the default. Not pedantry — a measured case, from a repository audited while writing this
skill:

- **128 `feols()` calls; 2 with an explicit `vcov`.**
- Under **fixest 0.12.1**, the version its `renv.lock` pins, `feols(y ~ d | district)` with no
  `vcov` returns the **cluster-robust** SE and prints `Standard-errors: Clustered (district)`,
  while `feols(y ~ d)` returns iid. So every paired No-FE / FE table put an iid column beside a
  cluster-robust column and presented the two as a comparison.
- Fifteen table notes described both columns as "heteroskedasticity-robust standard errors."
  Neither column was that.
- **Under fixest 0.14.2 the default changed to iid even with fixed effects present.** Verified on
  the same data: 0.036110 clustered under 0.12.1, 0.031540 iid under 0.14.2, from identical code.

No line of code was wrong. The estimator came from a default, the note was written from memory,
and the default then moved underneath the code — so the same script now produces different
standard errors depending on which `fixest` is installed, with `renv` as the only thing holding
the old behaviour in place. Writing `vcov` explicitly is what makes a script mean the same thing
next year. Corollary: **the SE clause in a table note is generated from the fitted object, never
typed.**

**The default estimator** is `estimatr::lm_robust(..., clusters = , se_type = "CR2")`. CR2 with
Bell–McCaffrey/Satterthwaite degrees of freedom is `estimatr`'s default and has materially better
coverage than CR0 or Stata's default when clusters are unbalanced or few. `lm_lin` for experiments
with covariates — Lin (2013) shows the full treatment × covariate interaction never hurts
asymptotic precision, while the uninteracted adjustment can. `fixest::feols` when many fixed
effects force it, with `vcov` written out.

**Wild cluster bootstrap only when clusters are few.** Below roughly 40 clusters, or with few
*treated* clusters however many total, escalate to `fwildclusterboot::boottest` — MacKinnon,
Nielsen and Webb's "31" variant — or to randomization inference. Above that, CR2 is enough and the
bootstrap buys runtime, not coverage. **Count treated clusters, not observations.** That is the
number that decides, and it is the one people skip: 80,000 observations in 6 treated districts is
a 6-cluster problem.

Where assignment is known, **randomization inference is the default, not the escalation**
(`ri2`, `randomizr`). It gets coverage right by construction because it reuses the actual
assignment mechanism instead of assuming one. The ladder script cannot infer that mechanism
from a binary regressor: pass `--ri N` only to assert complete random assignment. `--param` must
name a raw numeric assignment column; derived factor coefficients are rejected. The script rebuilds
the full design matrix after permuting clusters or rows, so interactions remain internally
consistent. Use `ri2` or `randomizr` for blocked, stratified, multilevel, or other mechanisms.

**Report the ladder.** `scripts/se_ladder.R` fits one specification and returns iid, HC1, HC2,
CR0, CR2, wild cluster bootstrap and randomization inference side by side, with the cluster and
treated-cluster counts. The design picks which rung is reported in the main table; the ladder goes
in the SI. **If the conclusion moves across the ladder, that is the result** — say so, rather than
reporting the friendliest rung and calling the others robustness.

**State a coverage check.** Simulate or bootstrap under the design and confirm the nominal 95%
interval covers near 95%. `DeclareDesign` makes this something you diagnose rather than assert.

[inference.md](references/inference.md) has the decision rules, the two-way / spatial / serial
branches, and the code.

**Design analysis, not just power.** Report the MDE, and — following Gelman and Carlin — the
Type S (wrong sign) and Type M (exaggeration) rates at effect sizes you actually find plausible.
A design with 20% power does not merely fail to detect; conditional on reaching significance it
exaggerates by a factor of two or more and gets the sign wrong often enough to matter. Run this
*especially* when an apparently strong effect has been found in a small, noisy design.

**Freeze mechanics.** Commit and tag `pap.md` before running any Y-on-X code. Where
pre-registration is not credible because the data already exist, split the sample: develop on the
exploratory half, confirm on the held-out half, and say in the paper that you did.

## 3. Interpret: name the effects you can rule out

**The words "significant" and "not significant" do not appear in the prose.** They compress an
interval into a binary at an arbitrary threshold, and the binary is the part that does not
replicate.

Report the estimate and its interval in substantive units, and say what the interval rules out.
A null is a statement about magnitudes:

> not — "quotas had no effect on women's subsequent election"
> but — "the estimate is 0.4pp (95% CI −1.0 to 1.8). We can rule out effects larger than 1.8pp,
> roughly a third of the smallest effect reported in [named study, with its number]."

Every null carries that second clause, and the comparator is a real number you looked up in a
primary source, not an intuition about what counts as small. Without it, "we can rule out effects
larger than X" is a number with no referent — and a comparator you half-remember is worse than
none, because it survives into the abstract.

Convert every coefficient into an implied count, probability, or share, and check it against a
physical or population bound. A coefficient implying more treated units than exist, or a turnout
change larger than the number of registered non-voters, is a bug — and this arithmetic finds bugs
that no residual plot will.

**The interval-first exhibit is the coefficient plot.** `theme_pub()` + `geom_errorbarh` +
`COLORS_PUB` from `00_config.R`, one row per specification, zero line dashed. Make it the default
figure for every headline result. Regression tables keep their star ladders because journals
expect them; the prose, the abstract, and the output contract do not.

[interpretation.md](references/interpretation.md) has the rewrite patterns and the
equivalence-testing option for when the claim really is "no meaningful effect."

## 4. Build: the repo, the pipeline, the exhibits, and the paper

Layout is flat, lowercase, and fixed:

```
scripts/  data/  figs/  tabs/  lit/  ms/  logs/
README.md  <name>.Rproj  .Rprofile  renv.lock
```

- Scripts are `NN[a-z]_<scope>_<verb>.R` — number is the pipeline stage, letter the sub-step or
  state. `00_config.R` holds constants, label dictionaries, the figure theme, and the reusable
  table-note strings; `00_utils.R` holds the table writers, string normalisers, and match helpers.
  Every analysis script sources both, opens with a header comment naming its purpose and **output
  path**, uses `here::here()` for every path, reports progress with `message()`, and prints
  `message("Created: <path>")` after each artifact. Dead code moves to `scripts/archive/`.
- **`99_run_all.R` is the driver**: an explicit ordered list grouped into named phases, a
  timestamped log in `logs/`, per-script timing, warning capture, and fail-fast. Not a regex glob
  over the scripts directory — phase order legitimately differs from filename order when a
  dependency requires it, and the reason belongs in the banner comment where a glob cannot put it.
- **No intermediate data files.** The pipeline recomputes. The exception is data that is expensive
  or impossible to re-collect — scrapes, API pulls, manual coding, paid extracts — cached once
  under `data/<source>/source/` with a provenance stamp and never regenerated by the driver. A
  cached file that exists because a join was slow is a file nobody can trace.
- **One theme, one table writer.** `theme_pub()`, `COLORS_PUB`, and the `FIG_WIDTH_*` constants for
  every figure; `ggsave(..., device = cairo_pdf)` into `figs/`. Tables only through `aer_etable()`
  (fixest) or `custom_stargazer()` (lm), never the package raw at the call site — that is what
  keeps 2 digits, booktabs, `\scriptsize`, and the notes block identical across forty tables.
- `ms/main.tex`, XeLaTeX, built by `latexmk -xelatex` through `compile.sh`. Tables enter as
  `\input{../tabs/x.tex}` fragments holding only the `tabular` and its notes; the float, caption,
  and label live in the manuscript. **Any number appearing in both prose and a table comes from a
  macro or an `\input`, never a typed digit** — that single mechanism prevents the most common
  error `audit-analysis` finds.
- **README order**: title → abstract paragraph with the headline number → the question and why it
  matters → the design in three sentences → the finding → `## Quick Start` → pipeline architecture
  → `## Data Dependencies` → `## Code Organization` → `## Notes on Analysis`, *including what was
  deliberately not reported and why* → `## Outputs` → `## Requirements`.

[repo-layout.md](references/repo-layout.md) has the full templates, the driver, and the README.

## 5. Audit: be audited before the numbers exist

Self-audit first. Run `audit-analysis` in `own` mode over everything from stages 1–4 **before the
outcome models are unblinded**. An audit after the results exist is an audit of a decision you
have already defended to yourself.

**Then a second model.** Two work non-interactively:

```bash
codex exec "<prompt>"

# Gemini via Antigravity. --print-timeout because the 5m default kills a real
# review; --dangerously-skip-permissions because headless auto-denies every tool
# request and the run returns "no output produced" without it -- paired with
# --mode plan, which keeps the agent read-only.
agy --mode plan --dangerously-skip-permissions \
  --print-timeout 45m --model gemini-3.1-pro-high -p "<prompt>"
```

The standalone `gemini` CLI may refuse individual OAuth outright; `agy` is then the only way in.
`release` owns these tooling details — check it there rather than rediscovering them.

**Run both when you can.** They do not fail the same way, and the union of two reviews is
meaningfully larger than either. `agy` also reaches Claude models, but a second opinion from the
same family as the first is worth less than one from a different family.

Give the second reader the data dictionary, the join contract, the PAP, and the code, and ask for
exactly three things: **the strongest rival explanation, the three assumptions most likely to be
wrong, and anything methodologically out of date.** Do not ask for a code review — that is not the
failure mode at this stage, and asking for it reliably gets you style notes instead of the
identification problem. Tell it not to summarise your work back to you and not to praise it.

Then **re-derive every finding before acting on it.** Reviewing this skill, one model correctly
caught that a claim about a package default was wrong for the current release — and was itself
wrong about the version the repo pinned, where the original claim held. Both halves mattered and
only running the code settled it.

This is the same gate discipline as `release`, where a second model is mandatory before anything
irreversible happens, and for the same reason: producing the headline number is the step you
cannot take back.

Only then run the pre-specified analysis. Anything discovered after this point is labelled
exploratory in the paper, not folded into the confirmatory results.

Deviations from the PAP get a table: what changed, why, and what the pre-specified version showed.
A deviation reported is a judgement call; a deviation unreported is the whole problem.

## Output contract

Start with the stage the analysis is at and what blocks the next one. Then provide:

1. The estimand in its seven parts, and the identifying assumption with what would violate it and
   whether that is observable.
2. The pre-analysis plan: hypotheses with predicted signs and magnitude ranges, the placebo and
   negative-control set, the multiplicity plan.
3. The estimator and its standard error, with the design reason for the clustering level, the
   cluster and treated-cluster counts, the SE ladder, and the coverage check.
4. Design analysis: MDE, and Type S and Type M rates at plausible effect sizes.
5. The build map: scripts in dependency order, exhibits, and the one command that runs it all.
6. The audit record: self-audit findings, second-model findings, and what changed.

Every result stated as an interval and what it rules out. Never present an estimate before the
plan that produced it.

## Sources

The literature each check came from, and what each supplied, is in
[sources.md](references/sources.md). Names there are routing devices, not appeals to authority.

## Red flags you are cutting corners

- You ran the outcome model before the plan was committed.
- You let the package choose the variance estimator, then described it from memory.
- You put an iid column and a cluster-robust column in one table and called it a comparison.
- You counted observations when the question was how many *treated clusters* you have.
- You reached for the wild cluster bootstrap with 300 clusters, or skipped it with 12.
- You reported one standard error without knowing what the others would have said.
- You picked the rung of the ladder that gave the answer you wanted.
- You wrote "significant" instead of naming the effects you can rule out.
- You reported a null without a comparator that makes the ruled-out range mean something.
- You wrote "we control for X" where the sentence needed "identification comes from Y."
- You added a control measured after treatment because it improved the fit.
- You chose the placebo test after you saw the main result.
- You ran a power calculation and skipped the Type M rate on a design you know is noisy.
- You cached an intermediate file because the pipeline was slow, and now nobody knows which code
  produced it.
- You fixed a number in a table and typed the new one into `ms.tex` by hand.
- You audited your own analysis and skipped the second reader because you were confident.
