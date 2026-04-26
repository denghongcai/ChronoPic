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
  LocaleSettings,
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
import { useI18n } from "./i18n-provider.js";
import { formatTimestamp } from "./lib/media.js";
import { Label } from "./label.js";
import { MemoryDetailPage } from "./memory-detail-page.js";
import { MemoryListSection } from "./memory-list-section.js";
import { PageViewContext, type PageView } from "./page-view.js";
import { PhotoViewerOverlay } from "./photo-viewer-overlay.js";
import { RecentMemories } from "./recent-memories.js";
import { SearchInput } from "./search-input.js";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "./select.js";
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
  localeSettings: LocaleSettings;
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
  onSaveLocaleSettings: (settings: LocaleSettings) => void | Promise<void>;
  onSaveMapSettings: (settings: MapSettings) => void | Promise<void>;
  onScanAll: () => void;
  onEnrichPendingSemantics?: () => void;
  onEnrichMemorySemantic?: (
    memoryId: string,
    context?: { name?: string | null; description?: string | null }
  ) => void | Promise<void>;
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
  const { t } = useI18n();
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
                {selectionMode || selectedPhotoIds.length > 0 ? t("actions.done") : t("actions.select")}
              </Button>
            ) : null}
            <Button
              className="rounded-full"
              onClick={() => setFiltersOpen((current) => !current)}
              size="sm"
              variant={filtersOpen ? "default" : "outline"}
            >
              <SlidersHorizontal className="h-4 w-4" />
              {t("actions.filter")}
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
  localeSettings,
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
  onSaveLocaleSettings,
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
  const { t } = useI18n();
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
              safeAiQueueStats.failed +
              memoryCandidates.length
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
	                    localeSettings={localeSettings}
	                    mapSettings={mapSettings}
                    isScanning={isScanning}
                    onAddLibrary={onAddLibrary}
	                    onSaveAISettings={onSaveAISettings}
	                    onSaveLocaleSettings={onSaveLocaleSettings}
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
                    memoryCandidateCount={memoryCandidates.length}
                    statusKind={statusKind}
                    statusMessage={statusMessage}
                    {...(isBatchEnrichingSemantic !== undefined ? { isBatchEnrichingSemantic } : {})}
                    {...(onEnrichPendingSemantics ? { onEnrichPendingSemantics } : {})}
                    {...(isGeneratingMemoryCandidates !== undefined ? { isGeneratingMemoryCandidates } : {})}
                    onGenerateMemoryCandidates={onGenerateMemoryCandidates}
                  />
                </div>
              ) : null}

              {statusKind !== "idle" && page !== "notifications" ? (
                <div
                  className={`mb-4 flex items-center justify-between rounded-2xl border px-4 py-3 text-sm shadow-sm ${statusShellClassName}`}
                >
                  <span>{statusMessage}</span>
                  <Badge tone={statusTone}>{t("notifications.recentAction")}</Badge>
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
  localeSettings,
  mapSettings,
  snapshot,
  isScanning,
  onAddLibrary,
  onSaveAISettings,
  onSaveLocaleSettings,
  onSaveMapSettings,
  onScanAll,
}: {
  aiEnabled: boolean;
  aiSettings: AISettings;
  localeSettings: LocaleSettings;
  mapSettings: MapSettings;
  snapshot: LibrarySnapshot;
  isScanning: boolean;
  onAddLibrary: () => void;
  onSaveAISettings: (settings: AISettings) => void | Promise<void>;
  onSaveLocaleSettings: (settings: LocaleSettings) => void | Promise<void>;
  onSaveMapSettings: (settings: MapSettings) => void | Promise<void>;
  onScanAll: () => void;
}) {
  const { t } = useI18n();
  const [draftAISettings, setDraftAISettings] = React.useState(aiSettings);
  const [draftLocaleSettings, setDraftLocaleSettings] = React.useState(localeSettings);
  const [draftMapSettings, setDraftMapSettings] = React.useState(mapSettings);
  const [savingAISettings, setSavingAISettings] = React.useState(false);
  const [savingLocaleSettings, setSavingLocaleSettings] = React.useState(false);
  const [savingMapSettings, setSavingMapSettings] = React.useState(false);

  React.useEffect(() => {
    setDraftAISettings(aiSettings);
  }, [aiSettings]);

  React.useEffect(() => {
    setDraftLocaleSettings(localeSettings);
  }, [localeSettings]);

  React.useEffect(() => {
    setDraftMapSettings(mapSettings);
  }, [mapSettings]);

  const stats = [
    { label: t("common.total"), value: snapshot.stats.totalPhotos, icon: HardDrive },
    { label: t("common.indexed"), value: snapshot.stats.indexedPhotos, icon: CheckCheck },
    { label: t("common.errors"), value: snapshot.stats.erroredPhotos, icon: AlertTriangle },
    { label: t("common.duplicates"), value: snapshot.stats.duplicatePhotos, icon: Sparkles },
  ];

  return (
    <div className="space-y-6">
      <div>
        <h2 className="font-['Space_Grotesk','IBM_Plex_Sans',sans-serif] text-2xl font-semibold tracking-tight text-stone-950">
          {t("settings.title")}
        </h2>
        <p className="mt-1 text-sm text-stone-500">{t("settings.description")}</p>
      </div>

      <div className="flex gap-3">
        <Button onClick={onAddLibrary} variant="accent">
          <FolderPlus className="h-4 w-4" />
          {t("actions.addFolder")}
        </Button>
        <Button disabled={isScanning} onClick={onScanAll} variant="outline">
          {isScanning ? <LoaderCircle className="h-4 w-4 animate-spin" /> : <FolderOpen className="h-4 w-4" />}
          {isScanning ? t("actions.scanning") : t("actions.scanLibrary")}
        </Button>
      </div>

      <div className="space-y-3 rounded-[28px] border border-stone-200 bg-stone-50/80 p-5 shadow-sm">
        <div>
          <h3 className="font-['Space_Grotesk','IBM_Plex_Sans',sans-serif] text-xl font-semibold tracking-tight text-stone-950">
            {t("settings.language.title")}
          </h3>
          <p className="mt-1 text-sm leading-6 text-stone-500">{t("settings.language.description")}</p>
        </div>
        <div className="grid gap-4 md:grid-cols-2">
          <div className="space-y-2">
            <Label>{t("settings.language.uiLocale")}</Label>
            <Select
              onValueChange={(value) =>
                setDraftLocaleSettings((current) => ({ ...current, locale: value as LocaleSettings["locale"] }))
              }
              value={draftLocaleSettings.locale}
            >
              <SelectTrigger className="rounded-2xl">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="en-US">{t("locale.enUS")}</SelectItem>
                <SelectItem value="zh-CN">{t("locale.zhCN")}</SelectItem>
              </SelectContent>
            </Select>
          </div>
          <div className="space-y-2">
            <Label>{t("settings.language.aiOutputLocale")}</Label>
            <Select
              onValueChange={(value) =>
                setDraftLocaleSettings((current) => ({
                  ...current,
                  aiOutputLocale: value as LocaleSettings["aiOutputLocale"],
                }))
              }
              value={draftLocaleSettings.aiOutputLocale}
            >
              <SelectTrigger className="rounded-2xl">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="follow-ui">{t("settings.language.followUi")}</SelectItem>
                <SelectItem value="en-US">{t("locale.enUS")}</SelectItem>
                <SelectItem value="zh-CN">{t("locale.zhCN")}</SelectItem>
              </SelectContent>
            </Select>
          </div>
        </div>
        <div className="flex justify-end">
          <Button
            disabled={savingLocaleSettings}
            onClick={async () => {
              setSavingLocaleSettings(true);
              try {
                await onSaveLocaleSettings(draftLocaleSettings);
              } finally {
                setSavingLocaleSettings(false);
              }
            }}
            variant="outline"
          >
            {savingLocaleSettings ? t("settings.language.saving") : t("settings.language.save")}
          </Button>
        </div>
      </div>

      <div className="space-y-3 rounded-[28px] border border-stone-200 bg-stone-50/80 p-5 shadow-sm">
        <div className="flex items-start justify-between gap-4">
          <div>
            <h3 className="font-['Space_Grotesk','IBM_Plex_Sans',sans-serif] text-xl font-semibold tracking-tight text-stone-950">
	              {t("settings.ai.title")}
            </h3>
            <p className="mt-1 text-sm leading-6 text-stone-500">
	              {t("settings.ai.description")}
            </p>
          </div>
	          <Badge tone={aiEnabled ? "success" : "neutral"}>{aiEnabled ? t("settings.ai.enabled") : t("settings.ai.disabled")}</Badge>
        </div>

        <div className="grid gap-4 md:grid-cols-2">
          <div className="space-y-2">
	            <Label>{t("settings.ai.provider")}</Label>
            <Input
              onChange={(event) => setDraftAISettings((current) => ({ ...current, providerName: event.target.value }))}
              placeholder={t("settings.ai.providerPlaceholder")}
              value={draftAISettings.providerName}
            />
          </div>
          <div className="space-y-2">
	            <Label>{t("settings.ai.model")}</Label>
            <Input
              onChange={(event) => setDraftAISettings((current) => ({ ...current, model: event.target.value }))}
              placeholder={t("settings.ai.modelPlaceholder")}
              value={draftAISettings.model}
            />
          </div>
          <div className="space-y-2 md:col-span-2">
	            <Label>{t("settings.ai.baseUrl")}</Label>
            <Input
              onChange={(event) => setDraftAISettings((current) => ({ ...current, baseURL: event.target.value }))}
              placeholder={t("settings.ai.baseUrlPlaceholder")}
              value={draftAISettings.baseURL}
            />
          </div>
          <div className="space-y-2 md:col-span-2">
	            <Label>{t("settings.ai.apiKey")}</Label>
            <Input
              onChange={(event) => setDraftAISettings((current) => ({ ...current, apiKey: event.target.value }))}
              placeholder={t("settings.ai.apiKeyPlaceholder")}
              type="password"
              value={draftAISettings.apiKey}
            />
          </div>
        </div>

        <div className="flex flex-wrap items-center justify-between gap-3">
          <p className="text-xs leading-5 text-stone-500">{t("settings.ai.runtimeNote")}</p>
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
	            {savingAISettings ? t("settings.ai.saving") : t("settings.ai.save")}
          </Button>
        </div>

      </div>

      <div className="space-y-3 rounded-[28px] border border-stone-200 bg-stone-50/80 p-5 shadow-sm">
        <div className="flex items-start justify-between gap-4">
          <div>
            <h3 className="font-['Space_Grotesk','IBM_Plex_Sans',sans-serif] text-xl font-semibold tracking-tight text-stone-950">
	              {t("settings.map.title")}
            </h3>
            <p className="mt-1 text-sm leading-6 text-stone-500">
	              {t("settings.map.description")}
            </p>
          </div>
          <Badge tone={draftMapSettings.apiKey ? "success" : "neutral"}>
	            {draftMapSettings.apiKey ? t("settings.map.configured") : t("settings.map.disabled")}
          </Badge>
        </div>

        <div className="grid gap-4 md:grid-cols-2">
          <div className="space-y-2 md:col-span-2">
            <Label>{t("settings.map.apiKey")}</Label>
            <Input
              onChange={(event) => setDraftMapSettings((current) => ({ ...current, apiKey: event.target.value }))}
              placeholder={t("settings.map.apiKeyPlaceholder")}
              value={draftMapSettings.apiKey}
            />
          </div>
          <div className="space-y-2 md:col-span-2">
            <Label>{t("settings.map.securityJsCode")}</Label>
            <Input
              onChange={(event) =>
                setDraftMapSettings((current) => ({ ...current, securityJsCode: event.target.value }))
              }
              placeholder={t("settings.map.securityJsCodePlaceholder")}
              value={draftMapSettings.securityJsCode}
            />
          </div>
        </div>

        <div className="flex flex-wrap items-center justify-between gap-3">
          <p className="text-xs leading-5 text-stone-500">{t("settings.map.note")}</p>
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
            {savingMapSettings ? t("settings.map.saving") : t("settings.map.save")}
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
	          <Label>{t("settings.sources.title")}</Label>
	          <Badge tone="info">{t("settings.sources.active", { count: snapshot.sources.length })}</Badge>
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
              <p className="text-xs leading-5 text-stone-500">{t("settings.sources.lastScan", { time: formatTimestamp(source.lastScanAt) })}</p>
            </div>
          ))}
          {snapshot.sources.length === 0 ? (
            <div className="rounded-2xl border border-dashed border-stone-300 bg-stone-50/70 px-5 py-10 text-center">
              <FolderPlus className="mx-auto mb-3 h-10 w-10 text-stone-400" />
	              <p className="text-sm font-medium text-stone-700">{t("settings.sources.emptyTitle")}</p>
              <p className="mt-2 text-sm leading-6 text-stone-500">
	                {t("settings.sources.emptyDescription")}
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
  memoryCandidateCount,
  isGeneratingMemoryCandidates,
  isBatchEnrichingSemantic,
  onGenerateMemoryCandidates,
  onEnrichPendingSemantics,
  statusKind,
  statusMessage,
}: {
  aiEnabled: boolean;
  aiQueueStats: SemanticQueueStats;
  memoryCandidateCount: number;
  isGeneratingMemoryCandidates?: boolean;
  isBatchEnrichingSemantic?: boolean;
  onGenerateMemoryCandidates?: () => void;
  onEnrichPendingSemantics?: () => void;
  statusKind: "idle" | "info" | "success" | "warn" | "error";
  statusMessage: string;
}) {
  const { t } = useI18n();
  const outstanding = aiQueueStats.disabled + aiQueueStats.pending + aiQueueStats.processing + aiQueueStats.failed;

  return (
    <div className="space-y-6">
      <div>
        <h2 className="font-['Space_Grotesk','IBM_Plex_Sans',sans-serif] text-2xl font-semibold tracking-tight text-stone-950">
          {t("notifications.title")}
        </h2>
        <p className="mt-1 text-sm text-stone-500">{t("notifications.description")}</p>
      </div>

      <div className="rounded-[28px] border border-stone-200 bg-stone-50/80 p-5 shadow-sm">
        <div className="flex flex-wrap items-start justify-between gap-4">
          <div className="space-y-3">
            <div className="flex flex-wrap items-center gap-2">
              <Badge tone="info">{t("notifications.aiQueue")}</Badge>
              {aiQueueStats.disabled > 0 ? <Badge tone="neutral">{t("notifications.needAi", { count: aiQueueStats.disabled })}</Badge> : null}
              {aiQueueStats.pending > 0 ? <Badge tone="info">{t("notifications.pending", { count: aiQueueStats.pending })}</Badge> : null}
              {aiQueueStats.processing > 0 ? <Badge tone="info">{t("notifications.processing", { count: aiQueueStats.processing })}</Badge> : null}
              {aiQueueStats.failed > 0 ? <Badge tone="danger">{t("notifications.failed", { count: aiQueueStats.failed })}</Badge> : null}
              {aiQueueStats.completed > 0 ? <Badge tone="success">{t("notifications.ready", { count: aiQueueStats.completed })}</Badge> : null}
            </div>
            <p className="text-sm leading-6 text-stone-600">
              {aiEnabled
                ? outstanding > 0
                  ? aiQueueStats.processing > 0 &&
                    aiQueueStats.disabled + aiQueueStats.pending + aiQueueStats.failed === 0
                    ? t("notifications.aiRunning")
                    : t("notifications.aiWaiting")
                  : t("notifications.aiEmpty")
                : t("notifications.aiDisabled")}
            </p>
          </div>
          <Button
            disabled={!aiEnabled || outstanding === 0 || isBatchEnrichingSemantic}
            onClick={() => void onEnrichPendingSemantics?.()}
            variant="outline"
          >
            {isBatchEnrichingSemantic ? t("notifications.processingQueue") : t("notifications.enrichQueue")}
          </Button>
        </div>
      </div>

      <div className="rounded-[28px] border border-stone-200 bg-stone-50/80 p-5 shadow-sm">
        <div className="flex flex-wrap items-start justify-between gap-4">
          <div className="space-y-3">
            <div className="flex flex-wrap items-center gap-2">
              <Badge tone="info">{t("notifications.memoryCandidates")}</Badge>
              {memoryCandidateCount > 0 ? <Badge tone="warn">{t("notifications.ready", { count: memoryCandidateCount })}</Badge> : <Badge tone="neutral">{t("notifications.ready", { count: 0 })}</Badge>}
            </div>
            <p className="text-sm leading-6 text-stone-600">
              {memoryCandidateCount > 0
                ? t("notifications.suggestedWaiting", { count: memoryCandidateCount })
                : t("notifications.noSuggestedMemories")}
            </p>
          </div>
          <Button
            disabled={isGeneratingMemoryCandidates}
            onClick={() => void onGenerateMemoryCandidates?.()}
            variant="outline"
          >
            {isGeneratingMemoryCandidates ? t("notifications.refreshing") : t("notifications.refreshSuggestions")}
          </Button>
        </div>
      </div>

      {statusKind !== "idle" ? (
        <p className="text-sm text-stone-500">{t("notifications.latestAction", { message: statusMessage })}</p>
      ) : null}
    </div>
  );
}
