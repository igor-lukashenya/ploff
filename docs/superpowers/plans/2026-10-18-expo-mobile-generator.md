# Expo Mobile Generator Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an `expo-mobile` moon generator so `make new-app STACK=expo-mobile NAME=<name>` scaffolds a working Expo (React Native) app.

**Architecture:** A new template directory `tools/generators/expo-mobile` modelled on `tools/generators/react-web`. It reuses the inherited `.moon/tasks/node.yml` tasks (lint/typecheck/test/build/format/dev) through `package.json` scripts, and overrides only the `sources` file group in its `moon.yml`. `new-project.sh` and `test-generators.sh` already handle templates without Dockerfile/compose files and auto-discover stacks, so **no script changes are needed** (Dockerfile/compose files only exist if the template ships them; `test-generators.sh` skips the docker build when no Dockerfile exists).

**Tech Stack:** Expo SDK 58 (`expo@~58.0.14`), Expo Router, TypeScript, TanStack Query v5, `jest-expo` + `@testing-library/react-native`, `eslint-config-expo`, Node 22.

**Spec:** `docs/superpowers/specs/2026-10-18-expo-mobile-generator-design.md`

## Global Constraints

- No Docker/compose output; app is NOT tagged `deployable`; tags are exactly `['mobile', 'expo']`.
- `moon.yml`: `language: 'typescript'`, `layer: 'application'`, `stack: 'frontend'`.
- `package.json` must define scripts `lint`, `lint:fix`, `type-check`, `test`, `build`, `dev` (required by `.moon/tasks/node.yml`).
- Layout: `app/` (routes), `components/`, `hooks/`, `services/`, `types/` at the app root.
- Tests: `jest-expo` + React Native Testing Library. Lint: `eslint-config-expo`. Server state: TanStack Query.
- `build` = `expo export` (bundling sanity check, output `dist/`, no native toolchain needed). `publish` stays the inherited task (depends on `build`; effectively a no-op because the app is not deployable).
- Variables: `name` (required, kebab-case), `bundle_id` (default `com.example.<name>`).
- Template file conventions: `.tera` files are rendered (avoid literal double-brace/`{%`/`{#` sequences unless intended), `.raw` files are copied verbatim.
- Conventional Commits, scope `expo-mobile` for generator changes. Kebab-case file names.

---

### Task 1: Expo template files and generator verification

**Files:**
- Create: `tools/generators/expo-mobile/template.yml`
- Create: `tools/generators/expo-mobile/moon.yml.tera`
- Create: `tools/generators/expo-mobile/package.json.tera`
- Create: `tools/generators/expo-mobile/package-lock.json.tera` (generated, see Step 3)
- Create: `tools/generators/expo-mobile/app.json.tera`
- Create: `tools/generators/expo-mobile/tsconfig.json.raw`
- Create: `tools/generators/expo-mobile/eslint.config.js.raw`
- Create: `tools/generators/expo-mobile/jest.config.js.raw`
- Create: `tools/generators/expo-mobile/README.md.tera`
- Create: `tools/generators/expo-mobile/app/_layout.tsx.raw`
- Create: `tools/generators/expo-mobile/app/index.tsx.tera`
- Create: `tools/generators/expo-mobile/components/status-text.tsx.raw`
- Create: `tools/generators/expo-mobile/hooks/use-health.ts.raw`
- Create: `tools/generators/expo-mobile/services/api.ts.raw`
- Create: `tools/generators/expo-mobile/types/health.ts.raw`
- Create: `tools/generators/expo-mobile/__tests__/home-screen.test.tsx.tera`
- Modify (if needed): `.gitignore` (add `.expo/` and `dist/` only if not already covered)

**Interfaces:**
- Consumes: moon template variables `name` (string) and `bundle_id` (string).
- Produces: a generated app at `apps/<name>` whose moon tasks `build`, `lint`, `typecheck`, `test` pass. Stack id used by scripts/docs: `expo-mobile`.

