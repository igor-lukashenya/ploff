#!/usr/bin/env bash
#
# check-conventional.sh — Verify Conventional Commit messages
#
# Usage:
#   ./tools/scripts/check-conventional.sh --title "<PR title>"
#   ./tools/scripts/check-conventional.sh --range <base>..<head>   # every non-merge commit
#   ./tools/scripts/check-conventional.sh --file <commit-msg-file> # git commit-msg hook
#
# Release Please derives each app's version and changelog from these messages
# (docs/guides/release-process.md). Format:
#
#   <type>(<scope>)!: <description>
#
#   type:  feat | fix | perf | revert | deps | docs | style | refactor | test |
#          build | ci | chore
#   scope: optional, kebab-case - usually the app or package name
#   !:     optional, marks a breaking change
#
# Also accepted: GitHub's 'Revert "..."' subjects.

set -euo pipefail

TYPES="feat|fix|perf|revert|deps|docs|style|refactor|test|build|ci|chore"
PATTERN="^(${TYPES})(\([a-z0-9]+(-[a-z0-9]+)*\))?!?: [^ ].*"
REVERT_PATTERN='^Revert ".+"$'

valid() {
  echo "$1" | grep -qE "$PATTERN" || echo "$1" | grep -qE "$REVERT_PATTERN"
}

explain() {
  cat >&2 <<HELP

Expected: <type>(<scope>): <description>
  types:    ${TYPES//|/, }
  examples: feat(orders): add refunds endpoint
            fix(sample-web): handle empty API response
            docs: update release guide
See docs/guides/release-process.md
HELP
}

case "${1:-}" in
  --title)
    TITLE="${2:?missing title}"
    if valid "$TITLE"; then
      echo "PR title OK: $TITLE"
    else
      echo "::error title=PR title is not a Conventional Commit::$TITLE"
      explain
      exit 1
    fi
    ;;

  --range)
    RANGE="${2:?missing range}"
    FAILED=0
    while IFS= read -r line; do
      [ -z "$line" ] && continue
      sha="${line%% *}"
      subject="${line#* }"
      if valid "$subject"; then
        echo "ok   ${sha:0:7} $subject"
      else
        echo "::error title=Commit is not a Conventional Commit::${sha:0:7} $subject"
        FAILED=1
      fi
    done < <(git log --no-merges --format='%H %s' "$RANGE")
    if [ "$FAILED" -ne 0 ]; then
      explain
      echo "Fix with an interactive rebase (git rebase -i <base>, 'reword') and force-push." >&2
      exit 1
    fi
    ;;

  --file)
    SUBJECT="$(sed -n '/^[^#]/{p;q}' "${2:?missing file}")"
    # Let git handle fixup!/squash! commits created by `git commit --fixup`
    if echo "$SUBJECT" | grep -qE '^(fixup|squash|amend)! '; then exit 0; fi
    if ! valid "$SUBJECT"; then
      echo "Commit message is not a Conventional Commit: $SUBJECT" >&2
      explain
      exit 1
    fi
    ;;

  *)
    sed -n '3,9p' "$0" | sed 's/^# \{0,1\}//'
    exit 2
    ;;
esac
