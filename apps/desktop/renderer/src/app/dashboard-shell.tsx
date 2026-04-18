import { Database, Layers3, ShieldCheck, Sparkles } from "lucide-react";

import type { AppCapabilities, LibrarySnapshot, PhotoFilter, PhotoFilterPatch, PhotoRecord } from "@chronopic/domain";
import { DetailPanel, FilterToolbar, LibrarySidebar, PhotoGrid } from "@chronopic/ui-components";

import { StatusTile } from "./status-tile";

interface DashboardShellProps {
  snapshot: LibrarySnapshot;
  capabilities: AppCapabilities;
  statusMessage: string;
  isScanning: boolean;
  filter: PhotoFilter;
  photos: PhotoRecord[];
  selectedPhotoId: string | null;
  selectedPhoto: PhotoRecord | null;
  draftTags: string;
  draftDatetime: string;
  onChangeFilter: (patch: PhotoFilterPatch) => void;
  onAddLibrary: () => void;
  onScanAll: () => void;
  onSelectPhoto: (photoId: string) => void;
  onOpenDetail: (photoId?: string) => void;
  onOpenGallery: () => void;
  onChangeDraftTags: (value: string) => void;
  onChangeDraftDatetime: (value: string) => void;
  onSaveTags: () => void;
  onSaveDatetime: () => void;
  onRollback: () => void;
}

export function DashboardShell(props: DashboardShellProps) {
  return (
    <div className="min-h-screen">
      <div className="mx-auto grid max-w-[1680px] gap-6 px-4 py-6 xl:grid-cols-[340px_minmax(0,1fr)] xl:px-6">
        <LibrarySidebar isScanning={props.isScanning} onAddLibrary={props.onAddLibrary} onScanAll={props.onScanAll} snapshot={props.snapshot} />
        <main className="grid gap-6">
          <header className="overflow-hidden rounded-[32px] border border-stone-200/70 bg-white/80 shadow-[0_24px_80px_-48px_rgba(24,24,27,0.45)] backdrop-blur">
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
                  <StatusTile icon={Layers3} label="Library Sources" tone="amber" value={String(props.snapshot.sources.length)} />
                  <StatusTile icon={Database} label="Indexed Photos" tone="blue" value={String(props.snapshot.stats.indexedPhotos)} />
                </div>
                <div className="grid gap-3 sm:grid-cols-2">
                  <StatusTile icon={ShieldCheck} label="Status" tone="stone" value={props.statusMessage} />
                  <StatusTile
                    icon={Sparkles}
                    label="AI Pipeline"
                    tone="emerald"
                    value={props.capabilities.aiEnabled ? "Enabled" : "Deferred"}
                  />
                </div>
              </div>
            </div>
          </header>
          <FilterToolbar filter={props.filter} onChange={props.onChangeFilter} />
          <section className="grid gap-6 2xl:grid-cols-[minmax(0,1fr)_390px]">
            <PhotoGrid
              onOpenDetail={(photoId) => props.onOpenDetail(photoId)}
              onSelect={props.onSelectPhoto}
              photos={props.photos}
              selectedPhotoId={props.selectedPhotoId}
            />
            <DetailPanel
              aiEnabled={props.capabilities.aiEnabled}
              draftDatetime={props.draftDatetime}
              draftTags={props.draftTags}
              onDatetimeChange={props.onChangeDraftDatetime}
              onOpenDetail={() => props.onOpenDetail()}
              onOpenGallery={props.onOpenGallery}
              onRollback={props.onRollback}
              onSaveDatetime={props.onSaveDatetime}
              onSaveTags={props.onSaveTags}
              onTagsChange={props.onChangeDraftTags}
              photo={props.selectedPhoto}
            />
          </section>
        </main>
      </div>
    </div>
  );
}
