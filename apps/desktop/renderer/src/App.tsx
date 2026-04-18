import { PhotoViewerOverlay } from "@chronopic/ui-components";

import { DashboardShell } from "./app/dashboard-shell";
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
    onPrevious: () => app.selectRelativePhoto(-1)
  });

  return (
    <>
      <DashboardShell
        capabilities={app.capabilities}
        draftDatetime={app.draftDatetime}
        draftTags={app.draftTags}
        filter={app.filter}
        isScanning={app.isScanning}
        onAddLibrary={app.handleAddLibrary}
        onChangeDraftDatetime={app.setDraftDatetime}
        onChangeDraftTags={app.setDraftTags}
        onChangeFilter={app.patchFilter}
        onOpenDetail={(photoId) => app.openViewer("detail", photoId)}
        onOpenGallery={() => app.openViewer("gallery")}
        onRollback={app.handleRollback}
        onSaveDatetime={app.handleSaveDatetime}
        onSaveTags={app.handleSaveTags}
        onScanAll={app.handleScanAll}
        onSelectPhoto={app.setSelectedPhotoId}
        photos={app.photos}
        selectedPhoto={app.selectedPhoto}
        selectedPhotoId={app.selectedPhotoId}
        snapshot={app.snapshot}
        statusMessage={app.statusMessage}
      />
      <PhotoViewerOverlay
        aiEnabled={app.capabilities.aiEnabled}
        canNavigateNext={app.canNavigateNext}
        canNavigatePrevious={app.canNavigatePrevious}
        draftDatetime={app.draftDatetime}
        draftTags={app.draftTags}
        mode={app.viewerMode}
        onClose={app.closeViewer}
        onDatetimeChange={app.setDraftDatetime}
        onNext={() => app.selectRelativePhoto(1)}
        onPrevious={() => app.selectRelativePhoto(-1)}
        onRollback={app.handleRollback}
        onSaveDatetime={app.handleSaveDatetime}
        onSaveTags={app.handleSaveTags}
        onSelectPhoto={app.setSelectedPhotoId}
        onSwitchMode={app.setViewerMode}
        onTagsChange={app.setDraftTags}
        photo={app.selectedPhoto}
        photos={app.photos}
        selectedPhotoId={app.selectedPhotoId}
      />
    </>
  );
}
