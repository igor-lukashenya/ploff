import { en } from './en';
import { es } from './es';
import type { Translation } from './types';

const dictionaries: Record<string, Translation> = { en, es };

export function useTranslations(locale: string): Translation {
  return dictionaries[locale] ?? en;
}
