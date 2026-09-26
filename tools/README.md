# Tools

Developer scripts, generators, and utilities for working with this monorepo.

## Structure

```
tools/
├── scripts/        # Bash scripts, invoked through the root Makefile
└── generators/     # moon templates for scaffolding apps and packages
```

## Scripts

| Script | Make target | Description |
| --- | --- | --- |
| `init-project.sh` | - | Personalize the template for a new solution (name, license) |
| `new-project.sh` | `make new-app` / `make new-package` | Generate a project from a template and register it |
| `new-adr.sh` | `make new-adr` | Create a new ADR from the template |
| `sync-templates.sh` | `make sync-templates` | Copy dependency versions from the sample apps into generator templates (`--check` reports drift; CI warns) |

All scripts are Bash (on Windows, use WSL or the devcontainer).

## Generators

Each folder in `tools/generators/` is a [moon template](https://moonrepo.dev/docs/guides/codegen):
a `template.yml` (title, destination, variables) plus files rendered with
[Tera](https://keats.github.io/tera/):

- `*.tera` files are rendered; `*.raw` files are copied verbatim (use `.raw` for anything
  containing `{{`, e.g. JSX)
- `[name | pascal_case]` in file names is replaced with the variable value
- Frontmatter `to: '../../infra/docker/...'` writes a file outside the project folder
  (**new files only** - moon overwrites existing files, so shared config is edited by
  `new-project.sh` instead)

`make stacks` lists the available generators.

### Adding a generator

1. Create `tools/generators/<stack>/template.yml` with `destination: 'apps/[name]'` (app) or
   `'packages/[name]'` (package) and a required `name` variable (optionally `port`)
2. Add the project files, including a `moon.yml` with `language`, `layer`, `stack`, `tags`
3. If the language has no `.moon/tasks/<language>.yml` yet, add one with the standard tasks
4. If it needs registration beyond what `new-project.sh` does (Release Please, root `.slnx`,
   Dependabot, npm lockfile), extend the script
5. Test it: `make new-app STACK=<stack> NAME=tmp-test && make run APP=tmp-test TASK=test`

## Adding a Script

1. Create the script in `tools/scripts/` (Bash, `set -euo pipefail`)
2. Make it executable: `chmod +x tools/scripts/my-script.sh`
3. Add a Makefile target in the root `Makefile`:
   ```makefile
   .PHONY: my-command
   my-command: ## Description of what this does
       bash tools/scripts/my-script.sh
   ```
