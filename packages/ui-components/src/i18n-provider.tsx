import * as React from "react";

import { createTranslator, defaultLocale, formatDateTime, type Locale, type TranslationKey, type TranslationValues } from "@chronopic/i18n";

export interface I18nContextValue {
  locale: Locale;
  t: (key: TranslationKey, values?: TranslationValues) => string;
  formatDateTime: (value: number | null | undefined) => string;
}

const I18nContext = React.createContext<I18nContextValue>({
  locale: defaultLocale,
  t: createTranslator(defaultLocale),
  formatDateTime: (value) => formatDateTime(defaultLocale, value),
});

export interface I18nProviderProps {
  children: React.ReactNode;
  locale: Locale;
}

export function I18nProvider({ children, locale }: I18nProviderProps) {
  const value = React.useMemo<I18nContextValue>(() => {
    const t = createTranslator(locale);
    return {
      locale,
      t,
      formatDateTime: (dateValue) => formatDateTime(locale, dateValue),
    };
  }, [locale]);

  return <I18nContext.Provider value={value}>{children}</I18nContext.Provider>;
}

export function useI18n(): I18nContextValue {
  return React.useContext(I18nContext);
}
