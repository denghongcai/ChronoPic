import { BellIcon, SparklesIcon } from "lucide-react";

import { Button } from "./button.js";
import { useI18n } from "./i18n-provider.js";
import { cn } from "./lib/cn.js";

export interface HeaderProps {
  className?: string;
}

export function Header({ className }: HeaderProps) {
  const { t } = useI18n();

  return (
    <header
      className={cn(
        "flex h-14 items-center justify-between px-6 text-stone-500",
        className
      )}
    >
      <div className="flex items-center gap-2 text-xs font-medium uppercase tracking-[0.22em] text-stone-400">
        <SparklesIcon className="h-3.5 w-3.5 text-amber-500" />
        <span>{t("header.tagline")}</span>
      </div>

      <div className="flex items-center gap-2">
        <Button className="h-9 w-9 rounded-full p-0 text-stone-500" size="sm" variant="ghost">
          <BellIcon className="h-4 w-4" />
        </Button>
      </div>
    </header>
  );
}
