---
name: audit-package
description: Use when auditing a software library or package for correctness defects — a dependency you rely on, a package you maintain, or a well-known package you suspect — and when preparing a bug fix to send upstream to a maintainer you do not know.
---

# Auditing a Package for Correctness Defects

## Overview

An analysis is wrong when a number does not mean what the prose says. A *library* is wrong in a narrower, more mechanical way: a function does not do what its own documentation says, and nothing complains. The failure that matters is not a crash — crashes get reported. It is the silent one: an argument accepted and never read, a value written to the wrong column, an operator applied to one group and not the other. Individually plausible numbers, wrong.

Division of labour: use `audit-analysis` when the question is whether an empirical result means what it claims. Use this when the question is whether a package computes what it documents, and when the deliverable is a pull request to a stranger.

The economics are unforgiving. Across ~27 R packages by prominent methodologists, a static detector produced 2 real bugs and a long tail of false positives; close reading of estimator code against its documentation produced the rest. Roughly **half of all agent-reported findings did not survive verification**. Budget accordingly: finding is cheap, confirming is the work.

## Usage

`/audit-package [path-or-repo] [mine|upstream]`

**mine** — you can commit. Findings end in a fix plus a test that fails without it.

**upstream** — the deliverable is a PR or issue in someone else's repository, under their name and yours. The bar is higher because a wrong claim is public and attributed.

## The bug classes that actually pay

Ordered by how often they turned up real defects.

1. **Documented argument silently ignored.** The formal exists, the docs describe behaviour, the body never reads it. Detect by comparing a function's formals to the symbols in its body, then keeping only *exported and documented* hits.
2. **Wrong variable in a forwarding call.** `f(a = a, b = a)` where `b = b` was meant. Grep-able, but see the false-positive trap below.
3. **Index/space mismatch.** Values computed in one representation and written at positions valid only in another — raw input columns versus a processed design matrix, say. Symptom: results depend on input *column order*.
4. **Asymmetric treatment of groups.** An operator applied to one arm and hard-coded for the other. The tell is a sibling code path that does it symmetrically.
5. **Front-end validates what the back-end cannot honour.** An option passes validation, then reaches an implementation with no branch for it, and dies on an unassigned internal variable.
6. **Order dependence.** Names assigned in one ordering while a mapping assumes another. Everything is labelled, nothing is right.

## Identities that catch them

Prefer checks with an exactly right answer. A violation is then a bug, not a judgement call.

- **Reference equivalence.** A pre-filter or fast path must return exactly what the slow path returns. A Bloom-filter join has false positives but never false negatives, so it must equal the plain join, row for row.
- **Limiting case.** As a smoothing or regularisation parameter goes to its extreme, the method must collapse to a known one — adaptive nearest neighbours to ordinary k-NN, linear tied-weight reconstruction to PCA. Compare subspaces by principal angles, not loadings; sign and rotation are free.
- **Unit-weight identity.** `weights = rep(1, n)` must reproduce the unweighted fit bit-for-bit.
- **Duplication identity.** Duplicating a row must equal giving it weight 2. Catches weights entering the point estimate but not the variance, or the reverse.
- **Group-restricted weights.** Weights that vary only within a group that cannot affect the estimand must not move it. This is what distinguishes an aggregation weight from a fitting weight.
- **Invariance.** Permuting rows, permuting columns, shifting or scaling where documented as invariant.
- **Determinism.** Same seed twice, bit-identical.
- **Self-consistency.** The reported objective must equal the objective recomputed by hand from the returned parameters. `fit` then `transform` must equal `fit_transform`.
- **Documented return values exist.** Compare the documented value section against `names()` of a real fitted object, across a grid of configurations — many slots are conditional, and one fit proves nothing.

## Verification discipline

Every rule here was bought with a mistake.

