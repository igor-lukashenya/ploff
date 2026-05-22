# 002. Git Branching Strategy

**Date**: 2026-05-22

**Status**: Accepted

**Deciders**: Igor Lukashenya

## Context

We are building a monorepo that hosts multiple independently deployable applications
(APIs, UIs, workers) with different release cadences. We need a branching strategy that:

- Supports parallel feature development across apps
- Allows independent QA cycles per feature and per app
- Supports environment promotion: dev -> test -> staging -> prod
- Never deploys un-QA'd code to production
- Doesn't create merge conflicts from long-lived branches
- Works with automated release tooling (Release Please)
- Scales from 2 apps to 20+ apps

The key scenario we must handle:
- Feature A and Feature B both merge to the integration branch
- Feature A passes QA, Feature B is still in QA
- We need to release Feature A to production without Feature B

## Decision

We will use **Trunk-Based Development with per-app Release Branches**.

### Branch Model

| Branch Pattern | Purpose | Lifetime |
|---|---|---|
| `main` | Integration branch, always latest code | Permanent |
| `feat/<scope>/<name>` | Feature development | 1-5 days |
| `fix/<scope>/<name>` | Bug fixes | 1-3 days |
| `release/<app>/<version>` | Release stabilization and QA | Days to 1 week |
| `hotfix/<app>/<version>` | Emergency production fixes | Hours |

### Environment Mapping

| Environment | Source | Trigger |
|---|---|---|
| dev | `main` | Auto-deploy on every merge |
| test | `main` (on-demand) | Manual trigger, QA picks a commit |
| staging | `release/<app>/<version>` branch | Auto-deploy when release branch created/updated |
| prod | Release tag (`<app>/v*`) | Auto-deploy on tag push |

### Release Flow

```
1. Features merge to main via PR (short-lived branches)
2. Dev environment always has latest from main
3. When ready to release an app:
   a. Cut release/<app>/vX.Y from main at a known-good commit
   b. Release branch auto-deploys to staging
   c. QA tests on staging
   d. Bug fixes go to release branch (cherry-pick back to main)
   e. When QA approves: merge release PR -> tag created -> deploy to prod
4. Release branch is deleted after release
```

### Hotfix Flow

```
1. Branch from production tag: hotfix/<app>/vX.Y.Z
2. Fix the issue
3. Tag <app>/vX.Y.Z -> deploy to prod
4. Cherry-pick fix back to main
```

### Tag Convention

Tags follow the pattern `<app>/v<semver>`:
- `sample-api/v1.2.0`
- `web/v3.0.0`
- `worker/v1.0.1`

### Automated Release Management

We use Release Please (Google) to:
- Track Conventional Commits per app
- Auto-generate changelogs per app
- Bump versions in project files (`.csproj`)
- Create GitHub Releases with notes
- Manage the release PR lifecycle

## Consequences

### Positive

- **Independent cadences**: API releases daily, UI weekly - completely decoupled
- **Safe production**: Only QA-approved code reaches prod via release branches
- **Simple branching**: Main + short-lived feature branches for daily work
- **No extra infrastructure**: No feature flag service or preview environments required
- **Automated versioning**: Release Please handles version bumps and changelogs
- **Clear audit trail**: Every release has a tag, GitHub Release, and changelog

### Negative

- **Release branch discipline**: Team must know when/where to cut release branches
- **Cherry-pick overhead**: Bug fixes on release branches need cherry-picking to main
- **Slightly more complex than pure trunk**: Release branches add a concept to learn

### Neutral

- Feature branches should stay short-lived (1-5 days) to minimize merge conflicts
- Large features spanning multiple PRs need coordination (merge in order)
- Release branch cuts should happen at predictable cadences per app

## Upgrade Path

As the team matures, we can evolve toward "QA on PR" with preview environments:
- Each PR gets an ephemeral environment for testing
- QA approves features before they merge to main
- Main becomes always-production-ready
- Release branches become unnecessary

This eliminates the release branch step entirely but requires infrastructure investment
(per-PR preview environments via Azure Container Apps, Kubernetes namespaces, or similar).

## Alternatives Considered

### GitFlow (develop + main + release)
- Rejected: `develop` branch becomes a shared bottleneck in monorepos, doesn't support
  per-app release cadences, designed for single-app repos

### Environment Branches (main -> staging -> production)
- Rejected: Branches diverge over time, cherry-picking is error-prone, doesn't scale
  with multiple apps

### Trunk-Based with Feature Flags
- Deferred: Requires feature flag infrastructure (LaunchDarkly/Unleash), adds code
  complexity, good option for future but over-engineered for current team size

### QA on PR with Preview Environments
- Deferred: Ideal end-state but requires infrastructure investment (ephemeral environments
  per PR), documented as upgrade path above
