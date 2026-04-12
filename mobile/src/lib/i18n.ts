import * as Localization from 'expo-localization';
import i18n from 'i18next';
import { initReactI18next } from 'react-i18next';

import en from '@/locales/en/common.json';
import uk from '@/locales/uk/common.json';

const resources = {
  en: { translation: en },
  uk: { translation: uk },
} as const;

function resolveInitialLanguage(): string {
  const code = Localization.getLocales()[0]?.languageCode?.toLowerCase();
  if (code === 'uk') return 'uk';
  return 'en';
}

void i18n.use(initReactI18next).init({
  compatibilityJSON: 'v4',
  resources,
  lng: resolveInitialLanguage(),
  fallbackLng: 'en',
  supportedLngs: ['en', 'uk'],
  interpolation: { escapeValue: false },
  react: { useSuspense: false },
});

export default i18n;
