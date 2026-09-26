# 004. Security Scanning and CI Supply-Chain Hardening

**Date**: 2026-09-27

**Status**: Accepted

**Deciders**: Igor Lukashenya

## Context

Solutions created from this template hold client code and deploy to client environments.
Before this decision the template had no automated checks for leaked secrets, vulnerable
dependencies, insecure infrastructure configuration or code vulnerabilities; security
depended on reviewers noticing problems.

The tooling itself is also an attack surface. In March 2026 the `aquasecurity/trivy-action`
and `setup-trivy` GitHub Actions were compromised: 76 of 77 version tags of `trivy-action`
were force-pushed to credential-stealing code, and a malicious Trivy binary was published.
Workflows that referenced the action by tag ran the malware with their secrets.

Constraints: must work for public and private repositories, must not require paid
licenses by default, and must add no heavy local tooling (Bash + pinned binaries only).

## Decision

1. **Secrets**: gitleaks scans staged changes in a pre-commit hook and every pushed commit
   range in CI.
2. **Dependencies and IaC**: Trivy scans lockfiles, Dockerfiles, Kubernetes and Terraform in
   CI and weekly (new CVEs appear for unchanged dependencies), failing on HIGH/CRITICAL
   findings that have a fix (`trivy.yaml`).
3. **.NET dependencies**: NuGet audit in the root `Directory.Build.props` fails every build
   with HIGH/CRITICAL vulnerable packages, including transitive ones. Trivy can't see .NET
   dependencies without NuGet lockfiles.
4. **Code**: CodeQL (`security-extended`) analyzes C# and TypeScript without a build, on
   PRs, `main` and weekly. It runs automatically on public repositories and on private ones
   only when `ENABLE_CODEQL` is set, because private code scanning needs GitHub Code Security.
5. **Containers run as non-root** (`USER app` for .NET images, `nginx-unprivileged` for web
   images), enforced by the Trivy misconfiguration scan.
6. **Supply chain**:
   - Every GitHub Action is pinned to a full commit SHA with a version comment; Dependabot
     keeps the pins current.
   - Scanners are installed from their GitHub releases, verified against SHA-256 checksums
     stored in this repository, not through third-party wrapper actions.
   - Scan jobs have read-only permissions and no secrets.
7. Secret and vulnerability scans are part of **CI Gate**; a finding blocks the merge.
8. Git hooks are managed by moon (`vcs.hooks`) and kept fast: secret scan and commit
   message check only.

## Consequences

### Positive

- Leaked secrets, known-vulnerable dependencies and insecure container/IaC configuration are
  caught before merge, with no paid tools required
- A compromised action tag or scanner release cannot run silently in CI: a changed SHA
  shows up as a Dependabot PR, and a tampered binary fails checksum verification
- The same scanners and settings run locally (`make scan`) and in CI

### Negative

- Scanner versions and checksums are updated by hand (Dependabot can't update them)
- SHA-pinned actions are less readable, and Dependabot PRs for them must be reviewed
- Weekly scans can fail `main` without any code change when new CVEs are published; this is
  intended, but needs someone to act on it
- Private repositories get no CodeQL unless they have GitHub Code Security

### Neutral

- The pre-commit secret scan is skipped (with a hint) when gitleaks isn't installed; CI is
  the enforcing layer
- Container image OS packages are not scanned yet (only once images are built and
  published, see the release/promotion ADR)

## Alternatives Considered

### Option A: Official scanner actions (`gitleaks/gitleaks-action`, `aquasecurity/trivy-action`)

- Pros: Less workflow code.
- Cons: `gitleaks-action` requires a paid license for organizations; `trivy-action` was the
  compromised component in March 2026. Pinned binaries give the same scanning with a smaller
  trust surface.

### Option B: GitHub-native only (secret scanning + push protection, Dependabot alerts)

- Pros: No configuration.
- Cons: Push protection and code scanning need GitHub Secret Protection / Code Security for
  private repositories; no IaC misconfiguration checks. Worth enabling alongside when available.

### Option C: pre-commit framework or Lefthook for hooks

- Pros: Large hook ecosystems.
- Cons: Another tool to install; moon already manages hooks for the repository.
