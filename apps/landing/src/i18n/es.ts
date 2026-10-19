import type { Translation } from './types';

export const es: Translation = {
  meta: {
    title: 'Plataforma de lanzamiento de monorepos',
    description:
      'Ploff (Project Lift Off) es una plantilla de monorepo — aplicaciones, paquetes compartidos, infraestructura, documentación y generadores que crean un servicio, web, móvil o landing en un comando.',
  },
  nav: {
    features: 'Características',
    github: 'GitHub',
  },
  hero: {
    badge: 'Project Lift Off',
    title: 'Lanza nuevos proyectos desde una única plataforma',
    subtitle:
      'Ploff es una plantilla de monorepo con todo lo que necesitas: aplicaciones, paquetes compartidos, infraestructura, CI y generadores que crean un servicio, web, móvil o landing en un comando.',
    cta: 'Empezar',
    secondary: 'Ver características',
  },
  features: {
    title: 'Todo lo que necesitas',
    subtitle: 'Empieza rápido y mantén la coherencia en todos tus proyectos.',
    items: [
      {
        title: 'Scaffolding en un comando',
        description:
          'make new-app STACK=<stack> NAME=<name> genera un proyecto .NET, React, Expo o Astro con pruebas.',
      },
      {
        title: 'Herramientas de monorepo',
        description: 'moon orquesta build, test, lint y CI con ejecuciones solo de lo afectado.',
      },
      {
        title: 'Landings multilingües',
        description: 'Landing pages en Astro con i18n, SEO y contenido listo para IA (GEO).',
      },
    ],
  },
  footer: {
    tagline: 'Hecho con Astro, impulsado por Ploff.',
    rights: 'Todos los derechos reservados.',
  },
};
