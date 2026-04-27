import type { PhotoRecord } from "@chronopic/domain";

export interface MemoryStorySection {
  id: string;
  monthKey: string | null;
  photoCount: number;
  coverPhotoId: string | null;
  coverThumbnailPath: string | null;
  fromDatetime: number | null;
  toDatetime: number | null;
  gpsCount: number;
  aiReadyCount: number;
}

function getMonthKey(timestamp: number): string {
  const date = new Date(timestamp);
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, "0");

  return `${year}-${month}`;
}

export function buildMemoryStorySections(records: PhotoRecord[]): MemoryStorySection[] {
  if (records.length === 0) {
    return [];
  }

  const sorted = [...records].sort((left, right) => {
    const leftTime = left.metadata.datetime ?? left.photo.updatedAt;
    const rightTime = right.metadata.datetime ?? right.photo.updatedAt;

    return leftTime - rightTime;
  });

  const grouped = new Map<string, PhotoRecord[]>();

  for (const record of sorted) {
    const key = record.metadata.datetime ? getMonthKey(record.metadata.datetime) : "undated";
    const bucket = grouped.get(key) ?? [];
    bucket.push(record);
    grouped.set(key, bucket);
  }

  return [...grouped.entries()].map(([key, group], index) => {
    const dated = group
      .map((record) => record.metadata.datetime)
      .filter((datetime): datetime is number => datetime != null)
      .sort((left, right) => left - right);
    const cover = group.find((record) => record.photo.thumbnailPath != null) ?? group[0] ?? null;
    const fromDatetime = dated[0] ?? null;
    const toDatetime = dated.at(-1) ?? null;
    const gpsCount = group.filter((record) => record.metadata.lat != null && record.metadata.lng != null).length;
    const aiReadyCount = group.filter((record) => record.semantic.aiStatus === "completed").length;

    return {
      id: key === "undated" ? `undated-${index}` : key,
      monthKey: key === "undated" ? null : key,
      photoCount: group.length,
      coverPhotoId: cover?.photo.id ?? null,
      coverThumbnailPath: cover?.photo.thumbnailPath ?? null,
      fromDatetime,
      toDatetime,
      gpsCount,
      aiReadyCount,
    };
  });
}
