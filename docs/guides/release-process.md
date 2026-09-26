# Release Process

This document describes how releases are created for the apps in this monorepo.

Every app is versioned and released **independently** by
[Release Please](https://github.com/googleapis/release-please), driven by
[Conventional Commits](https://www.conventionalcommits.org/). See
[ADR-002](../adr/002-git-branching-strategy.md) (branching) and
[ADR-003](../adr/003-monorepo-tooling.md) (tooling).

## Versioning

We follow [Semantic Versioning](https://semver.org/) (SemVer), per app:

```
MAJOR.MINOR.PATCH

MAJOR — Breaking changes (incompatible API changes)
MINOR — New features (backward compatible)
PATCH — Bug fixes (backward compatible)
```

Below 1.0.0, `feat` bumps the patch version and breaking changes bump the minor version.

| Commit | Example | Effect on the app's next version |
| --- | --- | --- |
| `fix(<app>): …` | `fix(orders): handle empty cart` | Patch |
| `feat(<app>): …` | `feat(orders): add refunds` | Minor |
| `feat(<app>)!: …` or `BREAKING CHANGE:` footer | `feat(orders)!: drop v1 API` | Major |
| `deps(<app>): …` | Dependabot updates | Patch |
| `docs`, `ci`, `chore`, `test`, `refactor` | | No release |

The **Conventional Commits** workflow rejects PRs whose title or commits don't follow this
format (`make check-commits` runs the same check locally).

Release Please attributes a commit to an app by the **files it changes** (`apps/<app>/`), so
the scope is for readability. Commits that only change `packages/` don't release any app;
see [Shared packages](#shared-packages).

## How a Release Happens

```
feat(orders): ...  ──► main ──► Release Please opens/updates "release orders X.Y.Z" PR
fix(orders): ...   ──► main ──► ... the PR accumulates changes and the changelog
                                 │
                   merge the PR ─┘──► tag orders/vX.Y.Z + GitHub Release
                                      ──► deploy-app.yml deploys orders to production
```

1. Merge Conventional Commit PRs to `main` as usual.
2. Release Please keeps one **release PR per app** up to date. It bumps the version
   (`.csproj` / `package.json` + `package-lock.json`), updates `apps/<app>/CHANGELOG.md` and
   `.release-please-manifest.json`.
3. When the app is ready to ship, review and **merge its release PR**. This creates the
   `<app>/vX.Y.Z` tag and GitHub Release, and deploys that version to production.

Apps release on their own schedule: merge each app's release PR whenever that app is ready.

### Conflicting release PRs

All release PRs edit `.release-please-manifest.json`. After one is merged, the Release Please
workflow merges `main` into the other open release PRs and resolves the manifest
automatically (`tools/scripts/refresh-release-prs.sh`). If a release PR conflicts in any
other file, the workflow shows a warning and you update that PR by hand.

## Setup

These are one-time settings for each repository created from the template:

1. **Settings → Actions → General → Workflow permissions**: enable
   **Allow GitHub Actions to create and approve pull requests** (required for release PRs).
2. **`RELEASE_PLEASE_TOKEN` secret** (recommended): Release PRs and their updates are pushed
   by the workflow. Pushes made with the default `GITHUB_TOKEN` don't trigger other workflows,
   so without this secret release PRs get **no CI run** until you trigger one (close and
   reopen the PR).
   1. Create a **fine-grained personal access token**
      (Settings → Developer settings → Personal access tokens → Fine-grained tokens):
      - Repository access: *Only select repositories* → this repository
      - Repository permissions: **Contents**, **Pull requests** and **Issues** (labels on
        release PRs) set to *Read and write*
      - Expiration: up to 1 year - renew it before it expires, or release PRs lose CI again
   2. Store it in the repository: Settings → Secrets and variables → Actions →
      **New repository secret** → name `RELEASE_PLEASE_TOKEN`.

   Release PRs are then authored by the token's owner instead of `github-actions[bot]`. For
   organizations, a GitHub App is the better long-term option; it needs a workflow step
   that creates a short-lived token on each run (`actions/create-github-app-token`).

## Shared Packages

Packages in `packages/` are not released on their own. A package change is rebuilt, retested
and deployed to **dev** for every app that depends on it, but Release Please only looks at
each app's own folder. To ship a package change to production in an app, land a commit
scoped to that app, for example `fix(orders): pick up shared-kernel fix`.

## Hotfix Process

For urgent production fixes:

1. Create a `hotfix/<app>/<version>` branch from the app's release tag (e.g. `orders/v1.2.0`)
2. Apply the fix with a `fix(<app>): …` commit and open a PR to `main`
3. Merge the PR, then merge the app's release PR that Release Please opens (`1.2.1`)
4. Verify the production deployment

## Manual Deployment

To deploy a specific app version to any environment, run the **Deploy App** workflow
(Actions → Deploy App → Run workflow) with the app name, version and environment.

## Verify

- [ ] Deployment completed successfully
- [ ] Health checks pass in the target environment
- [ ] Smoke test critical user flows
