import { CalendarClock, ChevronRight } from "lucide-react";

import type { PhotoRecord } from "@chronopic/domain";

import { Panel } from "./panel.js";
import { PhotoCard } from "./photo-card.js";
import { Button } from "./button.js";
import { Badge } from "./badge.js";

export interface RecentMemoriesProps {
  photos: PhotoRecord[];
  selectedPhotoId?: string | null;
  onSelect?: (photoId: string) => void;
  onOpenDetail?: (photoId: string) => void;
}

export function RecentMemories({
  photos,
  selectedPhotoId,
  onSelect,
  onOpenDetail,
}: RecentMemoriesProps) {
  if (photos.length === 0) return null;

  return (
    <Panel className="overflow-hidden">
      <div className="flex items-center justify-between border-b border-stone-200/70 px-5 py-4">
        <div className="flex items-center gap-2">
          <CalendarClock className="h-4 w-4 text-amber-500" />
          <h3 className="font-semibold text-stone-900">Recent Memories</h3>
          <Badge tone="neutral">{photos.length}</Badge>
        </div>
        <Button className="text-stone-500" size="sm" variant="ghost">
          See All Recent
          <ChevronRight className="h-4 w-4" />
        </Button>
      </div>
      <div className="flex gap-4 overflow-x-auto p-5 pb-4">
        {photos.slice(0, 6).map((record) => (
          <div className="w-48 shrink-0" key={record.photo.id}>
            <PhotoCard
              onOpenDetail={() => onOpenDetail?.(record.photo.id)}
              onSelect={() => onSelect?.(record.photo.id)}
              record={record}
              selected={selectedPhotoId === record.photo.id}
            />
          </div>
        ))}
      </div>
    </Panel>
  );
}
