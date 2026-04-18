import * as React from "react";

import type { AppCapabilities, LibrarySnapshot, Memory, PhotoFilter, PhotoFilterPatch, PhotoRecord } from "@chronopic/domain";

import { CreateMemoryDialog } from "./create-memory-dialog.js";
import { GallerySection } from "./gallery-section.js";
import { Header } from "./header.js";
import { PhotoViewerOverlay } from "./photo-viewer-overlay.js";
import { RecentMemories } from "./recent-memories.js";
import { Sidebar } from "./sidebar.js";
import { PageViewContext, type PageView } from "./page-view.js";
import type { EditControlsProps } from "./edit-controls.js";
import type { ViewerMode } from "./types.js";

export interface PhotoHomeProps extends EditControlsProps {
  photos: PhotoRecord[];
  selectedPhotoId: string | null;
  viewerMode: ViewerMode | null;
  viewerPhoto: PhotoRecord | null;
  filter: PhotoFilter;
  searchQuery: string;
  snapshot: LibrarySnapshot;
  isScanning: boolean;
  aiEnabled: boolean;
  memories: Memory[];
  onSelectPhoto: (photoId: string) => void;
  onOpenDetail: (photoId: string) => void;
  onFilterChange: (patch: PhotoFilterPatch) => void;
  onSearchChange: (query: string) => void;
  onAddLibrary: () => void;
  onScanAll: () => void;
  onCloseViewer: () => void;
  onPreviousPhoto: () => void;
  onNextPhoto: () => void;
  onSelectViewerPhoto: (photoId: string) => void;
  onSwitchViewerMode: (mode: ViewerMode) => void;
  onSelectMemory: (memoryId: string) => void;
  onConfirmCreateMemory: (name: string) => void;
  onToggleFavorite: (photoId: string, favorite: boolean) => void;
  canNavigatePrevious: boolean;
  canNavigateNext: boolean;
}

function HomeView({
  photos,
  recentPhotos,
  selectedPhotoId,
  filter,
  onFilterChange,
  onSelectPhoto,
  onOpenDetail,
  onToggleFavorite,
}: {
  photos: PhotoRecord[];
  recentPhotos: PhotoRecord[];
  selectedPhotoId: string | null;
  filter: PhotoFilter;
  onFilterChange: (patch: PhotoFilterPatch) => void;
  onSelectPhoto: (photoId: string) => void;
  onOpenDetail: (photoId: string) => void;
  onToggleFavorite: (photoId: string, favorite: boolean) => void;
}) {
  return (
    <div className="space-y-6">
      <RecentMemories
        onOpenDetail={onOpenDetail}
        onSelect={onSelectPhoto}
        photos={recentPhotos}
        selectedPhotoId={selectedPhotoId}
      />
      <GallerySection
        filter={filter}
        onFilterChange={onFilterChange}
        onOpenDetail={onOpenDetail}
        onSelect={onSelectPhoto}
        onToggleFavorite={onToggleFavorite}
        photos={photos}
        selectedPhotoId={selectedPhotoId}
      />
    </div>
  );
}

