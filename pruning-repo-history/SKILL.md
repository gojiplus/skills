---
name: pruning-repo-history
description: Collapse Git history to selected release commits or one commit, or recover release tags. Use only when the user requests history rewriting or tag reconstruction.
---

# Pruning Repository History

## Overview

Collapse a repo's history to a few meaningful commits — one per release, or just
the tip — without changing a byte of the working tree.

**The invariant: the new tip must point at the SAME git tree object as the old
tip.** Build with `git commit-tree` over the existing tree objects; never
`rebase` (merge commits make it awkward) or `filter-repo` (it rewrites commits
one-for-one, a different operation). Verify with `git rev-parse <new>^{tree}` vs
`git rev-parse <old>^{tree}` — exact, cheap, and it catches a dropped commit that
a diff review would miss.

Say the cost out loud before starting: `git blame` collapses to the checkpoints.
There is no size argument — packed history is usually a few hundred KB.

## Tool

`prune_repo.py` in this directory. Dry run is the default; `--yes` pushes.

```bash
prune_repo.py <repo> --mode releases          # one commit per published release
prune_repo.py <repo> --mode last              # collapse to a single commit
prune_repo.py <repo> --mode keep --keep A B HEAD --message-dir DIR
```

`--mode releases` matches published PyPI sdists / CRAN tarballs against every
commit. `--message-dir` takes `<short-sha>.txt` per checkpoint — write real
messages from the repo's own CHANGELOG/NEWS, not from your paraphrase of a diff.

## Identify releases by content, never by timestamps

Both timestamp rules fail, in opposite directions:

- "the version-bump commit" — a bump can sit unreleased for days
- "last commit before the upload" — a manual upload from a working tree
  committed minutes later puts the release commit *after* its own upload

Match the published archive's files against each commit's blobs. Hash raw **and**
LF-normalized (an archive built on Windows stores CRLF while git stores LF).
Exclude what the build tool generates: `PKG-INFO`, `*.egg-info`, a stub
`setup.cfg` containing only `[egg_info]`; for R, `MD5`, `data/datalist`,
`inst/doc/`, `build/`. `DESCRIPTION`/`PKG-INFO` are rewritten at build time, so
one mismatch there is expected.

Ties are normal — any commit touching only docs/CI leaves the tree matching.
**Break ties by closest in time to the upload.** Confirm against the repo's own
tags and CHANGELOG/NEWS headings; when they disagree with your match, the tags
are usually right and your rule is wrong.

When no commit fully matches, say so and leave it untagged. Some releases were
built from a tree that never reached git.

## Traps

| Trap | What happens | Do this |
|---|---|---|
| Creating a GitHub **Release** for an old tag | `release` events run the workflow from the **release's tag SHA** — a stale publish workflow in that old tree fires | Tag only. Tag *pushes* are silent |
| Tagging a version never published | A tag-triggered `release.yml` in that tree publishes it for real | `git ls-tree -r <commit> -- .github/workflows/` and grep `tags:` for **every** commit you'll tag, before pushing any |
| Branch ruleset | `required_status_checks` blocks *all* direct pushes, and a rewrite can't be routed through a PR (no common ancestry) | Toggle `enforcement: disabled`, push, restore. Read the ruleset, pipe through `jq` changing only `enforcement`, PUT the whole body |
| Backup branch on the remote | Permanent visible clutter | The tool writes a bundle to the temp dir and prints its size. Delete it in the same session once the fresh clone passes; a data-heavy repo makes a multi-GB bundle and the user does not want it kept |
| Local-only branches | Stranded — no shared ancestry after the rewrite | `git diff old-main branch > wip.patch`; because the tree is preserved it applies cleanly to the new history |
| Non-release tags | `pap-v1`-style pre-registration tags stop pointing at real history | Make those commits checkpoints too |
| Dynamic versioning | `uv-dynamic-versioning` reads the tag; CI's `fetch --no-tags` has nothing to resolve | Prefer a version stated in `pyproject.toml` |

## Verifying

Workflows are disabled around the push, so whether CI runs against the rewritten
head is a **race** — observed running 3 times in 4. Never rely on it in either
direction: a green tick may be from the old head, and silence is not a pass.
Clone the repo fresh and run its tests.

Audit branches *before* pruning: afterwards every surviving branch reports as
maximally divergent, so "N commits not in main" becomes meaningless.
`stale-branches.sh` classifies by whether content is already in main —
`git branch --merged` is useless against squash-merges.

## Reading a failed CI run

`gh run view --log` echoes the whole `run:` block at group start, so grepping the
log for an error string can match a line that **never executed**. Read step
conclusions first (`--json jobs --jq '.jobs[].steps[]'`), then get the real text
from `repos/O/R/check-runs/<id>/annotations`.

If CI goes red right after a prune, check whether a *moving* tag moved
(`gojiplus/py-canon@v1`). The tree is byte-identical, so a content-only check
cannot have changed its mind — only the workflow can.
