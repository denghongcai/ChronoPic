import { useEffect, useMemo, useState } from "react";

import type { AppCapabilities, LibrarySnapshot, PhotoFilter, PhotoFilterPatch, PhotoRecord } from "@chronopic/domain";
import type { ViewerMode } from "@chronopic/ui-components";

function toDatetimeInput(timestamp: number | null): string {
  if (!timestamp) {
    return "";
  }

  const date = new Date(timestamp);
  const local = new Date(date.getTime() - date.getTimezoneOffset() * 60000);
  return local.toISOString().slice(0, 16);
}

function parseTags(input: string): string[] {
  return input
    .split(",")
    .map((value) => value.trim())
    .filter(Boolean);
}

export function useChronoPicApp() {
  const [snapshot, setSnapshot] = useState<LibrarySnapshot>({
    sources: [],
    stats: {
      totalPhotos: 0,
      indexedPhotos: 0,
      erroredPhotos: 0,
      duplicatePhotos: 0
    }
  });
  const [capabilities, setCapabilities] = useState<AppCapabilities>({ aiEnabled: false, supportedMedia: [] });
  const [photos, setPhotos] = useState<PhotoRecord[]>([]);
  const [selectedPhotoId, setSelectedPhotoId] = useState<string | null>(null);
  const [draftTags, setDraftTags] = useState("");
  const [draftDatetime, setDraftDatetime] = useState("");
  const [isScanning, setIsScanning] = useState(false);
  const [statusMessage, setStatusMessage] = useState("Idle");
  const [viewerMode, setViewerMode] = useState<ViewerMode | null>(null);
  const [filter, setFilter] = useState<PhotoFilter>({
    limit: 120,
    offset: 0,
    sortBy: "datetime",
    sortDirection: "desc"
  });

  const selectedPhoto = useMemo(
    () => photos.find((photo) => photo.photo.id === selectedPhotoId) ?? null,
    [photos, selectedPhotoId]
  );
  const selectedPhotoIndex = useMemo(
    () => photos.findIndex((photo) => photo.photo.id === selectedPhotoId),
    [photos, selectedPhotoId]
  );
  const canNavigatePrevious = selectedPhotoIndex > 0;
  const canNavigateNext = selectedPhotoIndex >= 0 && selectedPhotoIndex < photos.length - 1;

  function patchFilter(patch: PhotoFilterPatch) {
    setFilter((current) => {
      const next: PhotoFilter = { ...current };

      for (const [key, value] of Object.entries(patch) as Array<[keyof PhotoFilterPatch, PhotoFilterPatch[keyof PhotoFilterPatch]]>) {
        if (value === undefined) {
          delete next[key as keyof PhotoFilter];
        } else {
          next[key as keyof PhotoFilter] = value as never;
        }
      }

      return next;
    });
  }

  useEffect(() => {
    void hydrate();
  }, []);

  useEffect(() => {
    void refreshPhotos();
  }, [filter]);

  useEffect(() => {
    setDraftTags(selectedPhoto?.semantic.labels.join(", ") ?? "");
    setDraftDatetime(toDatetimeInput(selectedPhoto?.metadata.datetime ?? null));
  }, [selectedPhotoId, selectedPhoto?.metadata.datetime, selectedPhoto?.semantic.labels]);

  useEffect(() => {
    if (!selectedPhoto && viewerMode) {
      setViewerMode(null);
    }
  }, [selectedPhoto, viewerMode]);

  async function hydrate() {
    const response = await window.chronoPic.initialize();
    setSnapshot(response.snapshot);
    setCapabilities(response.capabilities);
    await refreshPhotos();
  }

  async function refreshPhotos() {
    const nextPhotos = (await window.chronoPic.listPhotos(filter)) as PhotoRecord[];
    setPhotos(nextPhotos);
    setSelectedPhotoId((current) => {
      if (nextPhotos.length === 0) {
        return null;
      }

      return nextPhotos.some((photo) => photo.photo.id === current) ? current : nextPhotos[0]?.photo.id ?? null;
    });
  }

  async function refreshSnapshot() {
    setSnapshot((await window.chronoPic.getSnapshot()) as LibrarySnapshot);
  }

  async function handleAddLibrary() {
    const libraryPath = await window.chronoPic.pickLibraryDirectory();

    if (!libraryPath) {
      return;
    }

    await window.chronoPic.addLibrarySource(libraryPath);
    await refreshSnapshot();
    setStatusMessage(`Added library: ${libraryPath}`);
  }

  async function handleScanAll() {
    setIsScanning(true);
    setStatusMessage("Scanning libraries...");

    try {
      await window.chronoPic.scanLibrary();
      await refreshSnapshot();
      await refreshPhotos();
      setStatusMessage("Scan complete");
    } finally {
      setIsScanning(false);
    }
  }

  async function handleSaveTags() {
    if (!selectedPhotoId) {
      return;
    }

    const updated = (await window.chronoPic.updatePhotoTags(selectedPhotoId, parseTags(draftTags))) as PhotoRecord;
    setPhotos((current) => current.map((photo) => (photo.photo.id === updated.photo.id ? updated : photo)));
    setStatusMessage("Tags updated");
  }

  async function handleSaveDatetime() {
    if (!selectedPhotoId) {
      return;
    }

    const timestamp = draftDatetime ? new Date(draftDatetime).getTime() : null;
    const updated = (await window.chronoPic.updatePhotoDatetime(selectedPhotoId, timestamp)) as PhotoRecord;
    setPhotos((current) => current.map((photo) => (photo.photo.id === updated.photo.id ? updated : photo)));
    setStatusMessage("Datetime updated");
  }

  async function handleRollback() {
    if (!selectedPhotoId) {
      return;
    }

    const updated = (await window.chronoPic.rollbackLatestEdit(selectedPhotoId)) as PhotoRecord | null;

    if (!updated) {
      setStatusMessage("No edit to roll back");
      return;
    }

    setPhotos((current) => current.map((photo) => (photo.photo.id === updated.photo.id ? updated : photo)));
    setStatusMessage("Rolled back latest edit");
  }

  function openViewer(mode: ViewerMode, photoId?: string) {
    if (photoId) {
      setSelectedPhotoId(photoId);
    }

    setViewerMode(mode);
  }

  function closeViewer() {
    setViewerMode(null);
  }

  function selectRelativePhoto(step: number) {
    if (photos.length === 0) {
      return;
    }

    const currentIndex = selectedPhotoIndex >= 0 ? selectedPhotoIndex : 0;
    const nextIndex = Math.min(Math.max(currentIndex + step, 0), photos.length - 1);
    const nextPhoto = photos[nextIndex];

    if (nextPhoto) {
      setSelectedPhotoId(nextPhoto.photo.id);
    }
  }

  return {
    canNavigateNext,
    canNavigatePrevious,
    capabilities,
    draftDatetime,
    draftTags,
    filter,
    isScanning,
    openViewer,
    patchFilter,
    photos,
    selectedPhoto,
    selectedPhotoId,
    setDraftDatetime,
    setDraftTags,
    setSelectedPhotoId,
    setViewerMode,
    snapshot,
    statusMessage,
    viewerMode,
    handleAddLibrary,
    handleRollback,
    handleSaveDatetime,
    handleSaveTags,
    handleScanAll,
    closeViewer,
    selectRelativePhoto
  };
}
