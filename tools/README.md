# Tools

Developer scripts, generators, and utilities for working with this monorepo.

## Structure

```
tools/
├── scripts/        # Utility scripts (build, deploy, cleanup, etc.)
└── generators/     # Code generators / scaffolding templates
```

## Scripts

Place utility scripts in `tools/scripts/`. These should be referenced from the
root `Makefile` for discoverability.

Examples:
- `setup.sh` — Set up the development environment
- `new-app.sh` — Scaffold a new application in `apps/`
- `new-package.sh` — Scaffold a new shared package in `packages/`
- `new-adr.sh` — Create a new ADR from the template

## Generators

Place code generation templates in `tools/generators/`. These can be used with
scaffolding tools like Cookiecutter, Yeoman, Plop, or custom scripts.

## Adding a Script

1. Create the script in `tools/scripts/`
2. Make it executable: `chmod +x tools/scripts/my-script.sh`
3. Add a Makefile target in the root `Makefile`:
   ```makefile
   .PHONY: my-command
   my-command: ## Description of what this does
       ./tools/scripts/my-script.sh
   ```
