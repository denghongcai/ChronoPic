import { CalendarClock } from "lucide-react";

import type { PhotoRecord } from "@chronopic/domain";

import { Badge } from "./badge.js";
import { Panel } from "./panel.js";
import { PhotoCard } from "./photo-card.js";

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
            {props.photos.map((record) => (
              <PhotoCard
                key={record.photo.id}
                onOpenDetail={() => props.onOpenDetail(record.photo.id)}
                onSelect={() => props.onSelect(record.photo.id)}
                record={record}
                selected={props.selectedPhotoId === record.photo.id}
              />
            ))}
          </div>
        )}
      </div>
    </Panel>
  );
}
