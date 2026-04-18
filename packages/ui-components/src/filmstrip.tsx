import type { PhotoRecord } from "@chronopic/domain";

import { Badge } from "./badge.js";
import { Button } from "./button.js";
import { cn } from "./lib/cn.js";
import { MediaPreview } from "./lib/media.js";
import { Label } from "./label.js";

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
          <Button
            className={cn(
              "group relative h-20 w-20 shrink-0 overflow-hidden rounded-2xl p-0",
              "shadow-none",
              tone === "dark" ? "bg-stone-950/70" : "bg-white/90",
              selectedPhotoId === record.photo.id
                ? "border-amber-400 ring-2 ring-amber-300/70"
                : tone === "dark"
                  ? "border-stone-700 hover:border-stone-500"
                  : "border-stone-200 hover:border-stone-300"
            )}
            key={record.photo.id}
            onClick={() => onSelect(record.photo.id)}
            type="button"
            variant="outline"
          >
            <div className={cn("absolute inset-0", tone === "dark" ? "bg-stone-900" : "bg-stone-100")}>
              <MediaPreview className="transition duration-200 group-hover:scale-[1.04]" record={record} />
            </div>
          </Button>
        ))}
      </div>
    </div>
  );
}
