#!/usr/bin/env bash
#
# init-project.sh — Turn a copy of this template into a new solution
#
# Usage:
#   bash tools/scripts/init-project.sh
#
# Run it once, right after creating the repository from the template
# (see docs/guides/new-solution.md). It:
#   - replaces the template name (Ploff/ploff) with the solution's name and slug
#   - removes the sample apps (or keeps them with versions reset to 0.1.0)
#   - resets the changelog and, optionally, the git history
#   - prints the GitHub settings the new repository needs
#
# Needs only Bash, git and perl (no Node.js/.NET - it runs before `make setup`).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# ─── Colors ──────────────────────────────────────────────────────────────────

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;36m'
YELLOW='\033[0;33m'
NC='\033[0m'

# ─── Prompt for values ──────────────────────────────────────────────────────

echo ""
echo -e "${BLUE}🚀 Project LiftOff — Project Initializer${NC}"
echo -e "${BLUE}==========================================${NC}"
echo ""

read -rp "Project display name (e.g., My Awesome Project): " DISPLAY_NAME
if [ -z "$DISPLAY_NAME" ]; then
  echo -e "${RED}Error: Display name cannot be empty.${NC}"
  exit 1
fi

# Generate default slug from display name
DEFAULT_SLUG=$(echo "$DISPLAY_NAME" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//' | sed 's/-$//')
read -rp "Project slug for repo/URLs/code [${DEFAULT_SLUG}]: " SLUG
SLUG="${SLUG:-$DEFAULT_SLUG}"

if ! echo "$SLUG" | grep -qE '^[a-z][a-z0-9-]*$'; then
  echo -e "${RED}Error: Slug must be kebab-case (lowercase letters, numbers, hyphens).${NC}"
  exit 1
fi

CURRENT_YEAR=$(date +%Y)
read -rp "Copyright holder (e.g., Your Name or Company) []: " COPYRIGHT_HOLDER
COPYRIGHT_HOLDER="${COPYRIGHT_HOLDER:-$DISPLAY_NAME}"

read -rp "Remove the sample apps (sample-api, sample-web)? Generators don't need them (Y/n): " REMOVE_SAMPLES_INPUT
if [[ "$REMOVE_SAMPLES_INPUT" =~ ^[nN]$ ]]; then REMOVE_SAMPLES=false; else REMOVE_SAMPLES=true; fi

echo ""
echo -e "${YELLOW}Summary:${NC}"
echo -e "  Display name:      ${GREEN}${DISPLAY_NAME}${NC}"
echo -e "  Slug:              ${GREEN}${SLUG}${NC}"
echo -e "  Copyright:         ${GREEN}© ${CURRENT_YEAR} ${COPYRIGHT_HOLDER}${NC}"
if $REMOVE_SAMPLES; then
  echo -e "  Sample apps:       ${GREEN}remove${NC}"
else
  echo -e "  Sample apps:       ${GREEN}keep (versions reset to 0.1.0)${NC}"
fi
echo ""

read -rp "Proceed? (y/N): " CONFIRM
if [[ ! "$CONFIRM" =~ ^[yY]$ ]]; then
  echo "Aborted."
  exit 0
fi

cd "$REPO_ROOT"

# ─── Sample apps ─────────────────────────────────────────────────────────────

echo ""
if $REMOVE_SAMPLES; then
  bash tools/scripts/remove-samples.sh
else
  # A new solution starts at 0.1.0, not at the template's released versions
  echo -e "${BLUE}Resetting sample app versions to 0.1.0...${NC}"
  perl -pi -e 's/("apps\/[^"]+":\s*")[^"]*"/${1}0.1.0"/g' .release-please-manifest.json
  for csproj in apps/*/src/*/*.csproj; do
    [ -f "$csproj" ] && perl -pi -e 's|<Version>[^<]*</Version>|<Version>0.1.0</Version>|' "$csproj"
  done
  for pkg in apps/*/package.json; do
    [ -f "$pkg" ] && perl -0pi -e 's/("version":\s*")[^"]*"/${1}0.1.0"/' "$pkg"
  done
  for lock in apps/*/package-lock.json; do
    # root "version" and packages[""].version
    [ -f "$lock" ] && perl -0pi -e 's/("version":\s*")[^"]*"/${1}0.1.0"/; s/(""\s*:\s*\{[^{}]*?"version":\s*")[^"]*"/${1}0.1.0"/' "$lock"
  done
  rm -f apps/*/CHANGELOG.md
  echo -e "  ✅ versions, manifest and changelogs"
fi

# ─── Changelog ───────────────────────────────────────────────────────────────

if [ -f docs/release-notes/CHANGELOG.md ]; then
  cat > docs/release-notes/CHANGELOG.md <<'CHANGELOG'
# Changelog

Solution-level release notes. Each app's changes are recorded in its own
`apps/<app>/CHANGELOG.md`, maintained by Release Please.

## [Unreleased]
CHANGELOG
  echo -e "  ✅ docs/release-notes/CHANGELOG.md reset"
fi

# ─── Replace template name in git-tracked files ──────────────────────────────
#
# The template uses its own name as the placeholder so it stays runnable before
# initialization:  "Ploff" -> display name,  "ploff" -> slug.
# perl is used instead of `sed -i` for macOS/Linux/Git Bash portability; values are
# passed via the environment so special characters are never interpreted.

echo ""
echo -e "${BLUE}Replacing template name...${NC}"

if ! git grep -qI 'Ploff\|ploff' -- ':!tools/scripts/init-project.sh'; then
  echo -e "${YELLOW}No template references found - project already initialized?${NC}"
fi

# PascalCase name for the root .NET solution file (Ploff.slnx -> <Name>.slnx)
SOLUTION_NAME=$(echo "$DISPLAY_NAME" | perl -pe 's/[^A-Za-z0-9]+/ /g; s/(\w+)/\u$1/g; s/\s+//g')
SOLUTION_NAME="${SOLUTION_NAME:-Ploff}"

export PLOFF_DISPLAY_NAME="$DISPLAY_NAME" PLOFF_SLUG="$SLUG" PLOFF_SOLUTION="$SOLUTION_NAME"

while IFS= read -r file; do
  [ -f "$file" ] || continue
  # -I skips binary files
  if grep -qI 'Ploff\|ploff' "$file"; then
    perl -pi -e 's/Ploff\.slnx/$ENV{PLOFF_SOLUTION}.slnx/g; s/Ploff/$ENV{PLOFF_DISPLAY_NAME}/g; s/ploff/$ENV{PLOFF_SLUG}/g' "$file"
    echo -e "  ✅ ${file}"
  fi
done < <(git ls-files -- ':!tools/scripts/init-project.sh')

# LICENSE copyright line
if [ -f LICENSE ]; then
  export PLOFF_COPYRIGHT="Copyright (c) ${CURRENT_YEAR} ${COPYRIGHT_HOLDER}"
  perl -pi -e 's/^Copyright \(c\) [^\r\n]*/$ENV{PLOFF_COPYRIGHT}/' LICENSE
  echo -e "  ✅ LICENSE"
fi

# Root .NET solution file: Ploff.slnx -> <PascalCaseName>.slnx
if [ -f Ploff.slnx ] && [ "$SOLUTION_NAME" != "Ploff" ]; then
  git mv Ploff.slnx "${SOLUTION_NAME}.slnx"
  echo -e "  ✅ Ploff.slnx -> ${SOLUTION_NAME}.slnx"
fi

# ─── Optional: Reset git history ─────────────────────────────────────────────

echo ""
read -rp "Reset git history for a fresh start? (y/N): " RESET_GIT
if [[ "$RESET_GIT" =~ ^[yY]$ ]]; then
  rm -rf .git
  git init -q -b main
  git add -A
  git commit -q --no-verify -m "chore: initial solution setup from template"
  echo -e "${GREEN}Git history reset with initial commit.${NC}"
fi

# ─── Done ────────────────────────────────────────────────────────────────────

# GitHub settings links, if the origin remote points at GitHub
REPO_URL=""
if ORIGIN=$(git remote get-url origin 2>/dev/null); then
  REPO_PATH=$(echo "$ORIGIN" | sed -nE 's#^(https://github\.com/|git@github\.com:)([^/]+/[^/]+)$#\2#p' | sed 's/\.git$//')
  [ -n "$REPO_PATH" ] && REPO_URL="https://github.com/$REPO_PATH"
fi
link() { if [ -n "$REPO_URL" ]; then echo "     $REPO_URL/$1"; fi; }

echo ""
echo -e "${GREEN}🎉 Solution '${DISPLAY_NAME}' initialized!${NC}"
echo ""
echo "Next steps (details: docs/guides/new-solution.md):"
echo ""
echo "  1. Review and commit:  git status && git add -A && git commit -m \"chore: initialize solution\""
[ -z "$REPO_URL" ] && echo "     Then add the remote: git remote add origin <repo-url> && git push -u origin main"
echo "  2. Toolchains:         install proto once, open a new terminal, then:"
echo "                         make setup && make install-scanners"
echo "  3. First apps:         make stacks && make new-app STACK=<stack> NAME=<name>"
echo ""
echo "  GitHub settings for the new repository:"
echo "  4. Actions → General → Workflow permissions: allow GitHub Actions to create and approve pull requests"
link "settings/actions"
echo "  5. Pages → Source: GitHub Actions (documentation site)"
link "settings/pages"
echo "  6. Secret RELEASE_PLEASE_TOKEN (fine-grained token: Contents, Pull requests, Issues)"
link "settings/secrets/actions"
echo "  7. Branch rule for main: require 'CI Gate' and 'Conventional Commits'"
link "settings/rules"
echo "  8. Private repository with GitHub Code Security? Set variable ENABLE_CODEQL=true"
link "settings/variables/actions"
