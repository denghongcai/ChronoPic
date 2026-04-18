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
      draftDatetime={app.draftDatetime}
      draftTags={app.draftTags}
      filter={app.filter}
      isScanning={app.isScanning}
      memories={app.memories}
      onAddLibrary={app.handleAddLibrary}
      onCloseViewer={app.closeViewer}
      onDatetimeChange={app.setDraftDatetime}
      onFilterChange={app.patchFilter}
      onNextPhoto={() => app.selectRelativePhoto(1)}
      onOpenDetail={(photoId) => app.openViewer("detail", photoId)}
      onPreviousPhoto={() => app.selectRelativePhoto(-1)}
      onRollback={app.handleRollback}
      onSaveDatetime={app.handleSaveDatetime}
      onSaveTags={app.handleSaveTags}
      onScanAll={app.handleScanAll}
      onSearchChange={(query) => app.patchFilter({ query: query || undefined, offset: 0 })}
      onSelectPhoto={app.setSelectedPhotoId}
      onSelectViewerPhoto={app.setSelectedPhotoId}
      onSwitchViewerMode={app.setViewerMode}
      onTagsChange={app.setDraftTags}
      onSelectMemory={(memoryId) => app.patchFilter({ memoryId, offset: 0 })}
      onCreateMemory={() => app.handleCreateMemory("New Memory")}
      onToggleFavorite={app.handleToggleFavorite}
      photos={app.photos}
      searchQuery={app.filter.query ?? ""}
      selectedPhotoId={app.selectedPhotoId}
      snapshot={app.snapshot}
      viewerMode={app.viewerMode}
      viewerPhoto={app.selectedPhoto}
    />
  );
}
