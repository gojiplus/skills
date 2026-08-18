---
name: release
description: Cut a package release, tag, or registry publication. Requires user-facing documentation review with on-writing, complete tests, and independent second-model review before release.
---

# Releasing a Package

## Overview

A release is the one action in ordinary development that is not reversible. A bad commit
is amended, a bad branch is deleted, a bad deploy is rolled back. A version published to
PyPI or CRAN is *permanent* — the number can never be reused, the artifact is mirrored
within minutes, and the correction is a new release plus an explanation.

So the bar is not "I believe this is ready." The bar is **two independent parties ran the
code and agree**, where the second party is another model and not you.

The reason for the second party is measured, not theoretical. On one release, the author's
own review plus a fully green local suite plus seven green CI checks still shipped four
defects into a PR: a fusion gate that certified a model different from the one serialized,
a p-value with no nominal false-positive rate, a robots.txt check that ran *after* the
request robots forbade, and a date-to-week conversion that put 31 December in week 48. All
four were found by Codex in one pass. None were found by the author, who had read the same
code repeatedly and believed it correct.

You are not a reliable reviewer of code you just wrote. Neither is CI — it only knows what
the tests ask.

**What "independent" means.** A different model, with no memory of having written the
code, running it for itself. It does not mean a specific vendor. Codex and Gemini are both
qualified; so is any comparable reviewer you can actually invoke. What does *not* qualify
is you re-reading your own diff, a subagent spawned from your own context, or a second
pass by the same model in the same session — those share the blind spot that produced the
defect. Independence is the property being bought here, and vendor choice is just how you
buy it.

## Usage

`/release [version]` — e.g. `/release 0.13.0`. Without a version, infer it from the
changelog and confirm before tagging.

## The gates, in order

Each gate must pass before the next is attempted. Do not run them out of order and do not
proceed on a partial pass. If a gate fails, fix the cause and **restart from gate 1** —
a fix invalidates every result computed before it.

### Gate 1 — Preflight

- The working tree is clean. `git status --porcelain` is empty.
- You are on a branch **CI actually runs on**. Check the workflow's `on:` triggers. Many
  repos run CI only on `main` and pull requests, which means a tag cut from a feature
  branch publishes code CI has never seen. If the branch is not covered, open a PR first.
- The version is not already published and not already tagged. `git tag -l` and the
  registry both.
- The changelog has an entry for this version with a real date.
- **Nothing else is editing this repo.** A clean tree at gate 1 does not stay clean —
  another agent session, a cron job, or the user in a second terminal can start a
  refactor at any point during a long release. Check before you tag, not just at the
  start:

  ```bash
  git status --porcelain
  ps -eo pid,etime,command | grep -F "$(pwd)" | grep -v grep
  ```

  If you find unfamiliar modifications, **do not revert them and do not commit them** —
  find out whose they are first. On one release, a concurrent session was midway through
  extracting a package's test helpers into a separate dependency; `git add -A` would have
  swept a half-finished refactor into the release commit, and `git checkout --` would have
  destroyed an hour of someone else's work. Stop and ask.

  Re-run `git status --porcelain` immediately before the merge and again before the tag.
  A release is a snapshot of a moving tree, and the tag is what makes it permanent.

### Gate 2 — The project's own checks, run locally

Read the project's `CLAUDE.md` (or `AGENTS.md`, `Makefile`, `CONTRIBUTING.md`) and run the
commands it names — all of them, including the ones that are easy to forget because they
only run in CI. Do not substitute your own idea of a good check for the project's.

State the result as counts. "Tests pass" is not a result; "391 passed, 12 skipped" is.

**A green local run is not evidence CI will be green.** Local and CI differ in interpreter
version, installed browsers, network egress, and environment variables. One release passed
locally on Python 3.14 and failed CI on 3.11 and 3.12, because `ipaddress.is_global`
changed its answer for IPv4-mapped IPv6 addresses in 3.13. Treat any local-only pass as
provisional until gate 5.

**Run each check as its own command and read its exit code.** `&&` correctly stops at the
first failure, but a long compound command makes it easier to miss which gate failed in
noisy output. `set -e` also has shell-specific exceptions. Neither replaces inspecting
each result.

#### Gate 2a — US spelling

Assistant-written prose drifts into British spelling, and it lands in docstrings, README
text and changelog entries where it then looks deliberate. Grep the diff, not the whole
repo, so pre-existing text is not swept in:

