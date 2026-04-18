import { Camera, Clock3, HardDrive, MapPinned, Sparkles } from "lucide-react";

import type { PhotoRecord } from "@chronopic/domain";

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

export function MetadataGrid({ photo, aiEnabled }: { photo: PhotoRecord; aiEnabled: boolean }) {
  const MediaIcon = mediaIcon(photo.photo.mime);

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
      <MetaStat icon={Sparkles} label="AI" value={aiEnabled ? photo.semantic.aiStatus : "Disabled"} />
    </div>
  );
}
