import { ArrowLeft, ArrowRight, X } from "lucide-react";

import type { Memory, PhotoRecord } from "@chronopic/domain";

import { AddToMemoryMenu } from "./add-to-memory-menu.js";
import { Badge } from "./badge.js";
import { Button } from "./button.js";
import { Dialog, DialogContent, DialogDescription, DialogTitle } from "./dialog.js";
import { EditControls, type EditControlsProps } from "./edit-controls.js";
import { Filmstrip } from "./filmstrip.js";
import { IconButton } from "./icon-button.js";
import { useI18n } from "./i18n-provider.js";
import { formatTimestamp, MediaPreview } from "./lib/media.js";
import { MetadataGrid } from "./metadata-grid.js";
import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from "./tooltip.js";
import type { ViewerMode } from "./types.js";

export interface PhotoViewerOverlayProps extends EditControlsProps {
  mode: ViewerMode | null;
  photo: PhotoRecord | null;
  photos: PhotoRecord[];
  memories: Memory[];
  photoMemories: Memory[];
  selectedPhotoId: string | null;
  aiEnabled: boolean;
  canNavigatePrevious: boolean;
  canNavigateNext: boolean;
  onClose: () => void;
  onPrevious: () => void;
  onNext: () => void;
  onSelectPhoto: (photoId: string) => void;
  onSwitchMode: (mode: ViewerMode) => void;
  onAddToMemory: (memoryId: string, photoId: string) => void;
  searchQuery?: string | null;
}

