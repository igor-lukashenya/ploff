# Astro Landing Generator Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an `astro-landing` moon generator so `make new-app STACK=astro-landing NAME=<name>` scaffolds a multilingual, SEO- and GEO-ready marketing landing page, plus a Ploff landing page built from it.

**Architecture:** A new template directory `tools/generators/astro-landing` modelled on `tools/generators/react-web`. It reuses the inherited `.moon/tasks/node.yml` tasks (lint/typecheck/test/build/publish/format/dev) through `package.json` scripts, ships a static Astro site served by nginx (tagged `deployable`), and is registered like any other app by `new-project.sh` (which already auto-discovers stacks and handles release-please/dependabot/npm-ci). A `sync-templates.sh` extension keeps the template's dependency versions fresh from `apps/landing`.

**Tech Stack:** Astro 5 (static output), TypeScript, Tailwind CSS v4 via `@tailwindcss/vite`, `@astrojs/sitemap` + `@astrojs/robots-txt`, `@astrojs/check` (typecheck), ESLint + `eslint-plugin-astro`, Vitest, Node 22.

**Spec:** `docs/superpowers/specs/2026-10-19-astro-landing-generator-design.md`

## Global Constraints

- Template id is `astro-landing`; generated apps live at `apps/<name>` and are deployed as static sites (nginx), tagged `['deployable', 'astro']`.
- i18n: `defaultLocale: 'en'`, `locales: ['en', 'es']`, `prefixDefaultLocale: false` — `/` = English, `/es/` = Spanish.
- `moon.yml`: `language: 'typescript'`, `layer: 'application'`, `stack: 'frontend'`.
- `package.json` must define scripts `lint`, `lint:fix`, `type-check`, `test`, `build`, `dev` (required by `.moon/tasks/node.yml`); `test` must actually run and pass (vitest fails on no tests).
- Template file conventions: `.tera` files are rendered by moon (avoid literal `{{`/`{%`/`{#` unless intended); `.raw` files are copied verbatim; a leading `---\nto: '...'\n---` frontmatter redirects a file outside the app dir (Docker/compose/nginx go to `infra/docker/`).
- `site_url` is overridable at build time via `SITE_URL`; `site.name`, `site.url`, `site.defaultLocale`, `site.locales` (code/lang/label) and `site.links` (github/docs) are the single source of site metadata.
- GEO (per-language): every supported locale has `public/<locale>/llms.txt` + `public/<locale>/llms-full.txt`, with the default locale at the root (`/llms.txt`); the `<Seo>` component links them per locale.
- Adding a language = add the locale to `astro.config.mjs`, a dictionary in `src/i18n/`, a `src/pages/<locale>/index.astro`, and the locale's two GEO files (documented in README + AGENTS.md).
- Conventional Commits; kebab-case file names; scope `generators` for template/script changes, `landing` for the app, `astro-landing` for docs.

## Review Focus

The five behaviors most likely to bite a user that no task's happy-path test exercises by default:

1. **Locale path math with trailing slashes and nested paths** — a Spanish page `/es/features/` must map back to `/features/` and forward to `/es/features/` without doubled or dropped slashes. Pinned by `localizePath` tests in Task 1.
2. **Wrong origin in canonicals/hreflang/sitemap after deploy** — URLs must derive from `site.url` (which reads `SITE_URL`), never a hardcoded `example.com`. Pinned by `absoluteUrl`/`hreflangLinks` tests in Task 1 that assert against `site.url`.
3. **Per-locale GEO links** — `/es/` must emit `describedby`/`alternate` pointing at `/es/llms.txt` and `/es/llms-full.txt`, not the root files. Pinned by `llmsTxtPath`/`llmsFullPath` tests in Task 1.
4. **hreflang covers every configured locale** — `hreflangLinks` must emit one entry per `site.locales` entry (en + es), including the default locale. Pinned by `hreflangLinks` test in Task 1.
5. **Unknown locale falls back to English** — `useTranslations('fr')` must return the English dictionary rather than throw. Pinned by `useTranslations` test in Task 1.

---

## File Structure

