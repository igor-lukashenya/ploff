# Security Guide

How security checks work in this repository and what to do when one fails. For reporting
vulnerabilities, see `SECURITY.md` in the repository root.
The rationale is recorded in [ADR-004](../adr/004-security-scanning.md).

## Overview

| Check | Tool | Runs | Configuration |
| --- | --- | --- | --- |
| Secrets in commits | [gitleaks](https://github.com/gitleaks/gitleaks) | pre-commit hook; CI (`secret scan`) | default rules; `.gitleaksignore` for accepted findings |
| Vulnerable dependencies, IaC misconfigurations | [Trivy](https://trivy.dev) | CI (`vulnerability scan`); weekly | `trivy.yaml`, `.trivyignore` |
| Vulnerable NuGet packages | NuGet audit | every .NET restore/build | `Directory.Build.props` |
| Code vulnerabilities | [CodeQL](https://codeql.github.com) | PRs, `main`, weekly (`security.yml`) | `security-extended` queries |
| Outdated dependencies | Dependabot | weekly PRs | `.github/dependabot.yml` |

The secret and vulnerability scans are part of **CI Gate**, so a finding blocks the merge.

## Running Scans Locally

```bash
make install-scanners   # once: pinned gitleaks + trivy into ~/.local/bin
make scan               # full git history for secrets + dependencies/IaC with Trivy
```

The pre-commit hook scans staged changes automatically (see [Git Hooks](git-hooks.md)).

## When a Check Fails

### A secret was detected

1. **Treat the secret as compromised**, even if the PR is not merged yet: it is in the pushed
   git history. Revoke or rotate it first.
2. Remove it from the branch history (`git rebase -i`, or recreate the branch) and move the
   value to an environment variable or secret store.
3. False positive (e.g. a test fixture)? Add its fingerprint (printed by gitleaks) to
   `.gitleaksignore` with a comment.

### Trivy reports a vulnerability or misconfiguration

- **Vulnerable dependency**: update it (often a Dependabot PR already exists). Trivy only
  fails on HIGH/CRITICAL findings that have a fixed version.
- **Misconfiguration** (Dockerfile, Kubernetes, Terraform): fix the configuration. For
  example, containers must run as a non-root `USER`.
- **Accepted risk**: add the ID to `.trivyignore` with a comment explaining why and when
  to revisit it.

### NuGet audit fails the .NET build (NU1903/NU1904)

A direct or transitive package has a HIGH/CRITICAL vulnerability. Update the package, or
add a direct reference to a fixed version of the transitive one. Lower severities
(NU1901/NU1902) stay warnings.

### CodeQL alerts

CodeQL doesn't fail CI; alerts appear under **Security → Code scanning** and as PR
annotations. Fix them or dismiss them with a reason in GitHub.

## CodeQL in Private Repositories

Code scanning is free for public repositories. Private repositories need **GitHub Code
Security**, so CodeQL only runs there when the repository variable `ENABLE_CODEQL` is
`true` (Settings → Secrets and variables → Actions → Variables).

## Supply-Chain Rules for CI

The March 2026 compromise of `trivy-action` (malicious code pushed to existing version tags)
shows that CI tooling itself is an attack target. This repository therefore:

- **Pins every GitHub Action to a full commit SHA** (`uses: owner/action@<sha> # vX.Y.Z`).
  Dependabot updates the SHA and the version comment together; review those PRs like code.
- **Installs scanners as pinned binaries**, verified against SHA-256 checksums stored in the
  repository (`tools/scripts/install-scanners.sh`), instead of third-party wrapper actions.
- **Runs scans without secrets** and with read-only permissions.

To update a scanner: bump its version in `install-scanners.sh`, copy the checksums for all
four platforms from the release's checksum file, read the release notes, and open a PR.
