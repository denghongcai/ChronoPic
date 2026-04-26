import type { BrowseMode } from "@chronopic/domain";
import { CalendarDaysIcon, LayoutGridIcon, MapIcon } from "lucide-react";

import { Button } from "./button.js";
import { useI18n } from "./i18n-provider.js";
import { cn } from "./lib/cn.js";

const browseModes: Array<{ icon: typeof LayoutGridIcon; labelKey: "browse.mode.waterfall" | "browse.mode.map" | "browse.mode.timeline"; value: BrowseMode }> = [
  { value: "waterfall", labelKey: "browse.mode.waterfall", icon: LayoutGridIcon },
  { value: "map", labelKey: "browse.mode.map", icon: MapIcon },
  { value: "timeline", labelKey: "browse.mode.timeline", icon: CalendarDaysIcon },
];

export interface BrowseModeSwitcherProps {
  className?: string;
  mode: BrowseMode;
  onModeChange: (mode: BrowseMode) => void;
}

export function BrowseModeSwitcher({ className, mode, onModeChange }: BrowseModeSwitcherProps) {
  const { t } = useI18n();

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
            {t(item.labelKey)}
          </Button>
        );
      })}
    </div>
  );
}
