import fs from "node:fs/promises";
import path from "node:path";

import { nativeImage } from "electron";

import { safeFileKey } from "@chronopic/shared-utils";

export class ElectronThumbnailService {
  constructor(private readonly rootDir: string) {}

  async ensureReady(): Promise<void> {
    await fs.mkdir(this.rootDir, { recursive: true });
  }

  async generateThumbnail(sourcePath: string, mime: string, preferredKey: string): Promise<string> {
    await this.ensureReady();

    const key = safeFileKey(preferredKey);
    const isImage = mime.startsWith("image/");
    const extension = isImage ? ".jpg" : ".svg";
    const outputPath = path.join(this.rootDir, `${key}${extension}`);

    try {
      await fs.access(outputPath);
      return outputPath;
    } catch {
      if (isImage) {
        const image = nativeImage.createFromPath(sourcePath);

        if (!image.isEmpty()) {
          const resized = image.resize({ width: 480, height: 480, quality: "best" });
          await fs.writeFile(outputPath, resized.toJPEG(84));
          return outputPath;
        }
      }

      await fs.writeFile(outputPath, createPlaceholderSvg(path.basename(sourcePath)), "utf8");
      return outputPath;
    }
  }
}

function createPlaceholderSvg(label: string): string {
  return `<svg xmlns="http://www.w3.org/2000/svg" width="480" height="480" viewBox="0 0 480 480"><rect width="480" height="480" fill="#18252f"/><circle cx="240" cy="180" r="56" fill="#5ca2d1"/><rect x="120" y="300" width="240" height="20" rx="10" fill="#e5eef4"/><text x="240" y="360" font-size="20" font-family="sans-serif" text-anchor="middle" fill="#9db3c2">${escapeXml(
    label
  )}</text></svg>`;
}

function escapeXml(input: string): string {
  return input.replaceAll("&", "&amp;").replaceAll("<", "&lt;").replaceAll(">", "&gt;").replaceAll('"', "&quot;");
}
