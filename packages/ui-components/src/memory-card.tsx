import { CalendarClock, ImageIcon, Sparkles } from "lucide-react";

import type { Memory } from "@chronopic/domain";

import { Badge } from "./badge.js";
import { Button } from "./button.js";
import { formatTimestamp, thumbnailUrl } from "./lib/media.js";
import { getMemoryDescriptionPreview } from "./lib/memory-description.js";
import { cn } from "./lib/cn.js";

export interface MemoryCardProps {
  memory: Memory;
  selected?: boolean;
  onOpen: () => void;
}

export function MemoryCard({ memory, selected = false, onOpen }: MemoryCardProps) {
  const coverUrl = thumbnailUrl(memory.coverThumbnailPath);
  const descriptionPreview = getMemoryDescriptionPreview(memory.description);

  return (
    <Button
      className={cn(
        "group h-auto overflow-hidden rounded-[28px] border bg-white p-0 text-left shadow-sm transition duration-200 hover:-translate-y-0.5 hover:shadow-lg",
        selected ? "border-amber-400 ring-2 ring-amber-200" : "border-stone-200 hover:border-stone-300"
      )}
      onClick={onOpen}
      type="button"
      variant="outline"
    >
      <div className="relative aspect-[1.4] overflow-hidden bg-gradient-to-br from-amber-100 via-stone-100 to-sky-100">
        {coverUrl ? (
          <img alt={memory.name} className="h-full w-full object-cover transition duration-300 group-hover:scale-[1.03]" src={coverUrl} />
        ) : (
          <div className="grid h-full place-items-center">
            <Sparkles className="h-10 w-10 text-stone-400" />
          </div>
        )}
        <div className="absolute left-3 top-3">
          <Badge tone="neutral">{memory.photoCount} photos</Badge>
        </div>
        {memory.coverPhotoId ? (
          <div className="absolute right-3 top-3">
            <Badge tone="info">Custom Cover</Badge>
          </div>
        ) : null}
      </div>
      <div className="space-y-3 px-4 py-4">
        <div className="space-y-1">
          <p className="line-clamp-1 text-base font-semibold text-stone-950">{memory.name}</p>
          <p className="line-clamp-2 min-h-10 text-sm leading-5 text-stone-500">
            {descriptionPreview || "No description yet"}
          </p>
        </div>
        <div className="flex items-center justify-between text-xs text-stone-500">
          <span className="inline-flex items-center gap-1.5">
            <CalendarClock className="h-3.5 w-3.5" />
            {formatTimestamp(memory.updatedAt)}
          </span>
          <span className="inline-flex items-center gap-1.5">
            <ImageIcon className="h-3.5 w-3.5" />
            {memory.source}
          </span>
        </div>
      </div>
    </Button>
  );
}
