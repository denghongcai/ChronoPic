import type { Memory, PhotoRecord } from "@chronopic/domain";

export interface DiscoveryMatchSummary {
  labels: string[];
  description: string;
}

export function getDiscoveryMatchSummary(
  photo: PhotoRecord | null,
  memories: Memory[] = [],
  searchQuery?: string | null
): DiscoveryMatchSummary | null {
  const query = searchQuery?.trim().toLowerCase();
  if (!photo || !query) {
    return null;
  }

  const labels: string[] = [];

  maybePush(labels, "Filename", photo.photo.path.split("/").at(-1), query);
  maybePush(labels, "Caption", photo.semantic.caption, query);
  maybePush(labels, "Manual Tags", photo.semantic.labels.join(" "), query);
  maybePush(labels, "AI Caption", photo.semantic.generatedCaption, query);
  maybePush(labels, "AI Summary", photo.semantic.summary, query);
  maybePush(labels, "AI Tags", photo.semantic.generatedLabels.join(" "), query);

  for (const memory of memories) {
    maybePush(labels, "Memory Name", memory.name, query);
    maybePush(labels, "Memory Description", memory.description, query);
    maybePush(labels, "AI Memory Title", memory.generatedName, query);
    maybePush(labels, "AI Memory Summary", memory.generatedDescription, query);
    maybePush(labels, "AI Memory Tags", memory.generatedLabels.join(" "), query);
  }

  if (labels.length === 0) {
    return null;
  }

  return {
    labels,
    description: `Matched in ${labels.join(", ")}.`,
  };
}

function maybePush(
  labels: string[],
  label: string,
  value?: string | null,
  normalizedQuery?: string
) {
  const query = normalizedQuery ?? "";
  const haystack = value?.trim().toLowerCase();
  if (!haystack || !query || !haystack.includes(query) || labels.includes(label)) {
    return;
  }

  labels.push(label);
}