```bash
git diff <base>...HEAD --name-only | grep -E '\.(py|md|rst|txt|yml)$' | while read -r f; do
  [ -f "$f" ] || continue
  grep -onwE 'randomis(e|ed|ing|ation)|behaviour|modelling|labelled|centred|summaris(e|ed)|analys(e|ed|ing)|generalis(e|ed)|artefact|normalis(e|ed)|initialis(e|ed)|optimis(e|ed)|whilst|favour(ite|able)?|colour|licence|catalogue|defence' "$f" | sed "s|^|$f:|"
done
```

Note `analysis` is correct in both — match `analyse`/`analysed`/`analysing`, not `analysi`,
or the check drowns in false positives and gets ignored.

#### Gate 2b — Dead links

A release publishes documentation. A README badge pointing at a renamed repo, or a
changelog linking a moved issue, is a defect users hit immediately and the author never
sees. Check every link in the files the release actually ships:

```bash
grep -rhoE 'https?://[^ )>"]+' README.md CHANGELOG.md docs/ 2>/dev/null \
  | sed 's/[.,;:]$//' | sort -u | {
      failed=0
      while IFS= read -r url; do
        if ! code=$(curl -sL -o /dev/null -w '%{http_code}' --max-time 10 "$url"); then
          echo "ERROR  $url"
          failed=1
        elif [ "$code" -ge 400 ]; then
          echo "$code  $url"
          failed=1
        fi
      done
      exit "$failed"
    }
```

Anything 4xx is a blocker; a 5xx or a timeout may be the far end being down, so re-check
before calling it. Skip `docs/_build/` and any other generated tree — scanning build
artifacts produces noise that buries the real hits, which is exactly how `preen check`
became unreadable on one repo.

#### Gate 2c — User-facing package documentation

Treat the documentation users see before installation as part of the release artifact.
For every release, invoke the `on-writing` skill on the README and the registry landing
text. Audit the documentation index and release notes when they carry package claims. If
the package has no README, audit its equivalent landing page. Use Mode B by default: make
no edit unless you can name what the existing text does wrong for the reader. A completed
audit with no edits is a pass.

Check correctness separately from prose quality:

- State what the package does in the opening, then state the important limits close to the
  claims they qualify.
- Match the documented public API, installation commands, supported environments, and
  examples to the release candidate. Do not advertise removed or experimental features.
- Trace every quantitative or comparative claim to a reproducible result. Give its
  design and scope. Remove unverified wins, even when the sentence itself is well written.
- Keep paper plans, development history, roadmaps, and backward-compatibility promises out
  of package documentation unless users need them to install or use the release.
- Run the documented examples against the built package. Do not treat a documentation
  content check as evidence that the code works.
- Build the candidate with the project's normal packaging command, run its metadata
  checker, and inspect the rendered long description or registry preview. Confirm that it
  uses the audited source rather than stale or duplicated prose.

Record the `on-writing` triage mode, every edit and its reader-facing reason, any structural
suggestions not applied under Mode B, and the evidence for retained empirical claims.

### Gate 3 — Independent review (mandatory, never skipped)

Pick a reviewer that is not you and run it against the release diff:

```bash
# Codex — reviews the diff against a base branch directly
codex exec review --base main          # or the actual base branch

# Gemini via Antigravity (`agy`) — no review subcommand, so tell it which diff
# to read. Run it from a detached worktree of the release commit so it cannot
# collide with anything else editing the repo.
git worktree add --detach /tmp/review-wt <release-sha>
cd /tmp/review-wt && agy --mode plan --dangerously-skip-permissions \
  --print-timeout 45m --model gemini-3.1-pro-high \
  -p "Review 'git diff main...HEAD -- src/' for correctness defects. For each finding \
give file:line, what breaks, and the concrete input that triggers it. Ignore style and \
formatting. If an area is clean, say so rather than inventing a finding."
```

Three things about `agy` that cost a run each to discover:

- **`--print-timeout` defaults to 5 minutes** and a real review takes longer. It exits
  with `Error: timeout waiting for response` and you lose the work. Set it high.
- **Headless mode auto-denies every tool permission**, so without
  `--dangerously-skip-permissions` the run ends with "no output produced" — it cannot even
  run `git diff`. Pair it with `--mode plan`, which keeps the agent read-only.
