import * as React from "react";
import {
  AlertTriangle,
  CheckCheck,
  FolderOpen,
  FolderPlus,
  HardDrive,
  LoaderCircle,
  SlidersHorizontal,
  Sparkles,
} from "lucide-react";

import type {
  AISettings,
  BrowseMode,
  LibrarySnapshot,
  MapSettings,
  Memory,
  MemoryCandidate,
  PlaceGroup,
  PhotoFilter,
  PhotoFilterPatch,
  PhotoRecord,
  SemanticQueueStats,
} from "@chronopic/domain";

import { Badge } from "./badge.js";
import { BrowseModePlaceholder } from "./browse-mode-placeholder.js";
import { BrowseModeSwitcher } from "./browse-mode-switcher.js";
import { Button } from "./button.js";
import { CreateMemoryDialog } from "./create-memory-dialog.js";
import { DiscoveryLensStrip } from "./discovery-lens-strip.js";
import type { EditControlsProps } from "./edit-controls.js";
import { FilterToolbar } from "./filter-toolbar.js";
import { GallerySection } from "./gallery-section.js";
import { Input } from "./input.js";
import { formatTimestamp } from "./lib/media.js";
import { Label } from "./label.js";
import { MemoryDetailPage } from "./memory-detail-page.js";
import { MemoryListSection } from "./memory-list-section.js";
import { PageViewContext, type PageView } from "./page-view.js";
import { PhotoViewerOverlay } from "./photo-viewer-overlay.js";
import { RecentMemories } from "./recent-memories.js";
import { SearchInput } from "./search-input.js";
import { Sidebar } from "./sidebar.js";
import { SuggestedMemoriesSection } from "./suggested-memories-section.js";
import type { ViewerMode } from "./types.js";

const EMPTY_QUEUE_STATS: SemanticQueueStats = {
  disabled: 0,
  pending: 0,
  processing: 0,
  completed: 0,
  failed: 0,
};

export interface PhotoHomeProps extends EditControlsProps {
  mapBrowseContent?: React.ReactNode;
  photos: PhotoRecord[];
  placeGroups: PlaceGroup[];
  memories: Memory[];
  memoryCandidates: MemoryCandidate[];
  mappablePhotoCount: number;
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
  aiSettings: AISettings;
  mapSettings: MapSettings;
  aiQueueStats?: SemanticQueueStats;
  isBatchEnrichingSemantic?: boolean;
  isEnrichingMemorySemantic?: boolean;
  isGeneratingMemoryCandidates?: boolean;
  onSelectPhoto: (photoId: string) => void;
  onToggleBatchSelect: (photoId: string) => void;
  onClearBatchSelection: () => void;
  onOpenDetail: (photoId: string) => void;
  onFilterChange: (patch: PhotoFilterPatch) => void;
  onSearchChange: (query: string) => void;
  onAddLibrary: () => void;
  onSaveAISettings: (settings: AISettings) => void | Promise<void>;
  onSaveMapSettings: (settings: MapSettings) => void | Promise<void>;
  onScanAll: () => void;
  onEnrichPendingSemantics?: () => void;
  onEnrichMemorySemantic?: (memoryId: string) => void | Promise<void>;
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
  onGenerateMemoryCandidates: () => void | Promise<void>;
  onAcceptMemoryCandidate: (candidateId: string, input?: { name?: string; photoIds?: string[] }) => void | Promise<void>;
  onRejectMemoryCandidate: (candidateId: string) => void | Promise<void>;
  onUpdateMemory: (
    memoryId: string,
    updates: { name?: string; description?: string | null; coverPhotoId?: string | null }
  ) => Promise<Memory>;
  onAddPhotoToMemory: (memoryId: string, photoId: string) => Promise<void> | void;
  onAddSelectionToMemory: (memoryId: string, photoIds: string[]) => Promise<void> | void;
  onRemovePhotoFromMemory: (memoryId: string, photoId: string) => Promise<void> | void;
  onRemoveSelectionFromMemory: (memoryId: string, photoIds: string[]) => Promise<void> | void;
  onDeleteMemory: (memoryId: string) => Promise<void> | void;
  onToggleFavorite: (photoId: string, favorite: boolean) => void;
  timelineBrowseContent?: React.ReactNode;
  canNavigatePrevious: boolean;
  canNavigateNext: boolean;
}

