import type { enUS } from "./locales/en-US.js";

export type Locale = "en-US" | "zh-CN";
export type AIOutputLocale = Locale | "follow-ui";
export type TranslationKey = keyof typeof enUS;
export type TranslationDictionary = Record<TranslationKey, string>;
export type TranslationValues = Record<string, string | number | null | undefined>;

export interface LocaleSettings {
  locale: Locale;
  aiOutputLocale: AIOutputLocale;
}
