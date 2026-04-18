import type { PhotoRecord } from "@chronopic/domain";

import type { PhotoFilter, PhotoFilterPatch } from "@chronopic/domain";

import { Badge } from "./badge.js";
import { Panel } from "./panel.js";
import { PhotoCard } from "./photo-card.js";

export interface GallerySectionProps {
  photos: PhotoRecord[];
  selectedPhotoId?: string | null;
  filter: PhotoFilter;
  onFilterChange: (patch: PhotoFilterPatch) => void;
  onSelect?: (photoId: string) => void;
  onOpenDetail?: (photoId: string) => void;
  onToggleFavorite?: (photoId: string, favorite: boolean) => void;
}

export function GallerySection({
  photos,
  selectedPhotoId,
  filter,
  onFilterChange,
  onSelect,
  onOpenDetail,
  onToggleFavorite,
}: GallerySectionProps) {
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
        <Badge tone="neutral">{photos.length} items</Badge>
      </div>

      <div className="max-h-[68vh] overflow-auto p-5">
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
                onOpenDetail={() => onOpenDetail?.(record.photo.id)}
                onSelect={() => onSelect?.(record.photo.id)}
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