```
tools/generators/astro-landing/
├── template.yml                 # generator metadata + variables (name, site_name, site_url, port)
├── moon.yml.tera                # moon project: typescript/frontend, tags deployable+astro
├── astro.config.mjs.tera        # static output, i18n, tailwind vite plugin, sitemap+robots
├── package.json.tera            # scripts + deps
├── package-lock.json.tera       # resolved lockfile (name -> {{ name }})
├── tsconfig.json.raw            # extends astro/tsconfigs/strict + @ alias
├── eslint.config.js.raw         # eslint-plugin-astro + typescript-eslint
├── vitest.config.ts.raw         # node environment + @ alias
├── .gitignore.raw               # node_modules, dist, .astro, .env
├── .env.example.raw             # SITE_URL
├── README.md.tera               # commands, structure, "adding a language" (incl. GEO files)
├── Dockerfile.tera              # -> infra/docker/Dockerfile.{{ name }}
├── compose.yml.tera             # -> infra/docker/compose.{{ name }}.yml
├── nginx.conf.tera              # -> infra/docker/nginx-{{ name }}.conf (static site)
├── public/
│   ├── favicon.svg.raw
│   ├── llms.txt.tera            # en curated map
│   ├── llms-full.txt.tera       # en full copy
│   ├── es/llms.txt.tera         # es curated map
│   └── es/llms-full.txt.tera    # es full copy
└── src/
    ├── env.d.ts.raw             # /// <reference types="astro/client" />
    ├── styles/global.css.raw    # @import "tailwindcss";
    ├── lib/
    │   ├── site.ts.tera         # site metadata + locales + links
    │   ├── seo.ts.raw           # pure URL helpers (localePrefix, localizePath, absoluteUrl, hreflangLinks, llmsTxtPath, llmsFullPath)
    │   └── seo.test.ts.raw      # unit tests pinning the URL math
    ├── i18n/
    │   ├── types.ts.raw         # Translation interface
    │   ├── en.ts.raw            # English dictionary
    │   ├── es.ts.raw            # Spanish dictionary
    │   ├── index.ts.raw         # useTranslations(locale)
    │   └── index.test.ts.raw    # fallback test
    ├── components/
    │   ├── seo.astro.raw        # <head> SEO/GEO tags
    │   ├── language-switcher.astro.raw
    │   ├── header.astro.raw
    │   ├── footer.astro.raw
    │   ├── hero.astro.raw
    │   └── features.astro.raw
    ├── layouts/
    │   └── base-layout.astro.raw
    └── pages/
        ├── index.astro.raw      # en (route /)
        └── es/index.astro.raw   # es (route /es/)
```

---

### Task 1: Astro landing template + SEO/GEO helpers (TDD)

**Files:**
- Create: every file under `tools/generators/astro-landing/` (see File Structure above), except `README.md.tera`, `Dockerfile.tera`, `compose.yml.tera`, `nginx.conf.tera`, `public/**` and the `src/components` + `src/layouts` + `src/pages` UI files, which are added in Task 3.
- Task 1 files specifically: `template.yml`, `moon.yml.tera`, `astro.config.mjs.tera`, `package.json.tera`, `package-lock.json.tera`, `tsconfig.json.raw`, `eslint.config.js.raw`, `vitest.config.ts.raw`, `.gitignore.raw`, `.env.example.raw`, `src/env.d.ts.raw`, `src/styles/global.css.raw`, `src/lib/site.ts.tera`, `src/lib/seo.ts.raw`, `src/lib/seo.test.ts.raw`, `src/i18n/types.ts.raw`, `src/i18n/en.ts.raw`, `src/i18n/es.ts.raw`, `src/i18n/index.ts.raw`, `src/i18n/index.test.ts.raw`.

**Interfaces:**
- Consumes: moon template variables `name` (string, required), `site_name` (string, default `My Site`), `site_url` (string, default `https://example.com`), `port` (number, default 3000).
- Produces: `src/lib/site.ts` exports `site` (with `name`, `url`, `defaultLocale`, `locales: Array<{code,lang,label}>`, `links: {github, docs}`); `src/lib/seo.ts` exports `localePrefix(locale: string): string`, `localizePath(pathname: string, fromLocale: string, toLocale: string): string`, `absoluteUrl(path: string): string`, `hreflangLinks(pathname: string, fromLocale: string): Array<{lang: string; href: string}>`, `llmsTxtPath(locale: string): string`, `llmsFullPath(locale: string): string`; `src/i18n/index.ts` exports `useTranslations(locale: string): Translation`.

- [ ] **Step 1: Write `template.yml`**

```yaml
# moon template - https://moonrepo.dev/docs/guides/codegen
# Use via: make new-app STACK=astro-landing NAME=<name>
title: 'Astro landing page'
description: 'Astro 5 static site with i18n (en/es), SEO, and per-language GEO (llms.txt)'
destination: 'apps/[name]'

variables:
  name:
    type: 'string'
    required: true
    prompt: 'App name (kebab-case)?'
  site_name:
    type: 'string'
    default: 'My Site'
    prompt: 'Human-readable site name/title?'
  site_url:
    type: 'string'
    default: 'https://example.com'
    prompt: 'Public site URL (https://...)?'
  port:
    type: 'number'
    default: 3000
    prompt: 'Host port for local Docker Compose?'
```

- [ ] **Step 2: Write `moon.yml.tera`**

