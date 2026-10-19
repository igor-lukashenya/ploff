# 005. Expo for React Native Mobile Development

**Date**: 2026-10-18

**Status**: Accepted

**Deciders**: Igor Lukashenya

## Context

The monorepo needs to support React Native mobile development. Options range from managed
frameworks (Expo) to bare native toolchains (React Native CLI) to completely separate
native stacks (Flutter, Swift/Kotlin). The team requires a low-friction onboarding path for
web developers who also build mobile apps.

## Decision

Use **Expo** (managed workflow) for mobile development:

- **Stack**: `expo-mobile` generator in `tools/generators/expo-mobile`, scaffolds apps with
  `make new-app STACK=expo-mobile NAME=<name>`
- **Framework**: Expo SDK 58 with TypeScript, Expo Router (file-based routing), TanStack
  Query (server state), and Jest testing
- **Structure**: Mirrors `react-web` conventions: `app/` (Expo Router routes), `components/`,
  `hooks/`, `services/`, `types/`, `__tests__/` (tests kept out of routing layer)
- **CI**: Runs `expo export --platform android` as a bundling sanity check (no native
  toolchain needed); other tasks inherit from `.moon/tasks/node.yml` (lint, typecheck, test)
- **Deployment**: Apps are not `deployable` (no store builds yet). EAS Build/Submit will be
  added in a future ADR

## Consequences

### Positive

- **Low friction for web developers**: Expo abstracts the native iOS and Android toolchains;
  no Xcode/Android Studio setup needed for CI
- **Single language**: TypeScript across web and mobile; shared domain models and utilities
- **Standard stack**: Expo Router and TanStack Query are familiar to React developers
- **No CI overhead**: `expo export` runs on GitHub Actions without native dependencies
- **Familiar monorepo contract**: Apps follow the same moon task pattern, release versioning,
  and dependsOn conventions as other stacks

### Negative

- **No direct store deployment yet**: EAS Build/Submit for app stores is not integrated;
  developers must configure and upload manually or use EAS CLI locally (to be addressed in
  a future ADR)
- **Test suite gotcha**: TanStack Query tests must set `gcTime: 0` when creating a QueryClient,
  otherwise jest hangs for ~5 minutes after the test suite completes. The generated test file
  `__tests__/home-screen.test.tsx` sets this on its QueryClient with an explanatory comment;
  new tests must do the same (see template: `tools/generators/expo-mobile/__tests__/home-screen.test.tsx.tera`)
- **SDK drift & lockfile management**: The template's `package-lock.json` is refreshed manually
  (regenerate with `npx expo install` in a scratch app, then replace the name with the Tera
  name expression as in `tools/generators/react-web/package-lock.json.tera`) because Dependabot
  only watches `apps/*`, not `tools/generators/`, and `sync-templates.sh` only covers `react-web`
  until a reference Expo app exists. Generated apps themselves are covered by the Dependabot
  entry registered by `new-project.sh`
- **Limited customization**: Expo's managed workflow does not support some native modules; for
  apps needing native code (camera with custom processing, etc.), a bare workflow can be
  considered later
- **Release Please limitations**: Release Please bumps `package.json` and `package-lock.json`
  only; `expo.version` in `app.json` is not bumped automatically and must be kept in sync
  manually until an EAS/release workflow is added

### Neutral

- EAS services (updates, crash analytics, etc.) can be adopted as needed per app
- `bundle_id` defaults to `com.example.<name without hyphens>` but can be overridden per app

## Alternatives Considered

### Option A: React Native CLI (bare workflow)

- Pros: Full customization, access to native APIs, mature tooling (Android Studio, Xcode)
- Cons: Requires native toolchain on CI machines (complex to set up and maintain), higher
  friction for web developers, no dev server (slow iteration), larger learning curve

### Option B: Flutter or native (Swift/Kotlin)

- Pros: Mature native performance, ecosystem integration
- Cons: Entirely separate tech stack, separate dev experience, no code sharing with web
  frontend, higher training cost, multiple CI/CD pipelines
