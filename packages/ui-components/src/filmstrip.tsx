import type { PhotoRecord } from "@chronopic/domain";

import { Badge } from "./badge.js";
import { cn } from "./lib/cn.js";
import { Label } from "./label.js";
import { FilmstripItem } from "./filmstrip-item.js";

export interface FilmstripProps {
  photos: PhotoRecord[];
  selectedPhotoId: string | null;
  onSelect: (photoId: string) => void;
  tone?: "light" | "dark";
}

export function Filmstrip({ photos, selectedPhotoId, onSelect, tone = "light" }: FilmstripProps) {
  const shellClass = tone === "dark" ? "border-stone-800 bg-stone-950/70" : "border-stone-200/80 bg-white/90";

  return (
    <div className={cn("rounded-[24px] border p-3", shellClass)}>
      <div className="mb-3 flex items-center justify-between">
        <Label>{tone === "dark" ? "Gallery Strip" : "Filmstrip"}</Label>
        <Badge tone={tone === "dark" ? "dark" : "neutral"}>{photos.length} items</Badge>
      </div>
      <div className="flex gap-3 overflow-x-auto pb-1">
        {photos.map((record) => (
          <FilmstripItem
            key={record.photo.id}
            onSelect={() => onSelect(record.photo.id)}
            record={record}
            selected={selectedPhotoId === record.photo.id}
            tone={tone}
          />
        ))}
      </div>
    </div>
  );
}
