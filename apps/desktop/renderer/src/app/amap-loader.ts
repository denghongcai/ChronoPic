type ImportMetaEnvRecord = ImportMeta & {
  env?: Record<string, string | undefined>;
};

interface AMapMarker {
  on: (event: string, handler: () => void) => void;
  setMap: (map: AMapMap | null) => void;
}

interface AMapLngLat {
  getLat: () => number;
  getLng: () => number;
}

interface AMapBounds {
  getNorthEast: () => AMapLngLat;
  getSouthWest: () => AMapLngLat;
}

interface AMapMap {
  add: (overlays: AMapMarker[]) => void;
  destroy: () => void;
  getBounds: () => AMapBounds;
  getCenter?: () => AMapLngLat;
  getZoom?: () => number;
  on: (event: string, handler: () => void) => void;
  remove: (overlays: AMapMarker[]) => void;
  setFitView: (overlays?: AMapMarker[]) => void;
  setZoomAndCenter?: (zoom: number, center: [number, number]) => void;
}

export interface AMapNamespace {
  Map: new (
    container: HTMLElement,
    options: {
      center?: [number, number];
      mapStyle?: string;
      resizeEnable?: boolean;
      viewMode?: "2D" | "3D";
      zoom?: number;
      zooms?: [number, number];
    }
  ) => AMapMap;
  Marker: new (options: { content?: HTMLElement; position: [number, number]; title?: string }) => AMapMarker;
}

declare global {
  interface Window {
    AMap?: AMapNamespace;
  }
}

let amapPromise: Promise<AMapNamespace> | null = null;

function resolveAmapApiKey(): string | null {
  const env = (import.meta as ImportMetaEnvRecord).env ?? {};
  return env.VITE_AMAP_API_KEY ?? null;
}

export function getAmapApiKey(): string | null {
  return resolveAmapApiKey();
}

export async function loadAmap(): Promise<AMapNamespace> {
  if (window.AMap) {
    return window.AMap;
  }

  if (amapPromise) {
    return amapPromise;
  }

  const apiKey = resolveAmapApiKey();
  if (!apiKey) {
    throw new Error("Missing VITE_AMAP_API_KEY");
  }

  amapPromise = new Promise<AMapNamespace>((resolve, reject) => {
    const existing = document.querySelector<HTMLScriptElement>('script[data-chronopic-amap="true"]');
    if (existing) {
      existing.addEventListener("load", () => {
        if (window.AMap) {
          resolve(window.AMap);
        } else {
          reject(new Error("AMap loaded but window.AMap is unavailable"));
        }
      });
      existing.addEventListener("error", () => reject(new Error("Failed to load AMap script")));
      return;
    }

    const script = document.createElement("script");
    script.async = true;
    script.dataset.chronopicAmap = "true";
    script.src = `https://webapi.amap.com/maps?v=2.0&key=${encodeURIComponent(apiKey)}`;
    script.addEventListener("load", () => {
      if (window.AMap) {
        resolve(window.AMap);
      } else {
        reject(new Error("AMap loaded but window.AMap is unavailable"));
      }
    });
    script.addEventListener("error", () => reject(new Error("Failed to load AMap script")));
    document.head.appendChild(script);
  });

  return amapPromise;
}