function HomeView({
  photos,
  placeGroups,
  memories,
  mappablePhotoCount,
  searchQuery,
  selectedPhotoIds,
  selectedPhotoId,
  selectedPhotoMemories,
  selectedMemoryId,
  filter,
  onFilterChange,
  onSearchChange,
  onSelectPhoto,
  onToggleBatchSelect,
  onClearBatchSelection,
  onOpenDetail,
  onOpenMemory,
  onSeeAllMemories,
  onToggleFavorite,
  onAddPhotoToMemory,
  onAddSelectionToMemory,
  onCreateMemory,
  browseMode,
  onBrowseModeChange,
  mapBrowseContent,
  selectionMode,
  timelineBrowseContent,
  onSelectionModeChange,
}: {
  photos: PhotoRecord[];
  placeGroups: PlaceGroup[];
  memories: Memory[];
  mappablePhotoCount: number;
  searchQuery: string;
  selectedPhotoIds: string[];
  selectedPhotoId: string | null;
  selectedPhotoMemories: Memory[];
  selectedMemoryId: string | null;
  filter: PhotoFilter;
  onFilterChange: (patch: PhotoFilterPatch) => void;
  onSearchChange: (query: string) => void;
  onSelectPhoto: (photoId: string) => void;
  onToggleBatchSelect: (photoId: string) => void;
  onClearBatchSelection: () => void;
  onOpenDetail: (photoId: string) => void;
  onOpenMemory: (memoryId: string) => void;
  onSeeAllMemories: () => void;
  onToggleFavorite: (photoId: string, favorite: boolean) => void;
  onAddPhotoToMemory: (memoryId: string, photoId: string) => Promise<void> | void;
  onAddSelectionToMemory: (memoryId: string, photoIds: string[]) => Promise<void> | void;
  onCreateMemory: () => void;
  browseMode: BrowseMode;
  onBrowseModeChange: (mode: BrowseMode) => void;
  mapBrowseContent?: React.ReactNode;
  selectionMode: boolean;
  timelineBrowseContent?: React.ReactNode;
  onSelectionModeChange: (active: boolean) => void;
}) {
  const [filtersOpen, setFiltersOpen] = React.useState(false);
  return (
    <div className="space-y-6">
      <RecentMemories
        memories={memories}
        onCreateMemory={onCreateMemory}
        onOpenMemory={onOpenMemory}
        onSeeAll={onSeeAllMemories}
        selectedMemoryId={selectedMemoryId}
      />
      <section className="space-y-4">
        <div className="flex flex-wrap items-center justify-between gap-3">
          <BrowseModeSwitcher mode={browseMode} onModeChange={onBrowseModeChange} />
          <div className="ml-auto flex flex-wrap items-center justify-end gap-3">
            <SearchInput
              className="w-[320px]"
              onValueChange={onSearchChange}
              placeholder="Search moments, locations..."
              value={searchQuery}
            />
            {browseMode === "waterfall" ? (
              <Button
                className="rounded-full"
                onClick={() => {
                  if (selectionMode || selectedPhotoIds.length > 0) {
                    onClearBatchSelection();
                    onSelectionModeChange(false);
                    return;
                  }

                  onSelectionModeChange(true);
                }}
                size="sm"
                variant={selectionMode || selectedPhotoIds.length > 0 ? "accent" : "outline"}
              >
                {selectionMode || selectedPhotoIds.length > 0 ? "Done" : "Select"}
              </Button>
            ) : null}
            <Button
              className="rounded-full"
              onClick={() => setFiltersOpen((current) => !current)}
              size="sm"
              variant={filtersOpen ? "default" : "outline"}
            >
              <SlidersHorizontal className="h-4 w-4" />
              Filter
            </Button>
          </div>
        </div>
        {filtersOpen ? <FilterToolbar filter={filter} onChange={onFilterChange} /> : null}
        <DiscoveryLensStrip
          filter={filter}
          memories={memories}
          onBrowseModeChange={onBrowseModeChange}
          onFilterChange={onFilterChange}
          onOpenMemory={onOpenMemory}
          photos={photos}
          placeGroups={placeGroups}
        />
      </section>
      {browseMode === "waterfall" ? (
        <GallerySection
          activeMemory={memories.find((memory) => memory.id === selectedMemoryId) ?? null}
          filter={filter}
          selectedPhotoMemories={selectedPhotoMemories}
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
      ) : browseMode === "map" ? (
        mapBrowseContent ?? (
          <BrowseModePlaceholder
            currentScopeCount={photos.length}
            mappablePhotoCount={mappablePhotoCount}
            mode={browseMode}
            placeGroupCount={placeGroups.length}
            timelineReadyCount={photos.filter((record) => record.metadata.datetime != null).length}
          />
        )
      ) : timelineBrowseContent ? (
        timelineBrowseContent
      ) : (
        <BrowseModePlaceholder
          currentScopeCount={photos.length}
          mappablePhotoCount={mappablePhotoCount}
          mode={browseMode}
          placeGroupCount={placeGroups.length}
          timelineReadyCount={photos.filter((record) => record.metadata.datetime != null).length}
        />
      )}
    </div>
  );
}

