import { useEffect } from "react";

import type { ViewerMode } from "@chronopic/ui-components";

interface UseViewerShortcutsOptions {
  viewerMode: ViewerMode | null;
  selectedPhotoId: string | null;
  onCloseViewer: () => void;
  onOpenDetail: () => void;
  onOpenGallery: () => void;
  onNext: () => void;
  onPrevious: () => void;
}

export function useViewerShortcuts({
  viewerMode,
  selectedPhotoId,
  onCloseViewer,
  onOpenDetail,
  onOpenGallery,
  onNext,
  onPrevious
}: UseViewerShortcutsOptions) {
  useEffect(() => {
    function handleKeyDown(event: KeyboardEvent) {
      const target = event.target as HTMLElement | null;
      const isTextInput =
        target instanceof HTMLInputElement ||
        target instanceof HTMLTextAreaElement ||
        target instanceof HTMLSelectElement ||
        Boolean(target?.isContentEditable);

      if (isTextInput) {
        return;
      }

      if (event.key === "Escape" && viewerMode) {
        event.preventDefault();
        onCloseViewer();
        return;
      }

      if (viewerMode) {
        if (event.key === "ArrowRight") {
          event.preventDefault();
          onNext();
        } else if (event.key === "ArrowLeft") {
          event.preventDefault();
          onPrevious();
        } else if (event.key.toLowerCase() === "g") {
          event.preventDefault();
          onOpenGallery();
        } else if (event.key.toLowerCase() === "d") {
          event.preventDefault();
          onOpenDetail();
        }

        return;
      }

      if (selectedPhotoId) {
        if (event.key === "Enter") {
          event.preventDefault();
          onOpenDetail();
        } else if (event.key.toLowerCase() === "g") {
          event.preventDefault();
          onOpenGallery();
        }
      }
    }

    window.addEventListener("keydown", handleKeyDown);

    return () => {
      window.removeEventListener("keydown", handleKeyDown);
    };
  }, [onCloseViewer, onNext, onOpenDetail, onOpenGallery, onPrevious, selectedPhotoId, viewerMode]);
}
