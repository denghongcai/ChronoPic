import type { PhotoRecord } from "@chronopic/domain";

export interface AIClient {
  isEnabled(): boolean;
  analyzePhoto(photo: PhotoRecord): Promise<{
    labels: string[];
    caption: string | null;
    embeddingRef: string | null;
  }>;
}

export class DisabledAIClient implements AIClient {
  isEnabled(): boolean {
    return false;
  }

  async analyzePhoto(): Promise<{
    labels: string[];
    caption: null;
    embeddingRef: null;
  }> {
    return {
      labels: [],
      caption: null,
      embeddingRef: null
    };
  }
}
