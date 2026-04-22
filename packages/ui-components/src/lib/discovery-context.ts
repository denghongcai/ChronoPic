import type { AIPipelineStatus, PhotoFilter } from "@chronopic/domain";

import type { BadgeTone } from "../badge.js";

export interface DiscoveryContextBadge {
  label: string;
  tone: BadgeTone;
}

export interface DiscoveryContext {
  badges: DiscoveryContextBadge[];
  description: string;
}

export function getDiscoveryContext(
  filter: PhotoFilter,
  options: { activeMemoryName?: string | null } = {}
): DiscoveryContext | null {
  const badges: DiscoveryContextBadge[] = [];
  const descriptionParts: string[] = [];

  const activeMemoryName = options.activeMemoryName?.trim();

  if (activeMemoryName || filter.memoryId) {
    badges.push({ label: activeMemoryName ? activeMemoryName : "Memory scope", tone: "info" });
    descriptionParts.push(
      activeMemoryName
        ? `Browsing photos inside ${activeMemoryName}.`
        : "Browsing photos inside the current memory scope."
    );
  }

  if (filter.favorite) {
    badges.push({ label: "Favorites", tone: "neutral" });
    descriptionParts.push("Only favorite photos are included.");
  }

  if (filter.query) {
    badges.push({ label: `Search: ${filter.query}`, tone: "info" });
    descriptionParts.push(
      `Search is matching filenames, manual metadata, AI-generated captions, summaries, tags, and linked memory metadata for “${filter.query}”.`
    );
  }

  if (filter.tag) {
    badges.push({ label: `Tag: ${filter.tag}`, tone: "neutral" });
  }

  if (filter.mimePrefix) {
    badges.push({
      label: filter.mimePrefix === "image" ? "Photos only" : filter.mimePrefix === "video" ? "Videos only" : `${filter.mimePrefix} only`,
      tone: "neutral",
    });
  }

  if (filter.hasGps) {
    badges.push({ label: "With GPS", tone: "info" });
  }

  if (filter.indexed) {
    badges.push({ label: "Indexed", tone: "neutral" });
  }

  if (filter.hasError) {
    badges.push({ label: "Errors only", tone: "warn" });
  }

  if (filter.aiStatus) {
    for (const status of Array.isArray(filter.aiStatus) ? filter.aiStatus : [filter.aiStatus]) {
      badges.push({ label: aiStatusLabel(status), tone: aiStatusTone(status) });
    }
  }

  if (filter.fromDatetime != null || filter.toDatetime != null) {
    badges.push({ label: "Date range", tone: "neutral" });
  }

  if (badges.length === 0 && descriptionParts.length === 0) {
    return null;
  }

  return {
    badges,
    description:
      descriptionParts.join(" ") ||
      "The current browse surface is reflecting the active discovery filters.",
  };
}

function aiStatusLabel(status: AIPipelineStatus): string {
  switch (status) {
    case "completed":
      return "AI Ready";
    case "pending":
      return "Needs AI";
    case "processing":
      return "AI Processing";
    case "failed":
      return "AI Failed";
    case "disabled":
      return "AI Disabled";
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