```yaml
$schema: 'https://moonrepo.dev/schemas/moon.json'

language: 'typescript'
layer: 'application'
stack: 'frontend'
tags: ['deployable', 'astro']

project:
  title: '{{ name }}'
  description: 'Astro 5 multilingual marketing landing page'

# lint/typecheck/test/build/publish/format/dev are inherited from
# .moon/tasks/node.yml. Astro's src/ + public/ match the default sources group.
```

- [ ] **Step 3: Write `astro.config.mjs.tera`**

```js
// @ts-check
import { defineConfig } from 'astro/config';
import sitemap from '@astrojs/sitemap';
import robotsTxt from '@astrojs/robots-txt';
import tailwindcss from '@tailwindcss/vite';
import { fileURLToPath } from 'node:url';

// SITE_URL overrides the generator's site_url at build/deploy time.
const site = process.env.SITE_URL ?? '{{ site_url }}';

// https://astro.build/config
export default defineConfig({
  site,
  output: 'static',
  vite: {
    plugins: [tailwindcss()],
    resolve: { alias: { '@': fileURLToPath(new URL('./src', import.meta.url)) } },
  },
  i18n: {
    defaultLocale: 'en',
    locales: ['en', 'es'],
    routing: { prefixDefaultLocale: false },
  },
  integrations: [
    sitemap({ i18n: { defaultLocale: 'en', locales: { en: 'en-US', es: 'es-ES' } } }),
    robotsTxt({
      sitemap: true,
      policy: [
        { userAgent: 'GPTBot', allow: '/' },
        { userAgent: 'ClaudeBot', allow: '/' },
        { userAgent: 'PerplexityBot', allow: '/' },
        { userAgent: '*', allow: '/' },
      ],
    }),
  ],
});
```

Note: if the installed `@astrojs/sitemap` uses a different `i18n` option shape, follow its README (the intent — hreflang alternates in sitemap.xml — is fixed).

- [ ] **Step 4: Write `tsconfig.json.raw`, `eslint.config.js.raw`, `vitest.config.ts.raw`, `.gitignore.raw`, `.env.example.raw`, `src/env.d.ts.raw`, `src/styles/global.css.raw`**

`tsconfig.json.raw`:
```json
{
  "extends": "astro/tsconfigs/strict",
  "compilerOptions": {
    "baseUrl": ".",
    "paths": { "@/*": ["./src/*"] }
  },
  "include": [".astro/types.d.ts", "**/*"],
  "exclude": ["dist", "node_modules"]
}
```

`eslint.config.js.raw`:
```js
import eslintPluginAstro from 'eslint-plugin-astro';
import tseslint from 'typescript-eslint';

export default [
  ...eslintPluginAstro.configs.recommended,
  ...tseslint.configs.recommended,
  { ignores: ['dist/', '.astro/'] },
];
```

`vitest.config.ts.raw`:
```ts
import { defineConfig } from 'vitest/config';
import { fileURLToPath } from 'node:url';

export default defineConfig({
  resolve: { alias: { '@': fileURLToPath(new URL('./src', import.meta.url)) } },
  test: { include: ['src/**/*.test.ts'] },
});
```

`.gitignore.raw`:
```
node_modules
dist
.astro
.env
.env.*
!.env.example
*.log
.DS_Store
```

`.env.example.raw`:
```
# Public site URL — used for canonical URLs, sitemap, hreflang and Open Graph.
# Overrides the generator's site_url at build/deploy time.
# SITE_URL=https://example.com
```

`src/env.d.ts.raw`:
```ts
/// <reference types="astro/client" />
```

`src/styles/global.css.raw`:
```css
@import "tailwindcss";
```

- [ ] **Step 5: Write `src/lib/site.ts.tera`**

```ts
// Site-wide metadata. `name`/`url` are set at generation time; SITE_URL overrides
// the URL at build time. `locales` and `links` are edited in place for new sites.
export interface SiteLocale {
  code: string;
  lang: string;
  label: string;
}

export const site: {
  name: string;
  url: string;
  defaultLocale: string;
  locales: SiteLocale[];
  links: { github: string; docs: string };
} = {
  name: '{{ site_name }}',
  url: (process.env.SITE_URL ?? '{{ site_url }}').replace(/\/+$/, ''),
  defaultLocale: 'en',
  locales: [
    { code: 'en', lang: 'en-US', label: 'English' },
    { code: 'es', lang: 'es-ES', label: 'Español' },
  ],
  links: {
    github: 'https://github.com/',
    docs: 'https://github.com/',
  },
};
```

- [ ] **Step 6: Write the failing tests `src/lib/seo.test.ts.raw` and `src/i18n/index.test.ts.raw`**

