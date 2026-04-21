import type { ReactNode } from "react";
import { CalendarClock, Check, Heart, Square, Trash2 } from "lucide-react";

import type { Memory, PhotoRecord } from "@chronopic/domain";

import { AddToMemoryMenu } from "./add-to-memory-menu.js";
import { Badge } from "./badge.js";
import { IconButton } from "./icon-button.js";
import { cn } from "./lib/cn.js";
import { formatTimestamp, mediaIcon, mediaLabel, MediaPreview } from "./lib/media.js";

export interface PhotoCardProps {
  record: PhotoRecord;
  selected: boolean;
  onSelect: () => void;
  onOpenDetail: () => void;
  onToggleFavorite?: (photoId: string, favorite: boolean) => void;
  memories?: Memory[];
  onAddToMemory?: (memoryId: string, photoId: string) => void;
  onSecondaryAction?: (photoId: string) => void;
  secondaryActionLabel?: string;
  secondaryActionIcon?: ReactNode;
  batchSelected?: boolean;
  onToggleBatchSelect?: (photoId: string) => void;
  showHoverActions?: boolean;
}

export function PhotoCard({
  record,
  selected,
  onSelect,
  onOpenDetail,
  onToggleFavorite,
  memories = [],
  onAddToMemory,
  onSecondaryAction,
  secondaryActionLabel = "Remove from Memory",
  secondaryActionIcon = <Trash2 className="h-3.5 w-3.5" />,
  batchSelected = false,
  onToggleBatchSelect,
  showHoverActions = true,
}: PhotoCardProps) {
  const MediaIcon = mediaIcon(record.photo.mime);

  return (
    <div
      className={cn(
        "group relative h-auto select-none overflow-hidden rounded-[28px] border bg-white p-0 text-left shadow-[0_18px_42px_-28px_rgba(15,23,42,0.24)] transition duration-200 hover:-translate-y-0.5 hover:shadow-[0_24px_52px_-30px_rgba(15,23,42,0.28)]",
        batchSelected
          ? "border-amber-500 ring-2 ring-amber-200"
          : selected
            ? "border-amber-400 ring-2 ring-amber-200"
            : "border-stone-200 hover:border-stone-300"
      )}
      onClick={onSelect}
      onDoubleClick={onOpenDetail}
      onKeyDown={(event) => {
        if (event.key === "Enter") {
          event.preventDefault();
          onOpenDetail();
        }
      }}
      role="button"
      tabIndex={0}
    >
      <div className="relative aspect-[0.88] overflow-hidden bg-gradient-to-br from-stone-200 via-stone-100 to-amber-50">
        <MediaPreview className="transition duration-300 group-hover:scale-[1.03]" record={record} />
        <div className="absolute inset-0 bg-gradient-to-t from-stone-950/72 via-stone-950/10 to-transparent opacity-85 transition duration-200 group-hover:opacity-100" />
        <div className="absolute left-3 top-3 z-10 flex flex-wrap gap-2">
          {onToggleBatchSelect ? (
            <button
              className={cn(
                "flex h-8 w-8 items-center justify-center rounded-full border shadow-sm transition",
                batchSelected
                  ? "border-amber-400 bg-amber-500 text-white"
                  : "border-stone-200 bg-white/92 text-stone-500 hover:border-stone-300 hover:text-stone-700"
              )}
              onClick={(event) => {
                event.stopPropagation();
                onToggleBatchSelect(record.photo.id);
              }}
              title={batchSelected ? "Selected for batch actions" : "Select for batch actions"}
              type="button"
            >
              {batchSelected ? <Check className="h-3.5 w-3.5" /> : <Square className="h-3.5 w-3.5" />}
            </button>
          ) : null}
          {record.indexState.error ? <Badge tone="danger">Error</Badge> : null}
          {record.indexState.duplicateOf ? <Badge tone="warn">Duplicate</Badge> : null}
        </div>
        {showHoverActions && (
          <div className="absolute inset-x-3 top-3 z-10 flex justify-end gap-1 opacity-0 transition group-hover:opacity-100">
            <IconButton
              className={cn(
                record.photo.favorite
                  ? "bg-amber-500 text-white hover:bg-amber-600"
                  : "bg-stone-950/62 text-stone-100 hover:bg-stone-800"
              )}
              icon={<Heart className={cn("h-3.5 w-3.5", record.photo.favorite && "fill-current")} />}
              label={record.photo.favorite ? "Unfavorite" : "Favorite"}
              onClick={(e) => {
                e.stopPropagation();
                onToggleFavorite?.(record.photo.id, !record.photo.favorite);
              }}
              size="sm"
              tone="dark"
              variant="ghost"
            />
            {onAddToMemory ? (
              <div onClick={(e) => e.stopPropagation()}>
                <AddToMemoryMenu
                  label="Add to Memory"
                  memories={memories}
                  onAddToMemory={(memoryId) => onAddToMemory(memoryId, record.photo.id)}
                  tone="dark"
                  trigger="icon"
                />
              </div>
            ) : null}
            {onSecondaryAction ? (
              <IconButton
                className="bg-stone-950/62 text-stone-100 hover:bg-red-600"
                icon={secondaryActionIcon}
                label={secondaryActionLabel}
                onClick={(e) => {
                  e.stopPropagation();
                  onSecondaryAction(record.photo.id);
                }}
                size="sm"
                tone="dark"
                variant="ghost"
              />
            ) : null}
          </div>
        )}
        <div className="absolute inset-x-4 bottom-4 z-10">
          <div className="space-y-2 text-white">
            <div className="flex items-center justify-between text-[10px] font-medium uppercase tracking-[0.16em] text-white/78 opacity-0 transition group-hover:opacity-100">
              <span>Double-click to open</span>
              <MediaIcon className="h-3.5 w-3.5" />
            </div>
            <p className="line-clamp-1 text-base font-semibold tracking-tight">{mediaLabel(record)}</p>
            <div className="flex flex-wrap items-center gap-3 text-xs text-white/82">
              <span className="inline-flex items-center gap-1.5">
                <CalendarClock className="h-3.5 w-3.5" />
                {formatTimestamp(record.metadata.datetime)}
              </span>
              <span className="inline-flex items-center gap-1.5">
                <MediaIcon className="h-3.5 w-3.5" />
                {record.photo.mime.startsWith("video/") ? "Video" : "Image"}
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
