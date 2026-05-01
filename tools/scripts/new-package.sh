#!/usr/bin/env bash
#
# new-package.sh — Scaffold a new shared package in packages/
#
# Usage:
#   ./tools/scripts/new-package.sh <package-name>
#
# Example:
#   ./tools/scripts/new-package.sh shared-models
#   ./tools/scripts/new-package.sh shared-utils

set -euo pipefail

# ─── Validation ──────────────────────────────────────────────────────────────

if [ -z "${1:-}" ]; then
  echo "Usage: $0 <package-name>"
  echo "Example: $0 shared-models"
  exit 1
fi

PKG_NAME="$1"
PKG_DIR="packages/${PKG_NAME}"

if [ -d "$PKG_DIR" ]; then
  echo "Error: ${PKG_DIR} already exists."
  exit 1
fi

# Validate kebab-case name
if ! echo "$PKG_NAME" | grep -qE '^[a-z][a-z0-9-]*$'; then
  echo "Error: Package name must be kebab-case (lowercase letters, numbers, hyphens)."
  exit 1
fi

# ─── Create Package Structure ────────────────────────────────────────────────

echo "Creating package: ${PKG_NAME}..."

mkdir -p "${PKG_DIR}/src"
mkdir -p "${PKG_DIR}/tests"

# README
cat > "${PKG_DIR}/README.md" << EOF
# ${PKG_NAME}

> TODO: Describe what this shared package provides.

## Usage

> TODO: Explain how to import/reference this package from apps.

## API

> TODO: Document the public API of this package.

## Testing

\`\`\`bash
cd ${PKG_DIR}
# TODO: Add test command
\`\`\`
EOF

# .gitkeep for empty dirs
touch "${PKG_DIR}/src/.gitkeep"
touch "${PKG_DIR}/tests/.gitkeep"

# ─── Summary ─────────────────────────────────────────────────────────────────

echo ""
echo "✅ Package '${PKG_NAME}' created successfully!"
echo ""
echo "   ${PKG_DIR}/"
echo "   ├── README.md"
echo "   ├── src/"
echo "   └── tests/"
echo ""
echo "Next steps:"
echo "  1. Initialize the package with your language's tooling"
echo "  2. Update the README with usage instructions"
echo "  3. Configure apps to import from this package"
echo "  4. Add tests"
