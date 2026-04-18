# Release Process

This document describes how to create and manage releases for this project.

## Versioning

We follow [Semantic Versioning](https://semver.org/) (SemVer):

```
MAJOR.MINOR.PATCH

MAJOR — Breaking changes (incompatible API changes)
MINOR — New features (backward compatible)
PATCH — Bug fixes (backward compatible)
```

For pre-release versions: `1.0.0-alpha.1`, `1.0.0-beta.2`, `1.0.0-rc.1`

## Branching & Releases

```
main ─────●──────●──────●──────●──── (always deployable)
           \            │
            feature/x   tag: v1.2.0
```

- `main` is always in a deployable state
- Features are developed on feature branches and merged via PR
- Releases are created by tagging `main`

## Release Checklist

### 1. Prepare

- [ ] All features for the release are merged to `main`
- [ ] All CI checks pass on `main`
- [ ] Review the changelog for completeness

### 2. Update Changelog

Move items from `[Unreleased]` to a new version section in `docs/release-notes/CHANGELOG.md`:

```markdown
## [1.2.0] - 2026-04-18

### Added
- New user authentication flow (#42)

### Fixed
- Dashboard loading timeout (#38)
```

### 3. Tag the Release

```bash
# Create an annotated tag
git tag -a v1.2.0 -m "Release v1.2.0"

# Push the tag
git push origin v1.2.0
```

### 4. Create GitHub Release (if using GitHub)

1. Go to **Releases** → **Draft a new release**
2. Select the tag `v1.2.0`
3. Copy the changelog section as the release description
4. Publish the release

### 5. Deploy

The deployment pipeline can be triggered automatically by the tag, or manually:

```bash
# GitHub Actions
# Use the workflow_dispatch trigger or configure on tag push

# Azure DevOps
# Trigger the deploy pipeline with the target environment
```

### 6. Verify

- [ ] Deployment completed successfully
- [ ] Health checks pass in the target environment
- [ ] Smoke test critical user flows

## Hotfix Process

For urgent production fixes:

1. Create a `hotfix/<name>` branch from the latest release tag
2. Apply the fix
3. Open a PR to `main`
4. After merge, tag a new patch release (e.g., `v1.2.1`)
5. Deploy immediately

## Per-App Versioning (Optional)

In a monorepo, you may version apps independently:

```
v1.2.0              — Whole-project version (simple)
api/v1.2.0          — Per-app version tags (more granular)
web/v3.1.0
```

Choose the approach that fits your team. Whole-project versioning is simpler; per-app versioning gives more granular control.
