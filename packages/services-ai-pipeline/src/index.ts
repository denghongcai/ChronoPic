import fs from "node:fs/promises";
import path from "node:path";

import { streamText } from "ai";
import { createOpenAICompatible } from "@ai-sdk/openai-compatible";

import type { Memory, PhotoRecord } from "@chronopic/domain";
import { extractJsonObject, normalizeLabels, normalizeText } from "./internal.js";

export interface AIAnalysis {
  generatedLabels: string[];
  generatedCaption: string | null;
  summary: string | null;
  embeddingRef: string | null;
  aiProvider: string | null;
  aiModel: string | null;
  aiProcessedAt: number | null;
  aiError: string | null;
}

export interface MemoryAIAnalysis {
  generatedName: string | null;
  generatedDescription: string | null;
  generatedLabels: string[];
  aiProvider: string | null;
  aiModel: string | null;
  aiProcessedAt: number | null;
  aiError: string | null;
}

export interface AIClient {
  isEnabled(): boolean;
  analyzePhoto(photo: PhotoRecord): Promise<AIAnalysis>;
  analyzeMemory(memory: Memory, photos: PhotoRecord[]): Promise<MemoryAIAnalysis>;
}

export interface VercelCompatibleAIClientOptions {
  apiKey: string;
  baseURL: string;
  model: string;
  providerName?: string;
}

interface FileInput {
  data: Uint8Array;
  mediaType: string;
}

async function resolvePhotoInput(photo: PhotoRecord): Promise<FileInput | null> {
  const preferredPath =
    photo.photo.thumbnailPath && path.isAbsolute(photo.photo.thumbnailPath)
      ? photo.photo.thumbnailPath
      : photo.photo.mime.startsWith("image/")
        ? photo.photo.path
        : null;

  if (!preferredPath) {
    return null;
  }

  try {
    const data = await fs.readFile(preferredPath);
    const mediaType = preferredPath === photo.photo.path ? photo.photo.mime : "image/jpeg";
    return { data, mediaType };
  } catch {
    return null;
  }
}

function buildAnalysisPrompt(photo: PhotoRecord): string {
  const datetime = photo.metadata.datetime ? new Date(photo.metadata.datetime).toISOString() : "unknown";
  const gps =
    photo.metadata.lat != null && photo.metadata.lng != null
      ? `${photo.metadata.lat}, ${photo.metadata.lng}`
      : "unknown";

  return [
    "You are enriching a personal photo library for desktop browsing and search.",
    "Analyze the provided image and return strict JSON only.",
    "JSON shape:",
    '{ "caption": string | null, "summary": string | null, "labels": string[] }',
    "Rules:",
    "- caption: short natural title for the image, max 12 words.",
    "- summary: 1 concise sentence describing the scene, useful for semantic browsing.",
    "- labels: 3 to 8 lowercase tags, concise nouns/adjectives only, no duplicates.",
    "- Do not include reasoning, think tags, markdown explanation, or any text outside the JSON object.",
    "- Use the visual content as the primary source of truth.",
    "- If the image is ambiguous, stay conservative.",
    `Known metadata: mime=${photo.photo.mime}; datetime=${datetime}; gps=${gps}; path=${path.basename(photo.photo.path)}.`,
  ].join("\n");
}

export class DisabledAIClient implements AIClient {
  isEnabled(): boolean {
    return false;
  }

  async analyzePhoto(): Promise<AIAnalysis> {
    return {
      generatedLabels: [],
      generatedCaption: null,
      summary: null,
      embeddingRef: null,
      aiProvider: null,
      aiModel: null,
      aiProcessedAt: null,
      aiError: null,
    };
  }

  async analyzeMemory(): Promise<MemoryAIAnalysis> {
    return {
      generatedName: null,
      generatedDescription: null,
      generatedLabels: [],
      aiProvider: null,
      aiModel: null,
      aiProcessedAt: null,
      aiError: null,
    };
  }
}