- [ ] **Step 1: Write `template.yml`**

```yaml
# moon template - https://moonrepo.dev/docs/guides/codegen
# Use via: make new-app STACK=expo-mobile NAME=<name>
title: 'Expo mobile app'
description: 'React Native (Expo SDK) + TypeScript app with Expo Router, TanStack Query and Jest'
destination: 'apps/[name]'

variables:
  name:
    type: 'string'
    required: true
    prompt: 'App name (kebab-case)?'
  bundle_id:
    type: 'string'
    default: 'com.example.app'
    prompt: 'iOS bundle identifier / Android package?'
```

`new-project.sh` runs `moon generate --defaults -- --name <n>`, and moon does not interpolate one variable into another's default. So `app.json.tera` (Step 5) uses `bundle_id` only when it was overridden; otherwise it derives the id from `name`. Implement in `app.json.tera` with Tera: `{% if bundle_id == "com.example.app" %}com.example.{{ name | replace(from="-", to="") }}{% else %}{{ bundle_id }}{% endif %}`. Expo requires identifiers without hyphens, hence the `replace`.

- [ ] **Step 2: Write `moon.yml.tera`**

```yaml
$schema: 'https://moonrepo.dev/schemas/moon.json'

language: 'typescript'
layer: 'application'
stack: 'frontend'
tags: ['mobile', 'expo']

project:
  title: '{{ name }}'
  description: 'Expo (React Native) mobile application'

# lint/typecheck/test/build/publish/format/dev are inherited from
# .moon/tasks/node.yml. Only the input group differs: Expo has no src/ or index.html.
fileGroups:
  sources:
    - 'app/**/*'
    - 'components/**/*'
    - 'hooks/**/*'
    - 'services/**/*'
    - 'types/**/*'
    - 'assets/**/*'
    - '__tests__/**/*'
    - 'app.json'
    - 'package.json'
    - 'package-lock.json'
    - 'tsconfig*.json'
    - '*.config.*'
    - '/.editorconfig'
```

- [ ] **Step 3: Resolve dependencies and generate the lockfile in a scratch dir**

Run (scratch dir outside the repo):

```bash
SCRATCH=$(mktemp -d) && cd "$SCRATCH" && cat > package.json <<'EOF'
{ "name": "scratch", "private": true, "version": "0.1.0", "main": "expo-router/entry" }
EOF
npm install expo@~58.0.14 --no-audit --no-fund
npx expo install expo-router expo-constants expo-linking expo-status-bar react react-native react-native-safe-area-context react-native-screens
npm install @tanstack/react-query@^5
npx expo install --dev typescript @types/react @types/jest jest jest-expo @testing-library/react-native eslint eslint-config-expo
```

If npm reports peer-dependency errors (e.g. `react-test-renderer` required by `@testing-library/react-native`), install the peer with `npx expo install --dev <pkg>` until `npm ls` is clean. Then run `npx expo-doctor` and fix reported version mismatches with `npx expo install --check`.

Expected: `package.json` has resolved versions; `package-lock.json` exists.

- [ ] **Step 4: Create `package.json.tera` and `package-lock.json.tera` from the scratch result**

`package.json.tera` = scratch `package.json` with these changes: name set to the Tera expression for `name`, keep `"private": true`, `"version": "0.1.0"`, `"main": "expo-router/entry"`, and exactly these scripts:

```json
"scripts": {
  "dev": "expo start",
  "build": "expo export --platform android --output-dir dist",
  "lint": "eslint .",
  "lint:fix": "eslint . --fix",
  "test": "jest",
  "test:watch": "jest --watch",
  "type-check": "tsc --noEmit"
}
```

