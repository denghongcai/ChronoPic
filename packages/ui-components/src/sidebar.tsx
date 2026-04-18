import type * as React from "react";
import { BookOpenIcon, CogIcon, ImageIcon, PlusIcon, StarIcon } from "lucide-react";

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
    <div className="space-y-1">
      <Label className="px-2 text-[10px] font-semibold uppercase tracking-widest text-stone-400">
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
        "flex w-full items-center gap-2.5 rounded-lg px-2.5 py-2 text-left text-sm transition-colors",
        active
          ? "bg-amber-50 font-medium text-amber-900"
          : "text-stone-600 hover:bg-stone-100 hover:text-stone-900"
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
    <aside className={cn("flex flex-col gap-5 overflow-y-auto p-4", className)}>
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
          active={activeItem === "memories"}
          icon={BookOpenIcon}
          label="Memories"
          onClick={() => onSelectItem?.("memories")}
        />
        <SidebarItem
          active={activeItem === "settings"}
          icon={CogIcon}
          label="Library Settings"
          onClick={() => onSelectItem?.("settings")}
        />
      </SidebarSection>

      <div className="h-px bg-stone-200/70" />

      <SidebarSection title="Memories">
        {memories.length === 0 ? (
          <p className="px-2.5 py-1 text-xs text-stone-400">No memories yet</p>
        ) : (
          memories.map((memory) => (
            <SidebarItem
              key={memory.id}
              active={activeItem === memory.id}
              label={memory.name}
              onClick={() => onSelectMemory?.(memory.id)}
            />
          ))
        )}
      </SidebarSection>

      <div className="mt-auto pt-4">
        <Button className="w-full" onClick={onCreateMemory} size="sm" variant="outline">
          <PlusIcon className="h-4 w-4" />
          Create Memory
        </Button>
      </div>
    </aside>
  );
}
