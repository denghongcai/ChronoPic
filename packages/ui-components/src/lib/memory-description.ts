function stripMarkdown(value: string): string {
  return value
    .replace(/```[\s\S]*?```/g, " ")
    .replace(/`([^`]+)`/g, "$1")
    .replace(/!\[[^\]]*]\([^)]*\)/g, " ")
    .replace(/\[([^\]]+)]\([^)]*\)/g, "$1")
    .replace(/^#{1,6}\s+/gm, "")
    .replace(/^>\s?/gm, "")
    .replace(/^[-*+]\s+/gm, "")
    .replace(/^\d+\.\s+/gm, "")
    .replace(/[*_~>#-]+/g, " ");
}

export function getMemoryDescriptionMarkdown(value: string | null): string {
  return value ?? "";
}

export function hasMemoryDescription(value: string | null): boolean {
  return getMemoryDescriptionPreview(value).length > 0;
}

export function getMemoryDescriptionPreview(value: string | null): string {
  if (!value) {
    return "";
  }

  return stripMarkdown(value).replace(/\s+/g, " ").trim();
}
