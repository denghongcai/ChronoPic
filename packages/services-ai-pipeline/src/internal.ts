export function normalizeLabels(labels: unknown): string[] {
  if (!Array.isArray(labels)) {
    return [];
  }

  return Array.from(
    new Set(
      labels
        .map((value) => (typeof value === "string" ? value.trim() : ""))
        .filter(Boolean)
        .slice(0, 12)
    )
  );
}

export function normalizeText(value: unknown): string | null {
  if (typeof value !== "string") {
    return null;
  }

  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : null;
}

export function extractJsonObject(input: string): Record<string, unknown> | null {
  const trimmed = input.replace(/<think>[\s\S]*?<\/think>/gi, "").trim();

  if (trimmed.startsWith("{") && trimmed.endsWith("}")) {
    try {
      return JSON.parse(trimmed) as Record<string, unknown>;
    } catch {
      // Fall through to fenced extraction.
    }
  }

  const fenced = trimmed.match(/```(?:json)?\s*([\s\S]*?)```/i);
  if (fenced?.[1]) {
    try {
      return JSON.parse(fenced[1]) as Record<string, unknown>;
    } catch {
      return null;
    }
  }

  const candidates = trimmed.match(/\{[\s\S]*?\}/g) ?? [];
  for (let index = candidates.length - 1; index >= 0; index -= 1) {
    try {
      return JSON.parse(candidates[index]!) as Record<string, unknown>;
    } catch {
      continue;
    }
  }

  return null;
}
