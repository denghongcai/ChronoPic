import type { BrowseMode } from "@chronopic/domain";

import { Badge } from "./badge.js";
import { Panel } from "./panel.js";

const modeCopy: Record<Exclude<BrowseMode, "waterfall">, { description: string; eyebrow: string; title: string }> = {
  map: {
    eyebrow: "Map View",
    title: "Geospatial browsing is the next delivery step",
    description:
      "This view will render GPS-bearing photos on a Gaode map, support place-group exploration, and keep selection synchronized with the shared viewer flow.",
  },
  timeline: {
    eyebrow: "Timeline View",
    title: "Temporal browsing is queued after the map foundation",
    description:
      "This view will group photos by year, month, and day while preserving the same search, favorites, memory, and selection context as the waterfall shelf.",
  },
};

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
  const copy = modeCopy[mode];

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
          <p className="text-[11px] font-semibold uppercase tracking-[0.18em] text-stone-500">Current Scope</p>
          <p className="mt-2 text-2xl font-semibold tracking-tight text-stone-950">{currentScopeCount}</p>
          <p className="mt-1 text-sm text-stone-500">photos are in the current browse result set</p>
        </div>
        <div className="rounded-[24px] border border-stone-200 bg-stone-50/80 p-4">
          <p className="text-[11px] font-semibold uppercase tracking-[0.18em] text-stone-500">GPS Ready</p>
          <p className="mt-2 text-2xl font-semibold tracking-tight text-stone-950">{mappablePhotoCount}</p>
          <p className="mt-1 text-sm text-stone-500">photos currently have coordinates available for map/place exploration</p>
        </div>
        <div className="rounded-[24px] border border-stone-200 bg-stone-50/80 p-4">
          <p className="text-[11px] font-semibold uppercase tracking-[0.18em] text-stone-500">
            {mode === "map" ? "Place Groups" : "Timeline Ready"}
          </p>
          <p className="mt-2 text-2xl font-semibold tracking-tight text-stone-950">
            {mode === "map" ? placeGroupCount : timelineReadyCount}
          </p>
          <p className="mt-1 text-sm text-stone-500">
            {mode === "map"
              ? "local place buckets are already derivable from the current filtered GPS photos"
              : "photos currently have a datetime available for timeline grouping"}
          </p>
        </div>
      </div>
      <div className="px-5 pb-5">
        <div className="rounded-[24px] border border-dashed border-stone-300 bg-stone-50/70 px-5 py-4">
          <div className="flex flex-wrap items-center gap-2">
            <Badge tone="info">Phase In Progress</Badge>
            <p className="text-sm text-stone-700">
              The browse shell is now mode-aware. The next implementation step is to connect this mode to shared geospatial queries and the renderer-side map/timeline surfaces.
            </p>
          </div>
        </div>
      </div>
    </Panel>
  );
}
