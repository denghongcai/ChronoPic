import { CalendarClock } from "lucide-react";

import type { PhotoRecord } from "@chronopic/domain";

import { Badge } from "./badge.js";
import { useI18n } from "./i18n-provider.js";
import { Panel } from "./panel.js";
import { PhotoCard } from "./photo-card.js";

export interface PhotoGridProps {
  photos: PhotoRecord[];
  selectedPhotoId: string | null;
  onSelect: (photoId: string) => void;
  onOpenDetail: (photoId: string) => void;
}

export function PhotoGrid(props: PhotoGridProps) {
  const { t } = useI18n();

  return (
    <Panel className="overflow-hidden">
      <div className="flex items-center justify-between border-b border-stone-200/70 px-5 py-4">
        <div>
          <p className="text-[11px] font-semibold uppercase tracking-[0.22em] text-stone-500">{t("grid.mediaShelf")}</p>
          <h2 className="mt-2 font-['Space_Grotesk','IBM_Plex_Sans',sans-serif] text-2xl font-semibold tracking-tight text-stone-950">
            {t("grid.browseResults")}
          </h2>
          <p className="mt-2 text-sm text-stone-500">{t("grid.description")}</p>
        </div>
        <Badge tone="neutral">{t("common.items", { count: props.photos.length })}</Badge>
      </div>
      <div className="max-h-[68vh] overflow-auto p-5">
        {props.photos.length === 0 ? (
          <div className="grid min-h-[360px] place-items-center rounded-[24px] border border-dashed border-stone-300 bg-stone-50/70 px-6 text-center">
            <div className="max-w-sm space-y-3">
              <CalendarClock className="mx-auto h-12 w-12 text-stone-400" />
              <h3 className="text-lg font-semibold text-stone-900">{t("gallery.noMedia")}</h3>
              <p className="text-sm leading-6 text-stone-500">{t("gallery.emptyDescription")}</p>
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
