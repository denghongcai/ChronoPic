import { useEffect, useMemo, useRef, useState } from "react";

import {
  discoveryQueryToPhotoFilter,
  photoFilterToDiscoveryQuery,
} from "@chronopic/domain";
import type {
  AISettings,
  AppCapabilities,
  DiscoveryQuery,
  DiscoveryQueryPatch,
  LibrarySnapshot,
  MapSettings,
  Memory,
  MemoryCandidate,
  PhotoFilter,
  PhotoFilterPatch,
  PhotoRecord,
  PlaceGroup,
  SemanticQueueStats,
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
  const [aiSettings, setAISettings] = useState<AISettings>({
    apiKey: "",
    baseURL: "",
    model: "",
    providerName: "openai-compatible",
  });
  const [mapSettings, setMapSettings] = useState<MapSettings>({
    apiKey: "",
    securityJsCode: "",
  });
  const [photos, setPhotos] = useState<PhotoRecord[]>([]);
  const [placeGroups, setPlaceGroups] = useState<PlaceGroup[]>([]);
  const [timelineGroups, setTimelineGroups] = useState<TimelineGroup[]>([]);
  const [semanticQueueStats, setSemanticQueueStats] = useState<SemanticQueueStats>({
    disabled: 0,
    pending: 0,
    processing: 0,
    completed: 0,
    failed: 0,
  });
  const [timelineGranularity, setTimelineGranularity] = useState<TimelineGranularity>("month");
  const [mapViewport, setMapViewport] = useState<MapViewportState | null>(null);
  const [memories, setMemories] = useState<Memory[]>([]);
  const [memoryCandidates, setMemoryCandidates] = useState<MemoryCandidate[]>([]);
  const [mappablePhotoCount, setMappablePhotoCount] = useState(0);
  const [selectedPhotoMemories, setSelectedPhotoMemories] = useState<Memory[]>([]);
  const [selectedPhotoIds, setSelectedPhotoIds] = useState<string[]>([]);
  const [selectedPhotoId, setSelectedPhotoId] = useState<string | null>(null);
  const [draftTags, setDraftTags] = useState<string[]>([]);
  const [draftDatetime, setDraftDatetime] = useState("");
  const [draftCaption, setDraftCaption] = useState("");
  const [isEnrichingSemantic, setIsEnrichingSemantic] = useState(false);
  const [isEnrichingMemorySemantic, setIsEnrichingMemorySemantic] = useState(false);
  const [isGeneratingMemoryCandidates, setIsGeneratingMemoryCandidates] = useState(false);
  const [isBatchEnrichingSemantic, setIsBatchEnrichingSemantic] = useState(false);
  const [isScanning, setIsScanning] = useState(false);
  const [status, setStatus] = useState<AppStatus>(idleStatus);
  const [viewerMode, setViewerMode] = useState<ViewerMode | null>(null);
  const bridgeWarningShownRef = useRef(false);
  const [discoveryQuery, setDiscoveryQuery] = useState<DiscoveryQuery>({
    limit: 120,
    offset: 0,
    sortBy: "datetime",
    sortDirection: "desc"
  });
  const filter = useMemo(() => discoveryQueryToPhotoFilter(discoveryQuery), [discoveryQuery]);

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
  const bridge = (window as Window & { chronoPic?: Window["chronoPic"] }).chronoPic;

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

  function requireBridge(): Window["chronoPic"] | null {
    if (bridge) {
      return bridge;
    }

    if (!bridgeWarningShownRef.current) {
      bridgeWarningShownRef.current = true;
      setStatus({
        kind: "error",
        message: "Desktop bridge unavailable. Restart the app or check preload startup.",
      });
    }

    return null;
  }

  function patchFilter(patch: PhotoFilterPatch) {
    setDiscoveryQuery((current) => {
      const next: PhotoFilter = { ...discoveryQueryToPhotoFilter(current) };

      for (const [key, value] of Object.entries(patch) as Array<[keyof PhotoFilterPatch, PhotoFilterPatch[keyof PhotoFilterPatch]]>) {
        if (value === undefined) {
          delete next[key as keyof PhotoFilter];
        } else {
          next[key as keyof PhotoFilter] = value as never;
        }
      }

      return photoFilterToDiscoveryQuery(next);
    });
  }

  function patchDiscoveryQuery(patch: DiscoveryQueryPatch) {
    setDiscoveryQuery((current) => {
      const next: DiscoveryQuery = { ...current };

      for (const [key, value] of Object.entries(patch) as Array<
        [keyof DiscoveryQueryPatch, DiscoveryQueryPatch[keyof DiscoveryQueryPatch]]
      >) {
        if (value === undefined) {
          delete next[key as keyof DiscoveryQuery];
        } else {
          next[key as keyof DiscoveryQuery] = value as never;
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
  }, [discoveryQuery]);

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
    const activeBridge = requireBridge();
    if (!activeBridge) {
      return;
    }

    const [response, currentAISettings, currentMapSettings] = await Promise.all([
      activeBridge.initialize(),
      activeBridge.getAISettings(),
      activeBridge.getMapSettings(),
    ]);
    setSnapshot(response.snapshot);
    setCapabilities(response.capabilities);
    setAISettings(currentAISettings as AISettings);
    setMapSettings(currentMapSettings as MapSettings);
    await refreshPhotos();
    await refreshMemories();
    await refreshMemoryCandidates();
    await refreshSemanticQueueStats();
  }

  async function refreshPhotos() {
    const activeBridge = requireBridge();
    if (!activeBridge) {
      return;
    }

    const nextPhotos = (await activeBridge.listPhotosForDiscovery(discoveryQuery)) as PhotoRecord[];
    setPhotos(nextPhotos);
    setSelectedPhotoId((current) => {
      if (nextPhotos.length === 0) {
        return null;
      }

      return nextPhotos.some((photo) => photo.photo.id === current) ? current : nextPhotos[0]?.photo.id ?? null;
    });
  }

  async function refreshGeospatial() {
    const activeBridge = requireBridge();
    if (!activeBridge) {
      return;
    }

    const [nextMappableCount, nextPlaceGroups] = await Promise.all([
      activeBridge.countMappablePhotos(filter),
      activeBridge.listPlaceGroups({ filter, limit: 200, precision: 2 }),
    ]);

    setMappablePhotoCount(nextMappableCount as number);
    setPlaceGroups(nextPlaceGroups as PlaceGroup[]);
  }

  async function refreshTimeline() {
    const activeBridge = requireBridge();
    if (!activeBridge) {
      return;
    }

    const nextTimelineGroups = await activeBridge.listTimelineGroups({
      filter,
      granularity: timelineGranularity,
      limitGroups: 48,
    });

    setTimelineGroups(nextTimelineGroups as TimelineGroup[]);
  }

  async function refreshSemanticQueueStats() {
    const activeBridge = requireBridge();
    if (!activeBridge) {
      return;
    }

    const nextStats = (await activeBridge.getSemanticQueueStats()) as SemanticQueueStats;
    setSemanticQueueStats(nextStats);
  }

  async function refreshSnapshot() {
    const activeBridge = requireBridge();
    if (!activeBridge) {
      return;
    }

    setSnapshot((await activeBridge.getSnapshot()) as LibrarySnapshot);
  }

  async function handleAddLibrary() {
    const activeBridge = requireBridge();
    if (!activeBridge) {
      return;
    }

    try {
      const libraryPath = await activeBridge.pickLibraryDirectory();

      if (!libraryPath) {
        return;
      }

      await activeBridge.addLibrarySource(libraryPath);
      await refreshSnapshot();
      showStatus("success", `Added library: ${libraryPath}`);
    } catch (error) {
      showStatus("error", formatErrorMessage(error, "Failed to add library"));
    }
  }

  async function handleScanAll() {
    const activeBridge = requireBridge();
    if (!activeBridge) {
      return;
    }

    setIsScanning(true);
    showStatus("info", "Scanning libraries...");

    try {
      await activeBridge.scanLibrary();
      await refreshSnapshot();
      await refreshPhotos();
      await refreshMemories();
      await refreshGeospatial();
      await refreshTimeline();
      await refreshSemanticQueueStats();
      showStatus("success", "Scan complete");
    } catch (error) {
      showStatus("error", formatErrorMessage(error, "Scan failed"));
    } finally {
      setIsScanning(false);
    }
  }

  async function handleSaveAISettings(nextSettings: AISettings) {
    const activeBridge = requireBridge();
    if (!activeBridge) {
      throw new Error("Desktop bridge unavailable");
    }

    try {
      const response = (await activeBridge.saveAISettings(nextSettings)) as {
        settings: AISettings;
        capabilities: AppCapabilities;
      };

      setAISettings(response.settings);
      setCapabilities(response.capabilities);
      await refreshSemanticQueueStats();
      showStatus(
        response.capabilities.aiEnabled ? "success" : "warn",
        response.capabilities.aiEnabled ? "AI settings saved and enabled" : "AI settings saved, but AI is still disabled"
      );
    } catch (error) {
      showStatus("error", formatErrorMessage(error, "Failed to save AI settings"));
      throw error;
    }
  }

  async function handleSaveMapSettings(nextSettings: MapSettings) {
    const activeBridge = requireBridge();
    if (!activeBridge) {
      throw new Error("Desktop bridge unavailable");
    }

    try {
      const saved = (await activeBridge.saveMapSettings(nextSettings)) as MapSettings;
      setMapSettings(saved);
      showStatus("success", saved.apiKey ? "Map settings saved" : "Map settings saved, but map rendering is disabled");
    } catch (error) {
      showStatus("error", formatErrorMessage(error, "Failed to save map settings"));
      throw error;
    }
  }

  async function refreshMemories() {
    const activeBridge = requireBridge();
    if (!activeBridge) {
      return;
    }

    const nextMemories = (await activeBridge.listMemories()) as Memory[];
    setMemories(nextMemories);
  }

  async function refreshMemoryCandidates() {
    const activeBridge = requireBridge();
    if (!activeBridge) {
      return;
    }

    const nextCandidates = (await activeBridge.listMemoryCandidates()) as MemoryCandidate[];
    setMemoryCandidates(nextCandidates);
  }

  async function refreshSelectedPhotoMemories() {
    if (!selectedPhotoId) {
      setSelectedPhotoMemories([]);
      return;
    }

    const activeBridge = requireBridge();
    if (!activeBridge) {
      setSelectedPhotoMemories([]);
      return;
    }

    const nextMemories = (await activeBridge.listMemoriesByPhoto(selectedPhotoId)) as Memory[];
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

  async function handleGenerateMemoryCandidates() {
    setIsGeneratingMemoryCandidates(true);
    showStatus("info", "Generating suggested memories...");
    try {
      const nextCandidates = (await window.chronoPic.generateMemoryCandidates(12)) as MemoryCandidate[];
      setMemoryCandidates(nextCandidates);
      showStatus("success", `Generated ${nextCandidates.length} suggested memor${nextCandidates.length === 1 ? "y" : "ies"}`);
    } catch (error) {
      showStatus("error", formatErrorMessage(error, "Failed to generate suggested memories"));
    } finally {
      setIsGeneratingMemoryCandidates(false);
    }
  }

  async function handleAcceptMemoryCandidate(candidateId: string, input?: { name?: string; photoIds?: string[] }) {
    try {
      const accepted = (await window.chronoPic.acceptMemoryCandidate(candidateId, input)) as Memory;
      await refreshMemories();
      await refreshMemoryCandidates();
      showStatus("success", `Created memory: ${accepted.name}`);
    } catch (error) {
      showStatus("error", formatErrorMessage(error, "Failed to accept suggested memory"));
      throw error;
    }
  }

  async function handleRejectMemoryCandidate(candidateId: string) {
    try {
      await window.chronoPic.rejectMemoryCandidate(candidateId);
      setMemoryCandidates((current) => current.filter((candidate) => candidate.id !== candidateId));
      showStatus("success", "Rejected suggested memory");
    } catch (error) {
      showStatus("error", formatErrorMessage(error, "Failed to reject suggested memory"));
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

  async function handleEnrichMemorySemantic(memoryId: string) {
    if (!capabilities.aiEnabled) {
      showStatus("warn", "AI enrichment is not configured");
      return;
    }

    const memoryName = resolveMemoryName(memoryId);
    setIsEnrichingMemorySemantic(true);
    showStatus("info", `Generating AI summary for ${memoryName}...`);

    try {
      const updated = (await window.chronoPic.enrichMemorySemantic(memoryId)) as Memory;
      setMemories((current) => current.map((memory) => (memory.id === updated.id ? updated : memory)));

      if (updated.aiStatus === "failed") {
        showStatus("error", updated.aiError ?? `Failed to generate AI summary for ${updated.name}`);
        return;
      }

      showStatus("success", `Generated AI summary for ${updated.name}`);
    } catch (error) {
      showStatus("error", formatErrorMessage(error, "Failed to generate memory AI summary"));
    } finally {
      setIsEnrichingMemorySemantic(false);
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

  async function handleEnrichSemantic() {
    if (!selectedPhotoId) {
      return;
    }

    setIsEnrichingSemantic(true);
    showStatus("info", "Generating AI metadata...");

    try {
      const updated = (await window.chronoPic.enrichPhotoSemantic(selectedPhotoId)) as PhotoRecord;
      setPhotos((current) => current.map((photo) => (photo.photo.id === updated.photo.id ? updated : photo)));

      if (updated.semantic.aiStatus === "failed") {
        await refreshSemanticQueueStats();
        showStatus("error", updated.semantic.aiError ?? "AI enrichment failed");
        return;
      }

      await refreshSemanticQueueStats();
      showStatus("success", "AI metadata generated");
    } catch (error) {
      showStatus("error", formatErrorMessage(error, "Failed to generate AI metadata"));
    } finally {
      setIsEnrichingSemantic(false);
    }
  }

  async function handleEnrichPendingSemantics(limit = 12) {
    if (!capabilities.aiEnabled) {
      showStatus("warn", "AI enrichment is not configured");
      return;
    }

    setIsBatchEnrichingSemantic(true);
    showStatus("info", "Processing pending AI metadata...");
    void window.chronoPic.debugLog(`renderer:handleEnrichPendingSemantics start limit=${limit}`);

    let summary: {
      processed: number;
      completed: number;
      failed: number;
      skipped: number;
    };

    try {
      summary = (await window.chronoPic.enrichPendingSemantics(limit)) as {
        processed: number;
        completed: number;
        failed: number;
        skipped: number;
      };
      void window.chronoPic.debugLog(
        `renderer:handleEnrichPendingSemantics invoke success processed=${summary.processed} completed=${summary.completed} failed=${summary.failed} skipped=${summary.skipped}`
      );
    } catch (error) {
      void window.chronoPic.debugLog(
        `renderer:handleEnrichPendingSemantics invoke error=${
          error instanceof Error && error.message ? error.message : "unknown"
        }`
      );
      showStatus("error", formatErrorMessage(error, "Failed to process pending AI metadata"));
      setIsBatchEnrichingSemantic(false);
      return;
    }

    try {
      void window.chronoPic.debugLog("renderer:handleEnrichPendingSemantics refresh start");
      await refreshPhotos();
      await refreshSemanticQueueStats();
      void window.chronoPic.debugLog("renderer:handleEnrichPendingSemantics refresh success");
    } catch (error) {
      void window.chronoPic.debugLog(
        `renderer:handleEnrichPendingSemantics refresh error=${
          error instanceof Error && error.message ? error.message : "unknown"
        }`
      );
      showStatus("error", formatErrorMessage(error, "AI queue processed, but library refresh failed"));
      setIsBatchEnrichingSemantic(false);
      return;
    }

    try {
      if (summary.processed === 0) {
        showStatus("warn", "No pending AI items to process");
        return;
      }

      if (summary.failed > 0 || summary.skipped > 0) {
        showStatus(
          "warn",
          `AI queue: completed ${summary.completed}, failed ${summary.failed}, skipped ${summary.skipped}`
        );
        return;
      }

      showStatus("success", `AI queue processed ${summary.completed} photo${summary.completed === 1 ? "" : "s"}`);
    } finally {
      setIsBatchEnrichingSemantic(false);
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
    aiSettings,
    capabilities,
    discoveryQuery,
    draftCaption,
    draftDatetime,
    draftTags,
    filter,
    isBatchEnrichingSemantic,
    isEnrichingSemantic,
    isEnrichingMemorySemantic,
    isGeneratingMemoryCandidates,
    isScanning,
    mappablePhotoCount,
    mapSettings,
    mapViewport,
    memories,
    memoryCandidates,
    openViewer,
    patchDiscoveryQuery,
    patchFilter,
    placeGroups,
    photos,
    selectedPhotoIds,
    selectedPhotoMemories,
    selectedMemory,
    selectedPhoto,
    selectedPhotoId,
    semanticQueueStats,
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
    handleAcceptMemoryCandidate,
    handleCreateMemory,
    handleDeleteMemory,
    handleEnrichMemorySemantic,
    handleEnrichSemantic,
    handleEnrichPendingSemantics,
    handleGenerateMemoryCandidates,
    handleRejectMemoryCandidate,
    handleRemovePhotoFromMemory,
    handleRemoveSelectionFromMemory,
    handleRollback,
    handleSaveAISettings,
    handleSaveMapSettings,
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
