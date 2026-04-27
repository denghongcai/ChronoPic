import { CalendarDays, MapPin, Sparkles } from "lucide-react";

import type { MemoryStorySection } from "./lib/memory-story.js";
import { thumbnailUrl } from "./lib/media.js";
import { Badge } from "./badge.js";
import { useI18n } from "./i18n-provider.js";
import { Panel } from "./panel.js";

export interface MemoryStoryBoardProps {
  sections: MemoryStorySection[];
  onOpenSection?: (photoId: string) => void;
}

function monthDateFromKey(monthKey: string): Date {
  const [year, month] = monthKey.split("-");
  return new Date(Number(year), Number(month) - 1, 1);
}

export function MemoryStoryBoard({ sections, onOpenSection }: MemoryStoryBoardProps) {
  const { locale, t } = useI18n();

  if (sections.length === 0) {
    return null;
  }

  function formatSectionTitle(section: MemoryStorySection): string {
    if (!section.monthKey) {
      return t("story.undatedMoments");
    }

    return new Intl.DateTimeFormat(locale, { month: "long", year: "numeric" }).format(monthDateFromKey(section.monthKey));
  }

  function formatSectionSubtitle(section: MemoryStorySection): string {
    if (!section.fromDatetime) {
      return t("story.undated");
    }

    const formatter = new Intl.DateTimeFormat(locale, { month: "short", day: "numeric" });

    if (!section.toDatetime || section.fromDatetime === section.toDatetime) {
      return formatter.format(new Date(section.fromDatetime));
    }

    return t("story.dateRange", {
      from: formatter.format(new Date(section.fromDatetime)),
      to: formatter.format(new Date(section.toDatetime)),
    });
  }

  return (
    <Panel className="overflow-hidden">
      <div className="flex flex-wrap items-center justify-between gap-3 border-b border-stone-200/70 px-5 py-4">
        <div>
          <p className="text-[11px] font-semibold uppercase tracking-[0.22em] text-stone-500">{t("story.outline")}</p>
          <h2 className="mt-2 font-['Space_Grotesk','IBM_Plex_Sans',sans-serif] text-2xl font-semibold tracking-tight text-stone-950">
            {t("story.chaptersTitle")}
          </h2>
        </div>
        <Badge tone="neutral">{t("story.chapters", { count: sections.length })}</Badge>
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
                  <Badge tone="info">{t("story.chapterIndex", { index: index + 1 })}</Badge>
                  <span className="text-xs font-medium text-stone-400">{t("memory.detail.photos", { count: section.photoCount })}</span>
                </div>
                <div>
                  <h3 className="font-['Space_Grotesk','IBM_Plex_Sans',sans-serif] text-lg font-semibold tracking-tight text-stone-950">
                    {formatSectionTitle(section)}
                  </h3>
                  <p className="mt-1 text-sm text-stone-500">{formatSectionSubtitle(section)}</p>
                </div>
                <div className="flex flex-wrap gap-2">
                  {section.gpsCount > 0 ? (
                    <Badge tone="neutral">
                      <MapPin className="h-3 w-3" />
                      {t("story.mapped", { count: section.gpsCount })}
                    </Badge>
                  ) : null}
                  {section.aiReadyCount > 0 ? (
                    <Badge tone="neutral">
                      <Sparkles className="h-3 w-3" />
                      {t("story.aiReady", { count: section.aiReadyCount })}
                    </Badge>
                  ) : null}
                </div>
              </div>
            </button>
          );
        })}
      </div>
    </Panel>
  );
}