export function PhotoHome({
  photos,
  selectedPhotoId,
  viewerMode,
  viewerPhoto,
  filter,
  searchQuery,
  snapshot,
  isScanning,
  aiEnabled,
  memories,
  onSelectPhoto,
  onOpenDetail,
  onFilterChange,
  onSearchChange,
  onAddLibrary,
  onScanAll,
  onCloseViewer,
  onPreviousPhoto,
  onNextPhoto,
  onSelectViewerPhoto,
  onSwitchViewerMode,
  onSelectMemory,
  onConfirmCreateMemory,
  onToggleFavorite,
  canNavigatePrevious,
  canNavigateNext,
  draftCaption,
  draftDatetime,
  draftTags,
  onCaptionChange,
  onDatetimeChange,
  onTagsChange,
  onSaveCaption,
  onSaveDatetime,
  onSaveTags,
  onRollback,
}: PhotoHomeProps) {
  const [page, setPage] = React.useState<PageView>("home");
  const [createMemoryDialogOpen, setCreateMemoryDialogOpen] = React.useState(false);

  const recentPhotos = React.useMemo(
    () =>
      [...photos]
        .sort((a, b) => {
          const aTime = a.metadata.datetime ?? 0;
          const bTime = b.metadata.datetime ?? 0;
          return bTime - aTime;
        })
        .slice(0, 6),
    [photos]
  );

  return (
    <PageViewContext.Provider value={{ page, setPage }}>
      <div className="flex h-screen flex-col overflow-hidden bg-stone-50">
        <Header
          onOpenLibrarySettings={() => setPage("library-settings")}
          onSearchChange={onSearchChange}
          searchQuery={searchQuery}
        />

        <div className="flex flex-1 overflow-hidden">
          {/* Sidebar */}
          <Sidebar
            activeItem={page === "library-settings" ? "settings" : "all"}
            memories={memories}
            className="w-56 shrink-0 border-r border-stone-200/80 bg-white"
            onSelectItem={(id) => {
              if (id === "settings") setPage("library-settings");
              else setPage("home");
            }}
            onSelectMemory={onSelectMemory}
            onCreateMemory={() => setCreateMemoryDialogOpen(true)}
          />

          {/* Main content */}
          <main className="flex-1 overflow-y-auto">
            {page === "library-settings" ? (
              <div className="p-6">
                <div className="rounded-[32px] border border-stone-200/70 bg-white p-6 shadow-sm">
                  <LibrarySettingsPanel
                    isScanning={isScanning}
                    onAddLibrary={onAddLibrary}
                    onScanAll={onScanAll}
                    snapshot={snapshot}
                  />
                </div>
              </div>
            ) : (
              <div className="p-6">
                <HomeView
                  onOpenDetail={onOpenDetail}
                  onSelectPhoto={onSelectPhoto}
                  photos={photos}
                  recentPhotos={recentPhotos}
                  selectedPhotoId={selectedPhotoId}
                  filter={filter}
                  onFilterChange={onFilterChange}
                  onToggleFavorite={onToggleFavorite}
                />
              </div>
            )}
          </main>
        </div>

        <PhotoViewerOverlay
          aiEnabled={aiEnabled}
          canNavigateNext={canNavigateNext}
          canNavigatePrevious={canNavigatePrevious}
          draftCaption={draftCaption}
          draftDatetime={draftDatetime}
          draftTags={draftTags}
          mode={viewerMode}
          onCaptionChange={onCaptionChange}
          onClose={onCloseViewer}
          onDatetimeChange={onDatetimeChange}
          onNext={onNextPhoto}
          onPrevious={onPreviousPhoto}
          onRollback={onRollback}
          onSaveCaption={onSaveCaption}
          onSaveDatetime={onSaveDatetime}
          onSaveTags={onSaveTags}
          onSelectPhoto={onSelectViewerPhoto}
          onSwitchMode={onSwitchViewerMode}
          onTagsChange={onTagsChange}
          photo={viewerPhoto}
          photos={photos}
          selectedPhotoId={selectedPhotoId}
        />

        <CreateMemoryDialog
          open={createMemoryDialogOpen}
          onOpenChange={setCreateMemoryDialogOpen}
          onConfirm={onConfirmCreateMemory}
        />
      </div>
    </PageViewContext.Provider>
  );
}

import { AlertTriangle, CheckCheck, FolderOpen, FolderPlus, HardDrive, LoaderCircle, Sparkles } from "lucide-react";
import { Badge } from "./badge.js";
import { Button } from "./button.js";
import { formatTimestamp } from "./lib/media.js";
import { Label } from "./label.js";

function LibrarySettingsPanel({
  snapshot,
  isScanning,
  onAddLibrary,
  onScanAll,
}: {
  snapshot: LibrarySnapshot;
  isScanning: boolean;
  onAddLibrary: () => void;
  onScanAll: () => void;
}) {
  const stats = [
    { label: "Total", value: snapshot.stats.totalPhotos, icon: HardDrive },
    { label: "Indexed", value: snapshot.stats.indexedPhotos, icon: CheckCheck },
    { label: "Errors", value: snapshot.stats.erroredPhotos, icon: AlertTriangle },
    { label: "Duplicates", value: snapshot.stats.duplicatePhotos, icon: Sparkles },
  ];

  return (
    <div className="space-y-6">
      <div>
        <h2 className="font-['Space_Grotesk','IBM_Plex_Sans',sans-serif] text-2xl font-semibold tracking-tight text-stone-950">
          Library Settings
        </h2>
        <p className="mt-1 text-sm text-stone-500">
          Manage your library sources and indexing preferences.
        </p>
      </div>

      <div className="flex gap-3">
        <Button onClick={onAddLibrary} variant="accent">
          <FolderPlus className="h-4 w-4" />
          Add Folder
        </Button>
        <Button disabled={isScanning} onClick={onScanAll} variant="outline">
          {isScanning ? <LoaderCircle className="h-4 w-4 animate-spin" /> : <FolderOpen className="h-4 w-4" />}
          {isScanning ? "Scanning..." : "Scan Library"}
        </Button>
      </div>

      <div className="grid grid-cols-4 gap-3">
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
          <Label>Registered Sources</Label>
          <Badge tone="info">{snapshot.sources.length} active</Badge>
        </div>
        <div className="grid max-h-[38vh] gap-3 overflow-auto pr-1">
          {snapshot.sources.map((source) => (
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
          {snapshot.sources.length === 0 ? (
            <div className="rounded-2xl border border-dashed border-stone-300 bg-stone-50/70 px-5 py-10 text-center">
              <FolderPlus className="mx-auto mb-3 h-10 w-10 text-stone-400" />
              <p className="text-sm font-medium text-stone-700">No folders added yet</p>
              <p className="mt-2 text-sm leading-6 text-stone-500">
                Add a source folder to start indexing and generating thumbnails.
              </p>
            </div>
          ) : null}
        </div>
      </div>
    </div>
  );
}
