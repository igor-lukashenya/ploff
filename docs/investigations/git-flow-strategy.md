# Git Flow Investigation - Monorepo with Multiple Environments

## The Problem

In a monorepo with multiple apps and independent release cadences, we need a branching strategy that:

1. Supports parallel feature development across apps
2. Allows independent QA cycles per feature/app
3. Supports environment promotion: dev -> test -> staging -> prod
4. Never deploys un-QA'd code to production
5. Doesn't create merge hell with long-lived branches
6. Works with Release Please for automated versioning

---

## Option 1: Trunk-Based + Feature Flags

**Used by**: Google, Meta, Netflix, Spotify

```
main ─────●────●────●────●────●────●─────> (always deployable)
           \  /      \  /      \  /
            feat-A    feat-B    feat-C
            (1-2 days max)
```

**How it works**:
- `main` is the only long-lived branch
- Feature branches live 1-3 days max
- ALL code merges to main, even incomplete features
- Incomplete/risky features are behind **feature flags**
- Every environment runs the same code (main)
- Flags control what's active per environment

**Environment promotion**:
```
dev     = main + all flags ON (see everything)
test    = main + flags ON for features under QA
staging = main + flags ON for approved features only
prod    = main + only fully-approved flags ON
```

**The "users ready, payments not" scenario**:
- Both merge to main behind flags
- `FEATURE_USERS=true` in all environments
- `FEATURE_PAYMENTS=true` in dev/test only
- QA approves users -> enable flag in prod
- Payments stays hidden in prod until QA passes

**Pros**:
- Simplest branching model possible
- No merge conflicts from long-lived branches
- Can release any combination of features independently
- Supports true continuous deployment
- Works perfectly with Release Please (versions track main)

**Cons**:
- Requires feature flag infrastructure (LaunchDarkly, Unleash, Azure App Configuration, or custom)
- Code complexity: `if (flag.IsEnabled("payments")) { ... }`
- Technical debt: old flags must be cleaned up
- Not all changes can be flagged (database migrations, API contract changes)

**Best for**: Teams doing continuous deployment, SaaS products, mature engineering orgs

---

## Option 2: Trunk-Based + Release Branches (per app) - RECOMMENDED

**Used by**: Kubernetes, many OSS monorepos, GitLab

```
main ─────●────●────●────●────●────●────●─────>
           \  /      \  /     |
            feat-A    feat-B   \
                                release/sample-api/v1.2
                                  ●──fix──●──> tag v1.2.0 -> deploy
```

