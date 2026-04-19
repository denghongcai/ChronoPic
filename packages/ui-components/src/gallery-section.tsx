import type { Memory, PhotoRecord } from "@chronopic/domain";

import type { PhotoFilter, PhotoFilterPatch } from "@chronopic/domain";

import { AddToMemoryMenu } from "./add-to-memory-menu.js";
import { Badge } from "./badge.js";
import { Button } from "./button.js";
import { FilterToolbar } from "./filter-toolbar.js";
import { Panel } from "./panel.js";
import { PhotoCard } from "./photo-card.js";

export interface GallerySectionProps {
  photos: PhotoRecord[];
  activeMemory?: Memory | null;
  selectedPhotoMemories?: Memory[];
  selectedPhotoId?: string | null;
  selectedPhotoIds?: string[];
  selectionMode?: boolean;
  filter: PhotoFilter;
  onFilterChange: (patch: PhotoFilterPatch) => void;
  onSelect?: (photoId: string) => void;
  onOpenDetail?: (photoId: string) => void;
  onToggleFavorite?: (photoId: string, favorite: boolean) => void;
  memories?: Memory[];
  onAddToMemory?: (memoryId: string, photoId: string) => void;
  onAddSelectionToMemory?: (memoryId: string, photoIds: string[]) => void | Promise<void>;
  onToggleBatchSelect?: (photoId: string) => void;
  onClearBatchSelection?: () => void;
  onSelectionModeChange?: (active: boolean) => void;
}

