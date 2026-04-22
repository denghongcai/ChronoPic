import { MapPinned } from "lucide-react";
import { useEffect, useMemo, useRef, useState } from "react";

import type { GeoBounds, MapSettings, Memory, PhotoFilter, PlaceGroup, PhotoRecord } from "@chronopic/domain";
import { Badge, Button, Panel, formatTimestamp, getDiscoveryContext, getDiscoveryMatchSummary, thumbnailUrl } from "@chronopic/ui-components";

import { getAmapApiKey, loadAmap, type AMapNamespace } from "./amap-loader";

export interface MapBrowseSurfaceProps {
  activeMemoryName?: string | null;
  filter: PhotoFilter;
  mapSettings: MapSettings;
  mapViewport: { centerLat: number; centerLng: number; zoom: number } | null;
  mappablePhotoCount: number;
  onOpenDetail: (photoId: string) => void;
  onSelectPhoto: (photoId: string) => void;
  onViewportChange: (viewport: { centerLat: number; centerLng: number; zoom: number }) => void;
  photos: PhotoRecord[];
  placeGroups: PlaceGroup[];
  selectedPhotoMemories: Memory[];
  selectedPhotoId: string | null;
}

export function MapBrowseSurface({
  activeMemoryName,
  filter,
  mapSettings,
  mapViewport,
  mappablePhotoCount,
  onOpenDetail,
  onSelectPhoto,
  onViewportChange,
  photos,
  placeGroups,
  selectedPhotoMemories,
  selectedPhotoId,
}: MapBrowseSurfaceProps) {
  const mapContainerRef = useRef<HTMLDivElement | null>(null);
  const mapRef = useRef<InstanceType<AMapNamespace["Map"]> | null>(null);
  const markersRef = useRef<InstanceType<AMapNamespace["Marker"]>[]>([]);
  const placeCardRefs = useRef(new Map<string, HTMLButtonElement>());
  const [activePlaceGroups, setActivePlaceGroups] = useState<PlaceGroup[]>(placeGroups);
  const [mapError, setMapError] = useState<string | null>(null);
  const [mapReady, setMapReady] = useState(false);
  const hasApiKey = Boolean(getAmapApiKey(mapSettings));

  const representativePhotos = useMemo(() => {
    const byId = new Map(photos.map((photo) => [photo.photo.id, photo]));
    return new Map(activePlaceGroups.map((group) => [group.id, group.representativePhotoId ? byId.get(group.representativePhotoId) ?? null : null]));
  }, [activePlaceGroups, photos]);
  const selectedPhoto = useMemo(
    () => photos.find((record) => record.photo.id === selectedPhotoId) ?? null,
    [photos, selectedPhotoId]
  );
  const discoveryContext = useMemo(
    () => getDiscoveryContext(filter, { activeMemoryName: activeMemoryName ?? null }),
    [activeMemoryName, filter]
  );
  const selectedPhotoMatch = useMemo(
    () => getDiscoveryMatchSummary(selectedPhoto, selectedPhotoMemories, filter.query),
    [filter.query, selectedPhoto, selectedPhotoMemories]
  );

  const selectedGroupId = useMemo(
    () => activePlaceGroups.find((group) => group.representativePhotoId === selectedPhotoId)?.id ?? null,
    [activePlaceGroups, selectedPhotoId]
  );

  useEffect(() => {
    setActivePlaceGroups(placeGroups);
  }, [placeGroups]);

  async function refreshViewportGroups(bounds?: GeoBounds) {
    const nextPlaceGroups = (await window.chronoPic.listPlaceGroups({
      filter,
      limit: 200,
      precision: 2,
      ...(bounds ? { bounds } : {}),
    })) as PlaceGroup[];
    setActivePlaceGroups(nextPlaceGroups);
  }

  useEffect(() => {
    if (!mapContainerRef.current || !hasApiKey || mappablePhotoCount === 0) {
      return;
    }

    let disposed = false;

    void loadAmap(mapSettings)
      .then((AMap) => {
        if (disposed || !mapContainerRef.current) {
          return;
        }

        mapRef.current = new AMap.Map(mapContainerRef.current, {
          center: mapViewport
            ? [mapViewport.centerLng, mapViewport.centerLat]
            : placeGroups[0]
              ? [placeGroups[0].centerLng, placeGroups[0].centerLat]
              : [116.397428, 39.90923],
          mapStyle: "amap://styles/whitesmoke",
          resizeEnable: true,
          viewMode: "2D",
          zoom: mapViewport?.zoom ?? (placeGroups[0] ? 5 : 4),
          zooms: [3, 18],
        });
        setMapReady(true);
        void refreshViewportGroups();
      })
      .catch((error: unknown) => {
        if (!disposed) {
          setMapError(error instanceof Error ? error.message : "Failed to initialize AMap");
        }
      });

    return () => {
      disposed = true;
      markersRef.current.forEach((marker) => marker.setMap(null));
      markersRef.current = [];
      mapRef.current?.destroy();
      mapRef.current = null;
      setMapReady(false);
    };
  }, [hasApiKey, mapSettings, mapViewport, mappablePhotoCount, placeGroups]);

  useEffect(() => {
    if (!mapRef.current || !mapReady) {
      return;
    }

    const handleViewportChange = () => {
      const bounds = mapRef.current?.getBounds();
      if (!bounds) {
        return;
      }
      const center = mapRef.current?.getCenter?.();
      const zoom = mapRef.current?.getZoom?.();
      if (center && typeof zoom === "number") {
        onViewportChange({
          centerLat: center.getLat(),
          centerLng: center.getLng(),
          zoom,
        });
      }

      const northEast = bounds.getNorthEast();
      const southWest = bounds.getSouthWest();
      void refreshViewportGroups({
        east: northEast.getLng(),
        north: northEast.getLat(),
        south: southWest.getLat(),
        west: southWest.getLng(),
      });
    };

    mapRef.current.on("moveend", handleViewportChange);
    mapRef.current.on("zoomend", handleViewportChange);
  }, [filter, mapReady, onViewportChange]);

  useEffect(() => {
    if (!mapRef.current || !mapReady) {
      return;
    }

    void loadAmap(mapSettings).then((AMap) => {
      markersRef.current.forEach((marker) => marker.setMap(null));
      markersRef.current = [];

      const markers = activePlaceGroups.map((group) => {
        const markerChip = document.createElement("div");
        markerChip.className =
          `flex min-w-10 items-center justify-center rounded-full border px-3 py-1 text-xs font-semibold text-white shadow-lg ${
            group.id === selectedGroupId
              ? "border-sky-300 bg-sky-600"
              : "border-amber-300 bg-amber-500"
          }`;
        markerChip.textContent = String(group.photoCount);

        const marker = new AMap.Marker({
          content: markerChip,
          position: [group.centerLng, group.centerLat],
          title: `${group.photoCount} photos`,
        });

        marker.on("click", () => {
          if (group.representativePhotoId) {
            onSelectPhoto(group.representativePhotoId);
          }
        });

        return marker;
      });

      markersRef.current = markers;
      mapRef.current?.add(markers);
      if (markers.length > 0 && !selectedGroupId && !mapViewport) {
        mapRef.current?.setFitView(markers);
      }
    });
  }, [activePlaceGroups, mapReady, mapSettings, mapViewport, onSelectPhoto, selectedGroupId]);

  useEffect(() => {
    if (!selectedGroupId) {
      return;
    }

    const target = placeCardRefs.current.get(selectedGroupId);
    target?.scrollIntoView({ block: "nearest", behavior: "smooth" });
  }, [selectedGroupId]);

  useEffect(() => {
    if (!mapReady || !mapRef.current || !selectedGroupId) {
      return;
    }

    const group = activePlaceGroups.find((item) => item.id === selectedGroupId);
    if (!group || !mapRef.current.setZoomAndCenter) {
      return;
    }

    const currentCenter = mapRef.current.getCenter?.();
    const currentZoom = mapRef.current.getZoom?.();
    if (
      currentCenter &&
      typeof currentZoom === "number" &&
      Math.abs(currentCenter.getLat() - group.centerLat) < 0.01 &&
      Math.abs(currentCenter.getLng() - group.centerLng) < 0.01
    ) {
      return;
    }

    mapRef.current.setZoomAndCenter(currentZoom ?? 8, [group.centerLng, group.centerLat]);
  }, [activePlaceGroups, mapReady, selectedGroupId]);

  if (!hasApiKey) {
    return (
      <MapStatePanel
        description="Save an AMap API key in Library Settings to enable Gaode map rendering for browse mode."
        title="Map view is missing an API key"
        tone="warn"
      />
    );
  }

  if (mappablePhotoCount === 0) {
    return (
      <MapStatePanel
        description="The current browse scope has no GPS-bearing photos yet. Add media with coordinates or loosen the current filter to enable geographic exploration."
        title="No mappable photos in the current scope"
        tone="info"
      />
    );
  }

  if (mapError) {
    return <MapStatePanel description={mapError} title="Map view failed to initialize" tone="danger" />;
  }

  return (
    <Panel className="select-none overflow-hidden">
      <div className="flex items-end justify-between gap-4 border-b border-stone-200/70 px-5 py-4">
        <div className="space-y-1">
          <p className="text-[11px] font-semibold uppercase tracking-[0.22em] text-stone-400">Map View</p>
          <p className="text-sm text-stone-500">
            Pan or zoom to refresh place buckets. Markers, place cards, and the shared viewer all stay in the same selection flow.
          </p>
        </div>
        <div className="flex items-center gap-2">
          <Badge tone="info">{mappablePhotoCount} GPS photos</Badge>
          <Badge tone="neutral">{activePlaceGroups.length} viewport groups</Badge>
        </div>
      </div>
      <div className="grid gap-0 xl:grid-cols-[minmax(0,1.4fr)_420px]">
        <div className="min-h-[560px] border-b border-stone-200/70 xl:border-b-0 xl:border-r xl:border-stone-200/70">
          <div className="flex h-full min-h-[560px] flex-col">
            {discoveryContext ? (
              <div className="border-b border-stone-200/70 px-5 py-4">
                <div className="space-y-3 rounded-[24px] border border-stone-200 bg-stone-50/80 px-4 py-3">
                  <div className="flex flex-wrap items-center gap-2">
                    <Badge tone="info">Discovery Scope</Badge>
                    {discoveryContext.badges.map((badge) => (
                      <Badge key={badge.label} tone={badge.tone}>
                        {badge.label}
                      </Badge>
                    ))}
                  </div>
                  <p className="text-sm text-stone-700">{discoveryContext.description}</p>
                </div>
              </div>
            ) : null}
            <div className="h-full min-h-[420px] w-full bg-stone-100" ref={mapContainerRef} />
          </div>
        </div>
        <div className="max-h-[560px] overflow-auto p-4">
          <div className="space-y-3">
            {selectedPhoto ? (
              <div className="rounded-[24px] border border-sky-200 bg-sky-50/80 px-4 py-3">
                <div className="flex flex-wrap items-center gap-2">
                  <Badge tone="info">Selected Photo</Badge>
                  <p className="text-sm text-sky-900">
                    {selectedPhoto.photo.path.split("/").at(-1) ?? "Selected photo"} is the current geographic focus.
                  </p>
                  <Button
                    onClick={() => onOpenDetail(selectedPhoto.photo.id)}
                    size="sm"
                    variant="outline"
                  >
                    Open Detail
                  </Button>
                </div>
                {selectedPhotoMemories.length > 0 ? (
                  <div className="mt-3 flex flex-wrap items-center gap-2">
                    <p className="text-xs font-medium uppercase tracking-[0.18em] text-sky-700">Memories</p>
                    {selectedPhotoMemories.map((memory) => (
                      <Badge key={memory.id} tone={memory.coverPhotoId === selectedPhoto.photo.id ? "info" : "neutral"}>
                        {memory.name}
                        {memory.coverPhotoId === selectedPhoto.photo.id ? " cover" : ""}
                      </Badge>
                    ))}
                  </div>
                ) : null}
                {selectedPhotoMatch ? (
                  <p className="mt-3 text-sm text-sky-900">{selectedPhotoMatch.description}</p>
                ) : null}
              </div>
            ) : null}
            {activePlaceGroups.map((group) => {
              const representative = representativePhotos.get(group.id) ?? null;
              const isSelected = representative?.photo.id === selectedPhotoId;
              const representativeThumbnailPath = representative?.photo.thumbnailPath ?? undefined;

              return (
                <button
                  className={`w-full rounded-[24px] border p-3 text-left shadow-sm transition ${
                    isSelected ? "border-amber-400 bg-amber-50 ring-2 ring-amber-200" : "border-stone-200 bg-white hover:border-stone-300"
                  }`}
                  key={group.id}
                  ref={(node) => {
                    if (node) {
                      placeCardRefs.current.set(group.id, node);
                      return;
                    }

                    placeCardRefs.current.delete(group.id);
                  }}
                  onClick={() => representative?.photo.id && onSelectPhoto(representative.photo.id)}
                  type="button"
                >
                  <div className="flex gap-3">
                    <div className="h-20 w-24 shrink-0 overflow-hidden rounded-2xl bg-stone-100">
                      {representativeThumbnailPath ? (
                        <img
                          alt=""
                          className="h-full w-full object-cover"
                          src={thumbnailUrl(representativeThumbnailPath) ?? undefined}
                        />
                      ) : (
                        <div className="grid h-full place-items-center text-stone-400">
                          <MapPinned className="h-5 w-5" />
                        </div>
                      )}
                    </div>
                    <div className="min-w-0 flex-1">
                      <div className="flex flex-wrap items-center gap-2">
                        <Badge tone="info">{group.photoCount} photos</Badge>
                        <Badge tone="neutral">
                          {group.centerLat.toFixed(2)}, {group.centerLng.toFixed(2)}
                        </Badge>
                      </div>
                      <p className="mt-2 text-sm font-semibold text-stone-950">
                        {representative?.photo.path.split("/").at(-1) ?? "Representative photo"}
                      </p>
                      <p className="mt-1 text-xs text-stone-500">
                        {group.toDatetime != null ? `Latest capture ${formatTimestamp(group.toDatetime)}` : "No capture time available"}
                      </p>
                      {representative?.photo.id ? (
                        <div className="mt-3">
                          <Button
                            asChild
                            onClick={(event) => {
                              event.stopPropagation();
                              onOpenDetail(representative.photo.id);
                            }}
                            size="sm"
                            variant="outline"
                          >
                            <span>Open Photo</span>
                          </Button>
                        </div>
                      ) : null}
                    </div>
                  </div>
                </button>
              );
            })}
          </div>
        </div>
      </div>
    </Panel>
  );
}

function MapStatePanel({
  description,
  title,
  tone,
}: {
  description: string;
  title: string;
  tone: "danger" | "info" | "warn";
}) {
  return (
    <Panel className="overflow-hidden">
      <div className="grid min-h-[420px] place-items-center px-6 py-8 text-center">
        <div className="max-w-xl space-y-3">
          <Badge tone={tone}>{tone === "danger" ? "Map Error" : tone === "warn" ? "Map Setup" : "Map Empty"}</Badge>
          <h2 className="font-['Space_Grotesk','IBM_Plex_Sans',sans-serif] text-2xl font-semibold tracking-tight text-stone-950">
            {title}
          </h2>
          <p className="text-sm leading-6 text-stone-500">{description}</p>
        </div>
      </div>
    </Panel>
  );
}
