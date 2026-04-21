import { PhotoHome } from "@chronopic/ui-components";

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
    <PhotoHome
      aiEnabled={app.capabilities.aiEnabled}
      aiSettings={app.aiSettings}
      mapSettings={app.mapSettings}
      canNavigateNext={app.canNavigateNext}
      canNavigatePrevious={app.canNavigatePrevious}
      draftCaption={app.draftCaption}
      draftDatetime={app.draftDatetime}
      draftTags={app.draftTags}
      filter={app.filter}
      aiQueueStats={app.semanticQueueStats}
      isBatchEnrichingSemantic={app.isBatchEnrichingSemantic}
      isEnrichingMemorySemantic={app.isEnrichingMemorySemantic}
      isEnrichingSemantic={app.isEnrichingSemantic}
      isScanning={app.isScanning}
      mapBrowseContent={
        <MapBrowseSurface
          filter={app.filter}
          mapSettings={app.mapSettings}
          mapViewport={app.mapViewport}
          mappablePhotoCount={app.mappablePhotoCount}
          onOpenDetail={(photoId) => app.openViewer("detail", photoId)}
          onSelectPhoto={app.setSelectedPhotoId}
          onViewportChange={app.setMapViewport}
          photos={app.photos}
          placeGroups={app.placeGroups}
          selectedPhotoMemories={app.selectedPhotoMemories}
          selectedPhotoId={app.selectedPhotoId}
        />
      }
      mappablePhotoCount={app.mappablePhotoCount}
      memories={app.memories}
      onAddLibrary={app.handleAddLibrary}
      onSaveAISettings={app.handleSaveAISettings}
      onSaveMapSettings={app.handleSaveMapSettings}
      onEnrichPendingSemantics={app.handleEnrichPendingSemantics}
      onAddPhotoToMemory={app.handleAddPhotoToMemory}
      onAddSelectionToMemory={app.handleAddSelectionToMemory}
      onClearBatchSelection={app.clearBatchSelection}
      onCloseViewer={app.closeViewer}
      onDeleteMemory={app.handleDeleteMemory}
      onEnrichMemorySemantic={app.handleEnrichMemorySemantic}
      onDatetimeChange={app.setDraftDatetime}
      onEnrichSemantic={app.handleEnrichSemantic}
      onFilterChange={app.patchFilter}
      onNextPhoto={() => app.selectRelativePhoto(1)}
      onOpenDetail={(photoId) => app.openViewer("detail", photoId)}
      onPreviousPhoto={() => app.selectRelativePhoto(-1)}
      onRemovePhotoFromMemory={app.handleRemovePhotoFromMemory}
      onRemoveSelectionFromMemory={app.handleRemoveSelectionFromMemory}
      onRollback={app.handleRollback}
      onSaveDatetime={app.handleSaveDatetime}
      onSaveTags={app.handleSaveTags}
      onScanAll={app.handleScanAll}
      onSearchChange={(query) => app.patchFilter({ query: query || undefined, offset: 0 })}
      onSelectAllPhotos={() => app.patchFilter({ favorite: undefined, memoryId: undefined, offset: 0 })}
      onSelectFavorites={() => app.patchFilter({ favorite: true, memoryId: undefined, offset: 0 })}
      onSelectMemories={() => app.patchFilter({ favorite: undefined, memoryId: undefined, offset: 0 })}
      onSelectPhoto={app.setSelectedPhotoId}
      onToggleBatchSelect={app.toggleBatchSelect}
      onSelectViewerPhoto={app.setSelectedPhotoId}
      onSwitchViewerMode={app.setViewerMode}
      onTagsChange={app.setDraftTags}
      onCaptionChange={app.setDraftCaption}
      onSaveCaption={app.handleSaveCaption}
      onSelectMemory={(memoryId) => app.patchFilter({ favorite: undefined, memoryId, offset: 0 })}
      onConfirmCreateMemory={app.handleCreateMemory}
      onToggleFavorite={app.handleToggleFavorite}
      onUpdateMemory={app.handleUpdateMemory}
      placeGroups={app.placeGroups}
      photos={app.photos}
      searchQuery={app.filter.query ?? ""}
      statusKind={app.status.kind}
      statusMessage={app.status.message}
      selectedPhotoIds={app.selectedPhotoIds}
      selectedPhotoMemories={app.selectedPhotoMemories}
      selectedMemory={app.selectedMemory}
      selectedPhotoId={app.selectedPhotoId}
      snapshot={app.snapshot}
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
  );
}
