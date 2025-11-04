import i18n from 'i18next';
import { initReactI18next } from 'react-i18next';
import AsyncStorage from '@react-native-async-storage/async-storage';
import * as Localization from 'expo-localization';

import en from './locales/en';
import uk from './locales/uk';

const LANGUAGE_KEY = '@amunx_language';

// Get saved language or fallback to device locale
const getInitialLanguage = async (): Promise<string> => {
  try {
    const saved = await AsyncStorage.getItem(LANGUAGE_KEY);
    if (saved) return saved;

    // Fallback to device locale
    const deviceLocale = Localization.locale.split('-')[0]; // 'en-US' -> 'en'
    return ['en', 'uk'].includes(deviceLocale) ? deviceLocale : 'en';
  } catch {
    return 'en';
  }
};

// Save language preference
export const setLanguage = async (lng: string): Promise<void> => {
  try {
    await AsyncStorage.setItem(LANGUAGE_KEY, lng);
    await i18n.changeLanguage(lng);
  } catch (error) {
    console.error('Failed to save language:', error);
  }
};

// Initialize i18n
export const initI18n = async (): Promise<void> => {
  const initialLanguage = await getInitialLanguage();

  await i18n
    .use(initReactI18next)
    .init({
      resources: {
        en,
        uk,
      },
      lng: initialLanguage,
      fallbackLng: 'en',
      interpolation: {
        escapeValue: false, // React already escapes
      },
      react: {
        useSuspense: false,
      },
      compatibilityJSON: 'v3', // For pluralization
    });
};

export default i18n;

