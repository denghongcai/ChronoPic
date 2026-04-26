import type { BrowseMode } from "@chronopic/domain";

import { Badge } from "./badge.js";
import { useI18n } from "./i18n-provider.js";
import { Panel } from "./panel.js";

export interface BrowseModePlaceholderProps {
  mode: Exclude<BrowseMode, "waterfall">;
  currentScopeCount: number;
  mappablePhotoCount: number;
  placeGroupCount: number;
  timelineReadyCount: number;
}

export function BrowseModePlaceholder({
  mode,
  currentScopeCount,
  mappablePhotoCount,
  placeGroupCount,
  timelineReadyCount,
}: BrowseModePlaceholderProps) {
  const { t } = useI18n();
  const copy = {
    eyebrow: mode === "map" ? t("map.view") : t("timeline.view"),
    title: mode === "map" ? t("browsePlaceholder.mapTitle") : t("browsePlaceholder.timelineTitle"),
    description: mode === "map" ? t("browsePlaceholder.mapDescription") : t("browsePlaceholder.timelineDescription"),
  };

  return (
    <Panel className="overflow-hidden">
      <div className="border-b border-stone-200/70 px-5 py-4">
        <p className="text-[11px] font-semibold uppercase tracking-[0.22em] text-stone-500">{copy.eyebrow}</p>
        <h2 className="mt-2 font-['Space_Grotesk','IBM_Plex_Sans',sans-serif] text-2xl font-semibold tracking-tight text-stone-950">
          {copy.title}
        </h2>
        <p className="mt-2 max-w-3xl text-sm leading-6 text-stone-500">{copy.description}</p>
      </div>
      <div className="grid gap-4 p-5 md:grid-cols-3">
        <div className="rounded-[24px] border border-stone-200 bg-stone-50/80 p-4">
          <p className="text-[11px] font-semibold uppercase tracking-[0.18em] text-stone-500">{t("browsePlaceholder.currentScope")}</p>
          <p className="mt-2 text-2xl font-semibold tracking-tight text-stone-950">{currentScopeCount}</p>
          <p className="mt-1 text-sm text-stone-500">{t("browsePlaceholder.currentScopeDescription")}</p>
        </div>
        <div className="rounded-[24px] border border-stone-200 bg-stone-50/80 p-4">
          <p className="text-[11px] font-semibold uppercase tracking-[0.18em] text-stone-500">{t("browsePlaceholder.gpsReady")}</p>
          <p className="mt-2 text-2xl font-semibold tracking-tight text-stone-950">{mappablePhotoCount}</p>
          <p className="mt-1 text-sm text-stone-500">{t("browsePlaceholder.gpsReadyDescription")}</p>
        </div>
        <div className="rounded-[24px] border border-stone-200 bg-stone-50/80 p-4">
          <p className="text-[11px] font-semibold uppercase tracking-[0.18em] text-stone-500">
            {mode === "map" ? t("browsePlaceholder.placeGroups") : t("browsePlaceholder.timelineReady")}
          </p>
          <p className="mt-2 text-2xl font-semibold tracking-tight text-stone-950">
            {mode === "map" ? placeGroupCount : timelineReadyCount}
          </p>
          <p className="mt-1 text-sm text-stone-500">
            {mode === "map"
              ? t("browsePlaceholder.placeGroupsDescription")
              : t("browsePlaceholder.timelineReadyDescription")}
          </p>
        </div>
      </div>
      <div className="px-5 pb-5">
        <div className="rounded-[24px] border border-dashed border-stone-300 bg-stone-50/70 px-5 py-4">
          <div className="flex flex-wrap items-center gap-2">
            <Badge tone="info">{t("browsePlaceholder.phaseInProgress")}</Badge>
            <p className="text-sm text-stone-700">{t("browsePlaceholder.phaseDescription")}</p>
          </div>
        </div>
      </div>
    </Panel>
  );
}