**How it works**:
- `main` = integration branch, always has latest code
- Feature branches merge to main via PR (short-lived, 1-5 days)
- When ready to release an app, **cut a release branch** from main
- QA happens on the release branch (only that app's code matters)
- Only bug fixes cherry-picked to release branch
- When QA passes: tag + deploy to prod
- Release branch merges back to main (or is abandoned after tag)

**Environment mapping**:
```
dev     = auto-deploy from main (every merge)
test    = deploy from main on-demand (or from release branch)
staging = deploy from release branch (pre-prod verification)
prod    = deploy from release tag
```

**The "users ready, payments not" scenario**:
- feat-users merges to main (Day 1)
- feat-payments merges to main (Day 2)
- Cut `release/sample-api/v1.2` from main BEFORE payments merged
  OR cut it from the commit after users was merged
- QA tests the release branch (has users, no payments)
- Release branch deploys to staging, then prod
- Payments stays on main, will go in next release

**Key rule**: Cut the release branch at the right commit. It captures a snapshot of "what we want to release."

**Pros**:
- No feature flags needed
- Clear separation: main = development, release branch = stabilization
- Each app has independent release branches
- Works perfectly with Release Please (release branch = release PR)
- Battle-tested pattern

**Cons**:
- Need discipline about when to cut release branches
- Cherry-picking fixes to release branch can conflict
- Slightly more git complexity than pure trunk-based

**Best for**: Teams with distinct QA phase, multiple environments, mix of cadences

---

## Option 3: Environment Branches

**Used by**: Some legacy teams, Heroku-flow

```
main ─────●────●────●────> (development)
                \
staging ─────────●────●──> (cherry-pick or merge from main)
                       \
production ─────────────●─> (merge from staging)
```

**How it works**:
- `main` = dev environment
- `staging` = staging environment
- `production` = prod environment
- Code flows: main -> staging -> production (merge or cherry-pick)

**Pros**: Simple mental model ("branch = environment")
**Cons**:
- Merge conflicts between branches
- Branches diverge over time
- Cherry-picking is error-prone
- Doesn't scale with multiple apps
- Can't have independent release cycles per app

**Verdict**: AVOID. This model breaks down fast in monorepos.

---

## Option 4: GitFlow (Classic)

```
main ────────────────────────●──────────●───────>
                            /          /
develop ──●──●──●──●──●──●/──●──●──●─/─●──●──>
            \  /    \  /  /        \ /  /
             feat    feat/        release/1.2
                        /
                  release/1.1
```

**How it works**:
- `main` = production (tagged releases)
- `develop` = integration branch
- Feature branches -> develop
- Release branches from develop -> main
- Hotfix branches from main -> main + develop

**Monorepo problem**: develop becomes a shared bottleneck across ALL apps. You can't release sample-api independently from web if both share `develop`.

**Pros**: Well-known, tooling support
**Cons**:
- Designed for single-app repos
- `develop` is a bottleneck in monorepos
- Long-lived branches = merge pain
- Doesn't support per-app release cadences
- Overkill complexity for trunk-based deployment

**Verdict**: AVOID for monorepos. Works for single-app repos with infrequent releases.

---

## Option 5: Hybrid - Trunk-Based + Release Please + Short QA on PR

**A practical middle ground**:

```
main ─────●────●────●────●────●────●─────> (always deployable)
           \  /      \     /
            feat-A    feat-B (stays open until QA passes)
            (2 days)  (5 days, QA on preview env)
```

**How it works**:
- Feature branches are NOT merged until QA passes
- Each PR gets a **preview/ephemeral environment** for testing
- QA tests the feature IN the PR (not after merge)
- Once approved, merge to main
- Main is always production-ready
- Release Please creates releases from main

**Environment mapping**:
```
dev       = auto-deploy from main
preview   = per-PR ephemeral environment (for QA)
staging   = deploy from main (pre-prod smoke test)
prod      = triggered by Release Please tag
```

**The "users ready, payments not" scenario**:
- feat-users PR -> gets preview env -> QA tests there -> approves -> merge
- feat-payments PR -> gets preview env -> QA still testing -> stays open
- Main only has approved code -> safe to release anytime

**Pros**:
- Main is ALWAYS deployable (no half-baked features)
- No release branches needed
- No feature flags needed
- QA happens before merge (shift left)
- Clean git history
- Perfect fit for Release Please

**Cons**:
- Requires ephemeral/preview environments (cost + infra)
- Feature branches might live longer (merge conflicts risk)
- Hard for large features that span multiple PRs
- QA can become a bottleneck if PRs queue up

**Best for**: Teams with good CI/CD, able to spin up preview environments

---

## Comparison Matrix

| Criteria | Trunk + Flags | Trunk + Release Branches | Env Branches | GitFlow | Trunk + QA on PR |
|----------|:---:|:---:|:---:|:---:|:---:|
| Independent app releases | +++ | +++ | + | + | +++ |
| No un-QA'd code in prod | ++ | +++ | ++ | +++ | +++ |
| Simple branching | +++ | ++ | ++ | - | ++ |
| No extra infra needed | - | +++ | +++ | +++ | - |
| Works at scale (20+ apps) | +++ | ++ | - | - | ++ |
| Release Please compatible | +++ | ++ | - | - | +++ |
| Supports hotfixes | +++ | +++ | ++ | +++ | ++ |
| Low merge conflict risk | +++ | ++ | - | - | + |

---

## Recommendation for Ploff

### Primary: Option 2 - Trunk-Based + Release Branches (per app)

**Why**:
- No extra infrastructure required (no feature flag service)
- Clear QA phase supported
- Independent per-app release cadence
- Works with Release Please
- Proven at scale
- Matches existing CI setup (dorny/paths-filter + deploy workflows)

### Upgrade path: Move toward Option 5 (QA on PR) over time

As infrastructure matures:
- Add preview environments per PR (Azure Container Apps / Vercel / Kubernetes namespaces)
- QA tests features before merge
- Eliminates need for release branches entirely
- Simplest possible flow long-term

### Release Please integration with release branches

Release Please supports a `target-branch` config. Each app can have its own release track:

```yaml
# .github/workflows/release-please.yml
- uses: googleapis/release-please-action@v4
  with:
    config-file: release-please-config.json
    manifest-file: .release-please-manifest.json
    target-branch: main
```

When you cut a release branch, you can either:
1. Let Release Please track main only (tag when release branch merges back)
2. Run Release Please on the release branch directly

---

## Proposed Flow for Ploff

```
Feature Development:
  main <-- feat/add-users (short-lived, 1-5 days)
  main <-- feat/add-payments

Environment Deployment:
  dev     <- auto-deploy from main on every merge
  test    <- deploy from main on-demand (QA picks a commit)

Release Process (per app):
  1. Cut: release/sample-api/v1.2 from main (at known-good commit)
  2. QA tests release branch in staging environment
  3. Fix bugs on release branch (cherry-pick back to main)
  4. Approve -> tag sample-api/v1.2.0 -> deploy to prod
  5. Delete release branch

Hotfix:
  1. Branch from production tag: hotfix/sample-api/v1.2.1
  2. Fix + test
  3. Tag sample-api/v1.2.1 -> deploy to prod
  4. Cherry-pick fix to main
```

### Branch naming convention:
```
main                              # integration (always latest)
feat/<scope>/<description>        # feature work
fix/<scope>/<description>         # bug fixes
release/<app>/<version>           # release stabilization
hotfix/<app>/<version>            # emergency production fixes
```

### Tag naming convention:
```
sample-api/v1.2.0                 # production release
web/v3.0.0                        # production release
```

---

## Implementation Steps

1. Document this as ADR-002 (Git Branching Strategy)
2. Configure branch protection rules on GitHub
3. Set up auto-deploy to dev environment from main
4. Add release branch workflow templates
5. Configure Release Please with per-app components
6. Add deploy-on-tag workflows per app
7. Update CONTRIBUTING.md with the new flow

---
