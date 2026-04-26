import fs from "node:fs";
import path from "node:path";

import type { AISettings, LocaleSettings, MapSettings } from "@chronopic/domain";
import { defaultLocaleSettings, normalizeAIOutputLocale, normalizeLocale } from "@chronopic/i18n";

const DEFAULT_AI_SETTINGS: AISettings = {
  apiKey: "",
  baseURL: "",
  model: "",
  providerName: "openai-compatible",
};

const DEFAULT_MAP_SETTINGS: MapSettings = {
  apiKey: "",
  securityJsCode: "",
};

const DEFAULT_LOCALE_SETTINGS: LocaleSettings = defaultLocaleSettings;

function normalizeSettings(input: Partial<AISettings> | null | undefined): AISettings {
  return {
    apiKey: input?.apiKey?.trim() ?? "",
    baseURL: input?.baseURL?.trim() ?? "",
    model: input?.model?.trim() ?? "",
    providerName: input?.providerName?.trim() || "openai-compatible",
  };
}

function normalizeMapSettings(input: Partial<MapSettings> | null | undefined): MapSettings {
  return {
    apiKey: input?.apiKey?.trim() ?? "",
    securityJsCode: input?.securityJsCode?.trim() ?? "",
  };
}

function normalizeLocaleSettings(input: Partial<LocaleSettings> | null | undefined): LocaleSettings {
  return {
    locale: normalizeLocale(input?.locale),
    aiOutputLocale: normalizeAIOutputLocale(input?.aiOutputLocale),
  };
}

export class ChronoPicConfigStore {
  constructor(private readonly filePath: string) {}

  getAISettings(): AISettings {
    return this.read().ai;
  }

  getMapSettings(): MapSettings {
    return this.read().map;
  }

  getLocaleSettings(): LocaleSettings {
    return this.read().locale;
  }

  saveAISettings(settings: Partial<AISettings>): AISettings {
    const current = this.read();
    const next = {
      ...current,
      ai: normalizeSettings({
        ...current.ai,
        ...settings,
      }),
    };

    fs.mkdirSync(path.dirname(this.filePath), { recursive: true });
    fs.writeFileSync(this.filePath, JSON.stringify(next, null, 2), "utf8");
    return next.ai;
  }

  saveMapSettings(settings: Partial<MapSettings>): MapSettings {
    const current = this.read();
    const next = {
      ...current,
      map: normalizeMapSettings({
        ...current.map,
        ...settings,
      }),
    };

    fs.mkdirSync(path.dirname(this.filePath), { recursive: true });
    fs.writeFileSync(this.filePath, JSON.stringify(next, null, 2), "utf8");
    return next.map;
  }

  saveLocaleSettings(settings: Partial<LocaleSettings>): LocaleSettings {
    const current = this.read();
    const next = {
      ...current,
      locale: normalizeLocaleSettings({
        ...current.locale,
        ...settings,
      }),
    };

    fs.mkdirSync(path.dirname(this.filePath), { recursive: true });
    fs.writeFileSync(this.filePath, JSON.stringify(next, null, 2), "utf8");
    return next.locale;
  }

  private read(): { ai: AISettings; map: MapSettings; locale: LocaleSettings } {
    if (!fs.existsSync(this.filePath)) {
      return { ai: DEFAULT_AI_SETTINGS, map: DEFAULT_MAP_SETTINGS, locale: DEFAULT_LOCALE_SETTINGS };
    }

    try {
      const raw = JSON.parse(fs.readFileSync(this.filePath, "utf8")) as {
        ai?: Partial<AISettings>;
        map?: Partial<MapSettings>;
        locale?: Partial<LocaleSettings>;
      };
      return {
        ai: normalizeSettings(raw.ai),
        map: normalizeMapSettings(raw.map),
        locale: normalizeLocaleSettings(raw.locale),
      };
    } catch {
      return { ai: DEFAULT_AI_SETTINGS, map: DEFAULT_MAP_SETTINGS, locale: DEFAULT_LOCALE_SETTINGS };
    }
  }
}
