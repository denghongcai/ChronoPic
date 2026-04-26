import type { AIPipelineStatus, PhotoFilter } from "@chronopic/domain";
import { createTranslator } from "@chronopic/i18n";
import type { TranslationKey, TranslationValues } from "@chronopic/i18n";

import type { BadgeTone } from "../badge.js";

export interface DiscoveryContextBadge {
  label: string;
  tone: BadgeTone;
}

export interface DiscoveryContext {
  badges: DiscoveryContextBadge[];
  description: string;
}

type Translator = (key: TranslationKey, values?: TranslationValues) => string;

const fallbackT: Translator = createTranslator("en-US");

export function getDiscoveryContext(
  filter: PhotoFilter,
  options: { activeMemoryName?: string | null; t?: Translator } = {}
): DiscoveryContext | null {
  const t = options.t ?? fallbackT;
  const badges: DiscoveryContextBadge[] = [];
  const descriptionParts: string[] = [];

  const activeMemoryName = options.activeMemoryName?.trim();

  if (activeMemoryName || filter.memoryId) {
    badges.push({ label: activeMemoryName ? activeMemoryName : t("discovery.memoryScope"), tone: "info" });
    descriptionParts.push(
      activeMemoryName
        ? t("discovery.browsingMemory", { name: activeMemoryName })
        : t("discovery.browsingMemoryScope")
    );
  }

  if (filter.favorite) {
    badges.push({ label: t("sidebar.favorites"), tone: "neutral" });
    descriptionParts.push(t("discovery.favoritesDescription"));
  }

  if (filter.query) {
    badges.push({ label: t("discovery.searchBadge", { query: filter.query }), tone: "info" });
    descriptionParts.push(
      t("discovery.searchDescription", { query: filter.query })
    );
  }

  if (filter.tag) {
    badges.push({ label: t("discovery.tagBadge", { tag: filter.tag }), tone: "neutral" });
    descriptionParts.push(t("discovery.tagDescription", { tag: filter.tag }));
  }

  if (filter.mimePrefix) {
    badges.push({
      label: filter.mimePrefix === "image" ? t("discovery.photosOnly") : filter.mimePrefix === "video" ? t("discovery.videosOnly") : t("discovery.mimeOnly", { mime: filter.mimePrefix }),
      tone: "neutral",
    });
  }

  if (filter.hasGps) {
    badges.push({ label: t("discovery.withGps"), tone: "info" });
  }

  if (filter.indexed) {
    badges.push({ label: t("discovery.indexed"), tone: "neutral" });
  }

  if (filter.hasError) {
    badges.push({ label: t("discovery.errorsOnly"), tone: "warn" });
  }

  if (filter.aiStatus) {
    for (const status of Array.isArray(filter.aiStatus) ? filter.aiStatus : [filter.aiStatus]) {
      badges.push({ label: aiStatusLabel(status, t), tone: aiStatusTone(status) });
    }
  }

  if (filter.fromDatetime != null || filter.toDatetime != null) {
    badges.push({ label: t("discovery.dateRange"), tone: "neutral" });
  }

  if (badges.length === 0 && descriptionParts.length === 0) {
    return null;
  }

  return {
    badges,
    description:
      descriptionParts.join(" ") ||
      t("discovery.defaultDescription"),
  };
}

function aiStatusLabel(status: AIPipelineStatus, t: Translator): string {
  switch (status) {
    case "completed":
      return t("discovery.aiReady");
    case "pending":
      return t("discovery.needsAi");
    case "processing":
      return t("discovery.aiProcessing");
    case "failed":
      return t("discovery.aiFailed");
    case "disabled":
      return t("discovery.aiDisabled");
    default:
      return status;
  }
}

function aiStatusTone(status: AIPipelineStatus): BadgeTone {
  switch (status) {
    case "completed":
      return "info";
    case "pending":
      return "warn";
    case "processing":
      return "neutral";
    case "failed":
      return "warn";
    case "disabled":
      return "neutral";
    default:
      return "neutral";
  }
}
