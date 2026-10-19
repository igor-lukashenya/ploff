# Expo mobile generator — design

## Goal

Support React Native mobile development with Expo via a new moon generator:
`make new-app STACK=expo-mobile NAME=<name>`.

## Scope

In: generator, script adjustments, docs/ADR, generator test coverage.
Out: EAS Build/Submit, store deployment, a sample app, Docker/compose output.

## Generator `tools/generators/expo-mobile`

- Expo SDK (current stable), TypeScript, Expo Router (file-based routing), TanStack Query.
- Layout mirrors `react-web` conventions: `app/` (routes), `components/`, `hooks/`,
  `services/`, `types/`.
- Tests: `jest-expo` + React Native Testing Library. Lint: `eslint-config-expo`.
- Variables: `name` (required, kebab-case), `bundle_id` (optional, default `com.example.<name>`).
- package.json scripts required by `.moon/tasks/node.yml`: `lint`, `lint:fix`,
  `type-check`, `test`, `build`, `dev`.

## moon

- `moon.yml`: `language: typescript`, `layer: application`, `stack: frontend`,
  tags `['mobile', 'expo']`. No `deployable` tag.
- Inherits lint, typecheck, test, format from `.moon/tasks/node.yml`.
- Overrides: `build` runs the `build` script from `package.json` (`expo export --platform android --output-dir dist` — bundling sanity check);
  `publish` stays the inherited task (depends on `build`); the app is not `deployable`, so deploys never run it; `dev` runs `expo start`.
- Shared `sources` file group must cover `app/**/*` and `app.json` so mobile
  changes invalidate caches and trigger affected detection.
- `bundle_id` defaults to a value derived from `name` in `app.json`:
  `com.example.<name without hyphens>` if the default is not overridden.

## Scripts

- `new-project.sh` / `sync-templates.sh`: skip Dockerfile and compose fragment for
  `expo-mobile`; still register release-please, dependabot (npm) and other files.
- `test-generators.sh`: generate an `expo-mobile` app and run its tasks.

## CI

No workflow changes: affected detection runs lint/typecheck/test. The app is not
`deployable`, so deploy workflows ignore it.

## Docs

- ADR-005: Expo for mobile; no store deployment yet.
- Update `apps/README.md`, `AGENTS.md`, `README.md`, `docs/guides/new-solution.md`
  stack lists, and the generator's own `README.md.tera`.

## Risks

- Expo SDK / React Native dependency versions drift quickly; the template's lockfile
  must be regenerated and Dependabot covers updates.
- `expo export` needs no native toolchain, so it is safe in CI.