`src/lib/seo.test.ts.raw`:
```ts
import { describe, expect, it } from 'vitest';

import { absoluteUrl, hreflangLinks, llmsFullPath, llmsTxtPath, localizePath } from './seo';
import { site } from './site';

describe('localizePath', () => {
  it('keeps the default-locale home unchanged', () => {
    expect(localizePath('/', 'en', 'en')).toBe('/');
  });
  it('maps the default-locale home to Spanish', () => {
    expect(localizePath('/', 'en', 'es')).toBe('/es/');
  });
  it('maps the Spanish home back to the default locale', () => {
    expect(localizePath('/es/', 'es', 'en')).toBe('/');
  });
  it('maps a nested Spanish page to the default locale', () => {
    expect(localizePath('/es/features/', 'es', 'en')).toBe('/features/');
  });
  it('maps a nested default-locale page to Spanish', () => {
    expect(localizePath('/features/', 'en', 'es')).toBe('/es/features/');
  });
});

describe('absoluteUrl', () => {
  it('joins the site URL with a leading-slash path', () => {
    expect(absoluteUrl('/')).toBe(`${site.url}/`);
    expect(absoluteUrl('/es/')).toBe(`${site.url}/es/`);
  });
});

describe('hreflangLinks', () => {
  it('returns an alternate URL per configured locale, default first', () => {
    expect(hreflangLinks('/', 'en')).toEqual([
      { lang: 'en-US', href: `${site.url}/` },
      { lang: 'es-ES', href: `${site.url}/es/` },
    ]);
  });
});

describe('llms paths', () => {
  it('uses the root for the default locale and a prefix otherwise', () => {
    expect(llmsTxtPath('en')).toBe('/llms.txt');
    expect(llmsTxtPath('es')).toBe('/es/llms.txt');
    expect(llmsFullPath('en')).toBe('/llms-full.txt');
    expect(llmsFullPath('es')).toBe('/es/llms-full.txt');
  });
});
```

`src/i18n/index.test.ts.raw`:
```ts
import { describe, expect, it } from 'vitest';

import { useTranslations } from './index';

describe('useTranslations', () => {
  it('returns the dictionary for a known locale', () => {
    expect(useTranslations('es').hero.cta).toBeTruthy();
  });
  it('falls back to English for an unknown locale', () => {
    expect(useTranslations('fr')).toBe(useTranslations('en'));
  });
});
```

- [ ] **Step 7: Write `src/lib/seo.ts.raw` to satisfy the tests**

Signatures and the exact algorithm (no other choice):
```ts
import { site } from './site';

export function localePrefix(locale: string): string {
  return locale === site.defaultLocale ? '' : `/${locale}`;
}

export function localizePath(pathname: string, fromLocale: string, toLocale: string): string {
  let pagePath = pathname;
  const fromPrefix = localePrefix(fromLocale);
  if (fromPrefix && pagePath.startsWith(fromPrefix)) {
    pagePath = pagePath.slice(fromPrefix.length);
  }
  if (pagePath === '') pagePath = '/';
  const toPrefix = localePrefix(toLocale);
  return toPrefix === '' ? pagePath : `${toPrefix}${pagePath}`;
}

export function absoluteUrl(path: string): string {
  const normalized = path.startsWith('/') ? path : `/${path}`;
  return `${site.url}${normalized}`;
}

export interface HreflangLink { lang: string; href: string; }

export function hreflangLinks(pathname: string, fromLocale: string): HreflangLink[] {
  return site.locales.map((l) => ({
    lang: l.lang,
    href: absoluteUrl(localizePath(pathname, fromLocale, l.code)),
  }));
}

export function llmsTxtPath(locale: string): string {
  const prefix = localePrefix(locale);
  return `${prefix}/llms.txt`;
}

export function llmsFullPath(locale: string): string {
  const prefix = localePrefix(locale);
  return `${prefix}/llms-full.txt`;
}
```

- [ ] **Step 8: Write the i18n module**

`src/i18n/types.ts.raw`:
```ts
export interface FeatureItem {
  title: string;
  description: string;
}

export interface Translation {
  meta: { title: string; description: string };
  nav: { features: string; github: string };
  hero: { badge: string; title: string; subtitle: string; cta: string; secondary: string };
  features: { title: string; subtitle: string; items: FeatureItem[] };
  footer: { tagline: string; rights: string };
}
```

`src/i18n/en.ts.raw` — a `Translation` typed `const en: Translation` with generic copy for the five groups (`meta`, `nav`, `hero`, `features` with exactly three items, `footer`). `nav.github` = `"GitHub"`, `hero.cta` = `"Get started"`, `hero.secondary` = `"See features"` (a non-empty value so the test passes).

`src/i18n/es.ts.raw` — a faithful Spanish translation of `en.ts` with identical keys, also typed `const es: Translation`.

