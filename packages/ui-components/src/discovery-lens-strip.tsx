import { CalendarDays, Heart, MapPinned, Search, Sparkles, Tag } from "lucide-react";

import type { BrowseMode, Memory, PhotoFilter, PhotoFilterPatch, PhotoRecord, PlaceGroup } from "@chronopic/domain";

import { Badge } from "./badge.js";
import { Button } from "./button.js";
import { buildDiscoverySuggestions, type DiscoverySuggestion } from "./lib/discovery-suggestions.js";

export interface DiscoveryLensStripProps {
  filter: PhotoFilter;
  memories: Memory[];
  photos: PhotoRecord[];
  placeGroups: PlaceGroup[];
  onBrowseModeChange: (mode: BrowseMode) => void;
  onFilterChange: (patch: PhotoFilterPatch) => void;
  onOpenMemory: (memoryId: string) => void;
}

function getSuggestionIcon(suggestion: DiscoverySuggestion) {
  if (suggestion.kind === "memory") {
    return Heart;
  }

  if (suggestion.mode === "map") {
    return MapPinned;
  }

  if (suggestion.mode === "timeline") {
    return CalendarDays;
  }

  if (suggestion.id.includes("ai")) {
    return Sparkles;
  }

  if (suggestion.id.startsWith("tag:")) {
    return Tag;
  }

  return Search;
}

export function DiscoveryLensStrip({
  filter,
  memories,
  photos,
  placeGroups,
  onBrowseModeChange,
  onFilterChange,
  onOpenMemory,
}: DiscoveryLensStripProps) {
  const suggestions = buildDiscoverySuggestions({ filter, memories, photos, placeGroups }).filter(
    (suggestion) => suggestion.kind === "memory" || suggestion.kind === "mode"
  );

  if (suggestions.length === 0) {
    return null;
  }

  return (
    <div className="flex select-none flex-wrap items-center gap-2">
      <Badge tone="neutral">Discover</Badge>
      {suggestions.map((suggestion) => {
        const Icon = getSuggestionIcon(suggestion);

        return (
          <Button
            className="rounded-full"
            key={suggestion.id}
            onClick={() => {
              if (suggestion.mode) {
                onBrowseModeChange(suggestion.mode);
                return;
              }

              if (suggestion.memoryId) {
                onOpenMemory(suggestion.memoryId);
                return;
              }

              if (suggestion.patch) {
                onFilterChange(suggestion.patch);
              }
            }}
            size="sm"
            variant="outline"
          >
            <Icon className="h-4 w-4" />
            <span>{suggestion.label}</span>
            <span className="text-stone-400">{suggestion.detail}</span>
          </Button>
        );
      })}
    </div>
  );
}
