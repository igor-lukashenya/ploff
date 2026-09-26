#!/usr/bin/env bash
#
# remove-samples.sh — Remove the sample apps and everything that references them
#
# Usage:
#   ./tools/scripts/remove-samples.sh
#
# Called by init-project.sh when starting a new solution (or via `make remove-samples`).
# Removes apps/sample-*, their Dockerfiles/compose fragments/nginx configs, and their
# entries in Release Please, Dependabot, the root .slnx and AGENTS.md. Generators keep
# working without the samples (see `make test-generators`).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR/../.."

SAMPLES=$(find apps -mindepth 1 -maxdepth 1 -type d -name 'sample-*' -exec basename {} \; | sort)
if [ -z "$SAMPLES" ]; then
  echo "No sample apps found - nothing to remove."
  exit 0
fi

step() { echo "  • $*"; }
echo "Removing sample apps: $(echo "$SAMPLES" | tr '\n' ' ')"

for app in $SAMPLES; do
  rm -rf "apps/$app"
  rm -f "infra/docker/Dockerfile.$app" "infra/docker/compose.$app.yml" "infra/docker/nginx-$app.conf"
  step "apps/$app and infra/docker files"
done

# ─── Release Please config + manifest ────────────────────────────────────────
export SAMPLES
perl -0pi -e '
  for my $app (split /\n/, $ENV{SAMPLES}) {
    # "apps/<app>": { ... } (one nesting level: extra-files array of objects)
    s/,?\s*"apps\/\Q$app\E":\s*\{(?:[^{}]|\{[^{}]*\})*\}//g;
  }
  s/\{\s*,/{/g;
' release-please-config.json
perl -0pi -e '
  for my $app (split /\n/, $ENV{SAMPLES}) { s/,?\s*"apps\/\Q$app\E":\s*"[^"]*"//g; }
  s/\{\s*,/{/g; s/\{\s*\}/{}/g;
' .release-please-manifest.json
step "release-please-config.json + .release-please-manifest.json"

# ─── Dependabot: drop update entries for the sample directories ──────────────
awk -v samples="$SAMPLES" '
  BEGIN { n = split(samples, list, "\n") }
  function is_sample(block,   i) {
    for (i = 1; i <= n; i++) if (index(block, "directory: \"/apps/" list[i] "\"")) return 1
    return 0
  }
  function flush() { if (buf != "" && !is_sample(buf)) printf "%s", buf; buf = "" }
  /^  - package-ecosystem:/ { flush(); inblock = 1 }
  inblock && (/^$/ || /^  #/ || /^[^ ]/) && !/^  - package-ecosystem:/ { flush(); inblock = 0 }
  { if (inblock) buf = buf $0 "\n"; else print }
  END { flush() }
' .github/dependabot.yml > .github/dependabot.yml.tmp && mv .github/dependabot.yml.tmp .github/dependabot.yml
# Collapse the blank lines left behind
cat -s .github/dependabot.yml > .github/dependabot.yml.tmp && mv .github/dependabot.yml.tmp .github/dependabot.yml
step ".github/dependabot.yml"

# ─── Root .slnx: drop sample projects and folders left empty ─────────────────
for sln in ./*.slnx; do
  [ -f "$sln" ] || continue
  perl -0pi -e '
    for my $app (split /\n/, $ENV{SAMPLES}) { s/^[ \t]*<Project Path="apps\/\Q$app\E\/[^"]*"\s*\/>\n//mg; }
    1 while s/^[ \t]*<Folder Name="[^"]*">\s*<\/Folder>\n//mg;
  ' "$sln"
  step "$(basename "$sln")"
done

# ─── AGENTS.md project table ─────────────────────────────────────────────────
if [ -f AGENTS.md ]; then
  for app in $SAMPLES; do
    perl -ni -e "print unless /\\\`apps\\/\Q$app\E[\\/\\\`]/" AGENTS.md
  done
  step "AGENTS.md"
fi

echo ""
echo "✅ Sample apps removed. Create your first app with: make new-app STACK=<stack> NAME=<name>"
