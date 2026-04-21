import fs from "node:fs";
import path from "node:path";

import type { AISettings, MapSettings } from "@chronopic/domain";

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

export class ChronoPicConfigStore {
  constructor(private readonly filePath: string) {}

  getAISettings(): AISettings {
    return this.read().ai;
  }

  getMapSettings(): MapSettings {
    return this.read().map;
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

  private read(): { ai: AISettings; map: MapSettings } {
    if (!fs.existsSync(this.filePath)) {
      return { ai: DEFAULT_AI_SETTINGS, map: DEFAULT_MAP_SETTINGS };
    }

    try {
      const raw = JSON.parse(fs.readFileSync(this.filePath, "utf8")) as {
        ai?: Partial<AISettings>;
        map?: Partial<MapSettings>;
      };
      return {
        ai: normalizeSettings(raw.ai),
        map: normalizeMapSettings(raw.map),
      };
    } catch {
      return { ai: DEFAULT_AI_SETTINGS, map: DEFAULT_MAP_SETTINGS };
    }
  }
}
