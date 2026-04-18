import { CalendarClock, ChevronRight } from "lucide-react";

import type { Memory } from "@chronopic/domain";

import { Panel } from "./panel.js";
import { Button } from "./button.js";
import { Badge } from "./badge.js";
import { MemoryCard } from "./memory-card.js";

export interface RecentMemoriesProps {
  memories: Memory[];
  selectedMemoryId?: string | null;
  onOpenMemory?: (memoryId: string) => void;
  onSeeAll?: () => void;
}

export function RecentMemories({
  memories,
  selectedMemoryId,
  onOpenMemory,
  onSeeAll,
}: RecentMemoriesProps) {
  if (memories.length === 0) return null;

  return (
    <Panel className="overflow-hidden">
      <div className="flex items-center justify-between border-b border-stone-200/70 px-5 py-4">
        <div className="flex items-center gap-2">
          <CalendarClock className="h-4 w-4 text-amber-500" />
          <h3 className="font-semibold text-stone-900">Recent Memories</h3>
          <Badge tone="neutral">{memories.length}</Badge>
        </div>
        <Button className="text-stone-500" onClick={onSeeAll} size="sm" variant="ghost">
          See All Recent
          <ChevronRight className="h-4 w-4" />
        </Button>
      </div>
      <div className="flex gap-4 overflow-x-auto p-5 pb-4">
        {memories.slice(0, 6).map((memory) => (
          <div className="w-48 shrink-0" key={memory.id}>
            <MemoryCard
              memory={memory}
              onOpen={() => onOpenMemory?.(memory.id)}
              selected={selectedMemoryId === memory.id}
            />
          </div>
        ))}
      </div>
    </Panel>
  );
}
