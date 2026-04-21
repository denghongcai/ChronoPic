import type { Memory, PhotoFilter, PhotoRecord } from "@chronopic/domain";

import { AddToMemoryMenu } from "./add-to-memory-menu.js";
import { Badge } from "./badge.js";
import { Button } from "./button.js";
import { PhotoCard } from "./photo-card.js";

export interface GallerySectionProps {
  photos: PhotoRecord[];
  filter: PhotoFilter;
  activeMemory?: Memory | null;
  selectedPhotoMemories?: Memory[];
  selectedPhotoId?: string | null;
  selectedPhotoIds?: string[];
  selectionMode?: boolean;
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
  filter,
  activeMemory,
  selectedPhotoMemories = [],
  selectedPhotoId,
  selectedPhotoIds = [],
  selectionMode = false,
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
    activeMemory
  );
  const hasSemanticSearch = Boolean(filter.query);
  const hasAIStatusFilter = Boolean(filter.aiStatus);

  const emptyTitle = activeMemory
    ? `${activeMemory.name} has no visible photos`
    : "No media matches the current filters";

  const emptyDescription = activeMemory
    ? "Add photos to this memory from the gallery or viewer, or loosen the current query to reveal more of this memory."
    : "Adjust the query, remove a filter, or scan another folder to expand the result set.";

  return (
    <section className="select-none space-y-5">
      <p className="text-sm text-stone-500">Scan the current library scope visually. Click to inspect, double-click or press Enter to open detail.</p>

      <div className="space-y-4">
        {activeMemory || hasStructuredFilters ? (
          <div className="flex flex-wrap items-center gap-2 rounded-[24px] border border-stone-200 bg-white/70 px-4 py-3 shadow-[0_14px_34px_-26px_rgba(15,23,42,0.2)]">
            <Badge tone={activeMemory ? "info" : "neutral"}>{activeMemory ? "Memory Scope" : "Filtered View"}</Badge>
            <p className="text-sm text-stone-700">
              {activeMemory
                ? `Browsing photos inside ${activeMemory.name}.`
                : "Structured filters are narrowing the current media shelf."}
            </p>
          </div>
        ) : null}

        {(hasSemanticSearch || hasAIStatusFilter) && !activeMemory ? (
          <div className="flex flex-wrap items-center gap-2 rounded-[24px] border border-violet-200 bg-violet-50/80 px-4 py-3 shadow-[0_14px_34px_-26px_rgba(109,40,217,0.18)]">
            <Badge tone="info">Semantic Search</Badge>
            <p className="text-sm text-violet-900">
              Search matches path, manual metadata, and AI-generated captions, summaries, and tags.
            </p>
          </div>
        ) : null}

        {!isSelecting && selectedPhotoId ? (
          <div className="rounded-[24px] border border-sky-200 bg-sky-50/80 px-4 py-3 shadow-[0_14px_34px_-26px_rgba(14,116,144,0.25)]">
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
          <div className="flex flex-wrap items-center justify-between gap-3 rounded-[24px] border border-amber-200 bg-amber-50 px-4 py-3 shadow-[0_14px_34px_-26px_rgba(180,83,9,0.2)]">
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
          <div className="grid min-h-[360px] place-items-center rounded-[28px] border border-dashed border-stone-300 bg-white/60 px-6 text-center shadow-[0_18px_42px_-32px_rgba(15,23,42,0.2)]">
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
    </section>
  );
}