- **Reproduce on the dev default branch, not the released tarball.** One package was broken on its CRAN release and already fixed in dev; another's dev version was two releases ahead. Filing against a release fixed months ago is the most avoidable embarrassment available.
- **Resolve the default branch; never assume `master`.** A repository's `master` held an ancient version in which the bug genuinely did not exist, while `main` carried the current code. Reading the wrong branch produced a confident wrong conclusion.
- **When the maintainer has a known GitHub account, try `account/PackageName` directly.** Do not trust the `URL` field — one package listed only a homepage while an active repo existed under the author's account. Sibling packages' metadata is the clue.
- **Run tests through the package's own harness.** `testthat::test_dir(package=)` *loads* without *attaching*, so bare dataset names fail to resolve and the suite appears broken. Use `cd tests && Rscript testthat.R`; for Python, the project's own `pytest` invocation. This error put false "your test suite does not run" claims into two public PRs.
- **Measure the baseline the same way, before and after.** "No regression" is a measurement, not an assurance.
- **Re-run any delegated finding yourself.** Agents have been wrong in both directions — inventing defects and dismissing real ones.

### The false-positive traps

Before believing a static hit, rule these out:

- **Signature defaults.** `f <- function(a, b = a)` is correct and idiomatic. In one package, four of five textual matches were defaults and only one was a forwarding call. Check `formals()`, not the text.
- **Dynamic argument collection.** `mget(names, sys.frame())`, `as.list(environment())`, `match.call()` rewritten into `model.frame` — all consume arguments invisibly to a scanner. These accounted for most false "ignored argument" hits.
- **The delegate lacks the parameter.** Dropping an argument the callee cannot accept is correct, not a bug — common in deprecation shims.
- **The docs already scope it out.** An argument documented as applying only to one estimator is not a defect when another ignores it.

## Attack your own fix before you send it

A fix is a claim too, and mine have been wrong.

- **Is it correct, or merely different?** One patch forwarded a weight to a parameter that also reweighted the model fit, when only the aggregation should have been weighted. The discriminating test was weights varying only among units that cannot affect the estimand: the right parameter moved nothing, the wrong one moved the answer.
- **Does it break something that worked?** One guard fired unconditionally where the relevant code path was only reachable under a flag, turning valid calls into errors.
- **Is it complete?** Fixing a guard for one method while leaving the sibling method broken is half a fix.
- **Does the test pass for the right reason?** Revert the fix and confirm the test fails.
- **Does the documentation settle the intended behaviour?** A vignette sentence resolved one design question outright, and the resulting fix was simpler *and* more complete than the one it replaced.

## Deciding not to file

Not filing is a legitimate outcome and often the right one. Real-but-marginal findings filed beside substantive ones cost credibility.

Do not file when:

- **The diagnostics already reveal it.** If the balance table plainly shows the imbalance, the user is not misled.
- **It is already fixed upstream.**
- **It requires meaningless input.** A defect reachable only by passing values the method has no interpretation for is an input-validation gap, not a correctness bug.
- **The predicted harm does not occur.** Verify the consequence, not just the mechanism — one "silent corruption" turned out to error loudly on real input.
- **The fix is not in this project's control.** Then file an *issue* with the full analysis rather than a PR you cannot make correct. Withdrawing a PR and replacing it with a good issue is a gain, not a retreat.

## Sending it upstream

- One defect per PR. If two defects touch the same statement, they belong together; say so.
- Minimal diff. No reformatting, no drive-by fixes, no version bumps.
- Lead with the runnable reproduction and observed-versus-expected. The maintainer should be able to confirm in a minute.
- State plainly what you could not verify. If semantic equivalence with an older implementation is unchecked, say that.
- Neutral register. Describe behaviour; never impute carelessness. "The docs describe X; the body does Y" is enough.
- Note related defects you deliberately did not touch, and offer.
- **Correct publicly and promptly when wrong.** Comment on the PR; do not quietly edit the body.

## Red flags you are cutting corners

- You reported a finding without running the reproduction yourself.
- You verified against the released tarball and never checked the dev branch.
- You assumed the default branch.
- You ran the test suite in a way the project never runs it.
- You claimed "no regression" without a before measurement taken the same way.
- You treated a signature default as a forwarding bug.
- You proposed a fix without checking whether it breaks a currently-working call.
- You let "I could not tell" become a closure instead of an open lead.
- You filed a marginal finding because you had already done the work.
