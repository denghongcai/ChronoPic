import { BookMarked, Plus } from "lucide-react";

import type { Memory } from "@chronopic/domain";

import { Button } from "./button.js";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "./dropdown-menu.js";
import { IconButton } from "./icon-button.js";

export interface AddToMemoryMenuProps {
  memories: Memory[];
  onAddToMemory: (memoryId: string) => void;
  trigger?: "button" | "icon";
  label?: string;
  tone?: "light" | "dark";
  buttonVariant?: "ghost" | "outline" | "accent";
}

export function AddToMemoryMenu({
  memories,
  onAddToMemory,
  trigger = "button",
  label = "Add to Memory",
  tone = "light",
  buttonVariant,
}: AddToMemoryMenuProps) {
  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        {trigger === "icon" ? (
          <IconButton
            icon={<Plus className="h-4 w-4" />}
            label={label}
            size="sm"
            tone={tone}
          />
        ) : (
          <Button variant={buttonVariant ?? (tone === "dark" ? "ghost" : "outline")}>
            <BookMarked className="h-4 w-4" />
            {label}
          </Button>
        )}
      </DropdownMenuTrigger>
      <DropdownMenuContent align="end" className="w-64">
        <DropdownMenuLabel>Add photo to memory</DropdownMenuLabel>
        <DropdownMenuSeparator />
        {memories.length === 0 ? (
          <DropdownMenuItem disabled>No memories yet</DropdownMenuItem>
        ) : (
          memories.map((memory) => (
            <DropdownMenuItem key={memory.id} onClick={() => onAddToMemory(memory.id)}>
              <BookMarked className="mr-2 h-4 w-4 text-stone-500" />
              <span className="flex-1 truncate">{memory.name}</span>
              <span className="text-xs text-stone-400">{memory.photoCount}</span>
            </DropdownMenuItem>
          ))
        )}
      </DropdownMenuContent>
    </DropdownMenu>
  );
}
