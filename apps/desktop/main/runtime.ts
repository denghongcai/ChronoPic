import fs from "node:fs/promises";
import path from "node:path";

import { app } from "electron";

import type { AISettings } from "@chronopic/domain";
import { ChronoPicAppService } from "@chronopic/application";
import { ChronoPicDatabase } from "@chronopic/infra-db";
import { MediaFileService } from "@chronopic/infra-fs";
import { ThumbnailService } from "@chronopic/infra-image";
import { DisabledAIClient, VercelCompatibleAIClient } from "@chronopic/services-ai-pipeline";
import { IndexerService } from "@chronopic/services-indexer";

export interface ChronoPicRuntime {
  appService: ChronoPicAppService;
  close: () => void;
}

export async function createRuntime(options?: { aiSettings?: AISettings | null }): Promise<ChronoPicRuntime> {
  const rootDataDir = path.join(app.getPath("userData"), "chronopic");
  const thumbsDir = path.join(rootDataDir, "thumbs");
  const dbPath = path.join(rootDataDir, "chronopic.sqlite");

  await fs.mkdir(rootDataDir, { recursive: true });
  await fs.mkdir(thumbsDir, { recursive: true });

  const db = new ChronoPicDatabase(dbPath);
  db.recoverInterruptedAIProcessing();
  const mediaFiles = new MediaFileService();
  const thumbnails = new ThumbnailService(thumbsDir);
  const aiClient = createAIClientFromEnv(options?.aiSettings ?? null);
  const indexer = new IndexerService(db, mediaFiles, thumbnails, aiClient.isEnabled());
  const appService = new ChronoPicAppService(db, indexer, aiClient);

  return {
    appService,
    close: () => db.close()
  };
}

function createAIClientFromEnv(settings: AISettings | null) {
  const apiKey = process.env.CHRONOPIC_AI_API_KEY?.trim() || settings?.apiKey?.trim();
  const baseURL = process.env.CHRONOPIC_AI_BASE_URL?.trim() || settings?.baseURL?.trim();
  const model = process.env.CHRONOPIC_AI_MODEL?.trim() || settings?.model?.trim();

  if (!apiKey || !baseURL || !model) {
    return new DisabledAIClient();
  }

  return new VercelCompatibleAIClient({
    apiKey,
    baseURL,
    model,
    providerName: process.env.CHRONOPIC_AI_PROVIDER?.trim() || settings?.providerName?.trim() || "openai-compatible",
  });
}
