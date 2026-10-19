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

export interface HreflangLink {
  lang: string;
  href: string;
}

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
