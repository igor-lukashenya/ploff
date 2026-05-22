# Contributing to Ploff

Thank you for contributing! This document outlines conventions and processes for contributing to this monorepo.

## Table of Contents

- [Getting Started](#getting-started)
- [Repository Structure](#repository-structure)
- [Development Workflow](#development-workflow)
- [Branching Strategy](#branching-strategy)
- [Commit Messages](#commit-messages)
- [Releases](#releases)
- [Pull Requests](#pull-requests)
- [Code Style](#code-style)
- [Architecture Decisions](#architecture-decisions)

## Getting Started

1. Clone the repository
2. Read the [Getting Started Guide](docs/guides/getting-started.md)
3. Run `make setup` to install dependencies
4. Run `make test` to verify everything works
5. Run `make check` to verify lint + tests before pushing

## Repository Structure

See [README.md](README.md#repository-structure) for the full layout. Key rules:

- Every deployable unit lives in `apps/`
- Shared code goes in `packages/` - never duplicate across apps
- Infrastructure lives in `infra/` - not inside app directories
- Each app is independently versioned and releasable

## Development Workflow

1. Create a feature branch from `main` (see [Branching Strategy](#branching-strategy))
2. Make changes, commit often with [Conventional Commits](#commit-messages)
3. Ensure tests pass: `make test`
4. Ensure linting passes: `make lint`
5. Open a Pull Request targeting `main`
6. CI runs automatically (only affected apps are built/tested)
7. After review + approval, merge to `main`
8. Dev environment auto-deploys affected apps

## Branching Strategy

We use **Trunk-Based Development with per-app Release Branches**. See [ADR-002](docs/adr/002-git-branching-strategy.md) for the full rationale.

### Branch Types

| Branch Pattern | Purpose | Lifetime | Example |
|---|---|---|---|
| `main` | Integration branch, always latest code | Permanent | - |
| `feat/<scope>/<name>` | New feature development | 1-5 days | `feat/sample-api/add-users` |
| `fix/<scope>/<name>` | Bug fixes | 1-3 days | `fix/sample-api/auth-token-expiry` |
| `release/<app>/<version>` | Release stabilization + QA | Days to 1 week | `release/sample-api/v1.2` |
| `hotfix/<app>/<version>` | Emergency production fixes | Hours | `hotfix/sample-api/v1.2.1` |
| `docs/<name>` | Documentation-only changes | 1-3 days | `docs/update-api-guide` |
| `chore/<name>` | Tooling, CI, config changes | 1-3 days | `chore/upgrade-dotnet-11` |

### Rules

- **Keep branches short-lived** - merge within 1-5 days to minimize conflicts
- **Always branch from `main`** - never from another feature branch
- **Scope your branch name** - include the app name when the change is app-specific
- **Delete branches after merge** - no stale branches

### Environment Mapping

| Environment | Deployed From | Trigger |
|---|---|---|
| dev | `main` | Automatic on every merge |
| staging | `release/<app>/<version>` branch | Automatic on branch push |
| production | Release tag (`<app>/v*`) | Automatic when Release PR is merged |

## Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/). This is critical because **Release Please uses commit messages to determine version bumps and generate changelogs**.

### Format

```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

### Types

| Type | Version Bump | Description |
|---|---|---|
| `feat` | Minor (0.x.0) | New feature or capability |
| `fix` | Patch (0.0.x) | Bug fix |
| `docs` | None | Documentation only |
| `style` | None | Formatting, whitespace |
| `refactor` | None | Code change that neither fixes nor adds |
| `perf` | Patch | Performance improvement |
| `test` | None | Adding/updating tests |
| `build` | None | Build system or dependencies |
| `ci` | None | CI/CD configuration |
| `chore` | None | Maintenance tasks |

### Breaking Changes

For major version bumps, add `BREAKING CHANGE:` in the commit footer or `!` after the type:

```
feat(sample-api)!: change authentication to OAuth2

BREAKING CHANGE: JWT token format has changed. All clients must update.
```

### Scope

The scope should be the **app or package name** (matching the directory name in `apps/` or `packages/`):

```
feat(sample-api): add user management endpoint
fix(sample-api): handle null reference in health check
docs(sample-api): update API documentation
ci: add staging deployment workflow
chore: update .gitignore
```

Use no scope for changes that affect the entire repo (CI, root config, documentation).

### Examples

```bash
# Feature for an app (triggers minor version bump)
git commit -m "feat(sample-api): add user registration endpoint"

# Bug fix (triggers patch version bump)
git commit -m "fix(sample-api): return 404 instead of 500 for missing users"

# Documentation (no version bump)
git commit -m "docs(sample-api): add OpenAPI examples for user endpoints"

# CI change (no version bump)
git commit -m "ci: add code coverage reporting to CI pipeline"

# Breaking change (triggers major version bump)
git commit -m "feat(sample-api)!: replace REST with GraphQL API"
```

## Releases

Releases are automated via [Release Please](https://github.com/googleapis/release-please). You never manually bump versions or write changelogs.

### How It Works

1. You merge commits to `main` with Conventional Commit messages
2. Release Please automatically opens a **Release PR** per affected app
3. The Release PR shows the accumulated changes and proposed version bump
4. When you're ready to release, merge the Release PR
5. This creates a git tag (e.g., `sample-api/v1.2.0`) and GitHub Release
6. The tag triggers deployment to production

### Independent Release Cadences

Each app has its own Release PR. You control timing by choosing when to merge each one:

- **API**: Merge its Release PR daily or on every feature
- **Web UI**: Let changes accumulate, merge the Release PR weekly
- **Worker**: Release on-demand when ready

### Release with QA (Staging Verification)

For changes that need QA before production:

```bash
# 1. Cut a release branch from main at a known-good commit
git checkout main
git pull
git checkout -b release/sample-api/v1.2

# 2. Push - this auto-deploys to staging
git push -u origin release/sample-api/v1.2

# 3. QA tests on staging environment

# 4. If bugs found, fix on the release branch
git commit -m "fix(sample-api): correct validation error message"
git push  # staging auto-redeploys

# 5. Cherry-pick fixes back to main
git checkout main
git cherry-pick <commit-hash>

# 6. When QA approves - merge the Release Please PR on main
#    This tags and deploys to production
```

### Hotfixes

For urgent production fixes:

```bash
# 1. Branch from the production tag
git checkout -b hotfix/sample-api/v1.2.1 sample-api/v1.2.0

# 2. Fix the issue
git commit -m "fix(sample-api): patch critical auth bypass"

# 3. Push and deploy via manual workflow dispatch
git push -u origin hotfix/sample-api/v1.2.1

# 4. Cherry-pick fix back to main
git checkout main
git cherry-pick <commit-hash>
```

### Versioning

Each app tracks its own [Semantic Version](https://semver.org/):

- `MAJOR.MINOR.PATCH` (e.g., `1.2.3`)
- Breaking changes bump MAJOR
- New features bump MINOR
- Bug fixes bump PATCH

Current versions are tracked in `.release-please-manifest.json` and each app's `.csproj` file.

## Pull Requests

### Before Opening a PR

- [ ] Branch name follows convention: `feat/sample-api/short-description`
- [ ] All commits use Conventional Commit format
- [ ] `make check` passes (lint + test)
- [ ] No secrets, credentials, or `.env` files included

### PR Requirements

- Use the [PR template](.github/PULL_REQUEST_TEMPLATE.md) if available
- Link related issues or GitHub Project cards
- Request review from code owners (see [CODEOWNERS](.github/CODEOWNERS))
- All CI checks must pass (only affected apps are tested)
- At least one approval required
- Squash-merge is preferred for clean history

### CI Behavior

CI only builds and tests **affected apps** based on which files changed:

| Files Changed | Jobs That Run |
|---|---|
| `apps/sample-api/**` | sample-api lint + test + build |
| `packages/**` | All apps that depend on changed packages |
| `docs/**` | Docs build only |
| `infra/**` | Infrastructure validation |

## Code Style

- Use `.editorconfig` for base formatting (indentation, line endings)
- .NET: `dotnet format` enforces style (checked in CI)
- Each app/package may have additional language-specific linting
- Run `make lint` to check all formatting locally
- Run `make format` to auto-fix formatting issues

## Architecture Decisions

Significant decisions should be recorded as **Architecture Decision Records (ADRs)**:

1. Run `make new-adr NAME=short-description`
2. Fill in the template (context, decision, consequences)
3. Submit as part of your PR

Current ADRs:
- [001 - Monorepo Structure](docs/adr/001-monorepo-structure.md)
- [002 - Git Branching Strategy](docs/adr/002-git-branching-strategy.md)

See the [ADR template](docs/adr/000-template.md) for the format.
