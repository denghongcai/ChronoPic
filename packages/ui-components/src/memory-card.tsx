import { CalendarClock, ImageIcon, Sparkles } from "lucide-react";

import type { Memory } from "@chronopic/domain";

import { Badge } from "./badge.js";
import { Button } from "./button.js";
import { useI18n } from "./i18n-provider.js";
import { formatTimestamp, thumbnailUrl } from "./lib/media.js";
import { getMemoryDescriptionPreview } from "./lib/memory-description.js";
import { cn } from "./lib/cn.js";

export interface MemoryCardProps {
  memory: Memory;
  selected?: boolean;
  onOpen: () => void;
  variant?: "default" | "highlight";
}

export function MemoryCard({ memory, selected = false, onOpen, variant = "default" }: MemoryCardProps) {
  const { t } = useI18n();
  const coverUrl = thumbnailUrl(memory.coverThumbnailPath);
  const descriptionPreview = getMemoryDescriptionPreview(memory.description);
  const isHighlight = variant === "highlight";

  return (
    <Button
      className={cn(
        "group h-auto overflow-hidden p-0 text-left transition duration-200 hover:-translate-y-0.5",
        isHighlight
          ? "rounded-[32px] border border-stone-200/70 bg-white shadow-[0_18px_42px_-28px_rgba(15,23,42,0.35)] hover:shadow-[0_28px_60px_-34px_rgba(15,23,42,0.42)]"
          : "rounded-[28px] border bg-white shadow-sm hover:shadow-lg",
        selected ? "border-amber-400 ring-2 ring-amber-200" : "border-stone-200 hover:border-stone-300"
      )}
      onClick={onOpen}
      type="button"
      variant="outline"
    >
      <div
        className={cn(
          "relative overflow-hidden bg-gradient-to-br from-amber-100 via-stone-100 to-sky-100",
          isHighlight ? "aspect-[1.78]" : "aspect-[1.4]"
        )}
      >
        {coverUrl ? (
          <img alt={memory.name} className="h-full w-full object-cover transition duration-300 group-hover:scale-[1.03]" src={coverUrl} />
        ) : (
          <div className="grid h-full place-items-center">
            <Sparkles className="h-10 w-10 text-stone-400" />
          </div>
        )}
        <div className="absolute inset-0 bg-gradient-to-t from-stone-950/65 via-stone-950/10 to-stone-950/0" />
        <div className="absolute left-4 top-4 flex items-center gap-2">
          <Badge tone="neutral">{t("memory.detail.photos", { count: memory.photoCount })}</Badge>
          {memory.coverPhotoId ? <Badge tone="info">{t("memories.customCover")}</Badge> : null}
        </div>
        {isHighlight ? (
          <div className="absolute bottom-0 left-0 right-0 p-5 text-white">
            <div className="space-y-2">
              <p className="line-clamp-1 font-['Space_Grotesk','IBM_Plex_Sans',sans-serif] text-[1.75rem] font-semibold tracking-tight">
                {memory.name}
              </p>
              <div className="flex flex-wrap items-center gap-3 text-xs text-white/80">
                <span className="inline-flex items-center gap-1.5">
                  <CalendarClock className="h-3.5 w-3.5" />
                  {t("common.updated", { time: formatTimestamp(memory.updatedAt) })}
                </span>
                <span className="inline-flex items-center gap-1.5">
                  <ImageIcon className="h-3.5 w-3.5" />
                  {memory.source}
                </span>
              </div>
            </div>
          </div>
        ) : null}
      </div>
      {!isHighlight ? (
        <div className="space-y-3 px-4 py-4">
          <div className="space-y-1">
            <p className="line-clamp-1 text-base font-semibold text-stone-950">{memory.name}</p>
            <p className="line-clamp-2 min-h-10 text-sm leading-5 text-stone-500">
              {descriptionPreview || t("memories.noDescription")}
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
      ) : null}
    </Button>
  );
}
