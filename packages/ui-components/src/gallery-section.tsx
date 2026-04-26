import type { Memory, PhotoFilter, PhotoRecord } from "@chronopic/domain";

import { AddToMemoryMenu } from "./add-to-memory-menu.js";
import { Badge } from "./badge.js";
import { Button } from "./button.js";
import { useI18n } from "./i18n-provider.js";
import { getDiscoveryMatchSummary } from "./lib/discovery-match.js";
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
  const { t } = useI18n();
  const hasBatchSelection = selectedPhotoIds.length > 0;
  const isSelecting = selectionMode || hasBatchSelection;
  const selectedPhoto = photos.find((record) => record.photo.id === selectedPhotoId) ?? null;
  const selectedPhotoMatch = getDiscoveryMatchSummary(selectedPhoto, selectedPhotoMemories, filter.query, t);

  const emptyTitle = activeMemory
    ? t("gallery.memoryEmpty", { name: activeMemory.name })
    : t("gallery.noMedia");

  const emptyDescription = activeMemory
    ? t("gallery.memoryEmptyDescription")
    : t("gallery.emptyDescription");

  return (
    <section className="select-none space-y-5">
      <div className="space-y-4">
        {!isSelecting && selectedPhotoId ? (
          <div className="rounded-[24px] border border-sky-200 bg-sky-50/80 px-4 py-3 shadow-[0_14px_34px_-26px_rgba(14,116,144,0.25)]">
            <div className="flex flex-wrap items-center gap-2">
              <Badge tone="info">{t("map.selectedPhoto")}</Badge>
              {selectedPhotoMemories.length === 0 ? (
                <p className="text-sm text-sky-900">{t("gallery.notSavedToMemory")}</p>
              ) : (
                <>
                  <p className="text-sm text-sky-900">{t("gallery.savedTo")}</p>
                  {selectedPhotoMemories.map((memory) => (
                    <Badge key={memory.id} tone={memory.coverPhotoId === selectedPhotoId ? "info" : "neutral"}>
                      {memory.name}
                      {memory.coverPhotoId === selectedPhotoId ? ` ${t("common.cover")}` : ""}
                    </Badge>
                  ))}
                </>
              )}
              {selectedPhotoMatch ? (
                <p className="basis-full text-sm text-sky-900">{selectedPhotoMatch.description}</p>
              ) : null}
            </div>
          </div>
        ) : null}

        {hasBatchSelection ? (
          <div className="flex flex-wrap items-center justify-between gap-3 rounded-[24px] border border-amber-200 bg-amber-50 px-4 py-3 shadow-[0_14px_34px_-26px_rgba(180,83,9,0.2)]">
            <div className="flex items-center gap-2">
              <Badge tone="warn">{t("timeline.selected", { count: selectedPhotoIds.length })}</Badge>
              <p className="text-sm font-medium text-amber-950">{t("gallery.batchMessage")}</p>
            </div>
            <div className="flex items-center gap-2">
              {onAddSelectionToMemory ? (
                <AddToMemoryMenu
                  buttonVariant="accent"
                  label={t("timeline.addSelectedToMemory")}
                  memories={memories}
                  onAddToMemory={async (memoryId) => {
                    await onAddSelectionToMemory(memoryId, selectedPhotoIds);
                    onSelectionModeChange?.(false);
                  }}
                />
              ) : null}
              <Button onClick={onClearBatchSelection} size="sm" variant="outline">
                {t("timeline.clearSelection")}
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
