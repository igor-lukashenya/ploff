#!/usr/bin/env bash
#
# init-project.sh — Personalize this template for your new project
#
# Usage:
#   bash tools/scripts/init-project.sh
#
# This script replaces template tokens with your project's actual values.
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

# ─── Replace tokens in git-tracked files ─────────────────────────────────────

echo ""
echo -e "${BLUE}Replacing template tokens...${NC}"

cd "$REPO_ROOT"

# Get list of git-tracked text files (excludes .git/, binaries, etc.)
FILES=$(git ls-files)

while IFS= read -r file; do
  # Skip binary files and this script itself
  if file --mime-type "$file" 2>/dev/null | grep -q "text/"; then
    if grep -q '__PLOFF_' "$file" 2>/dev/null; then
      sed -i "s|__PLOFF_DISPLAY_NAME__|${DISPLAY_NAME}|g" "$file"
      sed -i "s|__PLOFF_SLUG__|${SLUG}|g" "$file"
      sed -i "s|__PLOFF_YEAR__|${CURRENT_YEAR}|g" "$file"
      sed -i "s|__PLOFF_COPYRIGHT_HOLDER__|${COPYRIGHT_HOLDER}|g" "$file"
      echo -e "  ✅ ${file}"
    fi
  fi
done <<< "$FILES"

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
