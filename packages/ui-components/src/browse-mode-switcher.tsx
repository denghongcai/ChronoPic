import type { BrowseMode } from "@chronopic/domain";

import { Badge } from "./badge.js";
import { Button } from "./button.js";
import { cn } from "./lib/cn.js";

const browseModes: Array<{ description: string; label: string; value: BrowseMode }> = [
  { value: "waterfall", label: "Waterfall", description: "Visual scan" },
  { value: "map", label: "Map", description: "Places & GPS" },
  { value: "timeline", label: "Timeline", description: "Dates & periods" },
];

export interface BrowseModeSwitcherProps {
  className?: string;
  mode: BrowseMode;
  onModeChange: (mode: BrowseMode) => void;
}

export function BrowseModeSwitcher({ className, mode, onModeChange }: BrowseModeSwitcherProps) {
  return (
    <div
      className={cn(
        "flex flex-wrap items-center justify-between gap-3 rounded-[24px] border border-stone-200 bg-white px-4 py-3 shadow-sm",
        className
      )}
    >
      <div>
        <p className="text-[11px] font-semibold uppercase tracking-[0.22em] text-stone-500">Browse Mode</p>
        <p className="mt-1 text-sm text-stone-600">
          Switch the same result scope across visual, geographic, and temporal exploration modes.
        </p>
      </div>
      <div className="flex flex-wrap items-center gap-2">
        {browseModes.map((item) => (
          <Button
            key={item.value}
            onClick={() => onModeChange(item.value)}
            size="sm"
            variant={mode === item.value ? "accent" : "outline"}
          >
            {item.label}
            <Badge tone={mode === item.value ? "neutral" : "info"}>{item.description}</Badge>
          </Button>
        ))}
      </div>
    </div>
  );
}
