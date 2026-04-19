import type * as React from "react";
import { BellIcon, BookOpenIcon, Clock3Icon, CogIcon, ImageIcon, PlusIcon, SparklesIcon, StarIcon } from "lucide-react";

import type { Memory } from "@chronopic/domain";

import { Button } from "./button.js";
import { cn } from "./lib/cn.js";
import { Label } from "./label.js";

export interface SidebarProps {
  className?: string;
  activeItem?: string;
  onSelectItem?: (id: string) => void;
  memories?: Memory[];
  onSelectMemory?: (memoryId: string) => void;
  onCreateMemory?: () => void;
}

function SidebarSection({ children, title }: { children: React.ReactNode; title: string }) {
  return (
    <div className="space-y-2">
      <Label className="px-3 text-[10px] font-semibold uppercase tracking-[0.22em] text-stone-400">
        {title}
      </Label>
      {children}
    </div>
  );
}

function SidebarItem({
  active,
  icon: Icon,
  label,
  onClick,
}: {
  active?: boolean;
  icon?: React.ComponentType<{ className?: string }>;
  label: string;
  onClick?: () => void;
}) {
  return (
    <button
      className={cn(
        "flex w-full items-center gap-3 rounded-2xl px-3 py-2.5 text-left text-sm transition-all",
        active
          ? "bg-stone-950 font-medium text-white shadow-sm"
          : "text-stone-500 hover:bg-stone-100/90 hover:text-stone-900"
      )}
      onClick={onClick}
      type="button"
    >
      {Icon && <Icon className="h-4 w-4 shrink-0" />}
      <span className="truncate">{label}</span>
    </button>
  );
}

export function Sidebar({
  className,
  activeItem,
  onSelectItem,
  memories = [],
  onSelectMemory,
  onCreateMemory,
}: SidebarProps) {
  return (
    <aside className={cn("flex select-none flex-col gap-8 overflow-y-auto px-4 py-5", className)}>
      <div className="flex items-center gap-3 px-3">
        <div className="flex h-9 w-9 items-center justify-center rounded-full bg-gradient-to-br from-amber-400 to-orange-500 text-sm font-bold text-white shadow-sm">
          L
        </div>
        <div className="min-w-0 flex-1">
          <p className="font-['Space_Grotesk','IBM_Plex_Sans',sans-serif] text-base font-semibold tracking-tight text-stone-950">
            ChronoPic
          </p>
          <p className="text-xs text-stone-400">Curate your local photo world</p>
        </div>
        <button
          className="grid h-9 w-9 shrink-0 place-items-center rounded-full border border-stone-200 bg-white text-stone-500 shadow-sm transition hover:border-stone-300 hover:text-stone-900"
          type="button"
        >
          <BellIcon className="h-4 w-4" />
        </button>
      </div>

      <SidebarSection title="Library">
        <SidebarItem
          active={activeItem === "all"}
          icon={ImageIcon}
          label="All Photos"
          onClick={() => onSelectItem?.("all")}
        />
        <SidebarItem
          active={activeItem === "favorites"}
          icon={StarIcon}
          label="Favorites"
          onClick={() => onSelectItem?.("favorites")}
        />
        <SidebarItem
          icon={Clock3Icon}
          label="Recent"
          onClick={() => onSelectItem?.("recent")}
        />
        <SidebarItem
          active={activeItem === "settings"}
          icon={CogIcon}
          label="Settings"
          onClick={() => onSelectItem?.("settings")}
        />
      </SidebarSection>

      <SidebarSection title="Memories">
        {memories.length === 0 ? (
          <p className="px-3 py-1 text-xs text-stone-400">No memories yet</p>
        ) : (
          memories.map((memory) => (
            <SidebarItem
              key={memory.id}
              active={activeItem === memory.id}
              icon={activeItem === memory.id ? SparklesIcon : BookOpenIcon}
              label={memory.name}
              onClick={() => onSelectMemory?.(memory.id)}
            />
          ))
        )}
      </SidebarSection>

      <div className="mt-auto pt-4">
        <Button className="w-full rounded-2xl" onClick={onCreateMemory} size="sm" variant="outline">
          <PlusIcon className="h-4 w-4" />
          Create Memory
        </Button>
      </div>
    </aside>
  );
}
