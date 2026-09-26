#!/usr/bin/env bash
#
# init-project.sh — Personalize this template for your new project
#
# Usage:
#   bash tools/scripts/init-project.sh
#
# This script replaces the template name (Ploff/ploff) with your project's values.
# Run it once after cloning/creating from the template.

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

echo ""
echo -e "${YELLOW}Summary:${NC}"
echo -e "  Display name:      ${GREEN}${DISPLAY_NAME}${NC}"
echo -e "  Slug:              ${GREEN}${SLUG}${NC}"
echo -e "  Copyright:         ${GREEN}© ${CURRENT_YEAR} ${COPYRIGHT_HOLDER}${NC}"
echo ""

read -rp "Proceed? (y/N): " CONFIRM
if [[ ! "$CONFIRM" =~ ^[yY]$ ]]; then
  echo "Aborted."
  exit 0
fi

# ─── Replace template name in git-tracked files ──────────────────────────────
#
# The template uses its own name as the placeholder so it stays runnable before
# initialization:  "Ploff" -> display name,  "ploff" -> slug.
# perl is used instead of `sed -i` for macOS/Linux/Git Bash portability; values are
# passed via the environment so special characters are never interpreted.

echo ""
echo -e "${BLUE}Replacing template name...${NC}"

cd "$REPO_ROOT"

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
  git init
  git add -A
  git commit -m "feat: initial project setup from Project LiftOff template"
  echo -e "${GREEN}Git history reset with initial commit.${NC}"
fi

# ─── Done ────────────────────────────────────────────────────────────────────

echo ""
echo -e "${GREEN}🎉 Project '${DISPLAY_NAME}' initialized successfully!${NC}"
echo ""
echo "Next steps:"
echo "  1. Review the changes: git diff"
echo "  2. Set the remote: git remote add origin <your-repo-url>"
echo "  3. Push: git push -u origin main"
echo "  4. Run: make setup && make up"
