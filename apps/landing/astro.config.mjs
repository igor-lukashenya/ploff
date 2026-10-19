// @ts-check
import { defineConfig } from 'astro/config';
import sitemap from '@astrojs/sitemap';
import tailwindcss from '@tailwindcss/vite';
import { fileURLToPath } from 'node:url';

// SITE_URL overrides the generator's site_url at build/deploy time.
const site = process.env.SITE_URL ?? 'https://example.com';

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
  ],
});
