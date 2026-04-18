import type { Memory } from "@chronopic/domain";

import { Badge } from "./badge.js";
import { MemoryCard } from "./memory-card.js";
import { Panel } from "./panel.js";

export interface MemoryListSectionProps {
  memories: Memory[];
  selectedMemoryId?: string | null;
  onOpenMemory: (memoryId: string) => void;
}

export function MemoryListSection({ memories, selectedMemoryId, onOpenMemory }: MemoryListSectionProps) {
  return (
    <Panel className="overflow-hidden">
      <div className="flex items-center justify-between border-b border-stone-200/70 px-5 py-4">
        <div>
          <p className="text-[11px] font-semibold uppercase tracking-[0.22em] text-stone-500">Memories</p>
          <h2 className="mt-2 font-['Space_Grotesk','IBM_Plex_Sans',sans-serif] text-2xl font-semibold tracking-tight text-stone-950">
            Browse memory collections
          </h2>
          <p className="mt-2 text-sm text-stone-500">Open a memory to review its story, edit metadata, and manage contained photos.</p>
        </div>
        <Badge tone="neutral">{memories.length} memories</Badge>
      </div>

      <div className="p-5">
        {memories.length === 0 ? (
          <div className="grid min-h-[280px] place-items-center rounded-[24px] border border-dashed border-stone-300 bg-stone-50/70 px-6 text-center">
            <div className="max-w-sm space-y-3">
              <h3 className="text-lg font-semibold text-stone-900">No memories yet</h3>
              <p className="text-sm leading-6 text-stone-500">Create a memory to group photos into a reusable story object instead of a temporary filter.</p>
            </div>
          </div>
        ) : (
          <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
            {memories.map((memory) => (
              <MemoryCard
                key={memory.id}
                memory={memory}
                onOpen={() => onOpenMemory(memory.id)}
                selected={selectedMemoryId === memory.id}
              />
            ))}
          </div>
        )}
      </div>
    </Panel>
  );
}
