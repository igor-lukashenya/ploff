#!/usr/bin/env bash
#
# scan-security.sh — Secret and vulnerability scanning (local, git hooks and CI)
#
# Usage:
#   ./tools/scripts/scan-security.sh secrets              # whole git history
#   ./tools/scripts/scan-security.sh secrets --staged     # staged changes (pre-commit hook)
#   ./tools/scripts/scan-security.sh secrets --range A..B # commit range (CI)
#   ./tools/scripts/scan-security.sh vulns                # trivy: dependencies + IaC (trivy.yaml)
#
# Scanners are installed with `make install-scanners` (pinned, checksum-verified).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR/../.."

require() { # tool, strict
  if command -v "$1" >/dev/null 2>&1; then return 0; fi
  if [ "$2" = "strict" ]; then
    echo "Error: $1 is not installed. Run 'make install-scanners'." >&2
    exit 1
  fi
  echo "⚠ $1 is not installed - skipping secret scan. Run 'make install-scanners'." >&2
  exit 0
}

case "${1:-}" in
  secrets)
    case "${2:-}" in
      --staged)
        # Never block a commit just because the scanner is missing locally
        require gitleaks lenient
        gitleaks git --staged --no-banner --redact --log-level=warn .
        ;;
      --range)
        require gitleaks strict
        gitleaks git --no-banner --redact --log-opts="${3:?missing range}" .
        ;;
      "")
        require gitleaks strict
        gitleaks git --no-banner --redact .
        ;;
      *) echo "Unknown option: $2" >&2; exit 2 ;;
    esac
    ;;

  vulns)
    require trivy strict
    trivy fs --config trivy.yaml .
    ;;

  *)
    sed -n '3,9p' "$0" | sed 's/^# \{0,1\}//'
    exit 2
    ;;
esac
