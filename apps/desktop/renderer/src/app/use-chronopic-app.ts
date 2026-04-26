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
  LocaleSettings,
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
import { createTranslator, defaultLocaleSettings, resolveAIOutputLocale } from "@chronopic/i18n";

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
  const [localeSettings, setLocaleSettings] = useState<LocaleSettings>(defaultLocaleSettings);
  const t = useMemo(() => createTranslator(localeSettings.locale), [localeSettings.locale]);
  const idleStatus = useMemo<AppStatus>(() => ({ kind: "idle", message: t("status.idle") }), [t]);
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
    return memories.find((memory) => memory.id === memoryId)?.name ?? t("sidebar.memories");
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
        message: t("status.bridgeUnavailable"),
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

    const [response, currentAISettings, currentMapSettings, currentLocaleSettings] = await Promise.all([
      activeBridge.initialize(),
      activeBridge.getAISettings(),
      activeBridge.getMapSettings(),
      activeBridge.getLocaleSettings(),
    ]);
    setSnapshot(response.snapshot);
    setCapabilities(response.capabilities);
    setAISettings(currentAISettings as AISettings);
    setMapSettings(currentMapSettings as MapSettings);
    setLocaleSettings(currentLocaleSettings as LocaleSettings);
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
      showStatus("success", t("status.addedLibrary", { path: libraryPath }));
    } catch (error) {
      showStatus("error", formatErrorMessage(error, t("status.failedAddLibrary")));
    }
  }

  async function handleScanAll() {
    const activeBridge = requireBridge();
    if (!activeBridge) {
      return;
    }

    setIsScanning(true);
    showStatus("info", t("status.scanningLibraries"));

    try {
      await activeBridge.scanLibrary();
      await refreshSnapshot();
      await refreshPhotos();
      await refreshMemories();
      await refreshGeospatial();
      await refreshTimeline();
      await refreshSemanticQueueStats();
      const nextCandidates = (await activeBridge.generateMemoryCandidates(12)) as MemoryCandidate[];
      setMemoryCandidates(nextCandidates);
      showStatus(
        "success",
        nextCandidates.length > 0
          ? t("status.scanCompleteWithSuggestions", { count: nextCandidates.length })
          : t("status.scanCompleteNoSuggestions")
      );
    } catch (error) {
      showStatus("error", formatErrorMessage(error, t("status.scanFailed")));
    } finally {
      setIsScanning(false);
    }
  }

  async function handleSaveAISettings(nextSettings: AISettings) {
    const activeBridge = requireBridge();
    if (!activeBridge) {
      throw new Error(t("status.bridgeUnavailable"));
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
        response.capabilities.aiEnabled ? t("status.aiSettingsEnabled") : t("status.aiSettingsDisabled")
      );
    } catch (error) {
      showStatus("error", formatErrorMessage(error, t("status.failedSaveAiSettings")));
      throw error;
    }
  }

  async function handleSaveMapSettings(nextSettings: MapSettings) {
    const activeBridge = requireBridge();
    if (!activeBridge) {
      throw new Error(t("status.bridgeUnavailable"));
    }

    try {
      const saved = (await activeBridge.saveMapSettings(nextSettings)) as MapSettings;
      setMapSettings(saved);
      showStatus("success", saved.apiKey ? t("status.mapSettingsSaved") : t("status.mapSettingsSavedDisabled"));
    } catch (error) {
      showStatus("error", formatErrorMessage(error, t("status.failedSaveMapSettings")));
      throw error;
    }
  }

  async function handleSaveLocaleSettings(nextSettings: LocaleSettings) {
    const activeBridge = requireBridge();
    if (!activeBridge) {
      return;
    }

    try {
      const saved = (await activeBridge.saveLocaleSettings(nextSettings)) as LocaleSettings;
      setLocaleSettings(saved);
      showStatus("success", t("status.languageSettingsSaved"));
    } catch (error) {
      showStatus("error", formatErrorMessage(error, t("status.failedSaveLanguageSettings")));
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
      showStatus("success", t("status.createdMemory", { name }));
    } catch (error) {
      showStatus("error", formatErrorMessage(error, t("status.failedCreateMemory")));
      throw error;
    }
  }

  async function handleGenerateMemoryCandidates() {
    setIsGeneratingMemoryCandidates(true);
    showStatus("info", t("status.generatingSuggestedMemories"));
    try {
      const nextCandidates = (await window.chronoPic.generateMemoryCandidates(12)) as MemoryCandidate[];
      setMemoryCandidates(nextCandidates);
      showStatus("success", t("status.generatedSuggestedMemories", { count: nextCandidates.length }));
    } catch (error) {
      showStatus("error", formatErrorMessage(error, t("status.failedGenerateSuggestedMemories")));
    } finally {
      setIsGeneratingMemoryCandidates(false);
    }
  }

  async function handleAcceptMemoryCandidate(candidateId: string, input?: { name?: string; photoIds?: string[] }) {
    try {
      const accepted = (await window.chronoPic.acceptMemoryCandidate(candidateId, input)) as Memory;
      await refreshMemories();
      await refreshMemoryCandidates();
      showStatus("success", t("status.createdMemory", { name: accepted.name }));
    } catch (error) {
      showStatus("error", formatErrorMessage(error, t("status.failedAcceptSuggestedMemory")));
      throw error;
    }
  }

  async function handleRejectMemoryCandidate(candidateId: string) {
    try {
      await window.chronoPic.rejectMemoryCandidate(candidateId);
      setMemoryCandidates((current) => current.filter((candidate) => candidate.id !== candidateId));
      showStatus("success", t("status.rejectedSuggestedMemory"));
    } catch (error) {
      showStatus("error", formatErrorMessage(error, t("status.failedRejectSuggestedMemory")));
      throw error;
    }
  }

  async function handleDeleteMemory(memoryId: string) {
    const memoryName = resolveMemoryName(memoryId);
    try {
      await window.chronoPic.deleteMemory(memoryId);
      setMemories((current) => current.filter((m) => m.id !== memoryId));
      showStatus("success", t("status.deletedMemory", { name: memoryName }));
    } catch (error) {
      showStatus("error", formatErrorMessage(error, t("status.failedDeleteMemory")));
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
        showStatus("success", t("status.renamedMemory", { name: updated.name }));
      } else if (Object.prototype.hasOwnProperty.call(updates, "description")) {
        showStatus("success", t("status.savedDescription", { name: updated.name }));
      } else if (Object.prototype.hasOwnProperty.call(updates, "coverPhotoId")) {
        showStatus("success", t("status.updatedCover", { name: updated.name }));
      } else {
        showStatus("success", t("status.updatedMemory", { name: updated.name }));
      }

      return updated;
    } catch (error) {
      showStatus("error", formatErrorMessage(error, t("status.failedUpdateMemory")));
      throw error;
    }
  }

  async function handleEnrichMemorySemantic(memoryId: string, context?: { name?: string | null; description?: string | null }) {
    if (!capabilities.aiEnabled) {
      showStatus("warn", t("status.aiNotConfigured"));
      return;
    }

    const memoryName = resolveMemoryName(memoryId);
    setIsEnrichingMemorySemantic(true);
    showStatus("info", t("status.generatingAiSummary", { name: memoryName }));

    try {
      const updated = (await window.chronoPic.enrichMemorySemantic(memoryId, {
        ...context,
        outputLocale: resolveAIOutputLocale(localeSettings),
      })) as Memory;
      setMemories((current) => current.map((memory) => (memory.id === updated.id ? updated : memory)));

      if (updated.aiStatus === "failed") {
        showStatus("error", updated.aiError ?? t("status.failedAiSummaryFor", { name: updated.name }));
        return;
      }

      showStatus("success", t("status.generatedAiSummary", { name: updated.name }));
    } catch (error) {
      showStatus("error", formatErrorMessage(error, t("status.failedMemoryAiSummary")));
    } finally {
      setIsEnrichingMemorySemantic(false);
    }
  }

  async function handleAddPhotoToMemory(memoryId: string, photoId: string) {
    const memoryName = resolveMemoryName(memoryId);
    try {
      const memberships = (await window.chronoPic.listMemoriesByPhoto(photoId)) as Memory[];
      if (memberships.some((memory) => memory.id === memoryId)) {
        showStatus("warn", t("status.photoAlreadyInMemory", { name: memoryName }));
        return;
      }

      await window.chronoPic.addPhotoToMemory(memoryId, photoId);
      await refreshMemories();
      if (filter.memoryId === memoryId) {
        await refreshPhotos();
      }
      showStatus("success", t("status.addedPhotoToMemory", { name: memoryName }));
    } catch (error) {
      showStatus("error", formatErrorMessage(error, t("status.failedAddPhotoToMemory")));
    }
  }

  async function handleAddSelectionToMemory(memoryId: string, photoIds: string[]) {
    const uniquePhotoIds = Array.from(new Set(photoIds));
    if (uniquePhotoIds.length === 0) {
      showStatus("warn", t("status.selectAtLeastOne"));
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
      segments.push(t("status.addedShort", { count: addedCount }));
    }
    if (alreadyPresentCount > 0) {
      segments.push(t("status.alreadyThereShort", { count: alreadyPresentCount }));
    }
    if (failedCount > 0) {
      segments.push(t("status.failedShort", { count: failedCount }));
    }

    if (addedCount === 0 && alreadyPresentCount > 0 && failedCount === 0) {
      showStatus("warn", t("status.noChangesAlreadyThere", { name: memoryName, count: alreadyPresentCount }));
      return;
    }

    if (failedCount > 0 || alreadyPresentCount > 0) {
      showStatus("warn", t("status.memoryBatchSummary", { name: memoryName, summary: segments.join(", ") }));
      return;
    }

    showStatus("success", t("status.addedPhotosToMemory", { count: addedCount, name: memoryName }));
  }

  async function handleRemoveSelectionFromMemory(memoryId: string, photoIds: string[]) {
    const uniquePhotoIds = Array.from(new Set(photoIds));
    if (uniquePhotoIds.length === 0) {
      showStatus("warn", t("status.selectAtLeastOne"));
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
      segments.push(t("status.removedShort", { count: removedCount }));
    }
    if (missingCount > 0) {
      segments.push(t("status.alreadyAbsentShort", { count: missingCount }));
    }
    if (failedCount > 0) {
      segments.push(t("status.failedShort", { count: failedCount }));
    }

    if (removedCount === 0 && missingCount > 0 && failedCount === 0) {
      showStatus("warn", t("status.noChangesAlreadyAbsent", { name: memoryName, count: missingCount }));
      return;
    }

    if (failedCount > 0 || missingCount > 0) {
      showStatus("warn", t("status.memoryBatchSummary", { name: memoryName, summary: segments.join(", ") }));
      return;
    }

    showStatus("success", t("status.removedPhotosFromMemory", { count: removedCount, name: memoryName }));
  }

  async function handleRemovePhotoFromMemory(memoryId: string, photoId: string) {
    const memoryName = resolveMemoryName(memoryId);
    try {
      const memberships = (await window.chronoPic.listMemoriesByPhoto(photoId)) as Memory[];
      if (!memberships.some((memory) => memory.id === memoryId)) {
        showStatus("warn", t("status.photoNoLongerInMemory", { name: memoryName }));
        return;
      }

      await window.chronoPic.removePhotoFromMemory(memoryId, photoId);
      await refreshMemories();
      if (filter.memoryId === memoryId) {
        await refreshPhotos();
      }
      showStatus("success", t("status.removedPhotoFromMemory", { name: memoryName }));
    } catch (error) {
      showStatus("error", formatErrorMessage(error, t("status.failedRemovePhotoFromMemory")));
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
      showStatus("success", t("status.tagsUpdated"));
    } catch (error) {
      showStatus("error", formatErrorMessage(error, t("status.failedUpdateTags")));
    }
  }

  async function handleSaveCaption() {
    if (!selectedPhotoId) {
      return;
    }

    try {
      const updated = (await window.chronoPic.updatePhotoCaption(selectedPhotoId, draftCaption || null)) as PhotoRecord;
      setPhotos((current) => current.map((photo) => (photo.photo.id === updated.photo.id ? updated : photo)));
      showStatus("success", t("status.captionUpdated"));
    } catch (error) {
      showStatus("error", formatErrorMessage(error, t("status.failedUpdateCaption")));
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
      showStatus("success", t("status.datetimeUpdated"));
    } catch (error) {
      showStatus("error", formatErrorMessage(error, t("status.failedUpdateDatetime")));
    }
  }

  async function handleEnrichSemantic() {
    if (!selectedPhotoId) {
      return;
    }

    setIsEnrichingSemantic(true);
    showStatus("info", t("status.generatingAiMetadata"));

    try {
      const updated = (await window.chronoPic.enrichPhotoSemantic(selectedPhotoId, {
        outputLocale: resolveAIOutputLocale(localeSettings),
      })) as PhotoRecord;
      setPhotos((current) => current.map((photo) => (photo.photo.id === updated.photo.id ? updated : photo)));

      if (updated.semantic.aiStatus === "failed") {
        await refreshSemanticQueueStats();
        showStatus("error", updated.semantic.aiError ?? t("status.aiEnrichmentFailed"));
        return;
      }

      await refreshSemanticQueueStats();
      showStatus("success", t("status.aiMetadataGenerated"));
    } catch (error) {
      showStatus("error", formatErrorMessage(error, t("status.failedGenerateAiMetadata")));
    } finally {
      setIsEnrichingSemantic(false);
    }
  }

  async function handleEnrichPendingSemantics(limit = 12) {
    if (!capabilities.aiEnabled) {
      showStatus("warn", t("status.aiNotConfigured"));
      return;
    }

    setIsBatchEnrichingSemantic(true);
    showStatus("info", t("status.processingPendingAi"));
    void window.chronoPic.debugLog(`renderer:handleEnrichPendingSemantics start limit=${limit}`);

    let summary: {
      processed: number;
      completed: number;
      failed: number;
      skipped: number;
    };

    try {
      summary = (await window.chronoPic.enrichPendingSemantics(limit, {
        outputLocale: resolveAIOutputLocale(localeSettings),
      })) as {
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
      showStatus("error", formatErrorMessage(error, t("status.failedProcessPendingAi")));
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
      showStatus("error", formatErrorMessage(error, t("status.aiQueueRefreshFailed")));
      setIsBatchEnrichingSemantic(false);
      return;
    }

    try {
      if (summary.processed === 0) {
        showStatus("warn", t("status.noPendingAi"));
        return;
      }

      if (summary.failed > 0 || summary.skipped > 0) {
        showStatus(
          "warn",
          t("status.aiQueueFailuresDetailed", {
            completed: summary.completed,
            failed: summary.failed,
            skipped: summary.skipped,
          })
        );
        return;
      }

      showStatus("success", t("status.aiQueueProcessed", { count: summary.completed }));
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
      showStatus("warn", t("status.noEditToRollback"));
      return;
    }

    setPhotos((current) => current.map((photo) => (photo.photo.id === updated.photo.id ? updated : photo)));
    showStatus("success", t("status.rolledBackLatest"));
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
    localeSettings,
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
    handleSaveLocaleSettings,
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
