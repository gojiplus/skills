---
name: release
description: Release a package after local checks, documentation review, independent model review, CI verification, and validation of the published artifact.
---

# Release a package

Release the exact artifact that was reviewed and tested. Publishing a package
version can be irreversible; a tag or green local test alone is not completion.
Use the project's established build, versioning, and publication workflow.

## Prepare the candidate

Read repository instructions, release configuration, changelog, and registry
metadata. Resolve the default branch and tag convention instead of assuming them.
Confirm the intended version is neither tagged nor published. Infer a missing
version from the changes and existing policy; resolve ambiguity before tagging.

Inventory local changes and concurrent work. Preserve unrelated edits and test in
an isolated checkout when necessary. Assemble the candidate into a clean, identified
commit before publishing; do not sweep other work into a release or revert it.
Confirm which branch/tag events trigger CI and publication.

## Verify locally

Run the project's own formatting, linting, tests, documentation build, and package
checks, including required slow or integration tiers. Attempt to install missing
dependencies. Record exact commands and counts, including skipped checks and their
reasons. Validate against the supported environments where required by the project.

Build the distributable, check its metadata and contents, and exercise documented
examples against the built package. For a new regression test, confirm it fails
without the relevant fix and passes with it. Use an isolated checkout or targeted
patch; do not stash or reset unrelated work.

## Review user-facing documentation

Use `on-writing` on the README, registry landing text, and substantive release
notes. Preserve the author's voice by default. A review requiring no edits passes.

Check that installation commands, examples, supported environments, public API,
and quantitative claims match the candidate. Generate repeated version or API
information from its source where practical. Build and inspect the rendered
registry description; confirm it uses the reviewed source. Check shipped links,
rechecking transient failures and distinguishing access restrictions from dead links.

## Obtain independent review

Use a different model that did not write the changes. A second pass by the same
model or a full-history subagent is not independent review. Give the reviewer the
candidate commit, absolute repository path, relevant base, scope, and test commands.
Use an isolated checkout. See [reviewer procedure](references/reviewers.md) for
identity checks, verification, and unavailable-reviewer handling.

Require the reviewer to run the relevant verification itself. Compare its test
counts and environment with the local run; investigate differences. Review both
summary and inline comments when using a hosted PR reviewer.

Every finding needs a disposition: fixed with evidence, or refuted with evidence.
A real unresolved defect blocks publication unless the user explicitly accepts it.
After a fix, rerun affected checks and required release gates on the new candidate,
and have the reviewer verify the repair. Previously reviewed unchanged material
need not be reviewed from scratch without a reason.

## Verify CI and the publication commit

Read structured CI job/check results for the candidate commit. Wait for all required
checks and confirm expected jobs actually ran. A missing run is not a pass. If CI
fails, diagnose before retrying.

Follow the project's merge flow. Immediately before tagging or publishing, verify
that the final commit contains the reviewed candidate and that any intervening
changes were checked. Resolve differences before proceeding. Check for new local
edits or concurrent changes again. If the publication commit lacks required CI,
run the established workflow for it; do not manufacture a meaningless code change.

## Publish and verify

Carry existing release authorization forward. If publication still needs approval,
finish the reviewable candidate and report remaining risks before asking. Do not
change the billing path, publish target, or intended version implicitly.

Create and push the appropriate tag or use the project's existing release trigger.
Keep workflow paths used by trusted publishing unchanged unless that configuration
is explicitly part of the task. Watch publication to completion, then confirm the
registry version and install or inspect the published artifact using the project's
normal verification approach.

Report the version and publication link, verified commit, local and independent
check results, CI status, and any user-accepted limitations. If publication or a
required gate did not complete, state that explicitly.