`src/i18n/index.ts.raw`:
```ts
import { en } from './en';
import { es } from './es';
import type { Translation } from './types';

const dictionaries: Record<string, Translation> = { en, es };

export function useTranslations(locale: string): Translation {
  return dictionaries[locale] ?? en;
}
```

- [ ] **Step 9: Resolve dependencies and generate `package.json.tera` + `package-lock.json.tera`**

In a scratch dir outside the repo:
```bash
SCRATCH=$(mktemp -d) && cd "$SCRATCH"
npm init -y >/dev/null
npm install astro@latest @astrojs/sitemap@latest @astrojs/robots-txt@latest tailwindcss@latest @tailwindcss/vite@latest --no-audit --no-fund
npm install -D @astrojs/check@latest typescript@latest eslint@latest eslint-plugin-astro@latest typescript-eslint@latest @eslint/js@latest globals@latest vitest@latest --no-audit --no-fund
```

If `eslint@latest` (10.x) has a peer conflict with `eslint-plugin-astro`, pin `eslint@^9` and re-run. Then assemble `package.json.tera`: `"name": "{{ name }}"`, `"private": true`, `"version": "0.1.0"`, `"type": "module"`, and exactly these scripts:
```json
"scripts": {
  "dev": "astro dev",
  "build": "astro build",
  "preview": "astro preview",
  "lint": "eslint .",
  "lint:fix": "eslint . --fix",
  "type-check": "astro check",
  "test": "vitest run",
  "test:watch": "vitest"
}
```
with `dependencies`/`devDependencies` copied from the scratch `package.json`. Generate `package-lock.json.tera` from the scratch lockfile, replacing the two `"name": "scratch"` occurrences with the `{{ name }}` expression (same form as `tools/generators/react-web/package-lock.json.tera`). Confirm the only Tera delimiters are those name expressions: `grep -n '{%\|{#' package-lock.json.tera` returns nothing and `{{ name }}` appears on exactly 2 lines. Delete the scratch dir.

- [ ] **Step 10: Verify the template generates a working project**

```bash
SCRATCH=$(mktemp -d)
git ls-files -z --cached --others --exclude-standard | tar --null -T - -cf - | tar -xf - -C "$SCRATCH"
cd "$SCRATCH"
bash tools/scripts/remove-samples.sh >/dev/null
bash tools/scripts/new-project.sh app astro-landing gen-astro-landing
moon run gen-astro-landing:test gen-astro-landing:typecheck gen-astro-landing:lint --summary minimal
```
Expected: `new-project.sh` completes (npm ci succeeds); `test` passes (the seo + i18n tests); `typecheck` (`astro check`) passes; `lint` passes. Fix in the template (not the generated copy) anything that fails, then re-run. Typical issues: eslint-plugin-astro/ESLint 10 peer mismatch (see Step 9), a missing `@typescript-eslint/parser` peer, the eslint flat-config combination (scope `typescript-eslint` to `**/*.ts` so it does not lint `.astro` files), or the `sitemap` i18n option shape.

- [ ] **Step 11: Commit**

```bash
git add tools/generators/astro-landing
git commit -m "feat(generators): add astro-landing stack"
```

---

### Task 2: Landing UI, GEO files, Docker and README

**Files:**
- Create: `tools/generators/astro-landing/src/components/seo.astro.raw`, `language-switcher.astro.raw`, `header.astro.raw`, `footer.astro.raw`, `hero.astro.raw`, `features.astro.raw`; `src/layouts/base-layout.astro.raw`; `src/pages/index.astro.raw`; `src/pages/es/index.astro.raw`; `public/favicon.svg.raw`; `public/llms.txt.tera`; `public/llms-full.txt.tera`; `public/es/llms.txt.tera`; `public/es/llms-full.txt.tera`; `README.md.tera`; `Dockerfile.tera`; `compose.yml.tera`; `nginx.conf.tera`.

**Interfaces:**
- Consumes: `site` (Task 1), `useTranslations` (Task 1), and the `seo.ts` helpers (Task 1).
- Produces: a complete generated landing page; `README.md` documenting the "adding a language" contract; `infra/docker/{Dockerfile,compose,nginx-}.<name>` for `make up`.

- [ ] **Step 1: Write `src/components/seo.astro.raw`**

Frontmatter computes, from `Astro.currentLocale` (defaulting to `site.defaultLocale`) and `Astro.url.pathname`: `canonical = absoluteUrl(pathname)`, `alternates = hreflangLinks(pathname, locale)`, `xDefault = absoluteUrl(localizePath(pathname, locale, site.defaultLocale))`, `llms = llmsTxtPath(locale)`, `llmsFull = llmsFullPath(locale)`, and `pageTitle = \`${site.name} · ${Astro.props.title}\``. The component receives `{ title: string; description: string }` props. It renders exactly these head elements (order as listed):

