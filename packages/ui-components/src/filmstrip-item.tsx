import type { PhotoRecord } from "@chronopic/domain";

import { Button } from "./button.js";
import { cn } from "./lib/cn.js";
import { MediaPreview } from "./lib/media.js";

export interface FilmstripItemProps {
  record: PhotoRecord;
  selected: boolean;
  onSelect: () => void;
  tone?: "light" | "dark";
}

export function FilmstripItem({ record, selected, onSelect, tone = "light" }: FilmstripItemProps) {
  return (
    <Button
      className={cn(
        "group relative h-20 w-20 shrink-0 overflow-hidden rounded-2xl p-0",
        "shadow-none",
        tone === "dark" ? "bg-stone-950/70" : "bg-white/90",
        selected
          ? "border-amber-400 ring-2 ring-amber-300/70"
          : tone === "dark"
            ? "border-stone-700 hover:border-stone-500"
            : "border-stone-200 hover:border-stone-300"
      )}
      onClick={onSelect}
      type="button"
      variant="outline"
    >
      <div className={cn("absolute inset-0", tone === "dark" ? "bg-stone-900" : "bg-stone-100")}>
        <MediaPreview className="transition duration-200 group-hover:scale-[1.04]" record={record} />
      </div>
    </Button>
  );
}
