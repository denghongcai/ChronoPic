import { Film, ImageIcon } from "lucide-react";

import type { PhotoRecord } from "@chronopic/domain";

export function assetUrl(host: "thumbs" | "media", assetPath: string | null): string | null {
  return assetPath ? `chronopic-asset://${host}/?path=${encodeURIComponent(assetPath)}` : null;
}

export function thumbnailUrl(thumbnailPath: string | null): string | null {
  return assetUrl("thumbs", thumbnailPath);
}

export function mediaUrl(assetPath: string | null): string | null {
  return assetUrl("media", assetPath);
}

export function formatTimestamp(timestamp: number | null): string {
  if (!timestamp) {
    return "unknown";
  }

  return new Intl.DateTimeFormat("zh-CN", {
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit"
  }).format(new Date(timestamp));
}

export function mediaLabel(record: PhotoRecord, fallback = "unknown"): string {
  return record.semantic.labels[0] ?? record.photo.path.split("/").at(-1) ?? fallback;
}

export function mediaIcon(mime: string) {
  return mime.startsWith("video/") ? Film : ImageIcon;
}

function displayPreviewUrl(record: PhotoRecord, preferOriginal: boolean): string | null {
  if (preferOriginal) {
    return mediaUrl(record.photo.path) ?? thumbnailUrl(record.photo.thumbnailPath);
  }

  return thumbnailUrl(record.photo.thumbnailPath) ?? mediaUrl(record.photo.path);
}

export interface MediaPreviewProps {
  record: PhotoRecord;
  className?: string;
  fit?: "cover" | "contain";
  preferOriginal?: boolean;
  controls?: boolean;
}

export function MediaPreview({
  record,
  className,
  fit = "cover",
  preferOriginal = false,
  controls = false
}: MediaPreviewProps) {
  const MediaIcon = mediaIcon(record.photo.mime);
  const mediaSource = displayPreviewUrl(record, preferOriginal);
  const fitClass = fit === "contain" ? "object-contain" : "object-cover";

  if (record.photo.mime.startsWith("video/")) {
    const videoSource = mediaUrl(record.photo.path);

    if (videoSource) {
      return (
        <video className={["h-full w-full bg-stone-950", fitClass, className].filter(Boolean).join(" ")} controls={controls} preload="metadata" src={videoSource} />
      );
    }
  }

  if (mediaSource) {
    return <img alt={record.photo.path} className={["h-full w-full", fitClass, className].filter(Boolean).join(" ")} src={mediaSource} />;
  }

  return (
    <div className={["grid h-full w-full place-items-center", className].filter(Boolean).join(" ")}>
      <MediaIcon className="h-12 w-12 text-stone-400" />
    </div>
  );
}