- `<title>{pageTitle}</title>`
- `<meta name="description" content={Astro.props.description} />`
- `<link rel="canonical" href={canonical} />`
- one `<link rel="alternate" hreflang={a.lang} href={a.href} />` per alternate, plus `<link rel="alternate" hreflang="x-default" href={xDefault} />`
- `<meta property="og:title|og:description|og:url|og:type|og:site_name" ... />` (og:type = `website`)
- `<meta name="twitter:card|twitter:title|twitter:description" ... />` (card = `summary_large_image`)
- `<link rel="alternate" type="text/markdown" href={llmsFull} />` and `<link rel="describedby" href={llms} />`
- `<script type="application/ld+json" set:html={JSON.stringify({ '@context': 'https://schema.org', '@type': 'Organization', name: site.name, url: site.url })} />`

- [ ] **Step 2: Write `src/layouts/base-layout.astro.raw`**

Renders the document shell: `<!doctype html>` with `<html lang={locale}>` (locale = `Astro.currentLocale ?? site.defaultLocale`), head containing `<meta charset="utf-8">`, `<meta name="viewport" ...>`, `<link rel="icon" ... href="/favicon.svg">`, and `<Seo title={t.meta.title} description={t.meta.description} />`; body containing `<Header />`, `<slot />`, `<Footer />`. Imports `../styles/global.css`, `site`, `useTranslations`, `Seo`, `Header`, `Footer`.

- [ ] **Step 3: Write `src/components/header.astro.raw`, `footer.astro.raw`, `hero.astro.raw`, `features.astro.raw`, `language-switcher.astro.raw`**

Tailwind-styled sections reading from `useTranslations(Astro.currentLocale ?? site.defaultLocale)` and `site`:

- `header`: sticky top bar with the site name (links to `/`), a "features" anchor link, the `LanguageSwitcher`, and a "GitHub" link using `site.links.github` (label from `t.nav.github`).
- `language-switcher`: for each `site.locales` entry, a link to the current page in that locale — `href = localizePath(Astro.url.pathname, Astro.currentLocale ?? site.defaultLocale, loc.code)` with `hreflang={loc.lang}` and the `loc.label` as text, marking the active locale.
- `hero`: badge, `t.hero.title`, `t.hero.subtitle`, primary CTA `t.hero.cta` → `site.links.docs`, secondary `t.hero.secondary` → `#features`.
- `features`: section id `features` with `t.features.title`, `t.features.subtitle`, and a grid of `t.features.items` (title + description each).
- `footer`: `t.footer.tagline`, a copyright line `© {year} {site.name}. {t.footer.rights}`, and the GitHub link.

- [ ] **Step 4: Write `src/pages/index.astro.raw` and `src/pages/es/index.astro.raw`**

Both files are identical, thin wrappers: import `BaseLayout`, `Hero`, `Features` and render `<BaseLayout><Hero /><Features /></BaseLayout>`. Astro's i18n routing serves `index.astro` at `/` (en) and `es/index.astro` at `/es/` (es); components pick the locale via `Astro.currentLocale`.

- [ ] **Step 5: Write `public/favicon.svg.raw`**

A simple branded SVG (any neutral mark) — no interpolation.

- [ ] **Step 6: Write the GEO files**

`public/llms.txt.tera` and `public/es/llms.txt.tera` — llms.txt format: `# {{ site_name }}`, a `> ` blockquote one-line summary, and a `## ` section listing `- [<title>]({{ site_url }}/<path>): <description>` entries pointing at the home page (and its locale prefix for the Spanish file). `public/llms-full.txt.tera` and `public/es/llms-full.txt.tera` — a fuller markdown version (site name, summary, and a plain-text rendering of the hero/features copy for that locale). The English files cover `/`; the Spanish files cover `/es/`. Keep under 50KB each.

- [ ] **Step 7: Write `README.md.tera`**

Sections: title (`{{ name }}`); one-line description; "Commands" (`make dev APP={{ name }}`, `make run APP={{ name }} TASK=test|lint|typecheck|build`, `make up` on port `{{ port }}`); "Site settings" (`site_name`, `site_url`/`SITE_URL`); "Structure" (point to `src/lib/site.ts`, `src/i18n/`, `src/components/`, `public/`); and a prominent **"Adding a language"** section enumerating the exact four edits — add the locale to `astro.config.mjs` `i18n.locales`, add `src/i18n/<locale>.ts`, add `src/pages/<locale>/index.astro`, and **add the locale's `public/<locale>/llms.txt` + `public/<locale>/llms-full.txt`** — with the sentence "GEO must cover every supported language".

- [ ] **Step 8: Write `Dockerfile.tera`, `compose.yml.tera`, `nginx.conf.tera`**

