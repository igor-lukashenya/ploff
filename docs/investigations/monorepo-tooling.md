# Monorepo Tooling Investigation - Independent Releases & Multi-App Management

## Problem Statement

Ploff is a monorepo boilerplate that will host multiple independently deployable apps (APIs, UIs, workers). We need:

1. **Independent release cycles** - API can release daily, UI weekly, worker on-demand
2. **Change detection** - only build/test/deploy what actually changed
3. **Per-app versioning** - each app has its own semantic version and changelog
4. **Scalable CI/CD** - works with 2 apps today, 20 apps tomorrow
5. **Minimal tooling overhead** - aligned with ADR-001 (no heavy JS-ecosystem tools)

---

## Category 1: Release Management & Versioning

### Option A: Release Please (Google) - RECOMMENDED

**What**: GitHub Action that automates releases based on Conventional Commits. Creates "Release PRs" that accumulate changes, then publishes GitHub Releases when merged.

**Monorepo support**: Native. Each app gets its own release track via `release-please-config.json`.

**How it works**:
```
commit: feat(sample-api): add user endpoint
  -> Release Please opens PR: "release: sample-api v1.2.0"
  -> PR accumulates more commits
  -> Merge PR -> GitHub Release created + tag: sample-api/v1.2.0
```

**Config example** (`release-please-config.json`):
```json
{
  "packages": {
    "apps/sample-api": {
      "component": "sample-api",
      "release-type": "simple",
      "bump-minor-pre-major": true,
      "changelog-path": "CHANGELOG.md"
    },
    "apps/web": {
      "component": "web",
      "release-type": "simple",
      "bump-minor-pre-major": true,
      "changelog-path": "CHANGELOG.md"
    }
  }
}
```

**Pros**:
- Zero runtime dependencies (GitHub Action only)
- Per-app changelogs auto-generated
- Conventional Commits driven (already our convention)
- Tags like `sample-api/v1.2.0` enable per-app deployment triggers
- Battle-tested at Google scale
- No Node.js or .NET tooling required at build time

