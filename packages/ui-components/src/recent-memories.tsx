import { ChevronRight, Plus } from "lucide-react";

import type { Memory } from "@chronopic/domain";

import { Button } from "./button.js";
import { Badge } from "./badge.js";
import { MemoryCard } from "./memory-card.js";

export interface RecentMemoriesProps {
  memories: Memory[];
  selectedMemoryId?: string | null;
  onOpenMemory?: (memoryId: string) => void;
  onSeeAll?: () => void;
  onCreateMemory?: () => void;
}

export function RecentMemories({
  memories,
  selectedMemoryId,
  onOpenMemory,
  onSeeAll,
  onCreateMemory,
}: RecentMemoriesProps) {
  return (
    <section className="select-none space-y-5">
      <div className="flex items-end justify-between gap-4">
        <div className="space-y-2">
          <div className="flex items-center gap-2">
            <p className="text-[11px] font-semibold uppercase tracking-[0.22em] text-stone-400">Discover</p>
            <span className="h-1 w-1 rounded-full bg-stone-300" />
            <p className="text-[11px] font-semibold uppercase tracking-[0.22em] text-stone-400">Highlights</p>
          </div>
          <div className="flex items-center gap-3">
            <h2 className="font-['Space_Grotesk','IBM_Plex_Sans',sans-serif] text-[2.15rem] font-semibold tracking-tight text-stone-950">
              Recent Memories
            </h2>
            <Badge tone="neutral">{memories.length}</Badge>
          </div>
        </div>
        {memories.length > 0 ? (
          <Button className="rounded-full px-4 text-stone-500" onClick={onSeeAll} size="sm" variant="ghost">
            See All Recent
            <ChevronRight className="h-4 w-4" />
          </Button>
        ) : null}
      </div>

      {memories.length === 0 ? (
        <div className="grid min-h-[260px] place-items-center rounded-[36px] border border-dashed border-stone-300 bg-white/70 px-6 py-8 text-center shadow-[0_18px_42px_-30px_rgba(15,23,42,0.28)]">
          <div className="max-w-md space-y-3">
            <p className="text-lg font-semibold text-stone-900">No recent memories yet</p>
            <p className="text-sm leading-6 text-stone-500">
              Create a memory to pin a cover image, write a description, and keep a reusable story object outside the gallery filter flow.
            </p>
            {onCreateMemory ? (
              <div className="pt-2">
                <Button className="rounded-full" onClick={onCreateMemory} variant="outline">
                  Create First Memory
                </Button>
              </div>
            ) : null}
          </div>
        </div>
      ) : (
        <div className="grid gap-5 xl:grid-cols-[minmax(0,1fr)_minmax(0,1fr)_320px]">
          {memories.slice(0, 2).map((memory) => (
            <MemoryCard
              key={memory.id}
              memory={memory}
              onOpen={() => onOpenMemory?.(memory.id)}
              selected={selectedMemoryId === memory.id}
              variant="highlight"
            />
          ))}
          <button
            className="grid min-h-[220px] place-items-center rounded-[32px] border border-dashed border-stone-300 bg-white/50 text-center shadow-[0_18px_42px_-30px_rgba(15,23,42,0.2)] transition hover:-translate-y-0.5 hover:bg-white hover:shadow-[0_24px_52px_-32px_rgba(15,23,42,0.24)]"
            onClick={() => onCreateMemory?.()}
            type="button"
          >
            <div className="space-y-3">
              <div className="mx-auto grid h-11 w-11 place-items-center rounded-full border border-stone-200 bg-white text-stone-500 shadow-sm">
                <Plus className="h-4 w-4" />
              </div>
              <div className="space-y-1">
                <p className="text-base font-semibold text-stone-900">New Memory</p>
                <p className="text-sm text-stone-500">Create a new memory from your library.</p>
              </div>
            </div>
          </button>
        </div>
      )}
    </section>
  );
}