`Dockerfile.tera` (frontmatter `to: '../../infra/docker/Dockerfile.{{ name }}'`): build stage `node:22-alpine`, `COPY apps/{{ name }}/package.json apps/{{ name }}/package-lock.json ./`, `RUN npm ci`, `COPY apps/{{ name }}/ ./`, `RUN npm run build`; production stage `nginxinc/nginx-unprivileged:alpine`, `COPY --from=build /app/dist /usr/share/nginx/html`, `COPY infra/docker/nginx-{{ name }}.conf /etc/nginx/conf.d/default.conf`, `USER 101`, `EXPOSE 8080`, `CMD ["nginx", "-g", "daemon off;"]`.

`compose.yml.tera` (frontmatter `to: '../../infra/docker/compose.{{ name }}.yml'`): a `{{ name }}` service that builds from the Dockerfile and maps `"{{ port }}:8080"`.

`nginx.conf.tera` (frontmatter `to: '../../infra/docker/nginx-{{ name }}.conf'`, body wrapped in `{% raw %}…{% endraw %}`): a static-site server block — `listen 8080`, `server_name _`, `root /usr/share/nginx/html`, `index index.html`, gzip for text/css/js/svg, a `/assets/` cache location, `location / { try_files $uri $uri/ =404; }` (no SPA fallback, no API proxy), and a `/nginx-health` endpoint returning `healthy`.

- [ ] **Step 9: Verify the full build**

Re-run the scratch flow from Task 1 Step 10, adding `gen-astro-landing:build` and (with Docker) `--docker`:
```bash
moon run gen-astro-landing:test gen-astro-landing:typecheck gen-astro-landing:lint gen-astro-landing:build --summary minimal
```
Expected: `build` produces `dist/` with `index.html`, `es/index.html`, `llms.txt`, `es/llms.txt`, `sitemap.xml`, `robots.txt`. Spot-check `dist/index.html` for `<link rel="canonical">`, hreflang alternates, `<link rel="describedby" href="/llms.txt">`, and the JSON-LD block; and `dist/es/index.html` for `href="/es/llms.txt"`.

- [ ] **Step 10: Commit**

```bash
git add tools/generators/astro-landing
git commit -m "feat(generators): add landing UI, GEO files and Docker support to astro-landing"
```

---

### Task 3: Ploff landing page `apps/landing`

**Files:**
- Create: `apps/landing/**` (generated), then customize `apps/landing/src/lib/site.ts`, `apps/landing/src/i18n/en.ts`, `apps/landing/src/i18n/es.ts`, `apps/landing/public/llms.txt`, `apps/landing/public/llms-full.txt`, `apps/landing/public/es/llms.txt`, `apps/landing/public/es/llms-full.txt`, `apps/landing/README.md`.

**Interfaces:**
- Consumes: the `astro-landing` template (Task 1–2); `new-project.sh` registration.
- Produces: a deployable Ploff landing page registered for Release Please + Dependabot.

- [ ] **Step 1: Generate the app**

Run `make new-app STACK=astro-landing NAME=landing`. Confirm `apps/landing/`, `infra/docker/Dockerfile.landing`, `infra/docker/compose.landing.yml`, `infra/docker/nginx-landing.conf` are created, and entries appear in `release-please-config.json`, `.release-please-manifest.json`, `.github/dependabot.yml`.

- [ ] **Step 2: Set site metadata**

In `apps/landing/src/lib/site.ts`, set `name: 'Ploff'`, `links.github`/`links.docs` to the Ploff repository URL, and leave `url` as the `SITE_URL`-overridable placeholder. Keep `defaultLocale: 'en'` and both locales.

- [ ] **Step 3: Write the Ploff copy**

Rewrite `en.ts` (and `es.ts` as its Spanish translation) with Ploff-specific copy: `meta` describing "Project Lift Off — a monorepo launchpad"; `hero` with the value prop and a "Get started" CTA linking to the repo; three `features.items` (e.g. one-command scaffolding via `make new-app`, monorepo tooling with moon/CI, i18n + SEO + GEO landing pages). Update the four `public/*/llms*.txt` files to describe Ploff in the matching language.

- [ ] **Step 4: Verify**

```bash
make run APP=landing TASK=build
make run APP=landing TASK=test
make run APP=landing TASK=typecheck
make run APP=landing TASK=lint
```
Expected: all pass; `apps/landing/dist/` contains both locales + GEO + SEO files.

- [ ] **Step 5: Commit**

```bash
git add apps/landing infra/docker/Dockerfile.landing infra/docker/compose.landing.yml infra/docker/nginx-landing.conf release-please-config.json .release-please-manifest.json .github/dependabot.yml
git commit -m "feat(landing): add Ploff landing page (Astro)"
```

