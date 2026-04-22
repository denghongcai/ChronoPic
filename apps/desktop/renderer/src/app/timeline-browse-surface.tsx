import { useEffect, useMemo, useState } from "react";

import type { Memory, PhotoFilter, PhotoRecord, TimelineGranularity, TimelineGroup } from "@chronopic/domain";
import { AddToMemoryMenu, Badge, Button, Panel, PhotoCard, getDiscoveryContext, getDiscoveryMatchSummary } from "@chronopic/ui-components";

interface TimelineBrowseSurfaceProps {
  filter: PhotoFilter;
  memories: Memory[];
  photos: PhotoRecord[];
  selectedPhotoId: string | null;
  selectedPhotoIds: string[];
  selectedPhotoMemories: Memory[];
  timelineGranularity: TimelineGranularity;
  timelineGroups: TimelineGroup[];
  onAddPhotoToMemory: (memoryId: string, photoId: string) => Promise<void> | void;
  onAddSelectionToMemory: (memoryId: string, photoIds: string[]) => Promise<void> | void;
  onClearBatchSelection: () => void;
  onTimelineGranularityChange: (granularity: TimelineGranularity) => void;
  onOpenDetail: (photoId: string) => void;
  onSelectPhoto: (photoId: string) => void;
  onToggleBatchSelect: (photoId: string) => void;
  onToggleFavorite: (photoId: string, favorite: boolean) => void;
}