**Cons**:
- GitHub-only (won't work in Azure DevOps without adaptation)
- Release PR workflow is opinionated (some teams prefer direct tagging)

**Verdict**: Best fit. Aligns with Conventional Commits, zero project dependencies, per-app releases out of the box.

---

### Option B: Versionize (.NET Tool)

**What**: .NET global tool that reads Conventional Commits and bumps version + generates CHANGELOG.

**Usage**: `dotnet versionize --proj-dir apps/sample-api`

**Pros**:
- Pure .NET, no Node.js
- Lightweight, simple CLI
- Updates `.csproj` version directly

**Cons**:
- Per-project scoping requires manual scripting
- No GitHub Release creation (just changelog + version bump)
- Less monorepo-aware than Release Please
- Still need CI glue to create tags/releases

**Verdict**: Good for simple cases but requires more glue code for monorepo.

---

### Option C: Nerdbank.GitVersioning (nbgv)

**What**: NuGet package that computes versions from git height + `version.json` per project.

**Pros**:
- .NET native, no external tools
- Deterministic builds (version from git history)
- Each project can have its own `version.json`

**Cons**:
- No changelog generation
- Git-height versioning is less human-readable (1.0.42 vs 1.2.0)
- Doesn't support Conventional Commits semantics
- Harder to communicate "what changed in this release"

**Verdict**: Good for CI build numbers but not for user-facing release management.

---

### Option D: Semantic Release (Node.js)

**What**: Node.js tool with plugins for monorepo, git tags, changelogs.

**Pros**:
- Very flexible plugin system
- Works with any project type

**Cons**:
- Requires Node.js in CI
- Heavy config for monorepo setup
- Goes against ADR-001 philosophy (adds JS ecosystem dependency)

**Verdict**: Skip - adds unnecessary JS dependency.

---

## Category 2: Change Detection (CI)

### Option A: dorny/paths-filter - ALREADY IN USE

**What**: GitHub Action that detects which paths changed and outputs boolean flags.

**Already configured** in `.github/workflows/ci.yml`. Just needs app entries added.

```yaml
- uses: dorny/paths-filter@v3
  id: filter
  with:
    filters: |
      sample-api:
        - 'apps/sample-api/**'
        - 'packages/**'
      web:
        - 'apps/web/**'
        - 'packages/**'
```

**Pros**: Simple, zero dependencies, already there
**Cons**: Path-based only (doesn't understand project references)

---

### Option B: dotnet-affected

**What**: .NET global tool that uses MSBuild project reference graph to find affected projects.

**Usage**: `dotnet affected --from main --format text`

**Pros**:
- Understands `.csproj` project references (if `packages/shared-lib` changes, it knows `sample-api` is affected)
- More accurate than path-based detection for .NET

**Cons**:
- .NET only (won't help with future JS/TS apps)
- Extra tool to install in CI

**Verdict**: Worth adding later when there are shared packages with cross-project references. Overkill for now.

---

### Recommendation: Use dorny/paths-filter (already there) + add app entries as apps are created.

---

## Category 3: Build Orchestration & Task Running

### Option A: Enhanced Makefile - RECOMMENDED

**What**: Extend current Makefile with per-app targets and an "affected" pattern.

```makefile
# Build only specific app
build-sample-api:
    cd apps/sample-api && dotnet build

# Build only what changed (used by CI)
build-affected:
    @for app in $(AFFECTED_APPS); do \
        $(MAKE) build-$$app; \
    done

# Release a specific app
release-sample-api:
    cd apps/sample-api && dotnet publish -c Release -o ../../dist/sample-api
```

**Pros**: Already in place, no new tools, works everywhere
**Cons**: No caching, no parallel task graph

---

### Option B: Just (casey/just)

**What**: Modern command runner, like Make but simpler syntax, cross-platform.

```just
# justfile
build app:
    cd apps/{{app}} && dotnet build

test app:
    cd apps/{{app}} && dotnet test

release app version:
    cd apps/{{app}} && dotnet publish -c Release
```

**Pros**: Cleaner syntax, better cross-platform, parameterized recipes
**Cons**: Extra tool to install, team needs to learn it, Make already works fine

**Verdict**: Nice-to-have but not worth switching. Make is universal.

---

### Option C: Nx

**Pros**: Task graph, caching, affected detection, remote cache
**Cons**: Node.js dependency, heavy for .NET monorepo, goes against ADR-001

**Verdict**: Skip per ADR-001 decision.

---

## Category 4: Solution & Project Structure

### Root Solution File

For IDE support and `dotnet` CLI commands across the whole repo, add a **root `.slnx`**:

```xml
<Solution>
  <Folder Name="/apps/">
    <Folder Name="/apps/sample-api/">
      <Project Path="apps/sample-api/SampleApi.csproj" />
    </Folder>
  </Folder>
  <Folder Name="/packages/">
    <!-- Shared packages here -->
  </Folder>
  <Folder Name="/tests/">
    <Project Path="apps/sample-api/tests/SampleApi.Tests/SampleApi.Tests.csproj" />
  </Folder>
</Solution>
```

This lets you `dotnet build Ploff.slnx` from root for local dev while CI builds individual apps.

---

## Category 5: Deployment Triggers

With Release Please + per-app tags, deployments trigger on tag patterns:

```yaml
# .github/workflows/deploy-sample-api.yml
on:
  push:
    tags:
      - 'sample-api/v*'

# .github/workflows/deploy-web.yml
on:
  push:
    tags:
      - 'web/v*'
```

This gives you:
- **API releases daily**: merge the Release PR for sample-api whenever ready
- **UI releases weekly**: let the web Release PR accumulate, merge on Fridays

---

## Final Recommendation

| Concern | Tool | Why |
|---------|------|-----|
| **Versioning & Releases** | Release Please | Per-app, Conventional Commits, zero deps |
| **Change Detection** | dorny/paths-filter | Already in CI, simple, effective |
| **Task Runner** | Makefile (enhanced) | Already there, universal |
| **IDE / Build All** | Root `.slnx` | Standard .NET tooling |
| **Deployment** | Tag-triggered workflows | Per-app deploy on tag push |
| **Changelogs** | Release Please (auto) | Generated from commits per app |

### What We DON'T Need (Yet)
- Nx / Turborepo (overkill, adds JS dependency)
- Bazel / Pants (enterprise scale, too complex)
- dotnet-affected (valuable later when shared packages grow)
- GitVersion / nbgv (Release Please handles this better for our workflow)

---

## Implementation Plan

1. Add `release-please-config.json` + `.release-please-manifest.json` to repo root
2. Add Release Please GitHub Action workflow
3. Create root `Ploff.slnx` referencing all projects
4. Expand `dorny/paths-filter` in CI with app entries
5. Add per-app deploy workflows triggered by tags
6. Update Makefile with per-app build/test/publish targets
7. Record decision as ADR-002

---
