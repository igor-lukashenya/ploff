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
