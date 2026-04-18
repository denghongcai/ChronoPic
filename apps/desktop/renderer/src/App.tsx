import { PhotoHome } from "@chronopic/ui-components";

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
      canNavigateNext={app.canNavigateNext}
      canNavigatePrevious={app.canNavigatePrevious}
      draftCaption={app.draftCaption}
      draftDatetime={app.draftDatetime}
      draftTags={app.draftTags}
      filter={app.filter}
      isScanning={app.isScanning}
      memories={app.memories}
      onAddLibrary={app.handleAddLibrary}
      onAddPhotoToMemory={app.handleAddPhotoToMemory}
      onAddSelectionToMemory={app.handleAddSelectionToMemory}
      onClearBatchSelection={app.clearBatchSelection}
      onCloseViewer={app.closeViewer}
      onDeleteMemory={app.handleDeleteMemory}
      onDatetimeChange={app.setDraftDatetime}
      onFilterChange={app.patchFilter}
      onNextPhoto={() => app.selectRelativePhoto(1)}
      onOpenDetail={(photoId) => app.openViewer("detail", photoId)}
      onPreviousPhoto={() => app.selectRelativePhoto(-1)}
      onRemovePhotoFromMemory={app.handleRemovePhotoFromMemory}
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
      photos={app.photos}
      searchQuery={app.filter.query ?? ""}
      statusMessage={app.statusMessage}
      selectedPhotoIds={app.selectedPhotoIds}
      selectedPhotoMemories={app.selectedPhotoMemories}
      selectedMemory={app.selectedMemory}
      selectedPhotoId={app.selectedPhotoId}
      snapshot={app.snapshot}
      viewerMode={app.viewerMode}
      viewerPhoto={app.selectedPhoto}
    />
  );
}
