import * as React from "react";
import {
  AlertTriangle,
  CheckCheck,
  FolderOpen,
  FolderPlus,
  HardDrive,
  LoaderCircle,
  Sparkles,
} from "lucide-react";

import type {
  LibrarySnapshot,
  Memory,
  PhotoFilter,
  PhotoFilterPatch,
  PhotoRecord,
} from "@chronopic/domain";

import { Badge } from "./badge.js";
import { Button } from "./button.js";
import { CreateMemoryDialog } from "./create-memory-dialog.js";
import type { EditControlsProps } from "./edit-controls.js";
import { GallerySection } from "./gallery-section.js";
import { Header } from "./header.js";
import { formatTimestamp } from "./lib/media.js";
import { Label } from "./label.js";
import { MemoryDetailPage } from "./memory-detail-page.js";
import { MemoryListSection } from "./memory-list-section.js";
import { PageViewContext, type PageView } from "./page-view.js";
import { PhotoViewerOverlay } from "./photo-viewer-overlay.js";
import { RecentMemories } from "./recent-memories.js";
import { Sidebar } from "./sidebar.js";
import type { ViewerMode } from "./types.js";

export interface PhotoHomeProps extends EditControlsProps {
  photos: PhotoRecord[];
  memories: Memory[];
  selectedPhotoMemories: Memory[];
  selectedPhotoIds: string[];
  selectedPhotoId: string | null;
  selectedMemory: Memory | null;
  viewerMode: ViewerMode | null;
  viewerPhoto: PhotoRecord | null;
  filter: PhotoFilter;
  searchQuery: string;
  statusKind: "idle" | "info" | "success" | "warn" | "error";
  statusMessage: string;
  snapshot: LibrarySnapshot;
  isScanning: boolean;
  aiEnabled: boolean;
  onSelectPhoto: (photoId: string) => void;
  onToggleBatchSelect: (photoId: string) => void;
  onClearBatchSelection: () => void;
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
  onSelectAllPhotos: () => void;
  onSelectFavorites: () => void;
  onSelectMemories: () => void;
  onConfirmCreateMemory: (name: string) => void | Promise<void>;
  onUpdateMemory: (
    memoryId: string,
    updates: { name?: string; description?: string | null; coverPhotoId?: string | null }
  ) => Promise<Memory>;
  onAddPhotoToMemory: (memoryId: string, photoId: string) => Promise<void> | void;
  onAddSelectionToMemory: (memoryId: string, photoIds: string[]) => Promise<void> | void;
  onRemovePhotoFromMemory: (memoryId: string, photoId: string) => Promise<void> | void;
  onDeleteMemory: (memoryId: string) => Promise<void> | void;
  onToggleFavorite: (photoId: string, favorite: boolean) => void;
  canNavigatePrevious: boolean;
  canNavigateNext: boolean;
}

function HomeView({
  photos,
  memories,
  selectedPhotoIds,
  selectedPhotoId,
  selectedMemoryId,
  filter,
  onFilterChange,
  onSelectPhoto,
  onToggleBatchSelect,
  onClearBatchSelection,
  onOpenDetail,
  onOpenMemory,
  onSeeAllMemories,
  onToggleFavorite,
  onAddPhotoToMemory,
  onAddSelectionToMemory,
  selectionMode,
  onSelectionModeChange,
}: {
  photos: PhotoRecord[];
  memories: Memory[];
  selectedPhotoIds: string[];
  selectedPhotoId: string | null;
  selectedMemoryId: string | null;
  filter: PhotoFilter;
  onFilterChange: (patch: PhotoFilterPatch) => void;
  onSelectPhoto: (photoId: string) => void;
  onToggleBatchSelect: (photoId: string) => void;
  onClearBatchSelection: () => void;
  onOpenDetail: (photoId: string) => void;
  onOpenMemory: (memoryId: string) => void;
  onSeeAllMemories: () => void;
  onToggleFavorite: (photoId: string, favorite: boolean) => void;
  onAddPhotoToMemory: (memoryId: string, photoId: string) => Promise<void> | void;
  onAddSelectionToMemory: (memoryId: string, photoIds: string[]) => Promise<void> | void;
  selectionMode: boolean;
  onSelectionModeChange: (active: boolean) => void;
}) {
  return (
    <div className="space-y-6">
      <RecentMemories
        memories={memories}
        onOpenMemory={onOpenMemory}
        onSeeAll={onSeeAllMemories}
        selectedMemoryId={selectedMemoryId}
      />
      <GallerySection
        filter={filter}
        onFilterChange={onFilterChange}
        memories={memories}
        onAddToMemory={onAddPhotoToMemory}
        onAddSelectionToMemory={onAddSelectionToMemory}
        onClearBatchSelection={onClearBatchSelection}
        onOpenDetail={onOpenDetail}
        onSelect={onSelectPhoto}
        onSelectionModeChange={onSelectionModeChange}
        onToggleBatchSelect={onToggleBatchSelect}
        onToggleFavorite={onToggleFavorite}
        photos={photos}
        selectionMode={selectionMode}
        selectedPhotoIds={selectedPhotoIds}
        selectedPhotoId={selectedPhotoId}
      />
    </div>
  );
}