export function GallerySection({
  photos,
  activeMemory,
  selectedPhotoMemories = [],
  selectedPhotoId,
  selectedPhotoIds = [],
  selectionMode = false,
  filter,
  onFilterChange,
  onSelect,
  onOpenDetail,
  onToggleFavorite,
  memories = [],
  onAddToMemory,
  onAddSelectionToMemory,
  onToggleBatchSelect,
  onClearBatchSelection,
  onSelectionModeChange,
}: GallerySectionProps) {
  const hasBatchSelection = selectedPhotoIds.length > 0;
  const isSelecting = selectionMode || hasBatchSelection;
  const hasStructuredFilters = Boolean(
    filter.query ||
      filter.favorite ||
      filter.memoryId ||
      filter.hasError ||
      filter.indexed ||
      filter.hasGps ||
      filter.mimePrefix ||
      filter.tag
  );

  const emptyTitle = activeMemory
    ? `${activeMemory.name} has no visible photos`
    : filter.favorite
      ? "No favorite photos match the current filters"
      : filter.query
        ? "No media matches this search"
        : "No media matches the current filters";

  const emptyDescription = activeMemory
    ? "Add photos to this memory from the gallery or viewer, or loosen the current query to reveal more of this memory."
    : filter.favorite
      ? "Try clearing a filter or favorite a few photos first so this shelf has something to show."
      : filter.query
        ? "Try a broader search term, remove a label/type filter, or scan another folder."
        : "Adjust the query, remove a filter, or scan another folder to expand the result set.";

  return (
    <Panel className="overflow-hidden">
      <div className="flex items-center justify-between border-b border-stone-200/70 px-5 py-4">
        <div>
          <p className="text-[11px] font-semibold uppercase tracking-[0.22em] text-stone-500">Gallery</p>
          <h2 className="mt-2 font-['Space_Grotesk','IBM_Plex_Sans',sans-serif] text-2xl font-semibold tracking-tight text-stone-950">
            Browse results
          </h2>
          <p className="mt-2 text-sm text-stone-500">Click to inspect, double-click or press Enter to open a focused view.</p>
        </div>
        <div className="flex items-center gap-2">
          <Button
            onClick={() => {
              if (isSelecting) {
                onClearBatchSelection?.();
                onSelectionModeChange?.(false);
                return;
              }

              onSelectionModeChange?.(true);
            }}
            size="sm"
            variant={isSelecting ? "accent" : "outline"}
          >
            {isSelecting ? "Done" : "Select"}
          </Button>
          <Badge tone="neutral">{photos.length} items</Badge>
        </div>
      </div>

      <div className="border-b border-stone-200/70 p-5">
        <FilterToolbar filter={filter} onChange={onFilterChange} />
      </div>

      <div className="p-5">
        {activeMemory || hasStructuredFilters ? (
          <div className="mb-4 flex flex-wrap items-center gap-2 rounded-[24px] border border-stone-200 bg-stone-50/80 px-4 py-3">
            <Badge tone={activeMemory ? "info" : "neutral"}>{activeMemory ? "Memory Scope" : "Filtered View"}</Badge>
            <p className="text-sm text-stone-700">
              {activeMemory
                ? `Browsing photos inside ${activeMemory.name}.`
                : filter.favorite
                  ? "Browsing favorite photos."
                  : filter.query
                    ? `Search active: “${filter.query}”.`
                    : "Structured filters are narrowing the current media shelf."}
            </p>
          </div>
        ) : null}

        {!isSelecting && selectedPhotoId ? (
          <div className="mb-4 rounded-[24px] border border-sky-200 bg-sky-50/80 px-4 py-3">
            <div className="flex flex-wrap items-center gap-2">
              <Badge tone="info">Selected Photo</Badge>
              {selectedPhotoMemories.length === 0 ? (
                <p className="text-sm text-sky-900">This photo is not saved to any memory yet.</p>
              ) : (
                <>
                  <p className="text-sm text-sky-900">Saved to:</p>
                  {selectedPhotoMemories.map((memory) => (
                    <Badge key={memory.id} tone={memory.coverPhotoId === selectedPhotoId ? "info" : "neutral"}>
                      {memory.name}
                      {memory.coverPhotoId === selectedPhotoId ? " cover" : ""}
                    </Badge>
                  ))}
                </>
              )}
            </div>
          </div>
        ) : null}

        {hasBatchSelection ? (
          <div className="mb-4 flex flex-wrap items-center justify-between gap-3 rounded-[24px] border border-amber-200 bg-amber-50 px-4 py-3">
            <div className="flex items-center gap-2">
              <Badge tone="warn">{selectedPhotoIds.length} selected</Badge>
              <p className="text-sm font-medium text-amber-950">Batch actions for selected photos</p>
            </div>
            <div className="flex items-center gap-2">
              {onAddSelectionToMemory ? (
                <AddToMemoryMenu
                  buttonVariant="accent"
                  label="Add Selected to Memory"
                  memories={memories}
                  onAddToMemory={async (memoryId) => {
                    await onAddSelectionToMemory(memoryId, selectedPhotoIds);
                    onSelectionModeChange?.(false);
                  }}
                />
              ) : null}
              <Button onClick={onClearBatchSelection} size="sm" variant="outline">
                Clear Selection
              </Button>
            </div>
          </div>
        ) : null}
        {photos.length === 0 ? (
          <div className="grid min-h-[360px] place-items-center rounded-[24px] border border-dashed border-stone-300 bg-stone-50/70 px-6 text-center">
            <div className="max-w-sm space-y-3">
              <p className="text-lg font-semibold text-stone-900">{emptyTitle}</p>
              <p className="text-sm leading-6 text-stone-500">{emptyDescription}</p>
            </div>
          </div>
        ) : (
          <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-3 2xl:grid-cols-4">
            {photos.map((record) => (
              <PhotoCard
                key={record.photo.id}
                {...(onAddToMemory && { memories, onAddToMemory })}
                batchSelected={selectedPhotoIds.includes(record.photo.id)}
                onOpenDetail={() => {
                  if (!isSelecting) {
                    onOpenDetail?.(record.photo.id);
                  }
                }}
                onSelect={() => {
                  if (isSelecting && onToggleBatchSelect) {
                    onToggleBatchSelect(record.photo.id);
                    return;
                  }

                  onSelect?.(record.photo.id);
                }}
                {...(isSelecting && onToggleBatchSelect && { onToggleBatchSelect })}
                {...(onToggleFavorite && { onToggleFavorite })}
                record={record}
                selected={selectedPhotoId === record.photo.id}
                showHoverActions
              />
            ))}
          </div>
        )}
      </div>
    </Panel>
  );
}