---

### Task 4: `sync-templates.sh` extension

**Files:**
- Modify: `tools/scripts/sync-templates.sh` (add an astro-landing manifest+lockfile sync, mirroring the existing react-web block).

**Interfaces:**
- Consumes: `apps/landing/package.json` + `package-lock.json` (Task 3).
- Produces: `tools/generators/astro-landing/package.json.tera` + `package-lock.json.tera` refreshed with the landing app's dependency versions (name/version reset to the template expressions).

- [ ] **Step 1: Add the astro-landing sync block**

After the react-web block, add a block that, when `apps/landing/package.json` exists and `tools/generators/astro-landing` exists, runs the same `node` inline script (reset `name` → `{{ name }}`, `version` → `0.1.0`, and `packages['']` name/version) over `package.json` and `package-lock.json` from `apps/landing` into `tools/generators/astro-landing/*.tera`. Do **not** sync verbatim `.raw` files (the template is the source of truth for those).

- [ ] **Step 2: Verify**

```bash
make sync-templates --check
```
Expected: `--check` reports no drift (the just-generated template already matches `apps/landing`), or lists astro-landing files if versions drifted — then run `make sync-templates` and commit.

- [ ] **Step 3: Commit**

```bash
git add tools/scripts/sync-templates.sh
git commit -m "feat(generators): sync astro-landing deps from the landing app"
```

---

### Task 5: Docs and ADR

**Files:**
- Create: `docs/adr/006-astro-landing.md`
- Modify: `docs/adr/index.md`, `apps/README.md`, `AGENTS.md`, `README.md`, `docs/guides/new-solution.md`

**Interfaces:**
- Consumes: stack id `astro-landing`, the ADR template.
- Produces: documentation only.

- [ ] **Step 1: Find every stack list to update**

Run: `grep -rn "react-web" README.md AGENTS.md apps/README.md docs/guides/new-solution.md`
Expected: the places naming stacks. Add `astro-landing` wherever stacks are enumerated.

- [ ] **Step 2: Write ADR-006**

Copy `docs/adr/000-template.md` to `docs/adr/006-astro-landing.md`. Context: the solution needs marketing landing pages that are translated, SEO-optimized, and AI-indexable. Decision: use Astro (static) generated by the `astro-landing` stack, with i18n (`en` default + `es`), Tailwind CSS v4, `@astrojs/sitemap` + `@astrojs/robots-txt`, and per-language GEO (`llms.txt`/`llms-full.txt` for every locale); deployable via nginx/Docker like `react-web`. Alternatives: hand-rolled multi-page sites (no generator), Next.js/React (heavier for static marketing pages), a CMS. Consequences: the GEO-per-language contract (adding a locale requires its GEO files); Astro/Tailwind/ESLint drift is managed by `sync-templates.sh` + Dependabot on `apps/landing`. Add a row to `docs/adr/index.md`.

- [ ] **Step 3: Update the stack lists**

In `apps/README.md` add `make new-app STACK=astro-landing NAME=landing   # Astro marketing landing page (i18n + SEO + GEO)` and note astro-landing apps ship a Dockerfile + compose fragment (deployable). In `AGENTS.md` add `astro-landing` to the generators row and an Architecture bullet: "Landing page pattern: Astro (static) with i18n, SEO and per-language GEO — see `docs/adr/006-astro-landing.md`; when adding a locale, also add its `llms.txt` + `llms-full.txt`". Apply analogous one-line edits to `README.md` (app structure example) and `docs/guides/new-solution.md` (stack list).

- [ ] **Step 4: Verify docs**

Run: `grep -rn "astro-landing" README.md AGENTS.md apps/README.md docs | head -20`
Expected: the stack mentioned consistently; ADR index row matches the existing format.

- [ ] **Step 5: Commit**

```bash
git add docs README.md AGENTS.md apps/README.md
git commit -m "docs(astro-landing): add ADR-006 and document the new stack"
```

---

### Task 6: Final verification

**Files:** none (verification only).

- [ ] **Step 1: Stack listing**

Run: `make stacks`
Expected: a row `astro-landing (app) Astro landing page ...` with the description from `template.yml`.

- [ ] **Step 2: Full generator suite**

Run: `make test-generators`
Expected: output includes `━━━ app astro-landing → gen-astro-landing` and the final `✅ All generators produced working projects: ... gen-astro-landing ...`; the guard reports all of `gen-astro-landing:build/lint/typecheck/test` ran.

- [ ] **Step 3: Repo checks**

Run: `make check`
Expected: PASS (existing projects unaffected; the new `landing` app's tasks pass).

- [ ] **Step 4: Clean tree**

Run: `git status --short`
Expected: empty (or only intended changes). Remove any scratch/log files left by the generator runs.
