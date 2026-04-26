import type { BrowseMode, Memory, PhotoFilter, PhotoFilterPatch, PhotoRecord, PlaceGroup } from "@chronopic/domain";
import { createTranslator } from "@chronopic/i18n";
import type { TranslationKey, TranslationValues } from "@chronopic/i18n";

export type DiscoverySuggestionKind = "filter" | "memory" | "mode" | "search";

export interface DiscoverySuggestion {
  id: string;
  kind: DiscoverySuggestionKind;
  label: string;
  detail: string;
  patch?: PhotoFilterPatch;
  memoryId?: string;
  mode?: BrowseMode;
  query?: string;
}

type Translator = (key: TranslationKey, values?: TranslationValues) => string;

const fallbackT: Translator = createTranslator("en-US");

function collectTopLabels(records: PhotoRecord[], limit: number): Array<{ label: string; count: number }> {
  const counts = new Map<string, number>();

  for (const record of records) {
    const labels = new Set([...record.semantic.labels, ...record.semantic.generatedLabels]);

    for (const label of labels) {
      const normalized = label.trim();
      if (normalized.length === 0) {
        continue;
      }

      counts.set(normalized, (counts.get(normalized) ?? 0) + 1);
    }
  }

  return [...counts.entries()]
    .sort((left, right) => right[1] - left[1] || left[0].localeCompare(right[0]))
    .slice(0, limit)
    .map(([label, count]) => ({ label, count }));
}

export function buildDiscoverySuggestions({
  filter,
  memories,
  photos,
  placeGroups,
  t = fallbackT,
}: {
  filter: PhotoFilter;
  memories: Memory[];
  photos: PhotoRecord[];
  placeGroups: PlaceGroup[];
  t?: Translator;
}): DiscoverySuggestion[] {
  const suggestions: DiscoverySuggestion[] = [];
  const gpsCount = photos.filter((record) => record.metadata.lat != null && record.metadata.lng != null).length;
  const favoriteCount = photos.filter((record) => record.photo.favorite).length;
  const aiReadyCount = photos.filter((record) => record.semantic.aiStatus === "completed").length;
  const needAiCount = photos.filter((record) => record.semantic.aiStatus === "pending" || record.semantic.aiStatus === "disabled").length;
  const timelineReadyCount = photos.filter((record) => record.metadata.datetime != null).length;

  if (!filter.hasGps && gpsCount > 0) {
    suggestions.push({
      id: "filter:gps",
      kind: "filter",
      label: t("discovery.withGps"),
      detail: t("discovery.withGpsDetail", { count: gpsCount }),
      patch: { hasGps: true, offset: 0 },
    });
  }

  if (!filter.favorite && favoriteCount > 0) {
    suggestions.push({
      id: "filter:favorites",
      kind: "filter",
      label: t("sidebar.favorites"),
      detail: t("discovery.favoritesDetail", { count: favoriteCount }),
      patch: { favorite: true, offset: 0 },
    });
  }

  if (filter.aiStatus !== "completed" && aiReadyCount > 0) {
    suggestions.push({
      id: "filter:ai-ready",
      kind: "filter",
      label: t("discovery.aiReady"),
      detail: t("discovery.aiReadyDetail", { count: aiReadyCount }),
      patch: { aiStatus: "completed", offset: 0 },
    });
  }

  if (filter.aiStatus !== "pending" && needAiCount > 0) {
    suggestions.push({
      id: "filter:needs-ai",
      kind: "filter",
      label: t("discovery.needsAi"),
      detail: t("discovery.needsAiDetail", { count: needAiCount }),
      patch: { aiStatus: "pending", offset: 0 },
    });
  }

  if (placeGroups.length > 0) {
    suggestions.push({
      id: "mode:map",
      kind: "mode",
      label: t("browse.mode.map"),
      detail: t("discovery.mapDetail", { count: placeGroups.length }),
      mode: "map",
    });
  }

  if (timelineReadyCount > 0) {
    suggestions.push({
      id: "mode:timeline",
      kind: "mode",
      label: t("browse.mode.timeline"),
      detail: t("discovery.timelineDetail", { count: timelineReadyCount }),
      mode: "timeline",
    });
  }

  for (const item of collectTopLabels(photos, 4)) {
    if (filter.tag === item.label || filter.query === item.label) {
      continue;
    }

    suggestions.push({
      id: `tag:${item.label}`,
      kind: "search",
      label: item.label,
      detail: t("discovery.matchesDetail", { count: item.count }),
      patch: { tag: item.label, offset: 0 },
      query: item.label,
    });
  }

  for (const memory of memories.filter((item) => item.photoCount > 0 && item.id !== filter.memoryId).slice(0, 3)) {
    suggestions.push({
      id: `memory:${memory.id}`,
      kind: "memory",
      label: memory.name,
      detail: t("discovery.photosDetail", { count: memory.photoCount }),
      memoryId: memory.id,
    });
  }

  return suggestions.slice(0, 10);
}