`package-lock.json.tera` = scratch `package-lock.json` with both `"name": "scratch"` occurrences (top level and `packages[""]`) replaced by the Tera `name` expression (same form as in `tools/generators/react-web/package-lock.json.tera`). Confirm those are the only Tera delimiters: `grep -n '{%\|{#' package-lock.json.tera` returns nothing and the name expression appears on exactly 2 lines.

Delete the scratch directory afterwards.

- [ ] **Step 5: Write the config files**

`app.json.tera` (the `bundle_id` expression is defined in Step 1; call it `BUNDLE_ID` here):

```json
{
  "expo": {
    "name": "<name>",
    "slug": "<name>",
    "version": "0.1.0",
    "scheme": "<name>",
    "orientation": "portrait",
    "userInterfaceStyle": "automatic",
    "ios": { "bundleIdentifier": "<BUNDLE_ID>" },
    "android": { "package": "<BUNDLE_ID>" },
    "plugins": ["expo-router"],
    "experiments": { "typedRoutes": true }
  }
}
```

Substitute `<name>` with the Tera `name` expression and `<BUNDLE_ID>` with the Step 1 `if/else` expression. Keep `{ "` with a space so no double-brace appears.

`tsconfig.json.raw`:

```json
{
  "extends": "expo/tsconfig.base",
  "compilerOptions": {
    "strict": true,
    "paths": { "@/*": ["./*"] }
  },
  "include": ["**/*.ts", "**/*.tsx", ".expo/types/**/*.ts", "expo-env.d.ts"],
  "exclude": ["dist", "node_modules"]
}
```

`eslint.config.js.raw`:

```js
const { defineConfig } = require('eslint/config');
const expo = require('eslint-config-expo/flat');

module.exports = defineConfig([
  expo,
  { ignores: ['dist/*', '.expo/*'] },
]);
```

`jest.config.js.raw`:

```js
module.exports = {
  preset: 'jest-expo',
  moduleNameMapper: { '^@/(.*)$': '<rootDir>/$1' },
  testPathIgnorePatterns: ['/node_modules/', '/dist/'],
};
```

Add `.expo/` and `dist/` to the root `.gitignore` only if `git check-ignore apps/x/.expo apps/x/dist` reports them as not ignored.

- [ ] **Step 6: Write the failing test first**

`__tests__/home-screen.test.tsx.tera` (outside `app/`, otherwise Expo Router treats it as a route). The one Tera expression is the `name` in the heading assertion:

```tsx
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { render, screen } from '@testing-library/react-native';

import HomeScreen from '@/app/index';

function mockFetchOk() {
  jest.spyOn(global, 'fetch').mockResolvedValue({
    ok: true,
    json: async () => ({ status: 'Healthy' }),
  } as Response);
}

function renderScreen() {
  const client = new QueryClient({ defaultOptions: { queries: { retry: false } } });
  return render(
    <QueryClientProvider client={client}>
      <HomeScreen />
    </QueryClientProvider>,
  );
}

describe('HomeScreen', () => {
  afterEach(() => {
    jest.restoreAllMocks();
  });

  it('renders the welcome heading', () => {
    mockFetchOk();
    renderScreen();
    expect(screen.getByText('Welcome to <name>')).toBeTruthy();
  });

  it('shows the API health status', async () => {
    mockFetchOk();
    renderScreen();
    expect(await screen.findByText('API: Healthy')).toBeTruthy();
  });

  it('shows an error when the API is unreachable', async () => {
    jest.spyOn(global, 'fetch').mockRejectedValue(new Error('network down'));
    renderScreen();
    expect(await screen.findByText('API: unavailable')).toBeTruthy();
  });
});
```

(`<name>` = the Tera `name` expression.)

Scratch-verify it fails: copy the template files from Steps 1-5 plus this test into a temp dir `app-x`, render the Tera expressions by hand (`name` = `app-x`, bundle id `com.example.appx`), run `npm ci && npx jest`.
Expected: FAIL with "Cannot find module '@/app/index'".

- [ ] **Step 7: Write the implementation files**

