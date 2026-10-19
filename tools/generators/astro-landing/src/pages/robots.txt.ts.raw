import type { APIRoute } from 'astro';

const robotsTxt = (sitemapURL: URL) => `User-agent: *
Allow: /

# AI crawlers that power generative search
User-agent: GPTBot
Allow: /

User-agent: ClaudeBot
Allow: /

User-agent: PerplexityBot
Allow: /

Sitemap: ${sitemapURL.href}`;

export const GET: APIRoute = ({ site }) => {
  // `site` is configured in astro.config.mjs, so it is always set.
  const sitemapURL = new URL('sitemap-index.xml', site!);
  return new Response(robotsTxt(sitemapURL), {
    headers: { 'Content-Type': 'text/plain; charset=utf-8' },
  });
};