- **The standalone `gemini` CLI may refuse individual OAuth entirely** ("no longer
  supported … migrate to the Antigravity suite"), in which case `agy` is the only way in.

For Codex, use `--uncommitted` for unpushed work and `--commit <sha>` for a single commit.
For either, give the release context in the prompt when the diff alone would not convey it.

Running **both** is better than running one — they do not fail the same way, and on a
large diff the union of two reviews is meaningfully larger than either. Do that whenever
both are available.

Then, **for every finding**, write down one of exactly two dispositions:

- **Fixed** — with the commit, and with a test that fails without the fix. Prove it: stash
  the fix, watch the test go red, restore it, watch it go green. Report both observations.
  A fix you did not watch fail is a fix you have not verified.
- **Refuted** — with the specific evidence that the finding is wrong. Reading the code
  again and still believing yourself is not evidence. Running it is.

"Acknowledged", "will address later", "low severity", and silence are not dispositions. If
a finding is real but genuinely out of scope for this release, that is a **release
blocker** until the user decides otherwise — surface it to them and stop. Downgrading a
real finding to get a release out is the failure this gate exists to prevent.

Codex reviews on the hosted PR (the `chatgpt-codex-connector` bot) count for this gate.
Fetch them explicitly — they are easy to miss:

```bash
gh pr view <N> --json reviews --jq '.reviews[] | "\(.author.login) [\(.state)]\n\(.body)"'
gh api repos/<owner>/<repo>/pulls/<N>/comments --jq '.[] | "\(.path):\(.line)\n\(.body)"'
```

The inline comments are a *different* endpoint from the review body and routinely contain
findings the summary omits. Fetch both, every time.

#### When the reviewer is unavailable

Usage limits, expired auth, and deprecated clients are routine, and "the reviewer is down"
is not a disposition. Work down this list before concluding you are blocked:

1. **Try a different auth path for the same tool.** A subscription that is out of credits
   is not the only way in — `printenv OPENAI_API_KEY | codex login --with-api-key` moves
   Codex onto per-token API billing, and Gemini reads `GEMINI_API_KEY` when its OAuth
   client is refused. **Ask before switching**, since this changes who gets billed and
   replaces the stored credentials.
2. **Try the other vendor.** This is the reason gate 3 names more than one. Codex being
   out says nothing about Gemini.
3. **Try the hosted PR reviewers**, which bill separately from the CLIs.
4. **Only then, surface the block to the user and stop.** Give them the options above,
   say what a release without independent review costs, and let them decide. If they
   choose to ship anyway, that is their call to make — but record in the release notes
   that gates 3 and 4 did not run.

What you must not do is quietly substitute yourself. Re-reading your own diff is worth
doing and is not this gate: on one release I reviewed my own work, declared it clean,
merged the reviewer's findings, then re-read the same code again and found eleven more
defects — two of which would have misreported statistical significance to a user. Self
review has a floor well above zero. That is an argument for doing it *and* the gate, not
for treating it as the gate.

### Gate 4 — The reviewer runs the verification, not you

Self-reported green is the single most common way a broken release ships. Three separate
times in one project's history, "the tests pass" meant the code under test never executed:
a cache test that cached nothing because the fixture domain was rejected upstream, a report
builder whose variable was shadowed so the assertion compared a value to itself, and a push
that was a no-op because the branch was not the one being pushed.

So have the reviewer run the suite itself and report what it observed. The prompt is the
same whichever tool you reached for in gate 3:

```bash
VERIFY="Run this project's full verification as documented in CLAUDE.md. \
Report the exact commands you ran and their exact output, including counts of passed, \
failed and skipped. Do not summarize or interpret — quote the output. If any command \
cannot run, say so explicitly rather than substituting another."

codex exec "$VERIFY"
agy --dangerously-skip-permissions --print-timeout 45m -p "$VERIFY"
```

Gate 4 needs to *run* things, so it cannot use `--mode plan`. Give it a worktree or a
clone rather than the working repo.

Compare its counts against gate 2's. **Any discrepancy is a stop.** Different skip counts
usually mean an environmental dependency one of you has and the other does not — which is
exactly the class of problem that becomes a CI failure or a broken wheel for a user.

**Make it prove which repo it tested.** A CLI agent may carry its own notion of the
"current project" and quietly ignore the directory you launched it from. On one release
the reviewer returned a beautifully formatted report — install log, 361 passing tests,
clean ruff, clean pyright — for *a completely different package on the same machine*. The
tell was the slow tier: `361 deselected / 0 selected`, when the project under release had
44 slow tests. Everything else looked like a pass.

So pin the path and require evidence:

- Pass the absolute path in the prompt and tell it not to change directories.
- Make its first step `pwd` and `head -20 pyproject.toml`, quoted back to you, and tell it
  to stop if the package name does not match.
- Use `--add-dir <path>` where the tool supports it.
- Check the returned counts against what you *know* the project has. A slow tier that
  selects zero when yours selects 44 is not a difference of environment; it is a different
  repository.

Verify the identity before you read the numbers. A report about the wrong project is not a
weaker pass than a report about the right one — it is no evidence at all, and it is far
more convincing than a failure.

### Gate 5 — CI, parsed as data

Never eyeball CI output and never pipe it through `awk`/`grep` to count states. Both have
produced confident false "all green" reports on runs that were failing. Parse the JSON and
assert on it:

```bash
gh pr checks <N> --json name,state | python3 -c "
import sys, json
rows = json.load(sys.stdin)
for r in sorted(rows, key=lambda x: (x['state'], x['name'])):
    print(f\"  {r['name']:<34} {r['state']}\")
bad = [r['name'] for r in rows if r['state'] not in ('SUCCESS','SKIPPED','NEUTRAL')]
print('VERDICT:', 'ALL GREEN' if not bad else 'BLOCKED: ' + ', '.join(bad))
"
```

Wait for every check to reach a terminal state. `IN_PROGRESS` is not a pass, and a run
that has not started yet does not appear in the list at all — confirm the count of checks
matches what the workflows should produce.

When a check fails, read `gh run view <id> --log-failed` and fix the cause. Never re-run a
failed job hoping for a different answer without first understanding why it failed; if it
is genuinely flaky, say so and show the evidence.

### Gate 6 — Publish

**Re-verify the default branch first — it is not the thing you tested.** Gates 2-5 ran
against your PR head. Between then and the tag, master can have moved, and what you
merged may not be what you validated. Both happened on one release:

- The PR was merged by someone else *hours before* the last fix was pushed to the branch,
  so a commit that was green in CI and covered by gate 4 simply never reached master.
  `git diff origin/master <validated-sha>` is what catches this; the PR showing "merged"
  does not.
- A Dependabot bump then landed on master, auto-merged with `GITHUB_TOKEN`. **GitHub does
  not trigger workflow runs for pushes made with `GITHUB_TOKEN`**, so that commit — which
  edited all four workflows including the publish one — had *no* CI run at all. Tagging
  there would have published from a commit CI had never seen, which is exactly what gate 1
  forbids.

So before tagging:

```bash
git fetch origin
git diff --stat origin/master <the-sha-you-validated>   # must be empty, or explain it
gh run list --commit $(git rev-parse origin/master) --limit 10   # must not be empty
```

If master's head has no CI run, do not tag it. Push a real PR (even a trivial one) to
force a run, or re-dispatch CI against master. An empty `gh run list` for a commit is not
"CI passed quietly"; it is "CI never happened."

Only now:

1. Merge to the default branch.
2. Tag, matching the repo's existing convention exactly (`v0.13.0` vs `0.13.0` — check
   `git tag -l`; getting this wrong can silently fail to trigger the publish workflow).
