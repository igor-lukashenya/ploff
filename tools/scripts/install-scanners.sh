#!/usr/bin/env bash
#
# install-scanners.sh — Install pinned, checksum-verified security scanners
#
# Usage:
#   ./tools/scripts/install-scanners.sh [install-dir]   # default: ~/.local/bin
#
# Installs gitleaks (secret scanning) and trivy (vulnerability/misconfiguration
# scanning). Versions and SHA-256 checksums are pinned HERE, in the repository -
# not taken from the release page - so a compromised release (as happened to
# trivy in March 2026) cannot be installed silently.
#
# Updating: bump the version, download the release checksums file, and copy the
# checksums for all four platforms below. Review the release notes first.

set -euo pipefail

GITLEAKS_VERSION="8.30.1"
TRIVY_VERSION="0.74.0"

INSTALL_DIR="${1:-$HOME/.local/bin}"

# ─── Platform ────────────────────────────────────────────────────────────────

case "$(uname -s)-$(uname -m)" in
  Linux-x86_64)                 PLATFORM="linux-x64" ;;
  Linux-aarch64 | Linux-arm64)  PLATFORM="linux-arm64" ;;
  Darwin-x86_64)                PLATFORM="darwin-x64" ;;
  Darwin-arm64)                 PLATFORM="darwin-arm64" ;;
  *) echo "Error: unsupported platform $(uname -s)-$(uname -m)" >&2; exit 1 ;;
esac

# ─── Pinned artifacts (asset name + SHA-256) ─────────────────────────────────

gitleaks_artifact() {
  case "$PLATFORM" in
    linux-x64)    echo "gitleaks_${GITLEAKS_VERSION}_linux_x64.tar.gz 551f6fc83ea457d62a0d98237cbad105af8d557003051f41f3e7ca7b3f2470eb" ;;
    linux-arm64)  echo "gitleaks_${GITLEAKS_VERSION}_linux_arm64.tar.gz e4a487ee7ccd7d3a7f7ec08657610aa3606637dab924210b3aee62570fb4b080" ;;
    darwin-x64)   echo "gitleaks_${GITLEAKS_VERSION}_darwin_x64.tar.gz dfe101a4db2255fc85120ac7f3d25e4342c3c20cf749f2c20a18081af1952709" ;;
    darwin-arm64) echo "gitleaks_${GITLEAKS_VERSION}_darwin_arm64.tar.gz b40ab0ae55c505963e365f271a8d3846efbc170aa17f2607f13df610a9aeb6a5" ;;
  esac
}

trivy_artifact() {
  case "$PLATFORM" in
    linux-x64)    echo "trivy_${TRIVY_VERSION}_Linux-64bit.tar.gz 2ae6fe3ee734b7fdf11335663e18c75ea12dccc76062f09f164a3b0f8be4371a" ;;
    linux-arm64)  echo "trivy_${TRIVY_VERSION}_Linux-ARM64.tar.gz b94ce1976bbf3c15b514b605ee88be7c6d94a29be2302847ff01cb794d47aad5" ;;
    darwin-x64)   echo "trivy_${TRIVY_VERSION}_macOS-64bit.tar.gz 472816f6888dda689d075c30254d4210b4d1035acf365aa72332f584c2f60485" ;;
    darwin-arm64) echo "trivy_${TRIVY_VERSION}_macOS-ARM64.tar.gz 1caada5e0e2091909357c7525d3aa76f4b660b13821bc143b190c7483e31cc11" ;;
  esac
}

# ─── Install ─────────────────────────────────────────────────────────────────

sha256() {
  if command -v sha256sum >/dev/null 2>&1; then sha256sum "$1" | cut -d' ' -f1
  else shasum -a 256 "$1" | cut -d' ' -f1
  fi
}

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
mkdir -p "$INSTALL_DIR"

install_tool() { # name version url-base "asset sha256"
  local name="$1" version="$2" base="$3" asset="${4%% *}" expected="${4##* }"

  if [ -x "$INSTALL_DIR/$name" ] && "$INSTALL_DIR/$name" --version 2>/dev/null | grep -q "$version"; then
    echo "  • $name $version already installed"
    return
  fi

  curl -fsSL -o "$TMP_DIR/$asset" "$base/$asset"
  local actual
  actual="$(sha256 "$TMP_DIR/$asset")"
  if [ "$actual" != "$expected" ]; then
    echo "Error: checksum mismatch for $asset" >&2
    echo "  expected $expected" >&2
    echo "  actual   $actual" >&2
    exit 1
  fi

  tar -xzf "$TMP_DIR/$asset" -C "$TMP_DIR" "$name"
  install -m 0755 "$TMP_DIR/$name" "$INSTALL_DIR/$name"
  echo "  • $name $version installed (checksum verified)"
}

echo "Installing security scanners into $INSTALL_DIR..."
install_tool gitleaks "$GITLEAKS_VERSION" \
  "https://github.com/gitleaks/gitleaks/releases/download/v${GITLEAKS_VERSION}" "$(gitleaks_artifact)"
install_tool trivy "$TRIVY_VERSION" \
  "https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}" "$(trivy_artifact)"

case ":$PATH:" in
  *":$INSTALL_DIR:"*) ;;
  *) echo "Note: add $INSTALL_DIR to your PATH." ;;
esac
