# Git Hooks

Git hooks catch problems before they reach a pull request. They are managed by
[moon](https://moonrepo.dev/docs/guides/vcs-hooks) and configured in `.moon/workspace.yml`
(`vcs.hooks`), so every developer gets the same hooks without extra tools.

## Setup

Hooks are installed by `make setup` (it runs `moon sync hooks`, which points git's
`core.hooksPath` at the generated `.moon/hooks/`). To enable secret scanning in the
pre-commit hook, also install the scanners once:

```bash
make setup
make install-scanners   # gitleaks + trivy into ~/.local/bin (pinned, checksum-verified)
```

## Hooks

| Hook | Runs | Why |
| --- | --- | --- |
| `pre-commit` | `scan-security.sh secrets --staged` (gitleaks) | Blocks commits that contain secrets. Skipped with a hint if gitleaks isn't installed |
| `commit-msg` | `check-conventional.sh --file <message>` | Release Please needs [Conventional Commits](release-process.md#versioning) |

Hooks are deliberately fast. Linting, type-checking and tests run in CI (`make ci` runs the
same checks locally).

## Skipping

Skip hooks for a single commit with `git commit --no-verify`. CI runs the same checks
(secret scan, Conventional Commits) on every pull request, so skipped problems are still
caught before merge.

## Changing Hooks

1. Edit `vcs.hooks` in `.moon/workspace.yml`. Commands run from the repository root and can
   use `$ARG1`, `$ARG2`, … for the hook's arguments.
2. Run `moon sync hooks` to regenerate them.

Keep hooks quick and make them work without optional tools. A slow or failing hook trains
people to use `--no-verify`.

## Removing Hooks

```bash
moon sync hooks --clean
```
