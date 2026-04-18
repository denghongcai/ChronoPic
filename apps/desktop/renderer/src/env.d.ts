import type { ChronoPicBridge } from "../../preload/bridge.js";

declare global {
  interface Window {
    chronoPic: ChronoPicBridge;
  }
}

export {};