export function TimelineBrowseSurface({
  filter,
  memories,
  photos,
  selectedPhotoId,
  selectedPhotoIds,
  selectedPhotoMemories,
  timelineGranularity,
  timelineGroups,
  onAddPhotoToMemory,
  onAddSelectionToMemory,
  onClearBatchSelection,
  onTimelineGranularityChange,
  onOpenDetail,
  onSelectPhoto,
  onToggleBatchSelect,
  onToggleFavorite,
}: TimelineBrowseSurfaceProps) {
  const [selectionMode, setSelectionMode] = useState(false);
  const hasBatchSelection = selectedPhotoIds.length > 0;
  const isSelecting = selectionMode || hasBatchSelection;

  useEffect(() => {
    if (selectedPhotoIds.length === 0 && selectionMode) {
      setSelectionMode(false);
    }
  }, [selectedPhotoIds.length, selectionMode]);

  const photosById = useMemo(() => new Map(photos.map((record) => [record.photo.id, record])), [photos]);
  const visibleGroups = useMemo(
    () =>
      timelineGroups
        .map((group) => ({
          ...group,
          records: group.photoIds.map((photoId) => photosById.get(photoId)).filter(Boolean) as PhotoRecord[],
        }))
        .filter((group) => group.records.length > 0),
    [photosById, timelineGroups]
  );

  const datedPhotoCount = useMemo(() => visibleGroups.reduce((total, group) => total + group.records.length, 0), [visibleGroups]);
  const undatedPhotoCount = Math.max(photos.length - datedPhotoCount, 0);
  const selectedPhoto = useMemo(
    () => photos.find((record) => record.photo.id === selectedPhotoId) ?? null,
    [photos, selectedPhotoId]
  );
  const activeMemoryName = useMemo(
    () => memories.find((memory) => memory.id === filter.memoryId)?.name ?? null,
    [filter.memoryId, memories]
  );
  const discoveryContext = useMemo(
    () => getDiscoveryContext(filter, { activeMemoryName }),
    [activeMemoryName, filter]
  );
  const selectedPhotoMatch = useMemo(
    () => getDiscoveryMatchSummary(selectedPhoto, selectedPhotoMemories, filter.query),
    [filter.query, selectedPhoto, selectedPhotoMemories]
  );

  return (
    <Panel className="select-none overflow-hidden">
      <div className="flex flex-wrap items-end justify-between gap-4 border-b border-stone-200/70 px-5 py-4">
        <div className="space-y-1">
          <p className="text-[11px] font-semibold uppercase tracking-[0.22em] text-stone-400">Timeline View</p>
          <p className="text-sm text-stone-500">Browse the current library scope chronologically and keep the same viewer and memory flows.</p>
        </div>
        <div className="flex flex-wrap items-center justify-end gap-2">
          <div className="flex items-center gap-1 rounded-full border border-stone-200 bg-stone-100/80 p-1">
            {timelineGranularities.map((item) => (
              <button
                key={item.value}
                className={`rounded-full px-3 py-1.5 text-xs font-semibold transition ${
                  timelineGranularity === item.value
                    ? "bg-white text-stone-950 shadow-sm"
                    : "text-stone-500 hover:text-stone-800"
                }`}
                onClick={() => onTimelineGranularityChange(item.value)}
                type="button"
              >
                {item.label}
              </button>
            ))}
          </div>
          <Button
            onClick={() => {
              if (isSelecting) {
                onClearBatchSelection();
                setSelectionMode(false);
                return;
              }

              setSelectionMode(true);
            }}
            size="sm"
            variant={isSelecting ? "accent" : "outline"}
          >
            {isSelecting ? "Done" : "Select"}
          </Button>
          <Badge tone="neutral">{visibleGroups.length} groups</Badge>
          <Badge tone="info">{datedPhotoCount} dated photos</Badge>
        </div>
      </div>

      <div className="p-5">
        <div className="mb-4 flex flex-wrap items-center gap-2 rounded-[24px] border border-stone-200 bg-stone-50/80 px-4 py-3">
          <Badge tone="info">Timeline Scope</Badge>
          <p className="text-sm text-stone-700">
            Showing {datedPhotoCount} dated photo{datedPhotoCount === 1 ? "" : "s"} across {visibleGroups.length}{" "}
            {timelineGranularity} group{visibleGroups.length === 1 ? "" : "s"} in the current result set.
          </p>
          {undatedPhotoCount > 0 ? (
            <Badge tone="warn">{undatedPhotoCount} undated hidden</Badge>
          ) : null}
          {discoveryContext?.badges.map((badge) => (
            <Badge key={badge.label} tone={badge.tone}>
              {badge.label}
            </Badge>
          ))}
          {discoveryContext ? (
            <p className="basis-full pt-1 text-sm text-stone-600">{discoveryContext.description}</p>
          ) : null}
        </div>

        {!isSelecting && selectedPhoto ? (
          <div className="mb-4 rounded-[24px] border border-sky-200 bg-sky-50/80 px-4 py-3">
            <div className="flex flex-wrap items-center gap-2">
              <Badge tone="info">Selected Photo</Badge>
              <p className="text-sm text-sky-900">
                {selectedPhoto.photo.path.split("/").at(-1) ?? "Selected photo"} is the current timeline focus.
              </p>
              <Button
                onClick={() => onOpenDetail(selectedPhoto.photo.id)}
                size="sm"
                variant="outline"
              >
                Open Detail
              </Button>
            </div>
            {selectedPhotoMemories.length > 0 ? (
              <div className="mt-3 flex flex-wrap items-center gap-2">
                <p className="text-xs font-medium uppercase tracking-[0.18em] text-sky-700">Memories</p>
                {selectedPhotoMemories.map((memory) => (
                  <Badge key={memory.id} tone={memory.coverPhotoId === selectedPhoto.photo.id ? "info" : "neutral"}>
                    {memory.name}
                    {memory.coverPhotoId === selectedPhoto.photo.id ? " cover" : ""}
                  </Badge>
                ))}
              </div>
            ) : null}
            {selectedPhotoMatch ? (
              <p className="mt-3 text-sm text-sky-900">{selectedPhotoMatch.description}</p>
            ) : null}
          </div>
        ) : null}

        {hasBatchSelection ? (
          <div className="mb-4 flex flex-wrap items-center justify-between gap-3 rounded-[24px] border border-amber-200 bg-amber-50 px-4 py-3">
            <div className="flex items-center gap-2">
              <Badge tone="warn">{selectedPhotoIds.length} selected</Badge>
              <p className="text-sm font-medium text-amber-950">Batch actions for selected photos in the timeline</p>
            </div>
            <div className="flex items-center gap-2">
              <Button
                onClick={() => setSelectionMode(false)}
                size="sm"
                variant="outline"
              >
                Keep Browsing
              </Button>
              <Button onClick={onClearBatchSelection} size="sm" variant="outline">
                Clear Selection
              </Button>
            </div>
          </div>
        ) : null}

        {hasBatchSelection ? (
          <div className="mb-6 flex justify-end">
            <div onClick={(event) => event.stopPropagation()}>
              <AddToMemoryMenu
                buttonVariant="accent"
                label="Add Selected to Memory"
                memories={memories}
                onAddToMemory={async (memoryId) => {
                  await onAddSelectionToMemory(memoryId, selectedPhotoIds);
                }}
              />
            </div>
          </div>
        ) : null}

        {visibleGroups.length === 0 ? (
          <div className="grid min-h-[360px] place-items-center rounded-[24px] border border-dashed border-stone-300 bg-stone-50/70 px-6 text-center">
            <div className="max-w-sm space-y-3">
              <p className="text-lg font-semibold text-stone-900">No dated photos available for the timeline</p>
              <p className="text-sm leading-6 text-stone-500">
                Timeline view only includes photos with a captured time. Scan folders with EXIF time data, or correct a few timestamps in detail view.
              </p>
            </div>
          </div>
        ) : (
          <div className="space-y-8">
            {visibleGroups.map((group) => (
              <section key={group.id} className="space-y-4">
                <div className="flex flex-wrap items-end justify-between gap-3">
                  <div>
                    <h3 className="font-['Space_Grotesk','IBM_Plex_Sans',sans-serif] text-xl font-semibold tracking-tight text-stone-950">
                      {group.label}
                    </h3>
                    <p className="mt-1 text-sm text-stone-500">
                      {group.records.length} photo{group.records.length === 1 ? "" : "s"} captured in this period
                    </p>
                  </div>
                  <div className="flex items-center gap-2">
                    <Badge tone="neutral">{group.granularity}</Badge>
                    {group.fromDatetime != null && group.toDatetime != null ? (
                      <Badge tone="info">
                        {new Intl.DateTimeFormat("zh-CN", { month: "2-digit", day: "2-digit" }).format(new Date(group.fromDatetime))}
                        {" - "}
                        {new Intl.DateTimeFormat("zh-CN", { month: "2-digit", day: "2-digit" }).format(new Date(group.toDatetime))}
                      </Badge>
                    ) : null}
                  </div>
                </div>

                <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-3 2xl:grid-cols-4">
                  {group.records.map((record) => (
                    <PhotoCard
                      key={record.photo.id}
                      batchSelected={selectedPhotoIds.includes(record.photo.id)}
                      {...(onAddPhotoToMemory && { memories, onAddToMemory: onAddPhotoToMemory })}
                      onOpenDetail={() => {
                        if (!isSelecting) {
                          onOpenDetail(record.photo.id);
                        }
                      }}
                      onSelect={() => {
                        if (isSelecting) {
                          onToggleBatchSelect(record.photo.id);
                          return;
                        }

                        onSelectPhoto(record.photo.id);
                      }}
                      {...(isSelecting && { onToggleBatchSelect })}
                      onToggleFavorite={onToggleFavorite}
                      record={record}
                      selected={selectedPhotoId === record.photo.id}
                      showHoverActions
                    />
                  ))}
                </div>
              </section>
            ))}
          </div>
        )}
      </div>
    </Panel>
  );
}

const timelineGranularities: Array<{ label: string; value: TimelineGranularity }> = [
  { label: "Year", value: "year" },
  { label: "Month", value: "month" },
  { label: "Day", value: "day" },
];