function buildMemoryAnalysisPrompt(memory: Memory, photos: PhotoRecord[]): string {
  const sampleLines = photos.slice(0, 12).map((photo, index) => {
    const date = photo.metadata.datetime ? new Date(photo.metadata.datetime).toISOString().slice(0, 10) : "unknown-date";
    const gps = photo.metadata.lat != null && photo.metadata.lng != null ? `${photo.metadata.lat},${photo.metadata.lng}` : "unknown-gps";
    const caption = photo.semantic.generatedCaption ?? photo.semantic.caption ?? path.basename(photo.photo.path);
    const summary = photo.semantic.summary ?? "no-summary";
    const labels = [...photo.semantic.labels, ...photo.semantic.generatedLabels].slice(0, 6).join(", ") || "no-tags";
    return `${index + 1}. date=${date}; gps=${gps}; caption=${caption}; summary=${summary}; labels=${labels}`;
  });

  return [
    "You are generating metadata for a photo memory inside a local-first desktop library.",
    "Return strict JSON only.",
    "JSON shape:",
    '{ "title": string | null, "description": string | null, "labels": string[] }',
    "Rules:",
    "- title: short evocative memory title, max 6 words.",
    "- description: 1 to 3 sentences, concise but specific, describing the trip/story/theme across the photos.",
    "- labels: 3 to 8 lowercase tags describing the whole memory.",
    "- Use the provided photo summaries as the source of truth. Do not invent people, places, or events not supported by the inputs.",
    "- Do not output markdown, bullets, or explanatory text outside the JSON object.",
    `Existing memory name: ${memory.name}.`,
    `Existing description: ${memory.description ?? "none"}.`,
    "Photo sample set:",
    ...sampleLines,
  ].join("\n");
}

export class VercelCompatibleAIClient implements AIClient {
  private readonly providerName: string;
  private readonly modelId: string;
  private readonly model: ReturnType<ReturnType<typeof createOpenAICompatible>>;

  constructor(options: VercelCompatibleAIClientOptions) {
    this.providerName = options.providerName ?? "openai-compatible";
    this.modelId = options.model;

    const provider = createOpenAICompatible({
      name: this.providerName,
      apiKey: options.apiKey,
      baseURL: options.baseURL,
    });

    this.model = provider(this.modelId);
  }

  isEnabled(): boolean {
    return true;
  }

  async analyzePhoto(photo: PhotoRecord): Promise<AIAnalysis> {
    const fileInput = await resolvePhotoInput(photo);
    const result = streamText({
      model: this.model,
      messages: [
        {
          role: "user",
          content: [
            { type: "text", text: buildAnalysisPrompt(photo) },
            ...(fileInput
              ? [
                  {
                    type: "file" as const,
                    data: fileInput.data,
                    mediaType: fileInput.mediaType,
                  },
                ]
              : []),
          ],
        },
      ],
    });
    let text = "";
    for await (const chunk of result.textStream) {
      text += chunk;
    }

    const payload = extractJsonObject(text);
    if (!payload) {
      throw new Error("Model returned non-JSON semantic output");
    }

    return {
      generatedLabels: normalizeLabels(payload.labels),
      generatedCaption: normalizeText(payload.caption),
      summary: normalizeText(payload.summary),
      embeddingRef: null,
      aiProvider: this.providerName,
      aiModel: this.modelId,
      aiProcessedAt: Date.now(),
      aiError: null,
    };
  }

  async analyzeMemory(memory: Memory, photos: PhotoRecord[]): Promise<MemoryAIAnalysis> {
    const result = streamText({
      model: this.model,
      messages: [
        {
          role: "user",
          content: [
            {
              type: "text",
              text: buildMemoryAnalysisPrompt(memory, photos),
            },
          ],
        },
      ],
    });

    let text = "";
    for await (const chunk of result.textStream) {
      text += chunk;
    }

    const payload = extractJsonObject(text);
    if (!payload) {
      throw new Error("Model returned non-JSON memory output");
    }

    return {
      generatedName: normalizeText(payload.title),
      generatedDescription: normalizeText(payload.description),
      generatedLabels: normalizeLabels(payload.labels),
      aiProvider: this.providerName,
      aiModel: this.modelId,
      aiProcessedAt: Date.now(),
      aiError: null,
    };
  }
}
