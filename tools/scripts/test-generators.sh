#!/usr/bin/env bash
#
# test-generators.sh — Generate one project per stack and verify it builds and passes
#
# Usage:
#   ./tools/scripts/test-generators.sh            # generate + build/lint/typecheck/test
#   ./tools/scripts/test-generators.sh --docker   # ... and build the generated Docker images
#
# Runs in a scratch copy of the repository (the working tree is never modified).
# The sample apps are removed from the copy first, so this also proves generators
# work in a solution that has deleted them.
#
# Requires the same tools as development: moon + Node.js (make setup), .NET SDK,
# and Docker for --docker. Used by CI when generators or shared tasks change.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

DOCKER=false
[ "${1:-}" = "--docker" ] && DOCKER=true

WORK_DIR="$(mktemp -d)"
cleanup() { rm -rf "$WORK_DIR"; }
trap cleanup EXIT

# ─── Scratch copy (tracked + untracked, non-ignored files) ───────────────────

cd "$REPO_ROOT"
git ls-files -z --cached --others --exclude-standard | tar --null -T - -cf - | tar -xf - -C "$WORK_DIR"
cd "$WORK_DIR"

export GIT_AUTHOR_NAME="generator-test" GIT_AUTHOR_EMAIL="generator-test@localhost"
export GIT_COMMITTER_NAME="$GIT_AUTHOR_NAME" GIT_COMMITTER_EMAIL="$GIT_AUTHOR_EMAIL"
git init -q && git add -A && git commit -q -m "chore: scratch copy"

# Remove sample apps and everything that references them
rm -rf apps/sample-*
rm -f infra/docker/compose.sample-*.yml infra/docker/Dockerfile.sample-* infra/docker/nginx-sample-*.conf
for sln in ./*.slnx; do
  [ -f "$sln" ] && printf '<Solution>\n</Solution>\n' > "$sln"
done

# ─── Generate one project per stack ──────────────────────────────────────────

GENERATED=()
for template in tools/generators/*/template.yml; do
  stack="$(basename "$(dirname "$template")")"
  case "$(sed -n "s/^destination: '\([a-z]*\)\/.*$/\1/p" "$template")" in
    apps) kind="app" ;;
    packages) kind="package" ;;
    *) echo "Skipping $stack: unknown destination" >&2; continue ;;
  esac
  name="gen-${stack}"
  echo "━━━ $kind $stack → $name"
  bash tools/scripts/new-project.sh "$kind" "$stack" "$name" > "gen-$name.log" 2>&1 \
    || { cat "gen-$name.log"; echo "✗ generation failed: $stack" >&2; exit 1; }
  GENERATED+=("$name")
done

# ─── Verify ──────────────────────────────────────────────────────────────────

echo "━━━ build, lint, typecheck, test: ${GENERATED[*]}"
moon run :build :lint :typecheck :test --summary minimal

if $DOCKER; then
  for name in "${GENERATED[@]}"; do
    dockerfile="infra/docker/Dockerfile.$name"
    [ -f "$dockerfile" ] || continue
    echo "━━━ docker build $name"
    docker build --quiet -f "$dockerfile" -t "generator-test/$name" . > /dev/null
    docker image rm "generator-test/$name" > /dev/null
  done
fi

echo ""
echo "✅ All generators produced working projects: ${GENERATED[*]}"
