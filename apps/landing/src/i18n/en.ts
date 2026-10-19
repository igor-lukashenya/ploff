import type { Translation } from './types';

export const en: Translation = {
  meta: {
    title: 'Monorepo launchpad',
    description:
      'Ploff (Project Lift Off) is a monorepo boilerplate — apps, shared packages, infrastructure, docs, and generators that scaffold a new service, web app, mobile app, or landing page in one command.',
  },
  nav: {
    features: 'Features',
    github: 'GitHub',
  },
  hero: {
    badge: 'Project Lift Off',
    title: 'Ship new projects from a single launchpad',
    subtitle:
      'Ploff is a monorepo boilerplate with everything you need: apps, shared packages, infrastructure, CI, and generators that scaffold a new service, web app, mobile app, or landing page in one command.',
    cta: 'Get started',
    secondary: 'See features',
  },
  features: {
    title: 'Everything you need',
    subtitle: 'Start fast and stay consistent across every project.',
    items: [
      {
        title: 'One-command scaffolding',
        description:
          'make new-app STACK=<stack> NAME=<name> generates a working .NET, React, Expo, or Astro project with tests.',
      },
      {
        title: 'Monorepo tooling',
        description: 'moon orchestrates build, test, lint, and CI with affected-only runs and shared tasks.',
      },
      {
        title: 'Multilingual landing pages',
        description: 'Astro landing pages with i18n, SEO, and AI-ready (GEO) content built in.',
      },
    ],
  },
  footer: {
    tagline: 'Built with Astro, powered by Ploff.',
    rights: 'All rights reserved.',
  },
};
