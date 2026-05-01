#!/usr/bin/env bash
#
# new-adr.sh — Create a new Architecture Decision Record
#
# Usage:
#   ./tools/scripts/new-adr.sh <short-title>
#
# Example:
#   ./tools/scripts/new-adr.sh database-selection
#   ./tools/scripts/new-adr.sh authentication-strategy

set -euo pipefail

# ─── Validation ──────────────────────────────────────────────────────────────

if [ -z "${1:-}" ]; then
  echo "Usage: $0 <short-title>"
  echo "Example: $0 database-selection"
  exit 1
fi

TITLE="$1"
ADR_DIR="docs/adr"

# Find the next ADR number
LAST_NUM=$(ls -1 "${ADR_DIR}" | grep -oE '^[0-9]+' | sort -n | tail -1)
NEXT_NUM=$(printf "%03d" $((10#${LAST_NUM} + 1)))

ADR_FILE="${ADR_DIR}/${NEXT_NUM}-${TITLE}.md"

if [ -f "$ADR_FILE" ]; then
  echo "Error: ${ADR_FILE} already exists."
  exit 1
fi

# ─── Create ADR ──────────────────────────────────────────────────────────────

DATE=$(date +%Y-%m-%d)

cat > "$ADR_FILE" << EOF
# ${NEXT_NUM}. ${TITLE//-/ }

**Date**: ${DATE}

**Status**: Proposed

**Deciders**: TODO

## Context

What is the issue that we're seeing that is motivating this decision or change?

## Decision

What is the change that we're proposing and/or doing?

## Consequences

What becomes easier or more difficult to do because of this change?

### Positive

- ...

### Negative

- ...

### Neutral

- ...

## Alternatives Considered

### Option A: ...

- Pros: ...
- Cons: ...

### Option B: ...

- Pros: ...
- Cons: ...
EOF

echo "✅ Created: ${ADR_FILE}"
echo ""
echo "Next steps:"
echo "  1. Edit the ADR: ${ADR_FILE}"
echo "  2. Add it to mkdocs.yml navigation under 'Architecture Decisions'"
echo "  3. Update docs/adr/index.md with the new entry"
echo "  4. Include in your PR"