export function PhotoHome({
  photos,
  memories,
  selectedPhotoMemories,
  selectedPhotoIds,
  selectedPhotoId,
  selectedMemory,
  viewerMode,
  viewerPhoto,
  filter,
  searchQuery,
  statusKind,
  statusMessage,
  snapshot,
  isScanning,
  aiEnabled,
  onSelectPhoto,
  onToggleBatchSelect,
  onClearBatchSelection,
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
  onSelectAllPhotos,
  onSelectFavorites,
  onSelectMemories,
  onConfirmCreateMemory,
  onUpdateMemory,
  onAddPhotoToMemory,
  onAddSelectionToMemory,
  onRemovePhotoFromMemory,
  onDeleteMemory,
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
  const statusTone =
    statusKind === "success"
      ? "success"
      : statusKind === "error"
        ? "danger"
        : statusKind === "info"
          ? "info"
          : "warn";

  const statusShellClassName =
    statusKind === "success"
      ? "border-emerald-200 bg-emerald-50 text-emerald-900"
      : statusKind === "error"
        ? "border-rose-200 bg-rose-50 text-rose-900"
        : statusKind === "info"
          ? "border-sky-200 bg-sky-50 text-sky-900"
          : "border-amber-200 bg-amber-50 text-amber-900";

  const [page, setPage] = React.useState<PageView>("home");
  const [createMemoryDialogOpen, setCreateMemoryDialogOpen] = React.useState(false);
  const [selectionMode, setSelectionMode] = React.useState(false);

  const recentMemories = React.useMemo(
    () => [...memories].sort((a, b) => b.updatedAt - a.updatedAt),
    [memories]
  );

  const activeSidebarItem = React.useMemo(() => {
    if (page === "library-settings") {
      return "settings";
    }

    if (page === "memories") {
      return "memories";
    }

    if (page === "memory-detail" && selectedMemory) {
      return selectedMemory.id;
    }

    if (filter.favorite) {
      return "favorites";
    }

    return "all";
  }, [filter.favorite, page, selectedMemory]);

  function openMemoryDetail(memoryId: string) {
    onSelectMemory(memoryId);
    setPage("memory-detail");
  }

  async function handleCreateMemory(name: string) {
    await onConfirmCreateMemory(name);
    onSelectMemories();
    setPage("memories");
  }

  async function handleSaveMemoryDescription(memoryId: string, description: string) {
    await onUpdateMemory(memoryId, { description });
  }

  async function handleDeleteMemory(memoryId: string) {
    await onDeleteMemory(memoryId);
    onSelectMemories();
    setPage("memories");
  }

  return (
    <PageViewContext.Provider value={{ page, setPage }}>
      <div className="flex h-screen flex-col overflow-hidden bg-stone-50">
        <Header
          onSearchChange={onSearchChange}
          searchQuery={searchQuery}
        />

        <div className="flex flex-1 overflow-hidden">
          <Sidebar
            activeItem={activeSidebarItem}
            className="w-56 shrink-0 border-r border-stone-200/80 bg-white"
            memories={recentMemories}
            onCreateMemory={() => setCreateMemoryDialogOpen(true)}
            onSelectItem={(id) => {
              if (id === "settings") {
                setPage("library-settings");
                return;
              }

              if (id === "memories") {
                onSelectMemories();
                setPage("memories");
                return;
              }

              if (id === "favorites") {
                onSelectFavorites();
                setPage("home");
                return;
              }

              onSelectAllPhotos();
              setPage("home");
            }}
            onSelectMemory={openMemoryDetail}
          />

          <main className="flex-1 overflow-y-auto">
            <div className="p-6">
              {page === "library-settings" ? (
                <div className="rounded-[32px] border border-stone-200/70 bg-white p-6 shadow-sm">
                  <LibrarySettingsPanel
                    isScanning={isScanning}
                    onAddLibrary={onAddLibrary}
                    onScanAll={onScanAll}
                    snapshot={snapshot}
                  />
                </div>
              ) : null}

              {statusKind !== "idle" ? (
                <div
                  className={`mb-4 flex items-center justify-between rounded-2xl border px-4 py-3 text-sm shadow-sm ${statusShellClassName}`}
                >
                  <span>{statusMessage}</span>
                  <Badge tone={statusTone}>Recent Action</Badge>
                </div>
              ) : null}

              {page === "memories" ? (
                <MemoryListSection
                  memories={recentMemories}
                  onOpenMemory={openMemoryDetail}
                  selectedMemoryId={selectedMemory?.id ?? null}
                />
              ) : null}

              {page === "memory-detail" && selectedMemory ? (
                <MemoryDetailPage
                  memory={selectedMemory}
                  onDeleteMemory={handleDeleteMemory}
                  onOpenDetail={onOpenDetail}
                  onRemovePhoto={onRemovePhotoFromMemory}
                  onRenameMemory={async (memoryId, name) => {
                    await onUpdateMemory(memoryId, { name });
                  }}
                  onSaveDescription={handleSaveMemoryDescription}
                  onSelectPhoto={onSelectPhoto}
                  onSetCover={async (memoryId, photoId) => {
                    await onUpdateMemory(memoryId, { coverPhotoId: photoId });
                  }}
                  onToggleFavorite={onToggleFavorite}
                  photos={photos}
                  selectedPhotoId={selectedPhotoId}
                />
              ) : null}

              {page === "memory-detail" && !selectedMemory ? (
                <MemoryListSection
                  memories={recentMemories}
                  onOpenMemory={openMemoryDetail}
                  selectedMemoryId={null}
                />
              ) : null}

              {page === "home" ? (
                <HomeView
                  filter={filter}
                  memories={recentMemories}
                  onFilterChange={onFilterChange}
                  onOpenDetail={onOpenDetail}
                  onOpenMemory={openMemoryDetail}
                  onSeeAllMemories={() => {
                    onSelectMemories();
                    setPage("memories");
                  }}
                  onAddPhotoToMemory={onAddPhotoToMemory}
                  onAddSelectionToMemory={onAddSelectionToMemory}
                  onClearBatchSelection={onClearBatchSelection}
                  onSelectPhoto={onSelectPhoto}
                  onSelectionModeChange={setSelectionMode}
                  onToggleBatchSelect={onToggleBatchSelect}
                  onToggleFavorite={onToggleFavorite}
                  photos={photos}
                  selectionMode={selectionMode}
                  selectedPhotoIds={selectedPhotoIds}
                  selectedMemoryId={selectedMemory?.id ?? null}
                  selectedPhotoId={selectedPhotoId}
                />
              ) : null}
            </div>
          </main>
        </div>

        <PhotoViewerOverlay
          aiEnabled={aiEnabled}
          canNavigateNext={canNavigateNext}
          canNavigatePrevious={canNavigatePrevious}
          draftCaption={draftCaption}
          draftDatetime={draftDatetime}
          draftTags={draftTags}
          memories={recentMemories}
          mode={viewerMode}
          onAddToMemory={onAddPhotoToMemory}
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
          photoMemories={selectedPhotoMemories}
          photos={photos}
          selectedPhotoId={selectedPhotoId}
        />

        <CreateMemoryDialog
          onConfirm={handleCreateMemory}
          onOpenChange={setCreateMemoryDialogOpen}
          open={createMemoryDialogOpen}
        />
      </div>
    </PageViewContext.Provider>
  );
}

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
