import { CalendarClock, Heart, Info, Trash2 } from "lucide-react";

import type { PhotoRecord } from "@chronopic/domain";

import { Badge } from "./badge.js";
import { cn } from "./lib/cn.js";
import { formatTimestamp, mediaIcon, mediaLabel, MediaPreview } from "./lib/media.js";

export interface PhotoCardProps {
  record: PhotoRecord;
  selected: boolean;
  onSelect: () => void;
  onOpenDetail: () => void;
  onToggleFavorite?: (photoId: string, favorite: boolean) => void;
  showHoverActions?: boolean;
}

export function PhotoCard({
  record,
  selected,
  onSelect,
  onOpenDetail,
  onToggleFavorite,
  showHoverActions = true,
}: PhotoCardProps) {
  const MediaIcon = mediaIcon(record.photo.mime);

  return (
    <div
      className={cn(
        "group relative h-auto overflow-hidden rounded-[24px] border bg-white p-0 text-left shadow-sm transition duration-200 hover:-translate-y-0.5 hover:shadow-lg",
        selected ? "border-amber-400 ring-2 ring-amber-200" : "border-stone-200 hover:border-stone-300"
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
      <div className="relative aspect-[1.05] overflow-hidden bg-gradient-to-br from-stone-200 via-stone-100 to-amber-50">
        <MediaPreview className="transition duration-300 group-hover:scale-[1.03]" record={record} />
        <div className="absolute left-3 top-3 flex flex-wrap gap-2">
          {record.indexState.error ? <Badge tone="danger">Error</Badge> : null}
          {record.indexState.duplicateOf ? <Badge tone="warn">Duplicate</Badge> : null}
        </div>
        {showHoverActions && (
          <div className="absolute inset-x-3 top-3 flex justify-end gap-1 opacity-0 transition group-hover:opacity-100">
            <button
              className={cn(
                "flex h-7 w-7 items-center justify-center rounded-full transition",
                record.photo.favorite
                  ? "bg-amber-500 text-white hover:bg-amber-600"
                  : "bg-stone-950/62 text-stone-100 hover:bg-stone-800"
              )}
              onClick={(e) => {
                e.stopPropagation();
                onToggleFavorite?.(record.photo.id, !record.photo.favorite);
              }}
              title={record.photo.favorite ? "Unfavorite" : "Favorite"}
              type="button"
            >
              <Heart className={cn("h-3.5 w-3.5", record.photo.favorite && "fill-current")} />
            </button>
            <button
              className="flex h-7 w-7 items-center justify-center rounded-full bg-stone-950/62 text-stone-100 transition hover:bg-stone-800"
              onClick={(e) => e.stopPropagation()}
              title="Info"
              type="button"
            >
              <Info className="h-3.5 w-3.5" />
            </button>
            <button
              className="flex h-7 w-7 items-center justify-center rounded-full bg-stone-950/62 text-stone-100 transition hover:bg-red-600"
              onClick={(e) => e.stopPropagation()}
              title="Delete"
              type="button"
            >
              <Trash2 className="h-3.5 w-3.5" />
            </button>
          </div>
        )}
        <div className="absolute inset-x-3 bottom-3 flex items-center justify-between rounded-2xl bg-stone-950/62 px-3 py-2 text-[11px] font-medium tracking-[0.12em] text-stone-100 opacity-0 transition group-hover:opacity-100">
          <span>Double-click to open</span>
          <MediaIcon className="h-3.5 w-3.5" />
        </div>
      </div>
      <div className="space-y-3 px-4 py-4">
        <div className="space-y-1">
          <p className="line-clamp-1 text-sm font-semibold text-stone-950">{mediaLabel(record)}</p>
          <p className="line-clamp-2 text-xs leading-5 text-stone-500">{record.photo.path.split("/").at(-1)}</p>
        </div>
        <div className="flex items-center justify-between text-xs text-stone-500">
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
  );
}
