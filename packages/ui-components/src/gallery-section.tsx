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
              <p className="text-lg font-semibold text-stone-900">No media matches the current filters</p>
              <p className="text-sm leading-6 text-stone-500">Adjust the query, remove a filter, or scan another folder to expand the result set.</p>
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
