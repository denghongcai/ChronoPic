import { BookMarked, Camera, Clock3, HardDrive, MapPinned, Sparkles } from "lucide-react";

import type { Memory, PhotoRecord } from "@chronopic/domain";

import { Badge } from "./badge.js";
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
  const MediaIcon = mediaIcon(photo.photo.mime);
  const discoveryMatch = getDiscoveryMatchSummary(photo, memories, searchQuery);

  return (
    <div className="grid gap-3 sm:grid-cols-2">
      <MetaStat icon={HardDrive} label="Path" value={photo.photo.path} />
      <MetaStat icon={MediaIcon} label="MIME" value={photo.photo.mime} />
      <MetaStat icon={Clock3} label="Datetime" value={formatTimestamp(photo.metadata.datetime)} />
      <MetaStat icon={Camera} label="Camera" value={photo.metadata.camera ?? "Unknown"} />
      <MetaStat
        icon={MapPinned}
        label="GPS"
        value={photo.metadata.lat != null && photo.metadata.lng != null ? "Available" : "Unavailable"}
      />
      <MetaStat
        icon={Sparkles}
        label="AI"
        value={aiEnabled ? `${photo.semantic.aiStatus}${photo.semantic.aiModel ? ` · ${photo.semantic.aiModel}` : ""}` : "Disabled"}
      />
      {discoveryMatch ? (
        <div className="rounded-2xl border border-sky-200 bg-sky-50/80 px-4 py-3 sm:col-span-2">
          <div className="mb-2 inline-flex h-9 w-9 items-center justify-center rounded-xl bg-white text-sky-700 shadow-sm">
            <Sparkles className="h-4 w-4" />
          </div>
          <p className="text-[11px] font-semibold uppercase tracking-[0.16em] text-sky-600">Discovery Match</p>
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
        <p className="text-[11px] font-semibold uppercase tracking-[0.16em] text-stone-500">AI Insights</p>
        <div className="mt-3 space-y-3 text-sm text-stone-700">
          <div>
            <p className="text-[11px] font-semibold uppercase tracking-[0.14em] text-stone-500">Generated Caption</p>
            <p className="mt-1 text-sm leading-6 text-stone-900">{photo.semantic.generatedCaption ?? "Not generated yet"}</p>
          </div>
          <div>
            <p className="text-[11px] font-semibold uppercase tracking-[0.14em] text-stone-500">Summary</p>
            <p className="mt-1 text-sm leading-6 text-stone-900">{photo.semantic.summary ?? "Not generated yet"}</p>
          </div>
          <div>
            <p className="text-[11px] font-semibold uppercase tracking-[0.14em] text-stone-500">Generated Tags</p>
            <div className="mt-2 flex flex-wrap gap-2">
              {photo.semantic.generatedLabels.length === 0 ? (
                <p className="text-sm text-stone-500">No generated tags yet</p>
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
              <p className="text-[11px] font-semibold uppercase tracking-[0.14em] text-rose-500">Last AI Error</p>
              <p className="mt-1 text-sm leading-6 text-rose-600">{photo.semantic.aiError}</p>
            </div>
          ) : null}
        </div>
      </div>
      <div className="rounded-2xl border border-stone-200 bg-stone-50/80 px-4 py-3 sm:col-span-2">
        <div className="mb-2 inline-flex h-9 w-9 items-center justify-center rounded-xl bg-white text-stone-700 shadow-sm">
          <BookMarked className="h-4 w-4" />
        </div>
        <p className="text-[11px] font-semibold uppercase tracking-[0.16em] text-stone-500">Memories</p>
        <div className="mt-2 flex flex-wrap gap-2">
          {memories.length === 0 ? (
            <p className="text-sm text-stone-500">Not saved to any memory yet</p>
          ) : (
            memories.map((memory) => (
              <Badge key={memory.id} tone={memory.coverPhotoId === photo.photo.id ? "info" : "neutral"}>
                {memory.name}
                {memory.coverPhotoId === photo.photo.id ? " cover" : ""}
              </Badge>
            ))
          )}
        </div>
      </div>
    </div>
  );
}
