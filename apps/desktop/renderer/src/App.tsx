import { I18nProvider, PhotoHome } from "@chronopic/ui-components";

import { MapBrowseSurface } from "./app/map-browse-surface";
import { TimelineBrowseSurface } from "./app/timeline-browse-surface";
import { useChronoPicApp } from "./app/use-chronopic-app";
import { useViewerShortcuts } from "./app/use-viewer-shortcuts";

export function App() {
  const app = useChronoPicApp();

  useViewerShortcuts({
    viewerMode: app.viewerMode,
    selectedPhotoId: app.selectedPhotoId,
    onCloseViewer: app.closeViewer,
    onOpenGallery: () => app.openViewer("gallery"),
    onNext: () => app.selectRelativePhoto(1),
    onOpenDetail: () => app.openViewer("detail"),
    onPrevious: () => app.selectRelativePhoto(-1),
  });

  return (
    <I18nProvider locale={app.localeSettings.locale}>
      <PhotoHome
        aiEnabled={app.capabilities.aiEnabled}
        aiQueueStats={app.semanticQueueStats}
        aiSettings={app.aiSettings}
        canNavigateNext={app.canNavigateNext}
        canNavigatePrevious={app.canNavigatePrevious}
        draftCaption={app.draftCaption}
        draftDatetime={app.draftDatetime}
        draftTags={app.draftTags}
        filter={app.filter}
        isBatchEnrichingSemantic={app.isBatchEnrichingSemantic}
        isEnrichingMemorySemantic={app.isEnrichingMemorySemantic}
        isEnrichingSemantic={app.isEnrichingSemantic}
        isGeneratingMemoryCandidates={app.isGeneratingMemoryCandidates}
        isScanning={app.isScanning}
        localeSettings={app.localeSettings}
        mapBrowseContent={
          <MapBrowseSurface
            activeMemoryName={app.selectedMemory?.name ?? null}
            filter={app.filter}
            mapSettings={app.mapSettings}
            mapViewport={app.mapViewport}
            mappablePhotoCount={app.mappablePhotoCount}
            onOpenDetail={(photoId) => app.openViewer("detail", photoId)}
            onSelectPhoto={app.setSelectedPhotoId}
            onViewportChange={app.setMapViewport}
            photos={app.photos}
            placeGroups={app.placeGroups}
            selectedPhotoId={app.selectedPhotoId}
            selectedPhotoMemories={app.selectedPhotoMemories}
          />
        }
        mapSettings={app.mapSettings}
        mappablePhotoCount={app.mappablePhotoCount}
        memories={app.memories}
        memoryCandidates={app.memoryCandidates}
        onAcceptMemoryCandidate={app.handleAcceptMemoryCandidate}
        onAddLibrary={app.handleAddLibrary}
        onAddPhotoToMemory={app.handleAddPhotoToMemory}
        onAddSelectionToMemory={app.handleAddSelectionToMemory}
        onCaptionChange={app.setDraftCaption}
        onClearBatchSelection={app.clearBatchSelection}
        onCloseViewer={app.closeViewer}
        onConfirmCreateMemory={app.handleCreateMemory}
        onDatetimeChange={app.setDraftDatetime}
        onDeleteMemory={app.handleDeleteMemory}
        onEnrichMemorySemantic={app.handleEnrichMemorySemantic}
        onEnrichPendingSemantics={app.handleEnrichPendingSemantics}
        onEnrichSemantic={app.handleEnrichSemantic}
        onFilterChange={app.patchFilter}
        onGenerateMemoryCandidates={app.handleGenerateMemoryCandidates}
        onNextPhoto={() => app.selectRelativePhoto(1)}
        onOpenDetail={(photoId) => app.openViewer("detail", photoId)}
        onPreviousPhoto={() => app.selectRelativePhoto(-1)}
        onRejectMemoryCandidate={app.handleRejectMemoryCandidate}
        onRemovePhotoFromMemory={app.handleRemovePhotoFromMemory}
        onRemoveSelectionFromMemory={app.handleRemoveSelectionFromMemory}
        onRollback={app.handleRollback}
        onSaveAISettings={app.handleSaveAISettings}
        onSaveCaption={app.handleSaveCaption}
        onSaveDatetime={app.handleSaveDatetime}
        onSaveLocaleSettings={app.handleSaveLocaleSettings}
        onSaveMapSettings={app.handleSaveMapSettings}
        onSaveTags={app.handleSaveTags}
        onScanAll={app.handleScanAll}
        onSearchChange={(query) => app.patchDiscoveryQuery({ text: query || undefined, offset: 0 })}
        onSelectAllPhotos={() => app.patchFilter({ favorite: undefined, memoryId: undefined, offset: 0 })}
        onSelectFavorites={() => app.patchFilter({ favorite: true, memoryId: undefined, offset: 0 })}
        onSelectMemories={() => app.patchFilter({ favorite: undefined, memoryId: undefined, offset: 0 })}
        onSelectMemory={(memoryId) => app.patchFilter({ favorite: undefined, memoryId, offset: 0 })}
        onSelectPhoto={app.setSelectedPhotoId}
        onSelectViewerPhoto={app.setSelectedPhotoId}
        onSwitchViewerMode={app.setViewerMode}
        onTagsChange={app.setDraftTags}
        onToggleBatchSelect={app.toggleBatchSelect}
        onToggleFavorite={app.handleToggleFavorite}
        onUpdateMemory={app.handleUpdateMemory}
        photos={app.photos}
        placeGroups={app.placeGroups}
        searchQuery={app.discoveryQuery.text ?? ""}
        selectedMemory={app.selectedMemory}
        selectedPhotoId={app.selectedPhotoId}
        selectedPhotoIds={app.selectedPhotoIds}
        selectedPhotoMemories={app.selectedPhotoMemories}
        snapshot={app.snapshot}
        statusKind={app.status.kind}
        statusMessage={app.status.message}
        timelineBrowseContent={
          <TimelineBrowseSurface
            filter={app.filter}
            memories={app.memories}
            onAddPhotoToMemory={app.handleAddPhotoToMemory}
            onAddSelectionToMemory={app.handleAddSelectionToMemory}
            onClearBatchSelection={app.clearBatchSelection}
            onOpenDetail={(photoId) => app.openViewer("detail", photoId)}
            onSelectPhoto={app.setSelectedPhotoId}
            onTimelineGranularityChange={app.setTimelineGranularity}
            onToggleBatchSelect={app.toggleBatchSelect}
            onToggleFavorite={app.handleToggleFavorite}
            photos={app.photos}
            selectedPhotoId={app.selectedPhotoId}
            selectedPhotoIds={app.selectedPhotoIds}
            selectedPhotoMemories={app.selectedPhotoMemories}
            timelineGranularity={app.timelineGranularity}
            timelineGroups={app.timelineGroups}
          />
        }
        viewerMode={app.viewerMode}
        viewerPhoto={app.selectedPhoto}
      />
    </I18nProvider>
  );
}
