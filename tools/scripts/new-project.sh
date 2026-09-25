#!/usr/bin/env bash
#
# new-project.sh — Scaffold a new app or shared package from a generator template
#
# Usage:
#   ./tools/scripts/new-project.sh <app|package> <stack> <name>
#
# Examples:
#   ./tools/scripts/new-project.sh app dotnet-service orders
#   ./tools/scripts/new-project.sh app react-web portal
#   ./tools/scripts/new-project.sh package dotnet-library shared-kernel
#
# Normally invoked via `make new-app` / `make new-package`.
#
# 1. Renders tools/generators/<stack> with `moon generate` (app files, Dockerfile,
#    compose fragment - new files only)
# 2. Registers the project in shared config that templates must not overwrite:
#    Release Please (apps), root .slnx (.NET), Dependabot, npm lockfile (Node)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$REPO_ROOT"

GENERATORS_DIR="tools/generators"

# ─── Helpers ─────────────────────────────────────────────────────────────────

die() { echo "Error: $*" >&2; exit 1; }
step() { echo "  • $*"; }

list_stacks() {
  echo "Available stacks:"
  for tpl in "$GENERATORS_DIR"/*/template.yml; do
    local dir kind
    dir="$(basename "$(dirname "$tpl")")"
    kind="$(template_kind "$dir")"
    printf '  %-18s %-8s %s\n' "$dir" "($kind)" "$(sed -n "s/^description: '\(.*\)'$/\1/p" "$tpl")"
  done
}

# app | package, derived from the template's destination
template_kind() {
  case "$(sed -n "s/^destination: '\([a-z]*\)\/.*$/\1/p" "$GENERATORS_DIR/$1/template.yml")" in
    apps) echo "app" ;;
    packages) echo "package" ;;
    *) echo "unknown" ;;
  esac
}

# Same conversion as moon's `pascal_case` filter for kebab-case names
pascal_case() {
  echo "$1" | awk -F'-' '{ for (i = 1; i <= NF; i++) printf "%s", toupper(substr($i, 1, 1)) substr($i, 2) }'
}

# First host port >= $1 that is not used by any compose fragment
next_free_port() {
  local port="$1" used
  used="$(cat infra/docker/docker-compose.yml infra/docker/compose.*.yml 2>/dev/null \
    | sed -n 's/^[[:space:]]*- "\([0-9][0-9]*\):[0-9][0-9]*"$/\1/p')"
  while echo "$used" | grep -qx "$port"; do
    port=$((port + 1))
  done
  echo "$port"
}

# ─── Validation ──────────────────────────────────────────────────────────────

if [ $# -ne 3 ]; then
  echo "Usage: $0 <app|package> <stack> <name>"
  echo ""
  list_stacks
  exit 1
fi

KIND="$1"
STACK="$2"
NAME="$3"

[[ "$KIND" =~ ^(app|package)$ ]] || die "first argument must be 'app' or 'package'."
[ -f "$GENERATORS_DIR/$STACK/template.yml" ] || { list_stacks; die "unknown stack '$STACK'."; }

TEMPLATE_KIND="$(template_kind "$STACK")"
[ "$TEMPLATE_KIND" = "$KIND" ] || die "stack '$STACK' is for ${TEMPLATE_KIND}s. Use 'make new-$TEMPLATE_KIND'."

echo "$NAME" | grep -qE '^[a-z][a-z0-9]*(-[a-z0-9]+)*$' \
  || die "name must be kebab-case (lowercase letters, numbers, single hyphens)."

if [ "$KIND" = "app" ]; then PROJECT_DIR="apps/$NAME"; else PROJECT_DIR="packages/$NAME"; fi
[ ! -e "$PROJECT_DIR" ] || die "$PROJECT_DIR already exists."

command -v moon >/dev/null 2>&1 || die "moon is not installed. Run 'make setup' first."
command -v node >/dev/null 2>&1 || die "node is not installed. Run 'make setup' first."

# ─── Generate ────────────────────────────────────────────────────────────────

GENERATE_ARGS=(--name "$NAME")

# Templates with a `port` variable get the first free host port from their default
if grep -q '^  port:' "$GENERATORS_DIR/$STACK/template.yml"; then
  DEFAULT_PORT="$(awk '/^  port:/ { f = 1 } f && /default:/ { print $2; exit }' "$GENERATORS_DIR/$STACK/template.yml")"
  PORT="$(next_free_port "$DEFAULT_PORT")"
  GENERATE_ARGS+=(--port "$PORT")
fi

echo "Creating $KIND '$NAME' from stack '$STACK'..."
moon generate "$STACK" --defaults -- "${GENERATE_ARGS[@]}"

[ -f "$PROJECT_DIR/moon.yml" ] || die "generation failed: $PROJECT_DIR/moon.yml was not created."

LANGUAGE="$(sed -n "s/^language: '\(.*\)'$/\1/p" "$PROJECT_DIR/moon.yml")"
PASCAL="$(pascal_case "$NAME")"

echo ""
echo "Registering '$NAME'..."

# ─── Release Please (apps only - packages are released with their consumers) ─

if [ "$KIND" = "app" ]; then
  node - "$NAME" "$LANGUAGE" "$PASCAL" <<'JS'
const fs = require('fs');
const [name, language, pascal] = process.argv.slice(2);
const key = `apps/${name}`;

const extraFiles = {
  csharp: [{ type: 'xml', path: `src/${pascal}/${pascal}.csproj`, xpath: '//Project/PropertyGroup/Version' }],
  typescript: [{ type: 'json', path: 'package.json', jsonpath: '$.version' }],
  javascript: [{ type: 'json', path: 'package.json', jsonpath: '$.version' }],
}[language] ?? [];

const update = (file, fn) => {
  const json = JSON.parse(fs.readFileSync(file, 'utf8'));
  fn(json);
  fs.writeFileSync(file, JSON.stringify(json, null, 2) + '\n');
};

update('release-please-config.json', (cfg) => {
  cfg.packages[key] = {
    component: name,
    'changelog-path': 'CHANGELOG.md',
    ...(extraFiles.length ? { 'extra-files': extraFiles } : {}),
  };
});
update('.release-please-manifest.json', (manifest) => {
  manifest[key] = '0.1.0';
});
JS
  step "release-please-config.json + .release-please-manifest.json"
fi

# ─── Root .NET solution ──────────────────────────────────────────────────────

if [ "$LANGUAGE" = "csharp" ]; then
  ROOT_SLN="$(ls ./*.slnx 2>/dev/null | head -1 || true)"
  if [ -n "$ROOT_SLN" ] && command -v dotnet >/dev/null 2>&1; then
    while IFS= read -r csproj; do
      dotnet sln "$ROOT_SLN" add "$csproj" --solution-folder "$PROJECT_DIR" >/dev/null
    done < <(find "$PROJECT_DIR" -name '*.csproj' | sort)
    step "$(basename "$ROOT_SLN")"
  else
    echo "  ! Skipped root .slnx registration (dotnet or root .slnx not found)"
  fi
fi

# ─── Dependabot ──────────────────────────────────────────────────────────────

case "$LANGUAGE" in
  csharp) ECOSYSTEM="nuget" ;;
  typescript | javascript) ECOSYSTEM="npm" ;;
  *) ECOSYSTEM="" ;;
esac

DEPENDABOT=".github/dependabot.yml"
MARKER="  # new-project.sh inserts entries for new apps/packages above this line"
if [ -n "$ECOSYSTEM" ] && grep -qF "$MARKER" "$DEPENDABOT"; then
  ENTRY="  - package-ecosystem: \"$ECOSYSTEM\"
    directory: \"/$PROJECT_DIR\"
    schedule:
      interval: \"weekly\"
    commit-message:
      prefix: \"deps($NAME)\"
    labels:
      - \"dependencies\"
    groups:
      $ECOSYSTEM-minor-patch:
        update-types: [\"minor\", \"patch\"]
"
  ENTRY="$ENTRY" MARKER="$MARKER" perl -0pi -e 's/^\Q$ENV{MARKER}\E$/$ENV{ENTRY}\n$ENV{MARKER}/m' "$DEPENDABOT"
  step "$DEPENDABOT"
fi

# ─── Node.js dependencies ────────────────────────────────────────────────────
# Templates ship a known-good package-lock.json; `npm ci` installs exactly that
# (the same command CI and Docker builds use).

if [[ "$LANGUAGE" =~ ^(typescript|javascript)$ ]]; then
  (cd "$PROJECT_DIR" && npm ci --no-audit --no-fund --loglevel=error)
  step "npm dependencies installed from package-lock.json"
fi

# ─── Summary ─────────────────────────────────────────────────────────────────

echo ""
echo "✅ ${KIND^} '$NAME' created in $PROJECT_DIR"
echo ""
echo "Next steps:"
echo "  1. Verify:            make run APP=$NAME TASK=test"
[ "$KIND" = "app" ] && echo "  2. Run locally:       make dev APP=$NAME"
[ "$KIND" = "package" ] && echo "  2. Use it from an app: add '$NAME' to the app's dependsOn in moon.yml and reference it (see packages/README.md)"
echo "  3. Describe it:       $PROJECT_DIR/README.md and moon.yml (project.description)"
echo "  4. Commit with scope: feat($NAME): initial scaffold"
