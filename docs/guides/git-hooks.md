# Git Hooks

This guide covers setting up Git hooks for automated pre-commit validation.

## Purpose

Git hooks run automated checks before commits and pushes, catching issues early:
- Linting and formatting
- Preventing secrets from being committed
- Enforcing commit message conventions
- Running fast tests

## Setup

Choose a Git hooks tool appropriate for your tech stack:

### Option A: Pre-commit (Python-based, language-agnostic)

[pre-commit](https://pre-commit.com/) works with any language.

```bash
# Install
pip install pre-commit

# Install hooks (reads .pre-commit-config.yaml)
pre-commit install
```

Example `.pre-commit-config.yaml`:

```yaml
repos:
  # Prevent secrets from being committed
  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.18.0
    hooks:
      - id: gitleaks

  # General file checks
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.6.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-json
      - id: check-merge-conflict
      - id: detect-private-key
      - id: no-commit-to-branch
        args: ['--branch', 'main']

  # Commit message format (Conventional Commits)
  - repo: https://github.com/compilerla/conventional-pre-commit
    rev: v3.2.0
    hooks:
      - id: conventional-pre-commit
        stages: [commit-msg]
```

### Option B: Husky (Node.js projects)

[Husky](https://typicode.github.io/husky/) is common in JavaScript/TypeScript projects.

```bash
npm install --save-dev husky
npx husky init
```

Example `.husky/pre-commit`:

```bash
#!/bin/sh
npm run lint
npm run test:unit
```

### Option C: Lefthook (Go-based, fast, language-agnostic)

[Lefthook](https://github.com/evilmartians/lefthook) is fast and works with any stack.

```bash
# Install
brew install lefthook   # or: go install github.com/evilmartians/lefthook@latest

# Install hooks
lefthook install
```

Example `lefthook.yml`:

```yaml
pre-commit:
  parallel: true
  commands:
    lint:
      run: make lint
    secrets:
      run: gitleaks protect --staged

commit-msg:
  commands:
    conventional:
      run: npx commitlint --edit {1}

pre-push:
  commands:
    test:
      run: make test-unit
```

## Recommended Checks

| Hook | Checks | Speed |
| --- | --- | --- |
| `pre-commit` | Linting, formatting, secret detection, file checks | Fast (< 10s) |
| `commit-msg` | Conventional Commit format | Instant |
| `pre-push` | Unit tests, type checking | Moderate (< 60s) |

## Secret Detection

**Critical**: Always include secret detection in your pre-commit hooks to prevent accidental credential commits.

Tools:
- [Gitleaks](https://github.com/gitleaks/gitleaks) — Fast, regex-based
- [detect-secrets](https://github.com/Yelp/detect-secrets) — Yelp's tool with baseline support

## CI Enforcement

Even with hooks, always run the same checks in CI. Hooks can be skipped (`--no-verify`), but CI cannot.
