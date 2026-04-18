import type * as React from "react";
import { AlertTriangle, CheckCheck, Database, Layers3, ShieldCheck, Sparkles } from "lucide-react";

import type { AppCapabilities, LibrarySnapshot } from "@chronopic/domain";

import { Panel } from "./panel.js";

export interface HomeStatsProps {
  snapshot: LibrarySnapshot;
  capabilities: AppCapabilities;
  statusMessage: string;
  isScanning: boolean;
}

export function HomeStats({ snapshot, capabilities, statusMessage, isScanning }: HomeStatsProps) {
  return (
    <Panel className="overflow-hidden">
      <div className="grid gap-8 px-7 py-7 lg:grid-cols-[minmax(0,1fr)_360px] lg:px-9 lg:py-9">
        <div className="space-y-4">
          <div className="inline-flex items-center rounded-full border border-amber-300/50 bg-amber-50 px-3 py-1 text-[11px] font-semibold uppercase tracking-[0.28em] text-amber-700">
            ChronoPic Desktop
          </div>
          <div className="space-y-3">
            <h1 className="max-w-3xl font-['Space_Grotesk','IBM_Plex_Sans',sans-serif] text-4xl font-semibold tracking-tight text-stone-950 lg:text-5xl">
              Local-first album workspace with cleaner timelines and safer indexing.
            </h1>
            <p className="max-w-2xl text-sm leading-7 text-stone-600 lg:text-base">
              Browse local media, fix timeline metadata, review duplicates, and keep the AI layer deferred without
              weakening the core desktop experience.
            </p>
          </div>
        </div>
        <div className="grid gap-3 self-start">
          <div className="grid gap-3 sm:grid-cols-2">
            <StatusTile icon={Layers3} label="Library Sources" tone="amber" value={String(snapshot.sources.length)} />
            <StatusTile icon={Database} label="Indexed Photos" tone="blue" value={String(snapshot.stats.indexedPhotos)} />
          </div>
          <div className="grid gap-3 sm:grid-cols-2">
            <StatusTile icon={ShieldCheck} label="Status" tone="stone" value={isScanning ? "Scanning..." : statusMessage} />
            <StatusTile
              icon={Sparkles}
              label="AI Pipeline"
              tone="emerald"
              value={capabilities.aiEnabled ? "Enabled" : "Deferred"}
            />
          </div>
        </div>
      </div>
    </Panel>
  );
}

function StatusTile({
  icon: Icon,
  label,
  tone,
  value,
}: {
  icon: React.ComponentType<{ className?: string }>;
  label: string;
  tone: "amber" | "blue" | "emerald" | "stone";
  value: string;
}) {
  const toneClasses = {
    amber: "bg-amber-50 text-amber-700",
    blue: "bg-blue-50 text-blue-700",
    emerald: "bg-emerald-50 text-emerald-700",
    stone: "bg-stone-100 text-stone-700",
  };

  return (
    <div className="rounded-2xl border border-stone-200 bg-white p-4 shadow-sm">
      <div className={`mb-3 inline-flex h-10 w-10 items-center justify-center rounded-xl ${toneClasses[tone]}`}>
        <Icon className="h-5 w-5" />
      </div>
      <p className="text-[11px] font-semibold uppercase tracking-[0.16em] text-stone-500">{label}</p>
      <p className="mt-1 text-xl font-semibold tracking-tight text-stone-950">{value}</p>
    </div>
  );
}