export function PhotoViewerOverlay(props: PhotoViewerOverlayProps) {
  const { t } = useI18n();

  if (!props.mode || !props.photo) {
    return null;
  }

  const activeIndex = props.photos.findIndex((record) => record.photo.id === props.selectedPhotoId);
  const fileName = props.photo.photo.path.split("/").at(-1) ?? "Photo";
  const indexLabel = activeIndex >= 0 ? `${activeIndex + 1} / ${props.photos.length}` : t("common.items", { count: props.photos.length });

  return (
    <TooltipProvider>
      <Dialog modal onOpenChange={(open) => (!open ? props.onClose() : undefined)} open>
        <DialogContent className={props.mode === "gallery" ? "bg-stone-950/96 text-stone-50" : "p-4"}>
          <DialogTitle className="sr-only">
            {props.mode === "gallery" ? t("viewer.galleryTitle") : t("viewer.detailTitle")}
          </DialogTitle>
          <DialogDescription className="sr-only">
            {t("viewer.description", { name: fileName, mode: props.mode })}
          </DialogDescription>
          {props.mode === "gallery" ? (
            <>
              <div className="absolute inset-x-0 top-0 z-10 flex items-center justify-between px-5 py-4">
                <div className="flex items-center gap-3">
                  <Badge className="border-stone-700 bg-stone-900/80 text-stone-200" tone="dark">
                    {t("viewer.galleryView")}
                  </Badge>
                  <span className="text-sm text-stone-300">{indexLabel}</span>
                </div>
                <Tooltip>
                  <TooltipTrigger asChild>
                    <Button className="border-stone-700 bg-stone-900/80 text-stone-100 hover:bg-stone-800" onClick={() => props.onSwitchMode("detail")} variant="ghost">
                      {t("viewer.detailView")}
                    </Button>
                  </TooltipTrigger>
                  <TooltipContent>{t("viewer.switchToDetail")}</TooltipContent>
                </Tooltip>
              </div>

              <div className="grid h-full grid-rows-[1fr_auto]">
                <div className="relative min-h-0 px-4 pt-20">
                  <Tooltip>
                    <TooltipTrigger asChild>
                      <div className="absolute left-5 top-1/2 z-10 -translate-y-1/2">
                        <IconButton
                          className="rounded-full"
                          disabled={!props.canNavigatePrevious}
                          icon={<ArrowLeft className="h-5 w-5" />}
                          label={t("actions.previousPhoto")}
                          onClick={props.onPrevious}
                          size="lg"
                          tone="dark"
                        />
                      </div>
                    </TooltipTrigger>
                    <TooltipContent>{t("viewer.previousTooltip")}</TooltipContent>
                  </Tooltip>
                  <Tooltip>
                    <TooltipTrigger asChild>
                      <div className="absolute right-5 top-1/2 z-10 -translate-y-1/2">
                        <IconButton
                          className="rounded-full"
                          disabled={!props.canNavigateNext}
                          icon={<ArrowRight className="h-5 w-5" />}
                          label={t("actions.nextPhoto")}
                          onClick={props.onNext}
                          size="lg"
                          tone="dark"
                        />
                      </div>
                    </TooltipTrigger>
                    <TooltipContent>{t("viewer.nextTooltip")}</TooltipContent>
                  </Tooltip>
                  <div className="grid h-full place-items-center">
                    <div className="h-full max-h-[calc(100vh-16rem)] w-full max-w-[1500px] overflow-hidden rounded-[32px] border border-stone-800 bg-stone-950 shadow-2xl">
                      <div className="h-full w-full" onDoubleClick={() => props.onSwitchMode("detail")}>
                        <MediaPreview className="bg-stone-950" controls fit="contain" preferOriginal record={props.photo} />
                      </div>
                    </div>
                  </div>
                </div>

                <div className="px-4 pb-4">
                  <div className="mx-auto max-w-[1500px] space-y-3">
                    <div className="flex items-center justify-between">
                      <div>
                        <p className="text-sm font-semibold text-stone-100">{fileName}</p>
                        <p className="text-sm text-stone-400">{formatTimestamp(props.photo.metadata.datetime)}</p>
                        <div className="mt-2 flex flex-wrap gap-2">
                          {props.photoMemories.length === 0 ? (
                            <Badge className="border-stone-700 bg-stone-900/80 text-stone-300" tone="dark">
                              {t("viewer.notInAnyMemory")}
                            </Badge>
                          ) : (
                            props.photoMemories.map((memory) => (
                              <Badge className="border-stone-700 bg-stone-900/80 text-stone-200" key={memory.id} tone="dark">
                                {memory.name}
                                {memory.coverPhotoId === props.selectedPhotoId ? ` ${t("common.cover")}` : ""}
                              </Badge>
                            ))
                          )}
                        </div>
                      </div>
                      <Tooltip>
                        <TooltipTrigger asChild>
                          <Button className="border-stone-700 bg-stone-900/80 text-stone-100 hover:bg-stone-800" onClick={() => props.onSwitchMode("detail")} variant="ghost">
                            {t("actions.openInspector")}
                          </Button>
                        </TooltipTrigger>
                        <TooltipContent>{t("viewer.openInspectorTooltip")}</TooltipContent>
                      </Tooltip>
                    </div>
                    <p className="text-xs text-stone-400">{t("viewer.galleryShortcuts")}</p>
                    <Filmstrip onSelect={props.onSelectPhoto} photos={props.photos} selectedPhotoId={props.selectedPhotoId} tone="dark" />
                  </div>
                </div>
              </div>
            </>
          ) : (
            <>
              <div className="mx-auto grid h-full max-w-[1720px] gap-4 xl:grid-cols-[minmax(0,1fr)_420px]">
                <div className="flex min-h-0 flex-col overflow-hidden rounded-[32px] border border-stone-800 bg-stone-950 text-stone-50 shadow-2xl">
                  <div className="flex items-center justify-between border-b border-stone-800 px-5 py-4">
                    <div className="flex items-center gap-3">
                      <Badge className="border-stone-700 bg-stone-900/80 text-stone-200" tone="dark">
                        {t("viewer.detailView")}
                      </Badge>
                      <span className="text-sm text-stone-300">{indexLabel}</span>
                    </div>
                    <div className="flex items-center gap-2">
                      <AddToMemoryMenu
                        memories={props.memories}
                        onAddToMemory={(memoryId) => props.onAddToMemory(memoryId, props.photo!.photo.id)}
                        tone="dark"
                        trigger="icon"
                      />
                      <Tooltip>
                        <TooltipTrigger asChild>
                          <IconButton
                            icon={<X className="h-4 w-4" />}
                            label={t("actions.close")}
                            onClick={props.onClose}
                            size="sm"
                            tone="dark"
                          />
                        </TooltipTrigger>
                        <TooltipContent>{t("viewer.closeTooltip")}</TooltipContent>
                      </Tooltip>
                      <Tooltip>
                        <TooltipTrigger asChild>
                          <IconButton
                            disabled={!props.canNavigatePrevious}
                            icon={<ArrowLeft className="h-4 w-4" />}
                            label={t("actions.previousPhoto")}
                            onClick={props.onPrevious}
                            size="sm"
                            tone="dark"
                          />
                        </TooltipTrigger>
                        <TooltipContent>{t("viewer.previousTooltip")}</TooltipContent>
                      </Tooltip>
                      <Tooltip>
                        <TooltipTrigger asChild>
                          <IconButton
                            disabled={!props.canNavigateNext}
                            icon={<ArrowRight className="h-4 w-4" />}
                            label={t("actions.nextPhoto")}
                            onClick={props.onNext}
                            size="sm"
                            tone="dark"
                          />
                        </TooltipTrigger>
                        <TooltipContent>{t("viewer.nextTooltip")}</TooltipContent>
                      </Tooltip>
                      <Tooltip>
                        <TooltipTrigger asChild>
                          <Button className="border-stone-700 bg-stone-900/80 text-stone-100 hover:bg-stone-800" onClick={() => props.onSwitchMode("gallery")} variant="ghost">
                            {t("viewer.gallery")}
                          </Button>
                        </TooltipTrigger>
                        <TooltipContent>{t("viewer.switchToGallery")}</TooltipContent>
                      </Tooltip>
                    </div>
                  </div>

                  <div className="grid min-h-0 flex-1 grid-rows-[1fr_auto] gap-4 p-4">
                    <div className="min-h-0 overflow-hidden rounded-[28px] border border-stone-800 bg-stone-900">
                      <div className="h-full w-full" onDoubleClick={() => props.onSwitchMode("gallery")}>
                        <MediaPreview className="bg-stone-950" controls fit="contain" preferOriginal record={props.photo} />
                      </div>
                    </div>
                    <p className="px-1 text-xs text-stone-400">{t("viewer.detailShortcuts")}</p>
                    <Filmstrip onSelect={props.onSelectPhoto} photos={props.photos} selectedPhotoId={props.selectedPhotoId} tone="dark" />
                  </div>
                </div>

                <div className="min-h-0 overflow-auto rounded-[32px] border border-stone-200/80 bg-white shadow-2xl">
                  <div className="flex items-center justify-between border-b border-stone-200/80 px-5 py-4">
                    <div>
                      <p className="text-[11px] font-semibold uppercase tracking-[0.22em] text-stone-500">{t("viewer.inspector")}</p>
                      <h2 className="mt-2 line-clamp-1 font-['Space_Grotesk','IBM_Plex_Sans',sans-serif] text-2xl font-semibold tracking-tight text-stone-950">
                        {fileName}
                      </h2>
                    </div>
                    <Badge tone={props.photo.indexState.error ? "danger" : "success"}>
                      {props.photo.indexState.error ? t("common.indexedWithError") : t("common.healthy")}
                    </Badge>
                  </div>
                  <div className="grid gap-5 p-5">
                    <MetadataGrid
                      aiEnabled={props.aiEnabled}
                      memories={props.photoMemories}
                      photo={props.photo}
                      searchQuery={props.searchQuery ?? null}
                    />
                    <EditControls
                      aiEnabled={props.aiEnabled}
                      aiStatus={props.photo.semantic.aiStatus}
                      draftCaption={props.draftCaption}
                      draftDatetime={props.draftDatetime}
                      draftTags={props.draftTags}
                      isEnrichingSemantic={props.isEnrichingSemantic ?? false}
                      onCaptionChange={props.onCaptionChange}
                      onDatetimeChange={props.onDatetimeChange}
                      onEnrichSemantic={props.onEnrichSemantic ?? (() => {})}
                      onRollback={props.onRollback}
                      onSaveCaption={props.onSaveCaption}
                      onSaveDatetime={props.onSaveDatetime}
                      onSaveTags={props.onSaveTags}
                      onTagsChange={props.onTagsChange}
                    />
                  </div>
                </div>
              </div>
            </>
          )}
        </DialogContent>
      </Dialog>
    </TooltipProvider>
  );
}
