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

function escapeHtml(value: string): string {
  return value
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");
}

function stripHtml(value: string): string {
  return value
    .replace(/<br\s*\/?>/gi, " ")
    .replace(/<\/p>/gi, " ")
    .replace(/<[^>]+>/g, "")
    .replace(/&nbsp;/g, " ")
    .replace(/&amp;/g, "&")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&quot;/g, '"')
    .replace(/&#039;/g, "'");
}

function sanitizeDescriptionHtml(value: string): string {
  return value
    .replace(/<script[\s\S]*?>[\s\S]*?<\/script>/gi, "")
    .replace(/<style[\s\S]*?>[\s\S]*?<\/style>/gi, "")
    .replace(/\son\w+="[^"]*"/gi, "")
    .replace(/\son\w+='[^']*'/gi, "")
    .replace(/\s(href|src)="javascript:[^"]*"/gi, "")
    .replace(/\s(href|src)='javascript:[^']*'/gi, "");
}

function isHtml(value: string): boolean {
  return /<\/?[a-z][\s\S]*>/i.test(value);
}

export function getMemoryDescriptionHtml(value: string | null): string {
  if (!value) {
    return "<p></p>";
  }

  try {
    const parsed = JSON.parse(value) as Array<{ content?: unknown }>;
    if (Array.isArray(parsed)) {
      const paragraphs = parsed.map((block) => extractTextFromContent(block?.content).trim());
      return paragraphs.length > 0
        ? paragraphs.map((paragraph) => `<p>${escapeHtml(paragraph)}</p>`).join("")
        : "<p></p>";
    }
  } catch {
    // Non-JSON values are either saved HTML from Tiptap or legacy plain text.
  }

  if (isHtml(value)) {
    return sanitizeDescriptionHtml(value);
  }

  return `<p>${escapeHtml(value)}</p>`;
}

export function hasMemoryDescription(value: string | null): boolean {
  return getMemoryDescriptionPreview(value).length > 0;
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
    return stripHtml(value).replace(/\s+/g, " ").trim();
  }
}