export function PhotoHome({
  photos,
  placeGroups,
  memories,
  memoryCandidates,
  mappablePhotoCount,
  mapBrowseContent,
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
  aiSettings,
  mapSettings,
  aiQueueStats,
  isBatchEnrichingSemantic,
  isEnrichingMemorySemantic,
  isGeneratingMemoryCandidates,
  onSelectPhoto,
  onToggleBatchSelect,
  onClearBatchSelection,
  onOpenDetail,
  onFilterChange,
  onSearchChange,
  onAddLibrary,
  onSaveAISettings,
  onSaveMapSettings,
  onScanAll,
  onEnrichPendingSemantics,
  onEnrichMemorySemantic,
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
  onGenerateMemoryCandidates,
  onAcceptMemoryCandidate,
  onRejectMemoryCandidate,
  onUpdateMemory,
  onAddPhotoToMemory,
  onAddSelectionToMemory,
  onRemovePhotoFromMemory,
  onRemoveSelectionFromMemory,
  onDeleteMemory,
  onToggleFavorite,
  timelineBrowseContent,
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
  isEnrichingSemantic,
  onEnrichSemantic,
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
  const [browseMode, setBrowseMode] = React.useState<BrowseMode>("waterfall");
  const [selectionMode, setSelectionMode] = React.useState(false);
  const safeAiQueueStats = aiQueueStats ?? EMPTY_QUEUE_STATS;

  const recentMemories = React.useMemo(
    () => [...memories].sort((a, b) => b.updatedAt - a.updatedAt),
    [memories]
  );

  const activeSidebarItem = React.useMemo(() => {
    if (page === "library-settings") {
      return "settings";
    }

    if (page === "notifications") {
      return "notifications";
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
    onClearBatchSelection();
    setSelectionMode(false);
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

  function handleBrowseModeChange(nextMode: BrowseMode) {
    if (nextMode === browseMode) {
      return;
    }

    onClearBatchSelection();
    setSelectionMode(false);
    setBrowseMode(nextMode);
  }

  return (
    <PageViewContext.Provider value={{ page, setPage }}>
      <div className="flex h-screen overflow-hidden bg-stone-50">
        <div className="flex flex-1 overflow-hidden">
          <Sidebar
            activeItem={activeSidebarItem}
            className="w-64 shrink-0 border-r border-stone-200/70 bg-white/80 backdrop-blur-sm"
            memories={recentMemories}
            notificationCount={
              safeAiQueueStats.disabled +
              safeAiQueueStats.pending +
              safeAiQueueStats.processing +
              safeAiQueueStats.failed
            }
            onCreateMemory={() => setCreateMemoryDialogOpen(true)}
            onSelectItem={(id) => {
              if (id === "settings") {
                onClearBatchSelection();
                setSelectionMode(false);
                setPage("library-settings");
                return;
              }

              if (id === "notifications") {
                onClearBatchSelection();
                setSelectionMode(false);
                setPage("notifications");
                return;
              }

              if (id === "memories") {
                onClearBatchSelection();
                setSelectionMode(false);
                onSelectMemories();
                setPage("memories");
                return;
              }

              if (id === "recent") {
                onClearBatchSelection();
                setSelectionMode(false);
                onSelectAllPhotos();
                setPage("home");
                return;
              }

              if (id === "favorites") {
                onClearBatchSelection();
                setSelectionMode(false);
                onSelectFavorites();
                setPage("home");
                return;
              }

              onClearBatchSelection();
              setSelectionMode(false);
              onSelectAllPhotos();
              setPage("home");
            }}
            onSelectMemory={openMemoryDetail}
          />

          <main className="flex-1 overflow-y-auto">
            <div className="mx-auto w-full max-w-[1680px] p-6">
              {page === "library-settings" ? (
                <div className="rounded-[32px] border border-stone-200/70 bg-white p-6 shadow-sm">
                  <LibrarySettingsPanel
                    aiEnabled={aiEnabled}
                    aiSettings={aiSettings}
                    mapSettings={mapSettings}
                    isScanning={isScanning}
                    onAddLibrary={onAddLibrary}
                    onSaveAISettings={onSaveAISettings}
                    onSaveMapSettings={onSaveMapSettings}
                    onScanAll={onScanAll}
                    snapshot={snapshot}
                  />
                </div>
              ) : null}

              {page === "notifications" ? (
                <div className="rounded-[32px] border border-stone-200/70 bg-white p-6 shadow-sm">
                  <NotificationCenterPanel
                    aiEnabled={aiEnabled}
                    aiQueueStats={safeAiQueueStats}
                    statusKind={statusKind}
                    statusMessage={statusMessage}
                    {...(isBatchEnrichingSemantic !== undefined ? { isBatchEnrichingSemantic } : {})}
                    {...(onEnrichPendingSemantics ? { onEnrichPendingSemantics } : {})}
                  />
                </div>
              ) : null}

              {statusKind !== "idle" && page !== "notifications" ? (
                <div
                  className={`mb-4 flex items-center justify-between rounded-2xl border px-4 py-3 text-sm shadow-sm ${statusShellClassName}`}
                >
                  <span>{statusMessage}</span>
                  <Badge tone={statusTone}>Recent Action</Badge>
                </div>
              ) : null}

              {page === "memories" ? (
                <div className="space-y-6">
                  <SuggestedMemoriesSection
                    candidates={memoryCandidates}
                    isGenerating={isGeneratingMemoryCandidates ?? false}
                    onAccept={onAcceptMemoryCandidate}
                    onGenerate={onGenerateMemoryCandidates}
                    onReject={onRejectMemoryCandidate}
                  />
                  <MemoryListSection
                    memories={recentMemories}
                    onCreateMemory={() => setCreateMemoryDialogOpen(true)}
                    onOpenMemory={openMemoryDetail}
                    selectedMemoryId={selectedMemory?.id ?? null}
                  />
                </div>
              ) : null}

              {page === "memory-detail" && selectedMemory ? (
                <MemoryDetailPage
                  memory={selectedMemory}
                  onDeleteMemory={handleDeleteMemory}
                  onOpenDetail={onOpenDetail}
                  onRemovePhoto={onRemovePhotoFromMemory}
                  onRemoveSelection={onRemoveSelectionFromMemory}
                  onRenameMemory={async (memoryId, name) => {
                    await onUpdateMemory(memoryId, { name });
                  }}
                  onSaveDescription={handleSaveMemoryDescription}
                  onClearBatchSelection={onClearBatchSelection}
                  onSelectPhoto={onSelectPhoto}
                  onSetCover={async (memoryId, photoId) => {
                    await onUpdateMemory(memoryId, { coverPhotoId: photoId });
                  }}
                  onToggleBatchSelect={onToggleBatchSelect}
                  onToggleFavorite={onToggleFavorite}
                  photos={photos}
                  selectedPhotoIds={selectedPhotoIds}
                  selectedPhotoId={selectedPhotoId}
                  {...(onEnrichMemorySemantic ? { onEnrichSemantic: onEnrichMemorySemantic } : {})}
                  {...(isEnrichingMemorySemantic !== undefined ? { isEnrichingSemantic: isEnrichingMemorySemantic } : {})}
                />
              ) : null}

              {page === "memory-detail" && !selectedMemory ? (
                <MemoryListSection
                  memories={recentMemories}
                  onCreateMemory={() => setCreateMemoryDialogOpen(true)}
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
                  onCreateMemory={() => setCreateMemoryDialogOpen(true)}
                  browseMode={browseMode}
                  mappablePhotoCount={mappablePhotoCount}
                  mapBrowseContent={mapBrowseContent}
                  onBrowseModeChange={handleBrowseModeChange}
                  onSearchChange={onSearchChange}
                  onSelectPhoto={onSelectPhoto}
                  onSelectionModeChange={setSelectionMode}
                  onToggleBatchSelect={onToggleBatchSelect}
                  onToggleFavorite={onToggleFavorite}
                  placeGroups={placeGroups}
                  photos={photos}
                  searchQuery={searchQuery}
                  selectionMode={selectionMode}
                  selectedPhotoIds={selectedPhotoIds}
                  selectedPhotoMemories={selectedPhotoMemories}
                  selectedMemoryId={selectedMemory?.id ?? null}
                  selectedPhotoId={selectedPhotoId}
                  timelineBrowseContent={timelineBrowseContent}
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
          isEnrichingSemantic={isEnrichingSemantic ?? false}
          memories={recentMemories}
          mode={viewerMode}
          onAddToMemory={onAddPhotoToMemory}
          onCaptionChange={onCaptionChange}
          onClose={onCloseViewer}
          onDatetimeChange={onDatetimeChange}
          onEnrichSemantic={onEnrichSemantic ?? (() => {})}
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
          searchQuery={searchQuery}
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
  aiEnabled,
  aiSettings,
  mapSettings,
  snapshot,
  isScanning,
  onAddLibrary,
  onSaveAISettings,
  onSaveMapSettings,
  onScanAll,
}: {
  aiEnabled: boolean;
  aiSettings: AISettings;
  mapSettings: MapSettings;
  snapshot: LibrarySnapshot;
  isScanning: boolean;
  onAddLibrary: () => void;
  onSaveAISettings: (settings: AISettings) => void | Promise<void>;
  onSaveMapSettings: (settings: MapSettings) => void | Promise<void>;
  onScanAll: () => void;
}) {
  const [draftAISettings, setDraftAISettings] = React.useState(aiSettings);
  const [draftMapSettings, setDraftMapSettings] = React.useState(mapSettings);
  const [savingAISettings, setSavingAISettings] = React.useState(false);
  const [savingMapSettings, setSavingMapSettings] = React.useState(false);

  React.useEffect(() => {
    setDraftAISettings(aiSettings);
  }, [aiSettings]);

  React.useEffect(() => {
    setDraftMapSettings(mapSettings);
  }, [mapSettings]);

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

      <div className="space-y-3 rounded-[28px] border border-stone-200 bg-stone-50/80 p-5 shadow-sm">
        <div className="flex items-start justify-between gap-4">
          <div>
            <h3 className="font-['Space_Grotesk','IBM_Plex_Sans',sans-serif] text-xl font-semibold tracking-tight text-stone-950">
              AI Enrichment
            </h3>
            <p className="mt-1 text-sm leading-6 text-stone-500">
              Configure the OpenAI-compatible endpoint used for photo and memory semantic enrichment.
            </p>
          </div>
          <Badge tone={aiEnabled ? "success" : "neutral"}>{aiEnabled ? "Enabled" : "Disabled"}</Badge>
        </div>

        <div className="grid gap-4 md:grid-cols-2">
          <div className="space-y-2">
            <Label>Provider</Label>
            <Input
              onChange={(event) => setDraftAISettings((current) => ({ ...current, providerName: event.target.value }))}
              placeholder="openai-compatible"
              value={draftAISettings.providerName}
            />
          </div>
          <div className="space-y-2">
            <Label>Model</Label>
            <Input
              onChange={(event) => setDraftAISettings((current) => ({ ...current, model: event.target.value }))}
              placeholder="unsloth/gemma-4-E4B-it-GGUF"
              value={draftAISettings.model}
            />
          </div>
          <div className="space-y-2 md:col-span-2">
            <Label>Base URL</Label>
            <Input
              onChange={(event) => setDraftAISettings((current) => ({ ...current, baseURL: event.target.value }))}
              placeholder="http://192.168.1.39:8888/v1"
              value={draftAISettings.baseURL}
            />
          </div>
          <div className="space-y-2 md:col-span-2">
            <Label>API Key</Label>
            <Input
              onChange={(event) => setDraftAISettings((current) => ({ ...current, apiKey: event.target.value }))}
              placeholder="sk-..."
              type="password"
              value={draftAISettings.apiKey}
            />
          </div>
        </div>

        <div className="flex flex-wrap items-center justify-between gap-3">
          <p className="text-xs leading-5 text-stone-500">
            Save applies immediately in the desktop runtime. Leaving any required field blank disables AI.
          </p>
          <Button
            disabled={savingAISettings}
            onClick={async () => {
              setSavingAISettings(true);
              try {
                await onSaveAISettings(draftAISettings);
              } finally {
                setSavingAISettings(false);
              }
            }}
            variant="outline"
          >
            {savingAISettings ? "Saving..." : "Save AI Settings"}
          </Button>
        </div>

      </div>

      <div className="space-y-3 rounded-[28px] border border-stone-200 bg-stone-50/80 p-5 shadow-sm">
        <div className="flex items-start justify-between gap-4">
          <div>
            <h3 className="font-['Space_Grotesk','IBM_Plex_Sans',sans-serif] text-xl font-semibold tracking-tight text-stone-950">
              Map Rendering
            </h3>
            <p className="mt-1 text-sm leading-6 text-stone-500">
              Configure the Gaode Web JS API used by ChronoPic map browse mode.
            </p>
          </div>
          <Badge tone={draftMapSettings.apiKey ? "success" : "neutral"}>
            {draftMapSettings.apiKey ? "Configured" : "Disabled"}
          </Badge>
        </div>

        <div className="grid gap-4 md:grid-cols-2">
          <div className="space-y-2 md:col-span-2">
            <Label>AMap API Key</Label>
            <Input
              onChange={(event) => setDraftMapSettings((current) => ({ ...current, apiKey: event.target.value }))}
              placeholder="your-amap-api-key"
              value={draftMapSettings.apiKey}
            />
          </div>
          <div className="space-y-2 md:col-span-2">
            <Label>Security JS Code</Label>
            <Input
              onChange={(event) =>
                setDraftMapSettings((current) => ({ ...current, securityJsCode: event.target.value }))
              }
              placeholder="optional-security-js-code"
              value={draftMapSettings.securityJsCode}
            />
          </div>
        </div>

        <div className="flex flex-wrap items-center justify-between gap-3">
          <p className="text-xs leading-5 text-stone-500">
            Saved map settings are used by the Map browse view. Leaving the API key blank disables map rendering.
          </p>
          <Button
            disabled={savingMapSettings}
            onClick={async () => {
              setSavingMapSettings(true);
              try {
                await onSaveMapSettings(draftMapSettings);
              } finally {
                setSavingMapSettings(false);
              }
            }}
            variant="outline"
          >
            {savingMapSettings ? "Saving..." : "Save Map Settings"}
          </Button>
        </div>
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

function NotificationCenterPanel({
  aiEnabled,
  aiQueueStats,
  isBatchEnrichingSemantic,
  onEnrichPendingSemantics,
  statusKind,
  statusMessage,
}: {
  aiEnabled: boolean;
  aiQueueStats: SemanticQueueStats;
  isBatchEnrichingSemantic?: boolean;
  onEnrichPendingSemantics?: () => void;
  statusKind: "idle" | "info" | "success" | "warn" | "error";
  statusMessage: string;
}) {
  const outstanding = aiQueueStats.disabled + aiQueueStats.pending + aiQueueStats.processing + aiQueueStats.failed;

  return (
    <div className="space-y-6">
      <div>
        <h2 className="font-['Space_Grotesk','IBM_Plex_Sans',sans-serif] text-2xl font-semibold tracking-tight text-stone-950">
          Notifications
        </h2>
        <p className="mt-1 text-sm text-stone-500">Track AI queue activity and the latest desktop actions in one place.</p>
      </div>

      <div className="rounded-[28px] border border-stone-200 bg-stone-50/80 p-5 shadow-sm">
        <div className="flex flex-wrap items-start justify-between gap-4">
          <div className="space-y-3">
            <div className="flex flex-wrap items-center gap-2">
              <Badge tone="info">AI Queue</Badge>
              {aiQueueStats.disabled > 0 ? <Badge tone="neutral">{aiQueueStats.disabled} need AI</Badge> : null}
              {aiQueueStats.pending > 0 ? <Badge tone="info">{aiQueueStats.pending} pending</Badge> : null}
              {aiQueueStats.processing > 0 ? <Badge tone="info">{aiQueueStats.processing} processing</Badge> : null}
              {aiQueueStats.failed > 0 ? <Badge tone="danger">{aiQueueStats.failed} failed</Badge> : null}
              {aiQueueStats.completed > 0 ? <Badge tone="success">{aiQueueStats.completed} ready</Badge> : null}
            </div>
            <p className="text-sm leading-6 text-stone-600">
              {aiEnabled
                ? outstanding > 0
                  ? aiQueueStats.processing > 0 &&
                    aiQueueStats.disabled + aiQueueStats.pending + aiQueueStats.failed === 0
                    ? "AI enrichment is currently running for some items."
                    : "Outstanding AI items are waiting in the library queue."
                  : "No outstanding AI queue items right now."
                : "AI is currently disabled. Configure it in Settings to enable queue processing."}
            </p>
          </div>
          <Button
            disabled={!aiEnabled || outstanding === 0 || isBatchEnrichingSemantic}
            onClick={() => void onEnrichPendingSemantics?.()}
            variant="outline"
          >
            {isBatchEnrichingSemantic ? "Processing Queue..." : "Enrich Queue"}
          </Button>
        </div>
      </div>

      <div className="rounded-[28px] border border-stone-200 bg-white p-5 shadow-sm">
        <div className="flex items-center justify-between gap-3">
          <div>
            <p className="text-[11px] font-semibold uppercase tracking-[0.18em] text-stone-500">Recent Action</p>
            <p className="mt-2 text-sm leading-6 text-stone-600">
              {statusKind === "idle" ? "No recent action recorded in this session." : statusMessage}
            </p>
          </div>
          {statusKind !== "idle" ? (
            <Badge tone={statusKind === "success" ? "success" : statusKind === "error" ? "danger" : statusKind === "info" ? "info" : "warn"}>
              {statusKind}
            </Badge>
          ) : null}
        </div>
      </div>
    </div>
  );
}
