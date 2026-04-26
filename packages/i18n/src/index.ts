import { enUS } from "./locales/en-US.js";
import { zhCN } from "./locales/zh-CN.js";
import type { AIOutputLocale, Locale, LocaleSettings, TranslationDictionary, TranslationKey, TranslationValues } from "./types.js";

export type { AIOutputLocale, Locale, LocaleSettings, TranslationDictionary, TranslationKey, TranslationValues };

export const defaultLocale: Locale = "en-US";
export const supportedLocales = ["en-US", "zh-CN"] as const satisfies readonly Locale[];
export const defaultLocaleSettings: LocaleSettings = {
  locale: defaultLocale,
  aiOutputLocale: "follow-ui",
};

const dictionaries: Record<Locale, TranslationDictionary> = {
  "en-US": enUS,
  "zh-CN": zhCN,
};

export function isSupportedLocale(value: string | null | undefined): value is Locale {
  return value === "en-US" || value === "zh-CN";
}

export function normalizeLocale(value: string | null | undefined): Locale {
  if (!value) {
    return defaultLocale;
  }

  if (isSupportedLocale(value)) {
    return value;
  }

  const normalized = value.toLowerCase();
  if (normalized.startsWith("zh")) {
    return "zh-CN";
  }

  return defaultLocale;
}

export function normalizeAIOutputLocale(value: string | null | undefined): AIOutputLocale {
  if (value === "follow-ui") {
    return value;
  }

  return isSupportedLocale(value) ? value : "follow-ui";
}

export function resolveAIOutputLocale(settings: Partial<LocaleSettings> | null | undefined): Locale {
  const locale = normalizeLocale(settings?.locale);
  const aiOutputLocale = normalizeAIOutputLocale(settings?.aiOutputLocale);
  return aiOutputLocale === "follow-ui" ? locale : aiOutputLocale;
}

export function createTranslator(localeInput: string | null | undefined) {
  const locale = normalizeLocale(localeInput);
  const dictionary = dictionaries[locale];
  const fallbackDictionary = dictionaries[defaultLocale];

  return function t(key: TranslationKey, values: TranslationValues = {}): string {
    const template = dictionary[key] ?? fallbackDictionary[key] ?? key;
    return template.replace(/\{(\w+)}/g, (_match, token: string) => {
      const value = values[token];
      return value == null ? "" : String(value);
    });
  };
}

export function formatDateTime(localeInput: string | null | undefined, value: number | null | undefined): string {
  if (value == null) {
    return localeInput === "zh-CN" ? "未知" : "Unknown";
  }

  return new Intl.DateTimeFormat(normalizeLocale(localeInput), {
    dateStyle: "medium",
    timeStyle: "short",
  }).format(new Date(value));
}

export function formatCount(localeInput: string | null | undefined, value: number): string {
  return new Intl.NumberFormat(normalizeLocale(localeInput)).format(value);
}

export function getDictionary(localeInput: string | null | undefined): TranslationDictionary {
  return dictionaries[normalizeLocale(localeInput)];
}

export function assertCompleteDictionaries(): void {
  const keys = Object.keys(enUS) as TranslationKey[];
  for (const locale of supportedLocales) {
    const dictionary = dictionaries[locale];
    for (const key of keys) {
      if (!dictionary[key]) {
        throw new Error(`Missing i18n key ${key} for locale ${locale}`);
      }
    }
  }
}
