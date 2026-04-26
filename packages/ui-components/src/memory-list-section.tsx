import type { Memory } from "@chronopic/domain";

import { Badge } from "./badge.js";
import { Button } from "./button.js";
import { useI18n } from "./i18n-provider.js";
import { MemoryCard } from "./memory-card.js";
import { Panel } from "./panel.js";

export interface MemoryListSectionProps {
  memories: Memory[];
  selectedMemoryId?: string | null;
  onOpenMemory: (memoryId: string) => void;
  onCreateMemory?: () => void;
}

export function MemoryListSection({ memories, selectedMemoryId, onOpenMemory, onCreateMemory }: MemoryListSectionProps) {
  const { t } = useI18n();

  return (
    <Panel className="overflow-hidden">
      <div className="flex items-center justify-between border-b border-stone-200/70 px-5 py-4">
        <div>
          <p className="text-[11px] font-semibold uppercase tracking-[0.22em] text-stone-500">{t("sidebar.memories")}</p>
          <h2 className="mt-2 font-['Space_Grotesk','IBM_Plex_Sans',sans-serif] text-2xl font-semibold tracking-tight text-stone-950">
            {t("memories.browseTitle")}
          </h2>
          <p className="mt-2 text-sm text-stone-500">{t("memories.browseDescription")}</p>
        </div>
        <Badge tone="neutral">{t("memories.count", { count: memories.length })}</Badge>
      </div>

      <div className="p-5">
        {memories.length === 0 ? (
          <div className="grid min-h-[280px] place-items-center rounded-[24px] border border-dashed border-stone-300 bg-stone-50/70 px-6 text-center">
            <div className="max-w-sm space-y-3">
              <h3 className="text-lg font-semibold text-stone-900">{t("memories.noMemoriesYet")}</h3>
              <p className="text-sm leading-6 text-stone-500">{t("memories.emptyListDescription")}</p>
              {onCreateMemory ? (
                <div className="pt-2">
                  <Button onClick={onCreateMemory} variant="outline">
                    {t("memories.createFirst")}
                  </Button>
                </div>
              ) : null}
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
