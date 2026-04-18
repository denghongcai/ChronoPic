import fs from "node:fs/promises";
import path from "node:path";

import { app } from "electron";

import { ChronoPicAppService } from "@chronopic/application";
import { ChronoPicDatabase } from "@chronopic/infra-db";
import { MediaFileService } from "@chronopic/infra-fs";
import { ThumbnailService } from "@chronopic/infra-image";
import { DisabledAIClient } from "@chronopic/services-ai-pipeline";
import { IndexerService } from "@chronopic/services-indexer";

export interface ChronoPicRuntime {
  appService: ChronoPicAppService;
  close: () => void;
}

export async function createRuntime(): Promise<ChronoPicRuntime> {
  const rootDataDir = path.join(app.getPath("userData"), "chronopic");
  const thumbsDir = path.join(rootDataDir, "thumbs");
  const dbPath = path.join(rootDataDir, "chronopic.sqlite");

  await fs.mkdir(rootDataDir, { recursive: true });
  await fs.mkdir(thumbsDir, { recursive: true });

  const db = new ChronoPicDatabase(dbPath);
  const mediaFiles = new MediaFileService();
  const thumbnails = new ThumbnailService(thumbsDir);
  const aiClient = new DisabledAIClient();
  const indexer = new IndexerService(db, mediaFiles, thumbnails);
  const appService = new ChronoPicAppService(db, indexer, aiClient);

  return {
    appService,
    close: () => db.close()
  };
}
