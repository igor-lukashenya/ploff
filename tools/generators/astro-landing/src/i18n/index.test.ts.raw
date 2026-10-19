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
