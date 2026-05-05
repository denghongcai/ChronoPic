import path from "node:path";

import { app } from "electron";

export function getChronoPicDataDir(): string {
  const override = process.env.CHRONOPIC_USER_DATA_DIR?.trim();
  return override ? path.resolve(override) : path.join(app.getPath("userData"), "chronopic");
}

export function getChronoPicThumbsDir(): string {
  return path.join(getChronoPicDataDir(), "thumbs");
}

export function getChronoPicDbPath(): string {
  return path.join(getChronoPicDataDir(), "chronopic.sqlite");
}

export function getChronoPicSettingsPath(): string {
  return path.join(getChronoPicDataDir(), "settings.json");
}

export function getChronoPicDebugLogPath(): string {
  return path.join(getChronoPicDataDir(), "debug.log");
}
