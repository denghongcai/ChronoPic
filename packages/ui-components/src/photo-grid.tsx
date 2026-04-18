import { CalendarClock } from "lucide-react";

import type { PhotoRecord } from "@chronopic/domain";

import { Badge } from "./badge.js";
import { Button } from "./button.js";
import { cn } from "./lib/cn.js";
import { formatTimestamp, mediaIcon, mediaLabel, MediaPreview } from "./lib/media.js";
import { Panel } from "./panel.js";

export interface PhotoGridProps {
  photos: PhotoRecord[];
  selectedPhotoId: string | null;
  onSelect: (photoId: string) => void;
  onOpenDetail: (photoId: string) => void;
}

export function PhotoGrid(props: PhotoGridProps) {
  return (
    <Panel className="overflow-hidden">
      <div className="flex items-center justify-between border-b border-stone-200/70 px-5 py-4">
        <div>
          <p className="text-[11px] font-semibold uppercase tracking-[0.22em] text-stone-500">Media Shelf</p>
          <h2 className="mt-2 font-['Space_Grotesk','IBM_Plex_Sans',sans-serif] text-2xl font-semibold tracking-tight text-stone-950">
            Browse results
          </h2>
          <p className="mt-2 text-sm text-stone-500">Click to inspect, double-click or press Enter to open a focused view.</p>
        </div>
        <Badge tone="neutral">{props.photos.length} items</Badge>
      </div>
      <div className="max-h-[68vh] overflow-auto p-5">
        {props.photos.length === 0 ? (
          <div className="grid min-h-[360px] place-items-center rounded-[24px] border border-dashed border-stone-300 bg-stone-50/70 px-6 text-center">
            <div className="max-w-sm space-y-3">
              <CalendarClock className="mx-auto h-12 w-12 text-stone-400" />
              <h3 className="text-lg font-semibold text-stone-900">No media matches the current filters</h3>
              <p className="text-sm leading-6 text-stone-500">Adjust the query, remove a toggle, or scan another folder to expand the result set.</p>
            </div>
          </div>
        ) : (
          <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-3 2xl:grid-cols-4">
            {props.photos.map((record) => {
              const MediaIcon = mediaIcon(record.photo.mime);

              return (
                <Button
                  className={cn(
                    "group h-auto overflow-hidden rounded-[24px] border bg-white p-0 text-left shadow-sm transition duration-200 hover:-translate-y-0.5 hover:shadow-lg",
                    props.selectedPhotoId === record.photo.id
                      ? "border-amber-400 ring-2 ring-amber-200"
                      : "border-stone-200 hover:border-stone-300"
                  )}
                  key={record.photo.id}
                  onClick={() => props.onSelect(record.photo.id)}
                  onDoubleClick={() => props.onOpenDetail(record.photo.id)}
                  onKeyDown={(event) => {
                    if (event.key === "Enter") {
                      event.preventDefault();
                      props.onOpenDetail(record.photo.id);
                    }
                  }}
                  type="button"
                  variant="outline"
                >
                  <div className="relative aspect-[1.05] overflow-hidden bg-gradient-to-br from-stone-200 via-stone-100 to-amber-50">
                    <MediaPreview className="transition duration-300 group-hover:scale-[1.03]" record={record} />
                    <div className="absolute left-3 top-3 flex flex-wrap gap-2">
                      {record.indexState.error ? <Badge tone="danger">Error</Badge> : null}
                      {record.indexState.duplicateOf ? <Badge tone="warn">Duplicate</Badge> : null}
                    </div>
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
                </Button>
              );
            })}
          </div>
        )}
      </div>
    </Panel>
  );
}
