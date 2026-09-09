# Independent release review

Use a different model with no memory of implementing the candidate. Use an existing
review capability or supported CLI, checking current official documentation for
commands and authentication. Do not hardcode a model name or bypass permission
controls to make a reviewer run.

Give it an isolated checkout and a bounded assignment: inspect the release diff,
identify concrete correctness defects, and run the project's specified checks.
Require each finding to include location, triggering input, observed behavior, and
why it violates the intended contract. Clean areas and rejected concerns are valid
outcomes. Do not coach the reviewer toward a suspected answer.

Before trusting results, require the reviewer to report the absolute path, package
identity, and commit it actually tested. Compare commands, selected test tiers,
passed/failed/skipped counts, and dependencies against the candidate's local run.
An impressive report about the wrong repository is no evidence.

For repairs, demonstrate a regression test failing without the production change
and passing with it, then run the relevant full harness. Avoid broad stash/reset
operations in a shared worktree. Reconcile every reviewer finding with a fixed or
refuted disposition supported by observed results.

If the chosen reviewer is unavailable, try another available independent model or
an authorized hosted reviewer. Do not change stored credentials or switch from a
subscription to paid API billing without authorization. For paid review, apply
`metered-runs` when available and honor the authorized spending limit.

If no independent reviewer can run, complete all other preparation and report the
specific missing gate. Only the user can waive it. Record a waiver and its limits
in the release record; never label self-review as independent review.
