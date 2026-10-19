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
