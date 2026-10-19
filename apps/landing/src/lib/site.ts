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
  name: 'Ploff',
  url: (process.env.SITE_URL ?? 'https://example.com').replace(/\/+$/, ''),
  defaultLocale: 'en',
  locales: [
    { code: 'en', lang: 'en-US', label: 'English' },
    { code: 'es', lang: 'es-ES', label: 'Español' },
  ],
  links: {
    github: 'https://github.com/igor-lukashenya/ploff',
    docs: 'https://github.com/igor-lukashenya/ploff',
  },
};