`services/api.ts.raw`:

```ts
const baseUrl = process.env.EXPO_PUBLIC_API_URL ?? 'http://localhost:8080';

export async function getJson<T>(path: string): Promise<T> {
  const response = await fetch(`${baseUrl}${path}`);
  if (!response.ok) {
    throw new Error(`Request failed: ${response.status}`);
  }
  return (await response.json()) as T;
}
```

`types/health.ts.raw`:

```ts
export interface Health {
  status: string;
}
```

`hooks/use-health.ts.raw`:

```ts
import { useQuery } from '@tanstack/react-query';

import { getJson } from '@/services/api';
import type { Health } from '@/types/health';

export function useHealth() {
  return useQuery({
    queryKey: ['health'],
    queryFn: () => getJson<Health>('/health'),
  });
}
```

`components/status-text.tsx.raw`:

```tsx
import { StyleSheet, Text } from 'react-native';

export function StatusText({ children }: { children: string }) {
  return <Text style={styles.text}>{children}</Text>;
}

const styles = StyleSheet.create({
  text: { fontSize: 16, color: '#555' },
});
```

`app/_layout.tsx.raw`:

```tsx
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { Stack } from 'expo-router';

const queryClient = new QueryClient();

export default function RootLayout() {
  return (
    <QueryClientProvider client={queryClient}>
      <Stack />
    </QueryClientProvider>
  );
}
```

`app/index.tsx.tera` (the `name` Tera expression sits inside the JSX text; JSX braces must not be adjacent to it):

```tsx
import { StyleSheet, Text, View } from 'react-native';

import { StatusText } from '@/components/status-text';
import { useHealth } from '@/hooks/use-health';

export default function HomeScreen() {
  const { data, isError } = useHealth();
  const status = isError ? 'unavailable' : (data?.status ?? '...');

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Welcome to <name></Text>
      <StatusText>{`API: ${status}`}</StatusText>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, alignItems: 'center', justifyContent: 'center', gap: 8 },
  title: { fontSize: 24, fontWeight: '600' },
});
```

(`<name>` = the Tera `name` expression, which renders to plain text so `Welcome to my-app` becomes a single `Text` child.)

- [ ] **Step 8: Write `README.md.tera`**

Sections: title (the `name`); one-line description; "Commands" (`make run APP=<name> TASK=dev|test|lint|typecheck|build`, or `npm run dev` inside the app); "Structure" (`app/` routes, `components/`, `hooks/`, `services/`, `types/`, `__tests__/`); "Configuration" (`EXPO_PUBLIC_API_URL`, default `http://localhost:8080`; bundle id in `app.json`); "Notes" (not deployed by CI; store builds via EAS are not set up, see `docs/adr/005-expo-mobile.md`).

- [ ] **Step 9: Run the generator end to end and fix issues**

Run: `make test-generators`
Expected: output includes `━━━ app expo-mobile → gen-expo-mobile`, moon runs `gen-expo-mobile:build/lint/typecheck/test` successfully, final line `✅ All generators produced working projects: ... gen-expo-mobile ...`, and `Verified N tasks ran`.

Fix in the template (not the generated copy) anything that fails, then re-run. Typical issues: peer-dependency mismatch (re-run Step 3 resolution), missing Expo types for `tsc` (add `expo-env.d.ts.raw` containing `/// <reference types="expo/types" />`), ESLint flat-config import path, `{ ok: true } as Response` typing. Also confirm the generated `app.json` has a hyphen-free bundle id.

- [ ] **Step 10: Commit**

```bash
git add tools/generators/expo-mobile .gitignore
git commit -m "feat(generators): add expo-mobile stack"
```

---

### Task 2: Docs and ADR

