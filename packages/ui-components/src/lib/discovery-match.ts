import type { Memory, PhotoRecord } from "@chronopic/domain";
import { createTranslator } from "@chronopic/i18n";
import type { TranslationKey, TranslationValues } from "@chronopic/i18n";

export interface DiscoveryMatchSummary {
  labels: string[];
  description: string;
}

type Translator = (key: TranslationKey, values?: TranslationValues) => string;

const fallbackT: Translator = createTranslator("en-US");

export function getDiscoveryMatchSummary(
  photo: PhotoRecord | null,
  memories: Memory[] = [],
  searchQuery?: string | null,
  t: Translator = fallbackT
): DiscoveryMatchSummary | null {
  const query = searchQuery?.trim().toLowerCase();
  if (!photo || !query) {
    return null;
  }

  const labels: string[] = [];

  maybePush(labels, t("discovery.filename"), photo.photo.path.split("/").at(-1), query);
  maybePush(labels, t("discovery.caption"), photo.semantic.caption, query);
  maybePush(labels, t("discovery.manualTags"), photo.semantic.labels.join(" "), query);
  maybePush(labels, t("discovery.aiCaption"), photo.semantic.generatedCaption, query);
  maybePush(labels, t("discovery.aiSummary"), photo.semantic.summary, query);
  maybePush(labels, t("discovery.aiTags"), photo.semantic.generatedLabels.join(" "), query);

  for (const memory of memories) {
    maybePush(labels, t("discovery.memoryName"), memory.name, query);
    maybePush(labels, t("discovery.memoryDescription"), memory.description, query);
    maybePush(labels, t("discovery.aiMemoryTitle"), memory.generatedName, query);
    maybePush(labels, t("discovery.aiMemorySummary"), memory.generatedDescription, query);
    maybePush(labels, t("discovery.aiMemoryTags"), memory.generatedLabels.join(" "), query);
  }

  if (labels.length === 0) {
    return null;
  }

  return {
    labels,
    description: t("discovery.matchDescription", { labels: labels.join(", ") }),
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
