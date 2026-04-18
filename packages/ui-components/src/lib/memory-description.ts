import type { PartialBlock } from "@blocknote/core";

function extractTextFromContent(content: unknown): string {
  if (typeof content === "string") {
    return content;
  }

  if (!Array.isArray(content)) {
    return "";
  }

  return content
    .map((item) => {
      if (typeof item === "string") {
        return item;
      }

      if (item && typeof item === "object" && "text" in item && typeof item.text === "string") {
        return item.text;
      }

      return "";
    })
    .join(" ");
}

export function defaultMemoryBlocks(): PartialBlock[] {
  return [{ type: "paragraph", content: "" }];
}

export function parseMemoryBlocks(value: string | null): PartialBlock[] {
  if (!value) {
    return defaultMemoryBlocks();
  }

  try {
    const parsed = JSON.parse(value) as PartialBlock[];
    return Array.isArray(parsed) && parsed.length > 0 ? parsed : defaultMemoryBlocks();
  } catch {
    return [{ type: "paragraph", content: value }];
  }
}

export function getMemoryDescriptionPreview(value: string | null): string {
  if (!value) {
    return "";
  }

  try {
    const parsed = JSON.parse(value) as Array<{ content?: unknown }>;
    if (!Array.isArray(parsed)) {
      return "";
    }

    return parsed
      .map((block) => extractTextFromContent(block?.content))
      .join(" ")
      .replace(/\s+/g, " ")
      .trim();
  } catch {
    return value.trim();
  }
}
