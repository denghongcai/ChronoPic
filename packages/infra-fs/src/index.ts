import crypto from "node:crypto";
import fs from "node:fs/promises";
import path from "node:path";

import exifr from "exifr";

import type { Metadata } from "@chronopic/domain";
import { ensureErrorMessage, normalizeAbsolutePath } from "@chronopic/shared-utils";

export const SUPPORTED_IMAGE_EXTENSIONS = new Set([".jpg", ".jpeg", ".png", ".webp", ".gif", ".heic", ".avif"]);
export const SUPPORTED_VIDEO_EXTENSIONS = new Set([".mp4", ".mov", ".m4v", ".webm"]);

const MIME_BY_EXTENSION: Record<string, string> = {
  ".avif": "image/avif",
  ".gif": "image/gif",
  ".heic": "image/heic",
  ".jpeg": "image/jpeg",
  ".jpg": "image/jpeg",
  ".m4v": "video/x-m4v",
  ".mov": "video/quicktime",
  ".mp4": "video/mp4",
  ".png": "image/png",
  ".webm": "video/webm",
  ".webp": "image/webp"
};

export interface MediaFileDescriptor {
  path: string;
  size: number;
  mime: string;
  createdAt: number;
  updatedAt: number;
}

export class MediaFileService {
  async scanDirectory(rootPath: string): Promise<string[]> {
    const resolvedRoot = normalizeAbsolutePath(rootPath);
    const results: string[] = [];

    await this.scanInto(resolvedRoot, results);
    results.sort((left, right) => left.localeCompare(right));
    return results;
  }

  async describeFile(filePath: string): Promise<MediaFileDescriptor> {
    const resolvedPath = normalizeAbsolutePath(filePath);
    const stats = await fs.stat(resolvedPath);
    const extension = path.extname(resolvedPath).toLowerCase();

    return {
      path: resolvedPath,
      size: stats.size,
      mime: MIME_BY_EXTENSION[extension] ?? "application/octet-stream",
      createdAt: stats.birthtimeMs || stats.ctimeMs || Date.now(),
      updatedAt: stats.mtimeMs || Date.now()
    };
  }

  async computeHash(filePath: string): Promise<string> {
    const buffer = await fs.readFile(filePath);
    return crypto.createHash("sha256").update(buffer).digest("hex");
  }

  async extractMetadata(filePath: string, fallbackTimestamp: number): Promise<Omit<Metadata, "photoId">> {
    const extension = path.extname(filePath).toLowerCase();

    if (!SUPPORTED_IMAGE_EXTENSIONS.has(extension)) {
      return {
        datetime: fallbackTimestamp,
        lat: null,
        lng: null,
        camera: null,
        confidence: 0.4,
        originalDatetimeText: null
      };
    }

    try {
      const parsed = (await exifr.parse(filePath)) as
        | {
            DateTimeOriginal?: Date;
            CreateDate?: Date;
            ModifyDate?: Date;
            latitude?: number;
            longitude?: number;
            Make?: string;
            Model?: string;
          }
        | undefined;

      const capturedDate = parsed?.DateTimeOriginal ?? parsed?.CreateDate ?? parsed?.ModifyDate ?? null;

      return {
        datetime: capturedDate ? capturedDate.getTime() : fallbackTimestamp,
        lat: parsed?.latitude ?? null,
        lng: parsed?.longitude ?? null,
        camera: [parsed?.Make, parsed?.Model].filter(Boolean).join(" ") || null,
        confidence: capturedDate ? 1 : 0.55,
        originalDatetimeText: capturedDate ? capturedDate.toISOString() : null
      };
    } catch (error) {
      return {
        datetime: fallbackTimestamp,
        lat: null,
        lng: null,
        camera: null,
        confidence: 0.2,
        originalDatetimeText: ensureErrorMessage(error)
      };
    }
  }

  isSupportedMedia(filePath: string): boolean {
    const extension = path.extname(filePath).toLowerCase();
    return SUPPORTED_IMAGE_EXTENSIONS.has(extension) || SUPPORTED_VIDEO_EXTENSIONS.has(extension);
  }

  listSupportedMedia(): string[] {
    return [...SUPPORTED_IMAGE_EXTENSIONS, ...SUPPORTED_VIDEO_EXTENSIONS].sort();
  }

  private async scanInto(currentPath: string, results: string[]): Promise<void> {
    const entries = await fs.readdir(currentPath, { withFileTypes: true });

    for (const entry of entries) {
      const entryPath = path.join(currentPath, entry.name);

      if (entry.isDirectory()) {
        await this.scanInto(entryPath, results);
        continue;
      }

      if (entry.isFile() && this.isSupportedMedia(entryPath)) {
        results.push(entryPath);
      }
    }
  }
}
