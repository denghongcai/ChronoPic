import { AlertTriangle, CheckCheck, FolderOpen, FolderPlus, HardDrive, LoaderCircle, Sparkles } from "lucide-react";

import type { LibrarySnapshot } from "@chronopic/domain";

import { formatTimestamp } from "./lib/media.js";
import { Badge, Button, FieldLabel, Panel } from "./primitives.js";

export interface LibrarySidebarProps {
  snapshot: LibrarySnapshot;
  isScanning: boolean;
  onAddLibrary: () => void;
  onScanAll: () => void;
}

export function LibrarySidebar(props: LibrarySidebarProps) {
  const stats = [
    { label: "Total", value: props.snapshot.stats.totalPhotos, icon: HardDrive },
    { label: "Indexed", value: props.snapshot.stats.indexedPhotos, icon: CheckCheck },
    { label: "Errors", value: props.snapshot.stats.erroredPhotos, icon: AlertTriangle },
    { label: "Duplicates", value: props.snapshot.stats.duplicatePhotos, icon: Sparkles }
  ];

  return (
    <aside className="grid content-start gap-4 xl:sticky xl:top-6">
      <Panel className="overflow-hidden">
        <div className="border-b border-stone-200/70 bg-gradient-to-br from-stone-950 via-stone-900 to-amber-950 px-5 py-6 text-stone-50">
          <p className="text-[11px] font-semibold uppercase tracking-[0.28em] text-amber-200">Library Control</p>
          <h2 className="mt-3 font-['Space_Grotesk','IBM_Plex_Sans',sans-serif] text-2xl font-semibold tracking-tight">
            Sources & scans
          </h2>
          <p className="mt-2 text-sm leading-6 text-stone-300">
            Register local folders, inspect indexing health, and re-run scans when the library changes.
          </p>
        </div>
        <div className="grid gap-4 p-5">
          <div className="grid gap-2 sm:grid-cols-2 xl:grid-cols-1">
            <Button className="w-full justify-start" onClick={props.onAddLibrary} variant="accent">
              <FolderPlus className="h-4 w-4" />
              Add Folder
            </Button>
            <Button className="w-full justify-start" disabled={props.isScanning} onClick={props.onScanAll} variant="outline">
              {props.isScanning ? <LoaderCircle className="h-4 w-4 animate-spin" /> : <FolderOpen className="h-4 w-4" />}
              {props.isScanning ? "Scanning..." : "Scan Library"}
            </Button>
          </div>
          <div className="grid grid-cols-2 gap-3">
            {stats.map((item) => {
              const Icon = item.icon;

              return (
                <div className="rounded-2xl border border-stone-200 bg-stone-50/80 p-3.5" key={item.label}>
                  <div className="mb-2 inline-flex h-9 w-9 items-center justify-center rounded-xl bg-white text-stone-700 shadow-sm">
                    <Icon className="h-4 w-4" />
                  </div>
                  <p className="text-[11px] font-semibold uppercase tracking-[0.16em] text-stone-500">{item.label}</p>
                  <p className="mt-1 text-xl font-semibold tracking-tight text-stone-950">{item.value}</p>
                </div>
              );
            })}
          </div>
          <div className="space-y-3">
            <div className="flex items-center justify-between">
              <FieldLabel>Registered Sources</FieldLabel>
              <Badge tone="info">{props.snapshot.sources.length} active</Badge>
            </div>
            <div className="grid max-h-[38vh] gap-3 overflow-auto pr-1">
              {props.snapshot.sources.map((source) => (
                <div className="rounded-2xl border border-stone-200 bg-white px-4 py-3.5 shadow-sm" key={source.id}>
                  <div className="mb-2 flex items-start gap-3">
                    <div className="mt-0.5 inline-flex h-9 w-9 items-center justify-center rounded-xl bg-amber-50 text-amber-700">
                      <FolderOpen className="h-4 w-4" />
                    </div>
                    <div className="min-w-0 flex-1">
                      <p className="break-all text-sm font-medium leading-6 text-stone-900">{source.path}</p>
                    </div>
                  </div>
                  <p className="text-xs leading-5 text-stone-500">Last scan: {formatTimestamp(source.lastScanAt)}</p>
                </div>
              ))}
              {props.snapshot.sources.length === 0 ? (
                <div className="rounded-2xl border border-dashed border-stone-300 bg-stone-50/70 px-5 py-10 text-center">
                  <FolderPlus className="mx-auto mb-3 h-10 w-10 text-stone-400" />
                  <p className="text-sm font-medium text-stone-700">No folders added yet</p>
                  <p className="mt-2 text-sm leading-6 text-stone-500">Add a source folder to start indexing and generating thumbnails.</p>
                </div>
              ) : null}
            </div>
          </div>
        </div>
      </Panel>
    </aside>
  );
}
