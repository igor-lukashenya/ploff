#!/usr/bin/env bash
#
# refresh-release-prs.sh — Bring open Release Please PR branches up to date with main
#
# Usage (CI - see .github/workflows/release-please.yml):
#   ./tools/scripts/refresh-release-prs.sh <release-branch>...
#
# Each app has its own release PR, and every release PR edits the shared
# .release-please-manifest.json. After one of them is merged, the others conflict
# on that file, and Release Please doesn't rebuild them (their notes didn't change).
#
# For each branch this script merges main in. If the manifest is the only
# conflict, it resolves it as: main's manifest + the versions this PR changed.
# Any other conflict is left for a human (the branch is skipped with a warning).
#
# Requires: git, jq. Environment: REMOTE (default origin), BASE (default main).

set -euo pipefail

REMOTE="${REMOTE:-origin}"
BASE="${BASE:-main}"
MANIFEST=".release-please-manifest.json"

if [ $# -eq 0 ]; then
  echo "No open release PR branches - nothing to refresh."
  exit 0
fi

git fetch --quiet "$REMOTE" "$BASE" "$@"

for branch in "$@"; do
  echo "── $branch"
  git checkout --quiet -B "$branch" "$REMOTE/$branch"

  if git merge-base --is-ancestor "$REMOTE/$BASE" HEAD; then
    echo "   already up to date with $BASE"
    continue
  fi

  if git merge --quiet --no-edit "$REMOTE/$BASE" >/dev/null 2>&1; then
    echo "   merged $BASE (no conflicts)"
  else
    CONFLICTS="$(git diff --name-only --diff-filter=U)"
    if [ "$CONFLICTS" != "$MANIFEST" ]; then
      git merge --abort
      echo "::warning title=Release PR needs manual update::$branch conflicts with $BASE in: $(echo "$CONFLICTS" | tr '\n' ' ')"
      continue
    fi

    MERGE_BASE="$(git merge-base HEAD "$REMOTE/$BASE")"
    jq -n \
      --argjson ours "$(git show "HEAD:$MANIFEST")" \
      --argjson base "$(git show "$MERGE_BASE:$MANIFEST")" \
      --argjson theirs "$(git show "$REMOTE/$BASE:$MANIFEST")" \
      '$theirs + ($ours | with_entries(select(.value != $base[.key])))' > "$MANIFEST"

    git add "$MANIFEST"
    git commit --quiet --no-edit
    echo "   merged $BASE, resolved $MANIFEST: $(jq -c . "$MANIFEST")"
  fi

  git push --quiet "$REMOTE" "HEAD:refs/heads/$branch"
  echo "   pushed"
done
