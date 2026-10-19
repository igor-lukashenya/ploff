# Astro landing-page generator — design

## Goal

Add an `astro-landing` moon generator so `make new-app STACK=astro-landing NAME=<name>`
scaffolds a marketing landing page, plus a real landing page for Ploff built from it.
Each generated site ships **translation (i18n)**, **SEO**, and **GEO** (Generative Engine
Optimization — being indexable by AI tools) out of the box.

## Scope

In: generator template, a Ploff landing page (`apps/landing`), a `sync-templates.sh`
extension, docs/ADR, generator test coverage.

Out: a CMS, dynamic server rendering (the site is static), analytics, A/B testing,
per-visitor geo-routing.

## What "translation, SEO, GEO" mean here

- **Translation**: Astro's built-in i18n routing. `defaultLocale: 'en'`, `locales: ['en', 'es']`,
  `prefixDefaultLocale: false` — so `/` serves English (the default) and `/es/` serves Spanish.
  Copy lives in typed per-locale dictionaries (`src/i18n/en.ts`, `src/i18n/es.ts`) and a
  `LanguageSwitcher` component swaps locales. Adding a language = add a dictionary + one line
  in `astro.config.mjs`.
- **SEO**: a `<Seo>` component renders `<title>`, meta description, canonical URL, `hreflang`
  alternates, Open Graph + Twitter cards, and JSON-LD (`Organization`/`WebSite`).
  `@astrojs/sitemap` emits `sitemap.xml` (with i18n alternates); `@astrojs/robots-txt` emits
  `robots.txt` (referencing the sitemap and allowing AI crawlers).
- **GEO** (per-language): one `llms.txt` (curated map: H1 + blockquote summary + `##` sections
  of `<url>: description` links) and one `llms-full.txt` (full markdown copy) **for every
  supported locale**, at the locale's own path — `/llms.txt` + `/llms-full.txt` (default `en`)
  and `/es/llms.txt` + `/es/llms-full.txt` (Spanish), matching Astro's URL structure. The
  `<Seo>` component links the current page to its locale's files via `rel="describedby"` and
  `rel="alternate" type="text/markdown"`, plus clean semantic HTML. This is the emerging
  standard for AI tools (ChatGPT, Perplexity). A hard convention is documented (template
  README + ADR + AGENTS.md): **adding a supported language requires adding its GEO files
  too**, so agents generating or extending a landing always ship GEO for all supported languages.

## Generator `tools/generators/astro-landing`

- **Stack**: Astro (current stable, 5.x) with `output: 'static'`; TypeScript; Tailwind CSS v4
  via `@tailwindcss/vite` (the `@astrojs/tailwind` integration is deprecated).
- **Tasks**: inherits `.moon/tasks/node.yml` (lint/typecheck/test/build/publish/format/dev).
  Scripts: `dev` = `astro dev`, `build` = `astro build`, `type-check` = `astro check`
  (`@astrojs/check`), `lint` = `eslint .` (`eslint-plugin-astro`), `test` = `vitest run`.
- **Tests**: Vitest unit-tests the plain-TS SEO/i18n helpers (`src/lib/seo.ts`, i18n
  dictionaries) — no experimental Astro component testing.
- **Layout**: `src/pages/index.astro` (en) + `src/pages/es/index.astro` (es),
  `src/layouts/`, `src/components/`, `src/i18n/`, `src/lib/`, `src/styles/global.css`.
- **Deploy**: static site served by nginx. Ships `Dockerfile` + compose fragment, tagged
  `deployable` (matches `react-web`), so `make up` and the existing deploy workflows handle it.
- **Variables**: `name` (required, kebab-case), `site_name` (human-readable title, default
  "My Site"), `site_url` (default `https://example.com`), `port` (default 3000, first-free).
  `site_url` is also read from `SITE_URL` at build time when set, so canonical/hreflang/
  sitemap/OG are correct the moment a real domain is supplied at deploy time.

## moon

- `moon.yml`: `language: 'typescript'`, `layer: 'application'`, `stack: 'frontend'`,
  tags `['deployable', 'astro']`. Inherits the default `sources` file group unchanged
  (`src/**/*`, `public/**/*`, `*.config.*`, `tsconfig*.json`, `package*.json` cover Astro).

## Scripts

- `new-project.sh` / `test-generators.sh`: no changes — they auto-discover any stack whose
  `template.yml` targets `apps/[name]`, register release-please + dependabot (npm), run
  `npm ci`, and `test-generators.sh` exercises the Dockerfile under `--docker`.
- `sync-templates.sh`: extend to copy `apps/landing`'s `package.json` + `package-lock.json`
  into the template (name/version reset), mirroring the `react-web` manifest sync. All other
  files (`.raw`/`.tera` source, config, i18n, SEO/GEO helpers) stay authored in the template,
  which is the single source of truth — `apps/landing` is a generated copy, so fixes go in the
  template (same model as `expo-mobile`, which has no reference app).

## Ploff landing page `apps/landing`

Generated from the template via `make new-app` (so Release Please + Dependabot registration
is automatic), then customized with Ploff copy in English and Spanish (Spanish drafted by the
implementer, to be reviewed later). The main CTA links to the Ploff GitHub repository. It is a
real app — not a `sample-*` app — so `remove-samples.sh` / `init-project.sh` leave it alone;
the "Ploff" wording is rewritten to the solution name by `init-project.sh` as usual.

## CI

No workflow changes: affected detection runs lint/typecheck/test/build; the `deployable` tag
means the (currently placeholder) deploy step includes it.

## Docs

- ADR-006: Astro for marketing landing pages (i18n + SEO + per-language GEO).
- Update `apps/README.md`, `AGENTS.md`, `README.md`, `docs/guides/new-solution.md` stack
  lists, and the generator's own `README.md.tera`.
- `AGENTS.md` and the template README record the convention that **GEO must cover every
  supported language** (add the locale's `llms.txt` + `llms-full.txt` whenever a locale is added).

## Risks

- Astro/Tailwind/ESLint versions drift quickly; the template lockfile is generated once and
  refreshed by `sync-templates.sh` + Dependabot on `apps/landing`.
- `eslint-plugin-astro` compatibility with the repo's ESLint major must be verified when the
  lockfile is generated (resolve in a scratch project, confirm `npm run lint` passes).
- `llms.txt` adoption is uneven; it complements (not replaces) sitemap/robots/on-page SEO.
- Adding a language is a multi-file edit (locale, dictionary, page, two GEO files); the README
  and AGENTS.md convention is the mitigation against forgetting the GEO files.
