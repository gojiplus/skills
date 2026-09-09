#!/usr/bin/env bash
# Classify a repo's branches and, with --delete, remove only the provably safe ones.
#
#   stale-branches.sh <repo-path> [--delete]
#
# `git branch --merged` is the wrong test here: a squash-merged branch is not an
# ancestor of main, so it reports as unmerged forever. What actually matters is
# whether the branch's CONTENT is already in main. Two ways that can be true:
#
#   contained  - `git diff main branch` is empty; the tree is reproduced in main
#   ancestor   - every commit is reachable from main
#
# Anything else has content that exists nowhere else and is never auto-deleted.
# Branches named backup/* are always kept -- they are the escape hatches.
set -euo pipefail
REPO=${1:?usage: stale-branches.sh <repo-path> [--delete]}
DELETE=${2:-}
cd "$REPO"
git fetch --prune -q

MAIN=$(git symbolic-ref --short refs/remotes/origin/HEAD | sed 's|origin/||')
echo "== default branch: $MAIN"

MERGED_PRS=$(gh pr list --state merged --limit 200 --json headRefName --jq '.[].headRefName' 2>/dev/null | sort -u || true)

echo
echo "== remote branches"
while IFS= read -r b; do
  [ "$b" = "$MAIN" ] && continue
  case "$b" in backup/*) echo "  KEEP      $b  (escape hatch)"; continue;; esac
  if [ -z "$(git diff "origin/$MAIN" "origin/$b")" ]; then          verdict="SAFE      "; why="content identical to $MAIN"
  elif git merge-base --is-ancestor "origin/$b" "origin/$MAIN"; then verdict="SAFE      "; why="ancestor of $MAIN"
  elif printf '%s\n' "$MERGED_PRS" | grep -qx "$b"; then             verdict="SAFE      "; why="PR merged"
  else
    verdict="KEEP      "
    why="$(git rev-list --count "origin/$MAIN..origin/$b") commits not in $MAIN"
  fi
  echo "  ${verdict}$b  ($why)"
  if [ "$DELETE" = "--delete" ] && [ "${verdict# }" != "KEEP      " ] && [ "${verdict}" = "SAFE      " ]; then
    git push -q origin --delete "$b" && echo "            deleted"
  fi
done < <(git ls-remote --heads origin | awk '{print $2}' | sed 's|refs/heads/||')

echo
echo "== local branches whose upstream is gone"
git branch -vv | grep ': gone]' | awk '{print "  "$1}' || echo "  (none)"
