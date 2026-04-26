import { Check, Lightbulb, Sparkles, Trash2, X } from "lucide-react";
import * as React from "react";

import type { MemoryCandidate } from "@chronopic/domain";

import { Badge } from "./badge.js";
import { Button } from "./button.js";
import { useI18n } from "./i18n-provider.js";
import { Input } from "./input.js";
import { thumbnailUrl } from "./lib/media.js";
import { Panel } from "./panel.js";

export interface SuggestedMemoriesSectionProps {
  candidates: MemoryCandidate[];
  isGenerating?: boolean;
  onGenerate: () => void | Promise<void>;
  onAccept: (candidateId: string, input?: { name?: string; photoIds?: string[] }) => void | Promise<void>;
  onReject: (candidateId: string) => void | Promise<void>;
}

export function SuggestedMemoriesSection({
  candidates,
  isGenerating = false,
  onGenerate,
  onAccept,
  onReject,
}: SuggestedMemoriesSectionProps) {
  const { t } = useI18n();
  const [draftTitles, setDraftTitles] = React.useState<Record<string, string>>({});
  const [removedPhotoIds, setRemovedPhotoIds] = React.useState<Record<string, string[]>>({});
  const [expandedPhotoControls, setExpandedPhotoControls] = React.useState<Record<string, boolean>>({});

  return (
    <Panel className="overflow-hidden">
      <div className="flex flex-wrap items-center justify-between gap-3 border-b border-stone-200/70 px-5 py-4">
        <div>
          <p className="text-[11px] font-semibold uppercase tracking-[0.22em] text-stone-500">{t("memories.suggestedTitle")}</p>
          <h2 className="mt-2 font-['Space_Grotesk','IBM_Plex_Sans',sans-serif] text-2xl font-semibold tracking-tight text-stone-950">
            {t("memories.suggestedHeading")}
          </h2>
          <p className="mt-2 text-sm text-stone-500">
            {t("memories.suggestedDescription")}
          </p>
        </div>
        <div className="flex items-center gap-2">
          <Badge tone={candidates.length > 0 ? "warn" : "neutral"}>
            {t("memories.ready", { count: candidates.length })}
          </Badge>
          <Button disabled={isGenerating} onClick={() => void onGenerate()} variant="accent">
            <Sparkles className="h-4 w-4" />
            {isGenerating ? t("memories.generating") : t("memories.generate")}
          </Button>
        </div>
      </div>
      <div className="p-5">
        {candidates.length === 0 ? (
          <div className="grid min-h-[220px] place-items-center rounded-[24px] border border-dashed border-stone-300 bg-stone-50/70 px-6 text-center">
            <div className="max-w-md space-y-3">
              <Lightbulb className="mx-auto h-8 w-8 text-stone-400" />
              <h3 className="text-lg font-semibold text-stone-900">{t("memories.noPendingSuggestions")}</h3>
              <p className="text-sm leading-6 text-stone-500">
                {t("memories.noPendingSuggestionsDescription")}
              </p>
            </div>
          </div>
        ) : (
          <div className="grid gap-4 xl:grid-cols-2">
            {candidates.map((candidate) => {
              const coverUrl = thumbnailUrl(candidate.coverThumbnailPath);
              const removed = new Set(removedPhotoIds[candidate.id] ?? []);
              const retainedPhotoIds = candidate.photoIds.filter((photoId) => !removed.has(photoId));
              const draftTitle = draftTitles[candidate.id] ?? candidate.title;
              const photoControlsOpen = expandedPhotoControls[candidate.id] ?? false;

              return (
                <article className="overflow-hidden rounded-[28px] border border-stone-200 bg-white shadow-sm" key={candidate.id}>
                  <div className="grid gap-0 md:grid-cols-[180px_minmax(0,1fr)]">
                    <div className="relative min-h-[180px] bg-gradient-to-br from-amber-100 via-stone-100 to-sky-100">
                      {coverUrl ? <img alt="" className="h-full min-h-[180px] w-full object-cover" src={coverUrl} /> : null}
                      <div className="absolute left-3 top-3 flex flex-wrap gap-2">
                        <Badge tone="info">{candidate.source}</Badge>
                        <Badge tone="neutral">{Math.round(candidate.confidence * 100)}%</Badge>
                      </div>
                    </div>
                    <div className="flex flex-col gap-4 p-4">
                      <div className="space-y-2">
                        <Input
                          aria-label={t("memories.suggestedTitleAria")}
                          onChange={(event) =>
                            setDraftTitles((current) => ({ ...current, [candidate.id]: event.target.value }))
                          }
                          value={draftTitle}
                        />
                        <p className="text-sm leading-6 text-stone-500">{candidate.reason}</p>
                      </div>
                      <div className="flex flex-wrap gap-2">
                        <Badge tone="neutral">{t("memory.detail.photos", { count: retainedPhotoIds.length })}</Badge>
                        {candidate.generatedLabels.map((label) => (
                          <Badge key={label} tone="neutral">
                            {label}
                          </Badge>
                        ))}
                      </div>
                      <div className="flex flex-col gap-2">
                        <Button
                          className="w-fit"
                          onClick={() =>
                            setExpandedPhotoControls((current) => ({ ...current, [candidate.id]: !photoControlsOpen }))
                          }
                          size="sm"
                          variant="ghost"
                        >
                          <Trash2 className="h-3.5 w-3.5" />
                          {photoControlsOpen ? t("memories.hidePhotoControls") : t("memories.adjustPhotos")}
                        </Button>
                        {photoControlsOpen ? (
                          <div className="flex flex-wrap gap-2">
                            {candidate.photoIds.slice(0, 10).map((photoId, index) => {
                              const isRemoved = removed.has(photoId);

                              return (
                                <Button
                                  className={isRemoved ? "line-through opacity-50" : ""}
                                  key={photoId}
                                  onClick={() => {
                                    setRemovedPhotoIds((current) => {
                                      const next = new Set(current[candidate.id] ?? []);
                                      if (next.has(photoId)) {
                                        next.delete(photoId);
                                      } else {
                                        next.add(photoId);
                                      }
                                      return { ...current, [candidate.id]: [...next] };
                                    });
                                  }}
                                  size="sm"
                                  variant="outline"
                                >
                                  {t("memories.photoIndex", { index: index + 1 })}
                                </Button>
                              );
                            })}
                          </div>
                        ) : null}
                      </div>
                      <div className="mt-auto flex justify-end gap-2">
                        <Button onClick={() => void onReject(candidate.id)} size="sm" variant="ghost">
                          <X className="h-4 w-4" />
                          {t("memories.reject")}
                        </Button>
                        <Button
                          disabled={!draftTitle.trim() || retainedPhotoIds.length === 0}
                          onClick={() => void onAccept(candidate.id, { name: draftTitle.trim(), photoIds: retainedPhotoIds })}
                          size="sm"
                          variant="accent"
                        >
                          <Check className="h-4 w-4" />
                          {t("memories.acceptMemory")}
                        </Button>
                      </div>
                    </div>
                  </div>
                </article>
              );
            })}
          </div>
        )}
      </div>
    </Panel>
  );
}
