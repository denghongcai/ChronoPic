import type { BrowseMode } from "@chronopic/domain";
import { CalendarDaysIcon, LayoutGridIcon, MapIcon } from "lucide-react";

import { Button } from "./button.js";
import { cn } from "./lib/cn.js";

const browseModes: Array<{ description: string; icon: typeof LayoutGridIcon; label: string; value: BrowseMode }> = [
  { value: "waterfall", label: "Waterfall", description: "Visual scan", icon: LayoutGridIcon },
  { value: "map", label: "Map", description: "Places & GPS", icon: MapIcon },
  { value: "timeline", label: "Timeline", description: "Dates & periods", icon: CalendarDaysIcon },
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
        "inline-flex flex-wrap items-center gap-1 rounded-full border border-stone-200 bg-white/88 p-1 shadow-sm",
        "select-none",
        className
      )}
    >
      {browseModes.map((item) => {
        const Icon = item.icon;
        return (
          <Button
            key={item.value}
            className="rounded-full"
            onClick={() => onModeChange(item.value)}
            size="sm"
            variant={mode === item.value ? "secondary" : "ghost"}
          >
            <Icon className="h-3.5 w-3.5" />
            {item.label}
          </Button>
        );
      })}
    </div>
  );
}