**Files:**
- Create: `docs/adr/005-expo-mobile.md` (via `bash tools/scripts/new-adr.sh` if it supports it; otherwise copy `docs/adr/000-template.md`)
- Modify: `docs/adr/index.md`
- Modify: `apps/README.md` (stack examples and generated-files paragraph)
- Modify: `AGENTS.md` (generators row: add `expo-mobile`; architecture bullet for mobile)
- Modify: `README.md`, `docs/guides/new-solution.md` (wherever stacks are enumerated)
- Modify: `docs/superpowers/specs/2026-10-18-expo-mobile-generator-design.md` (note that `publish` stays the inherited task)

**Interfaces:**
- Consumes: stack id `expo-mobile` and decisions from Task 1.
- Produces: documentation only.

- [ ] **Step 1: Find every stack list to update**

Run: `grep -rn "react-web" README.md AGENTS.md apps/README.md docs/guides/new-solution.md docs/adr/003-monorepo-tooling.md`
Expected: the places naming stacks; add `expo-mobile` next to `react-web` only where stacks are enumerated.

- [ ] **Step 2: Write ADR-005**

Use the ADR template. Context: need mobile development in the monorepo. Decision: Expo (managed workflow) with Expo Router, TypeScript, TanStack Query, generated by the `expo-mobile` stack as a non-deployable moon project; CI runs lint/typecheck/test/build only. Alternatives considered: bare React Native CLI (heavier native toolchain), Flutter/native (not in the current stack). Consequences: no store delivery pipeline yet (EAS to be added in a future ADR); `expo export` is the CI bundling check; Expo SDK upgrades arrive via Dependabot and may need `npx expo install --check`. Add a row to `docs/adr/index.md` following the existing format.

- [ ] **Step 3: Update the stack lists**

In `apps/README.md` add under the `make new-app` examples: `make new-app STACK=expo-mobile NAME=companion   # Expo / React Native mobile app`, and note in the generated-files paragraph that `expo-mobile` apps get no Dockerfile or compose fragment and are not deployed. In `AGENTS.md` add `expo-mobile` to the generators row and an Architecture bullet: "Mobile pattern: Expo (React Native) with Expo Router - see `docs/adr/005-expo-mobile.md`". Apply analogous one-line edits to the other files found in Step 1.

- [ ] **Step 4: Amend the spec**

In the spec's moon section replace "`publish` is a no-op" with "`publish` stays the inherited task (depends on `build`); the app is not `deployable`, so deploys never run it", and note `build` is defined by the `build` script in `package.json`. Also note `bundle_id` defaults to a value derived from `name` in `app.json`.

- [ ] **Step 5: Verify docs**

Run: `grep -rn "expo-mobile" README.md AGENTS.md apps/README.md docs | head -20`
Expected: stack mentioned consistently; ADR index row matches the existing format.

- [ ] **Step 6: Commit**

```bash
git add docs README.md AGENTS.md apps/README.md
git commit -m "docs(expo-mobile): add ADR-005 and document the new stack"
```

---

### Task 3: Final verification

**Files:** none (verification only).

- [ ] **Step 1: Run the stack listing**

Run: `make stacks`
Expected: a row `expo-mobile (app) Expo mobile app ...` with the description from `template.yml`.

- [ ] **Step 2: Real generation smoke test**

With a clean tree run: `make new-app STACK=expo-mobile NAME=smoke-mobile && make run APP=smoke-mobile TASK=test`.
Expected: files in `apps/smoke-mobile` (no `infra/docker/*smoke-mobile*`), entries for `apps/smoke-mobile` in `release-please-config.json`, `.release-please-manifest.json` and `.github/dependabot.yml`, test task passes. Then revert: `git checkout -- . && git clean -fd apps/smoke-mobile` and confirm `git status --short` is empty.

- [ ] **Step 3: Run the repo checks**

Run: `make check`
Expected: PASS (the new stack does not affect existing projects).

- [ ] **Step 4: Confirm clean tree**

Run: `git status --short`
Expected: empty. Remove any logs or scratch files left by `make test-generators`.
