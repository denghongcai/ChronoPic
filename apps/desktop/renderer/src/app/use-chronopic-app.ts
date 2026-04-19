import { useEffect, useMemo, useState } from "react";

import type {
  AppCapabilities,
  LibrarySnapshot,
  Memory,
  PhotoFilter,
  PhotoFilterPatch,
  PhotoRecord,
  PlaceGroup,
  TimelineGranularity,
  TimelineGroup,
} from "@chronopic/domain";
import type { ViewerMode } from "@chronopic/ui-components";

type StatusKind = "idle" | "info" | "success" | "warn" | "error";

interface AppStatus {
  kind: StatusKind;
  message: string;
}

interface MapViewportState {
  centerLat: number;
  centerLng: number;
  zoom: number;
}

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
  const idleStatus: AppStatus = { kind: "idle", message: "Idle" };
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
  const [placeGroups, setPlaceGroups] = useState<PlaceGroup[]>([]);
  const [timelineGroups, setTimelineGroups] = useState<TimelineGroup[]>([]);
  const [timelineGranularity, setTimelineGranularity] = useState<TimelineGranularity>("month");
  const [mapViewport, setMapViewport] = useState<MapViewportState | null>(null);
  const [memories, setMemories] = useState<Memory[]>([]);
  const [mappablePhotoCount, setMappablePhotoCount] = useState(0);
  const [selectedPhotoMemories, setSelectedPhotoMemories] = useState<Memory[]>([]);
  const [selectedPhotoIds, setSelectedPhotoIds] = useState<string[]>([]);
  const [selectedPhotoId, setSelectedPhotoId] = useState<string | null>(null);
  const [draftTags, setDraftTags] = useState<string[]>([]);
  const [draftDatetime, setDraftDatetime] = useState("");
  const [draftCaption, setDraftCaption] = useState("");
  const [isScanning, setIsScanning] = useState(false);
  const [status, setStatus] = useState<AppStatus>(idleStatus);
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
  const selectedMemory = useMemo(
    () => memories.find((memory) => memory.id === filter.memoryId) ?? null,
    [filter.memoryId, memories]
  );
  const selectedPhotoIndex = useMemo(
    () => photos.findIndex((photo) => photo.photo.id === selectedPhotoId),
    [photos, selectedPhotoId]
  );
  const canNavigatePrevious = selectedPhotoIndex > 0;
  const canNavigateNext = selectedPhotoIndex >= 0 && selectedPhotoIndex < photos.length - 1;

  function resolveMemoryName(memoryId: string): string {
    return memories.find((memory) => memory.id === memoryId)?.name ?? "memory";
  }

  function showStatus(kind: Exclude<StatusKind, "idle">, message: string) {
    setStatus({ kind, message });
  }

  function formatErrorMessage(error: unknown, fallback: string): string {
    if (error instanceof Error && error.message) {
      return `${fallback}: ${error.message}`;
    }

    return fallback;
  }

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
    void refreshGeospatial();
  }, [filter]);

  useEffect(() => {
    void refreshTimeline();
  }, [filter, timelineGranularity]);

  useEffect(() => {
    setDraftTags(selectedPhoto?.semantic.labels ?? []);
    setDraftDatetime(toDatetimeInput(selectedPhoto?.metadata.datetime ?? null));
    setDraftCaption(selectedPhoto?.semantic.caption ?? "");
  }, [selectedPhotoId, selectedPhoto?.metadata.datetime, selectedPhoto?.semantic.labels, selectedPhoto?.semantic.caption]);

  useEffect(() => {
    setSelectedPhotoIds((current) => current.filter((photoId) => photos.some((photo) => photo.photo.id === photoId)));
  }, [photos]);

  useEffect(() => {
    if (!selectedPhoto && viewerMode) {
      setViewerMode(null);
    }
  }, [selectedPhoto, viewerMode]);

  useEffect(() => {
    void refreshSelectedPhotoMemories();
  }, [selectedPhotoId, memories]);

  useEffect(() => {
    if (isScanning || status.kind === "idle") {
      return;
    }

    const timer = window.setTimeout(() => {
      setStatus(idleStatus);
    }, 2400);

    return () => window.clearTimeout(timer);
  }, [idleStatus, isScanning, status]);

  async function hydrate() {
    const response = await window.chronoPic.initialize();
    setSnapshot(response.snapshot);
    setCapabilities(response.capabilities);
    await refreshPhotos();
    await refreshMemories();
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

  async function refreshGeospatial() {
    const [nextMappableCount, nextPlaceGroups] = await Promise.all([
      window.chronoPic.countMappablePhotos(filter),
      window.chronoPic.listPlaceGroups({ filter, limit: 200, precision: 2 }),
    ]);

    setMappablePhotoCount(nextMappableCount as number);
    setPlaceGroups(nextPlaceGroups as PlaceGroup[]);
  }

  async function refreshTimeline() {
    const nextTimelineGroups = await window.chronoPic.listTimelineGroups({
      filter,
      granularity: timelineGranularity,
      limitGroups: 48,
    });

    setTimelineGroups(nextTimelineGroups as TimelineGroup[]);
  }

  async function refreshSnapshot() {
    setSnapshot((await window.chronoPic.getSnapshot()) as LibrarySnapshot);
  }

  async function handleAddLibrary() {
    try {
      const libraryPath = await window.chronoPic.pickLibraryDirectory();

      if (!libraryPath) {
        return;
      }

      await window.chronoPic.addLibrarySource(libraryPath);
      await refreshSnapshot();
      showStatus("success", `Added library: ${libraryPath}`);
    } catch (error) {
      showStatus("error", formatErrorMessage(error, "Failed to add library"));
    }
  }

  async function handleScanAll() {
    setIsScanning(true);
    showStatus("info", "Scanning libraries...");

    try {
      await window.chronoPic.scanLibrary();
      await refreshSnapshot();
      await refreshPhotos();
      await refreshMemories();
      await refreshGeospatial();
      await refreshTimeline();
      showStatus("success", "Scan complete");
    } catch (error) {
      showStatus("error", formatErrorMessage(error, "Scan failed"));
    } finally {
      setIsScanning(false);
    }
  }

  async function refreshMemories() {
    const nextMemories = (await window.chronoPic.listMemories()) as Memory[];
    setMemories(nextMemories);
  }

  async function refreshSelectedPhotoMemories() {
    if (!selectedPhotoId) {
      setSelectedPhotoMemories([]);
      return;
    }

    const nextMemories = (await window.chronoPic.listMemoriesByPhoto(selectedPhotoId)) as Memory[];
    setSelectedPhotoMemories(nextMemories);
  }

  async function handleCreateMemory(name: string, description?: string) {
    try {
      const created = (await window.chronoPic.createMemory(name, description, "manual")) as Memory;
      setMemories((current) => [...current, created]);
      showStatus("success", `Created memory: ${name}`);
    } catch (error) {
      showStatus("error", formatErrorMessage(error, "Failed to create memory"));
      throw error;
    }
  }

  async function handleDeleteMemory(memoryId: string) {
    const memoryName = resolveMemoryName(memoryId);
    try {
      await window.chronoPic.deleteMemory(memoryId);
      setMemories((current) => current.filter((m) => m.id !== memoryId));
      showStatus("success", `Deleted memory: ${memoryName}`);
    } catch (error) {
      showStatus("error", formatErrorMessage(error, "Failed to delete memory"));
      throw error;
    }
  }

  async function handleUpdateMemory(
    memoryId: string,
    updates: { name?: string; description?: string | null; coverPhotoId?: string | null }
  ) {
    try {
      const updated = (await window.chronoPic.updateMemory(memoryId, updates)) as Memory;
      setMemories((current) => current.map((memory) => (memory.id === updated.id ? updated : memory)));

      if (Object.prototype.hasOwnProperty.call(updates, "name") && updates.name) {
        showStatus("success", `Renamed memory to ${updated.name}`);
      } else if (Object.prototype.hasOwnProperty.call(updates, "description")) {
        showStatus("success", `Saved description for ${updated.name}`);
      } else if (Object.prototype.hasOwnProperty.call(updates, "coverPhotoId")) {
        showStatus("success", `Updated cover for ${updated.name}`);
      } else {
        showStatus("success", `Updated memory: ${updated.name}`);
      }

      return updated;
    } catch (error) {
      showStatus("error", formatErrorMessage(error, "Failed to update memory"));
      throw error;
    }
  }

  async function handleAddPhotoToMemory(memoryId: string, photoId: string) {
    const memoryName = resolveMemoryName(memoryId);
    try {
      const memberships = (await window.chronoPic.listMemoriesByPhoto(photoId)) as Memory[];
      if (memberships.some((memory) => memory.id === memoryId)) {
        showStatus("warn", `Photo is already in ${memoryName}`);
        return;
      }

      await window.chronoPic.addPhotoToMemory(memoryId, photoId);
      await refreshMemories();
      if (filter.memoryId === memoryId) {
        await refreshPhotos();
      }
      showStatus("success", `Added photo to ${memoryName}`);
    } catch (error) {
      showStatus("error", formatErrorMessage(error, "Failed to add photo to memory"));
    }
  }

  async function handleAddSelectionToMemory(memoryId: string, photoIds: string[]) {
    const uniquePhotoIds = Array.from(new Set(photoIds));
    if (uniquePhotoIds.length === 0) {
      showStatus("warn", "Select at least one photo first");
      return;
    }

    const memoryName = resolveMemoryName(memoryId);
    let addedCount = 0;
    let alreadyPresentCount = 0;
    let failedCount = 0;

    await Promise.all(
      uniquePhotoIds.map(async (photoId) => {
        try {
          const memberships = (await window.chronoPic.listMemoriesByPhoto(photoId)) as Memory[];
          if (memberships.some((memory) => memory.id === memoryId)) {
            alreadyPresentCount += 1;
            return;
          }

          await window.chronoPic.addPhotoToMemory(memoryId, photoId);
          addedCount += 1;
        } catch {
          failedCount += 1;
        }
      })
    );

    await refreshMemories();
    if (filter.memoryId === memoryId) {
      await refreshPhotos();
    }

    setSelectedPhotoIds([]);

    const segments = [];
    if (addedCount > 0) {
      segments.push(`added ${addedCount}`);
    }
    if (alreadyPresentCount > 0) {
      segments.push(`${alreadyPresentCount} already there`);
    }
    if (failedCount > 0) {
      segments.push(`${failedCount} failed`);
    }

    if (addedCount === 0 && alreadyPresentCount > 0 && failedCount === 0) {
      showStatus("warn", `No changes in ${memoryName}: ${alreadyPresentCount} already there`);
      return;
    }

    if (failedCount > 0 || alreadyPresentCount > 0) {
      showStatus("warn", `${memoryName}: ${segments.join(", ")}`);
      return;
    }

    showStatus("success", `Added ${addedCount} photo${addedCount === 1 ? "" : "s"} to ${memoryName}`);
  }

  async function handleRemoveSelectionFromMemory(memoryId: string, photoIds: string[]) {
    const uniquePhotoIds = Array.from(new Set(photoIds));
    if (uniquePhotoIds.length === 0) {
      showStatus("warn", "Select at least one photo first");
      return;
    }

    const memoryName = resolveMemoryName(memoryId);
    let removedCount = 0;
    let missingCount = 0;
    let failedCount = 0;

    await Promise.all(
      uniquePhotoIds.map(async (photoId) => {
        try {
          const memberships = (await window.chronoPic.listMemoriesByPhoto(photoId)) as Memory[];
          if (!memberships.some((memory) => memory.id === memoryId)) {
            missingCount += 1;
            return;
          }

          await window.chronoPic.removePhotoFromMemory(memoryId, photoId);
          removedCount += 1;
        } catch {
          failedCount += 1;
        }
      })
    );

    await refreshMemories();
    if (filter.memoryId === memoryId) {
      await refreshPhotos();
    }

    setSelectedPhotoIds([]);

    const segments = [];
    if (removedCount > 0) {
      segments.push(`removed ${removedCount}`);
    }
    if (missingCount > 0) {
      segments.push(`${missingCount} already absent`);
    }
    if (failedCount > 0) {
      segments.push(`${failedCount} failed`);
    }

    if (removedCount === 0 && missingCount > 0 && failedCount === 0) {
      showStatus("warn", `No changes in ${memoryName}: ${missingCount} already absent`);
      return;
    }

    if (failedCount > 0 || missingCount > 0) {
      showStatus("warn", `${memoryName}: ${segments.join(", ")}`);
      return;
    }

    showStatus("success", `Removed ${removedCount} photo${removedCount === 1 ? "" : "s"} from ${memoryName}`);
  }

  async function handleRemovePhotoFromMemory(memoryId: string, photoId: string) {
    const memoryName = resolveMemoryName(memoryId);
    try {
      const memberships = (await window.chronoPic.listMemoriesByPhoto(photoId)) as Memory[];
      if (!memberships.some((memory) => memory.id === memoryId)) {
        showStatus("warn", `Photo is no longer in ${memoryName}`);
        return;
      }

      await window.chronoPic.removePhotoFromMemory(memoryId, photoId);
      await refreshMemories();
      if (filter.memoryId === memoryId) {
        await refreshPhotos();
      }
      showStatus("success", `Removed photo from ${memoryName}`);
    } catch (error) {
      showStatus("error", formatErrorMessage(error, "Failed to remove photo from memory"));
    }
  }

  async function handleToggleFavorite(photoId: string, favorite: boolean) {
    const updated = (await window.chronoPic.updatePhotoFavorite(photoId, favorite)) as PhotoRecord;
    setPhotos((current) => current.map((photo) => (photo.photo.id === updated.photo.id ? updated : photo)));
  }

  async function handleSaveTags() {
    if (!selectedPhotoId) {
      return;
    }

    try {
      const updated = (await window.chronoPic.updatePhotoTags(selectedPhotoId, draftTags)) as PhotoRecord;
      setPhotos((current) => current.map((photo) => (photo.photo.id === updated.photo.id ? updated : photo)));
      showStatus("success", "Tags updated");
    } catch (error) {
      showStatus("error", formatErrorMessage(error, "Failed to update tags"));
    }
  }

  async function handleSaveCaption() {
    if (!selectedPhotoId) {
      return;
    }

    try {
      const updated = (await window.chronoPic.updatePhotoCaption(selectedPhotoId, draftCaption || null)) as PhotoRecord;
      setPhotos((current) => current.map((photo) => (photo.photo.id === updated.photo.id ? updated : photo)));
      showStatus("success", "Caption updated");
    } catch (error) {
      showStatus("error", formatErrorMessage(error, "Failed to update caption"));
    }
  }

  async function handleSaveDatetime() {
    if (!selectedPhotoId) {
      return;
    }

    try {
      const timestamp = draftDatetime ? new Date(draftDatetime).getTime() : null;
      const updated = (await window.chronoPic.updatePhotoDatetime(selectedPhotoId, timestamp)) as PhotoRecord;
      setPhotos((current) => current.map((photo) => (photo.photo.id === updated.photo.id ? updated : photo)));
      showStatus("success", "Datetime updated");
    } catch (error) {
      showStatus("error", formatErrorMessage(error, "Failed to update datetime"));
    }
  }

  async function handleRollback() {
    if (!selectedPhotoId) {
      return;
    }

    const updated = (await window.chronoPic.rollbackLatestEdit(selectedPhotoId)) as PhotoRecord | null;

    if (!updated) {
      showStatus("warn", "No edit to roll back");
      return;
    }

    setPhotos((current) => current.map((photo) => (photo.photo.id === updated.photo.id ? updated : photo)));
    showStatus("success", "Rolled back latest edit");
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

  function toggleBatchSelect(photoId: string) {
    setSelectedPhotoIds((current) =>
      current.includes(photoId) ? current.filter((id) => id !== photoId) : [...current, photoId]
    );
  }

  function clearBatchSelection() {
    setSelectedPhotoIds([]);
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
    draftCaption,
    draftDatetime,
    draftTags,
    filter,
    isScanning,
    mappablePhotoCount,
    mapViewport,
    memories,
    openViewer,
    patchFilter,
    placeGroups,
    photos,
    selectedPhotoIds,
    selectedPhotoMemories,
    selectedMemory,
    selectedPhoto,
    selectedPhotoId,
    setDraftCaption,
    setDraftDatetime,
    setDraftTags,
    setMapViewport,
    setSelectedPhotoId,
    setTimelineGranularity,
    setViewerMode,
    snapshot,
    status,
    timelineGranularity,
    timelineGroups,
    viewerMode,
    handleAddLibrary,
    handleAddPhotoToMemory,
    handleAddSelectionToMemory,
    handleCreateMemory,
    handleDeleteMemory,
    handleRemovePhotoFromMemory,
    handleRemoveSelectionFromMemory,
    handleRollback,
    handleSaveCaption,
    handleSaveDatetime,
    handleSaveTags,
    handleScanAll,
    handleToggleFavorite,
    handleUpdateMemory,
    clearBatchSelection,
    closeViewer,
    selectRelativePhoto,
    toggleBatchSelect,
  };
}
