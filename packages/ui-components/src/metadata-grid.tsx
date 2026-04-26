import { BookMarked, Camera, Clock3, HardDrive, MapPinned, Sparkles } from "lucide-react";

import type { Memory, PhotoRecord } from "@chronopic/domain";

import { Badge } from "./badge.js";
import { useI18n } from "./i18n-provider.js";
import { getDiscoveryMatchSummary } from "./lib/discovery-match.js";
import { formatTimestamp, mediaIcon } from "./lib/media.js";

function MetaStat({
  icon: Icon,
  label,
  value
}: {
  icon: typeof HardDrive;
  label: string;
  value: string;
}) {
  return (
    <div className="rounded-2xl border border-stone-200 bg-stone-50/80 px-4 py-3">
      <div className="mb-2 inline-flex h-9 w-9 items-center justify-center rounded-xl bg-white text-stone-700 shadow-sm">
        <Icon className="h-4 w-4" />
      </div>
      <p className="text-[11px] font-semibold uppercase tracking-[0.16em] text-stone-500">{label}</p>
      <p className="mt-1 break-all text-sm leading-6 text-stone-900">{value}</p>
    </div>
  );
}

export function MetadataGrid({
  photo,
  aiEnabled,
  memories = [],
  searchQuery,
}: {
  photo: PhotoRecord;
  aiEnabled: boolean;
  memories?: Memory[];
  searchQuery?: string | null;
}) {
  const { t } = useI18n();
  const MediaIcon = mediaIcon(photo.photo.mime);
  const discoveryMatch = getDiscoveryMatchSummary(photo, memories, searchQuery, t);

  return (
    <div className="grid gap-3 sm:grid-cols-2">
      <MetaStat icon={HardDrive} label={t("metadata.path")} value={photo.photo.path} />
      <MetaStat icon={MediaIcon} label={t("metadata.mime")} value={photo.photo.mime} />
      <MetaStat icon={Clock3} label={t("metadata.datetime")} value={formatTimestamp(photo.metadata.datetime)} />
      <MetaStat icon={Camera} label={t("metadata.camera")} value={photo.metadata.camera ?? t("metadata.unknown")} />
      <MetaStat
        icon={MapPinned}
        label={t("metadata.gps")}
        value={photo.metadata.lat != null && photo.metadata.lng != null ? t("metadata.available") : t("metadata.unavailable")}
      />
      <MetaStat
        icon={Sparkles}
        label={t("filter.ai")}
        value={aiEnabled ? `${photo.semantic.aiStatus}${photo.semantic.aiModel ? ` · ${photo.semantic.aiModel}` : ""}` : t("metadata.disabled")}
      />
      {discoveryMatch ? (
        <div className="rounded-2xl border border-sky-200 bg-sky-50/80 px-4 py-3 sm:col-span-2">
          <div className="mb-2 inline-flex h-9 w-9 items-center justify-center rounded-xl bg-white text-sky-700 shadow-sm">
            <Sparkles className="h-4 w-4" />
          </div>
          <p className="text-[11px] font-semibold uppercase tracking-[0.16em] text-sky-600">{t("metadata.discoveryMatch")}</p>
          <p className="mt-2 text-sm leading-6 text-sky-900">{discoveryMatch.description}</p>
          <div className="mt-3 flex flex-wrap gap-2">
            {discoveryMatch.labels.map((label) => (
              <Badge key={label} tone="info">
                {label}
              </Badge>
            ))}
          </div>
        </div>
      ) : null}
      <div className="rounded-2xl border border-stone-200 bg-stone-50/80 px-4 py-3 sm:col-span-2">
        <div className="mb-2 inline-flex h-9 w-9 items-center justify-center rounded-xl bg-white text-stone-700 shadow-sm">
          <Sparkles className="h-4 w-4" />
        </div>
        <p className="text-[11px] font-semibold uppercase tracking-[0.16em] text-stone-500">{t("metadata.aiInsights")}</p>
        <div className="mt-3 space-y-3 text-sm text-stone-700">
          <div>
            <p className="text-[11px] font-semibold uppercase tracking-[0.14em] text-stone-500">{t("metadata.generatedCaption")}</p>
            <p className="mt-1 text-sm leading-6 text-stone-900">{photo.semantic.generatedCaption ?? t("metadata.notGeneratedYet")}</p>
          </div>
          <div>
            <p className="text-[11px] font-semibold uppercase tracking-[0.14em] text-stone-500">{t("metadata.summary")}</p>
            <p className="mt-1 text-sm leading-6 text-stone-900">{photo.semantic.summary ?? t("metadata.notGeneratedYet")}</p>
          </div>
          <div>
            <p className="text-[11px] font-semibold uppercase tracking-[0.14em] text-stone-500">{t("metadata.generatedTags")}</p>
            <div className="mt-2 flex flex-wrap gap-2">
              {photo.semantic.generatedLabels.length === 0 ? (
                <p className="text-sm text-stone-500">{t("metadata.noGeneratedTags")}</p>
              ) : (
                photo.semantic.generatedLabels.map((label) => (
                  <Badge key={label} tone="info">
                    {label}
                  </Badge>
                ))
              )}
            </div>
          </div>
          {photo.semantic.aiError ? (
            <div>
              <p className="text-[11px] font-semibold uppercase tracking-[0.14em] text-rose-500">{t("metadata.lastAiError")}</p>
              <p className="mt-1 text-sm leading-6 text-rose-600">{photo.semantic.aiError}</p>
            </div>
          ) : null}
        </div>
      </div>
      <div className="rounded-2xl border border-stone-200 bg-stone-50/80 px-4 py-3 sm:col-span-2">
        <div className="mb-2 inline-flex h-9 w-9 items-center justify-center rounded-xl bg-white text-stone-700 shadow-sm">
          <BookMarked className="h-4 w-4" />
        </div>
        <p className="text-[11px] font-semibold uppercase tracking-[0.16em] text-stone-500">{t("sidebar.memories")}</p>
        <div className="mt-2 flex flex-wrap gap-2">
          {memories.length === 0 ? (
            <p className="text-sm text-stone-500">{t("metadata.notSavedToMemory")}</p>
          ) : (
            memories.map((memory) => (
              <Badge key={memory.id} tone={memory.coverPhotoId === photo.photo.id ? "info" : "neutral"}>
                {memory.name}
                {memory.coverPhotoId === photo.photo.id ? ` ${t("common.cover")}` : ""}
              </Badge>
            ))
          )}
        </div>
      </div>
    </div>
  );
}