3. Push the tag.
4. **Watch the publish workflow to completion** and confirm the artifact is actually live
   on the registry. A release is not done when the tag is pushed; it is done when the
   thing a user installs is the thing you built.

If publishing is keyed to a specific workflow filename (trusted publishing on PyPI binds
OIDC claims to the workflow path), do not move or rename that file as part of a release.

## Report honestly

State what passed, what was skipped and why, and what remains open. If a gate was not run,
say which and why — never let silence imply a pass. If the release ships with a known
defect the user accepted, name it in the release notes.

## Red flags

| Thought | Reality |
|---|---|
| "The reviewer will probably find nothing, skip it" | It found four P1s in code that passed local tests, CI, and self-review. |
| "Codex is out of credits, so gate 3 is impossible" | Try API-key auth, then the other vendor, then the hosted bots. Blocked is a conclusion, not an opening move. |
| "I'll review it myself instead, carefully" | Do that too — but a careful self-review that declared the code clean still had eleven defects left in it, found by the *next* careful self-review. |
| "A subagent can be the second party" | It shares your context and your blind spot. Independence means a different model that did not write the code. |
| "That finding is a nitpick" | Triage it in writing anyway. "Week 48 vs 52" sounds like a nitpick and returns content a month off. |
| "Tests pass locally, CI will be fine" | Different interpreter, no browsers, no network. Provisional until gate 5. |
| "The test is green, so the fix works" | Watch it fail without the fix, or you have not tested the fix. |
| "I'll just tag from this branch" | If CI does not run on it, you are publishing unreviewed code. |
| "Let me grep the check states" | Parse JSON. Text-munging CI output has produced false greens. |
| "I'll address the review comment after release" | A release is not reversible. After is too late. |
