import { CalendarDays, MapPin, Sparkles } from "lucide-react";

import type { MemoryStorySection } from "./lib/memory-story.js";
import { thumbnailUrl } from "./lib/media.js";
import { Badge } from "./badge.js";
import { Button } from "./button.js";
import { Panel } from "./panel.js";

export interface MemoryStoryBoardProps {
  sections: MemoryStorySection[];
  onOpenSection?: (photoId: string) => void;
}

export function MemoryStoryBoard({ sections, onOpenSection }: MemoryStoryBoardProps) {
  if (sections.length === 0) {
    return null;
  }

  return (
    <Panel className="overflow-hidden">
      <div className="flex flex-wrap items-center justify-between gap-3 border-b border-stone-200/70 px-5 py-4">
        <div>
          <p className="text-[11px] font-semibold uppercase tracking-[0.22em] text-stone-500">Story Outline</p>
          <h2 className="mt-2 font-['Space_Grotesk','IBM_Plex_Sans',sans-serif] text-2xl font-semibold tracking-tight text-stone-950">
            Chapters inside this memory
          </h2>
        </div>
        <Badge tone="neutral">{sections.length} chapters</Badge>
      </div>
      <div className="grid gap-4 p-5 lg:grid-cols-3">
        {sections.map((section, index) => {
          const coverUrl = thumbnailUrl(section.coverThumbnailPath);
          const canOpen = Boolean(section.coverPhotoId && onOpenSection);

          return (
            <button
              className="group overflow-hidden rounded-[24px] border border-stone-200 bg-white text-left shadow-sm transition hover:-translate-y-0.5 hover:border-stone-300 hover:shadow-md disabled:hover:translate-y-0 disabled:hover:shadow-sm"
              disabled={!canOpen}
              key={section.id}
              onClick={() => {
                if (section.coverPhotoId) {
                  onOpenSection?.(section.coverPhotoId);
                }
              }}
              type="button"
            >
              <div className="aspect-[1.35] overflow-hidden bg-stone-100">
                {coverUrl ? (
                  <img alt="" className="h-full w-full object-cover transition duration-500 group-hover:scale-[1.03]" src={coverUrl} />
                ) : (
                  <div className="grid h-full place-items-center text-stone-400">
                    <CalendarDays className="h-8 w-8" />
                  </div>
                )}
              </div>
              <div className="space-y-3 p-4">
                <div className="flex items-center justify-between gap-3">
                  <Badge tone="info">Chapter {index + 1}</Badge>
                  <span className="text-xs font-medium text-stone-400">{section.photoCount} photos</span>
                </div>
                <div>
                  <h3 className="font-['Space_Grotesk','IBM_Plex_Sans',sans-serif] text-lg font-semibold tracking-tight text-stone-950">
                    {section.title}
                  </h3>
                  <p className="mt-1 text-sm text-stone-500">{section.subtitle}</p>
                </div>
                <div className="flex flex-wrap gap-2">
                  {section.gpsCount > 0 ? (
                    <Badge tone="neutral">
                      <MapPin className="h-3 w-3" />
                      {section.gpsCount} mapped
                    </Badge>
                  ) : null}
                  {section.aiReadyCount > 0 ? (
                    <Badge tone="neutral">
                      <Sparkles className="h-3 w-3" />
                      {section.aiReadyCount} AI
                    </Badge>
                  ) : null}
                </div>
                {canOpen ? (
                  <Button asChild className="pointer-events-none w-full" size="sm" variant="outline">
                    <span>Open chapter lead</span>
                  </Button>
                ) : null}
              </div>
            </button>
          );
        })}
      </div>
    </Panel>
  );
}
