---
name: develop-r
description: Develop or modernize R packages using established validation, vector, and condition tooling. Complements Posit's R skills with r-canon review defaults and machine-readable error contracts.
---

# Develop R

Use maintained R tooling for general plumbing and keep domain rules explicit.
First inspect the package's instructions, DESCRIPTION, tests, and development
commands. Respect its minimum R version and intentional dependency constraints.

## Start upstream

When available, read the relevant skills from
[Posit's r-lib collection](https://github.com/posit-dev/skills/tree/main/r-lib):
`r-package-development` for package work, `r-cli` for diagnostics, `r-testthat`
for tests, and `r-tidyverse-style` for style reviews. Use the installed skill or
read its upstream SKILL.md; do not silently install plugins or copy their contents
into this skill. These are Posit community skills; `r-package-development`
credits Simon P. Couch.

For fleet packages, read the applicable revision of
[r-canon's standard](https://github.com/gojiplus/r-canon/blob/main/STANDARD.md),
especially implementation guidance and the package's chosen tooling. Prefer a
local checkout when available. Upstream style suggestions do not automatically
replace fleet formatter settings. If skills cannot be retrieved, use
[R Packages](https://r-pkgs.org/) and the libraries' official references, and
report the missing source only when it materially limits the work.

## Choose standard primitives

- Prefer `cli` and `rlang` for informative, classed conditions. Preserve issue
  codes and other machine-readable metadata; chain underlying errors with
  `parent`. Callers should not need to parse messages.
- Use consistent predicates or `checkmate` for scalar validation, exact choice
  matching with `rlang::arg_match()`, and explicit unused-dots checks when needed.
- Use `vctrs` where vector size, coercion, or recycling semantics matter. Verify
  API lifecycle in current official documentation: `vec_assert()` / `vec_is()`
  are questioning; prefer the documented vector/size checks or type predicates.
  Do not silently cast inputs that the public contract says to reject.
- Select dependencies that remove real duplication. Do not add the whole
  tidyverse, replace clear base-R checks mechanically, or build a generic
  validation framework inside a domain package.
- Keep statistical and data-integrity checks explicit. Type validity alone
  cannot establish a valid sampling design or justify an inference.

## Validate the change

For validation refactors, exercise accepted and rejected inputs, missingness,
sizes, and coercion boundaries relevant to the contract. Assert condition classes
and metadata used by downstream callers; use snapshots for diagnostics whose
presentation matters. Run the package's local test, lint, and check commands;
regenerate documentation when its source changes. Report actual results and
unavailable checks. Keep unrelated formatting, release, and dependency migrations
outside the change unless requested.
