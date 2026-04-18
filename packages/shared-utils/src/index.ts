import crypto from "node:crypto";
import path from "node:path";

export function createId(prefix: string): string {
  return `${prefix}_${crypto.randomUUID()}`;
}

export function normalizeAbsolutePath(input: string): string {
  return path.resolve(input);
}

export function ensureErrorMessage(error: unknown): string {
  if (error instanceof Error) {
    return error.message;
  }

  if (typeof error === "string") {
    return error;
  }

  return "Unknown error";
}

export function serializeStringArray(values: string[]): string {
  return JSON.stringify(values);
}

export function parseStringArray(value: string | null | undefined): string[] {
  if (!value) {
    return [];
  }

  try {
    const parsed = JSON.parse(value) as unknown;
    return Array.isArray(parsed) ? parsed.filter((item): item is string => typeof item === "string") : [];
  } catch {
    return [];
  }
}

export function dedupeStrings(values: string[]): string[] {
  return [...new Set(values.map((value) => value.trim()).filter(Boolean))];
}

export function formatMonthKey(timestamp: number | null): string {
  if (!timestamp) {
    return "Unknown";
  }

  const date = new Date(timestamp);
  return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, "0")}`;
}

export function clamp(value: number, min: number, max: number): number {
  return Math.min(Math.max(value, min), max);
}

export async function runWithConcurrency<T>(
  items: T[],
  concurrency: number,
  handler: (item: T, index: number) => Promise<void>
): Promise<void> {
  const limit = clamp(concurrency, 1, Math.max(1, items.length || 1));
  let cursor = 0;

  const workers = Array.from({ length: limit }, async () => {
    while (cursor < items.length) {
      const currentIndex = cursor;
      cursor += 1;
      const item = items[currentIndex];

      if (item !== undefined) {
        await handler(item, currentIndex);
      }
    }
  });

  await Promise.all(workers);
}

export function safeFileKey(input: string): string {
  return crypto.createHash("sha1").update(input).digest("hex");
}
