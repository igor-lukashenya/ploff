#!/usr/bin/env bash
#
# sync-templates.sh — Copy dependency versions from the sample apps into the
# generator templates in tools/generators/
#
# Usage:
#   ./tools/scripts/sync-templates.sh           # update templates in place
#   ./tools/scripts/sync-templates.sh --check   # report drift, change nothing
#
# Dependabot keeps the sample apps up to date but cannot see the templates.
# The sample apps are the source of truth:
#   apps/sample-api  -> NuGet versions in every generator .csproj template
#   apps/sample-web  -> package.json + package-lock.json of the react-web template
#                       (name and version reset for new apps), and every
#                       verbatim .raw file of the react-web template
# Samples that no longer exist (e.g. removed in a client repo) are skipped.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$REPO_ROOT"

CHECK=false
[ "${1:-}" = "--check" ] && CHECK=true

GENERATORS="tools/generators"
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

# Work on a copy so --check never touches the tree
cp -R "$GENERATORS" "$WORK_DIR/generators"
OUT="$WORK_DIR/generators"

# ─── NuGet versions from sample-api ──────────────────────────────────────────

SAMPLE_API_PROJECTS=$(find apps/sample-api -name '*.csproj' -not -path '*/bin/*' -not -path '*/obj/*' 2>/dev/null || true)
if [ -n "$SAMPLE_API_PROJECTS" ]; then
  while IFS=$'\t' read -r package version; do
    find "$OUT" -name '*.csproj.tera' -o -name '*.csproj.raw' | while IFS= read -r tpl; do
      PKG="$package" VER="$version" perl -pi -e \
        's/(<PackageReference Include="\Q$ENV{PKG}\E" Version=")[^"]*(")/$1$ENV{VER}$2/g' "$tpl"
    done
  done < <(cat $SAMPLE_API_PROJECTS \
    | sed -n 's/.*<PackageReference Include="\([^"]*\)" Version="\([^"]*\)".*/\1\t\2/p' | sort -u)
fi

# ─── npm manifest + lockfile from sample-web ────────────────────────────────

# New apps start at 0.1.0 with the template's name placeholder, whatever version
# sample-web has been released as.
if [ -f apps/sample-web/package.json ] && [ -d "$OUT/react-web" ]; then
  for file in package.json package-lock.json; do
    node - "apps/sample-web/$file" "$OUT/react-web/$file.tera" <<'JS'
const fs = require('fs');
const [src, dest] = process.argv.slice(2);
const json = JSON.parse(fs.readFileSync(src, 'utf8'));
const reset = (entry) => Object.assign(entry, { name: '{{ name }}', version: '0.1.0' });
reset(json);
if (json.packages?.['']) reset(json.packages['']);
fs.writeFileSync(dest, JSON.stringify(json, null, 2) + '\n');
JS
  done

  # Verbatim (.raw) template files are exact copies of sample-web files
  while IFS= read -r raw; do
    rel="${raw#"$OUT/react-web/"}"
    rel="${rel%.raw}"
    if [ -f "apps/sample-web/$rel" ]; then
      cp "apps/sample-web/$rel" "$raw"
    fi
  done < <(find "$OUT/react-web" -name '*.raw' -type f)
fi

# ─── Report / apply ──────────────────────────────────────────────────────────
# (diff -rq quotes paths containing spaces, e.g. "[name | pascal_case]"; quotes are stripped)

if diff -rq "$GENERATORS" "$OUT" > "$WORK_DIR/drift.txt"; then
  echo "Generator templates are in sync with the sample apps."
  exit 0
fi

if $CHECK; then
  echo "Generator templates are out of sync with the sample apps:"
  sed "s/'//g" "$WORK_DIR/drift.txt" | sed -n "s|^Files \(.*\) and $OUT/.* differ\$|\1|p" | sed 's/^/  /'
  echo "Run 'make sync-templates' and commit the result."
  exit 1
fi

cp -R "$OUT/." "$GENERATORS/"
echo "Updated generator templates:"
sed "s/'//g" "$WORK_DIR/drift.txt" | sed -n "s|^Files \(.*\) and $OUT/.* differ\$|\1|p" | sed 's/^/  /'
