import { ArrowLeft, ArrowRight, X } from "lucide-react";

import type { PhotoRecord } from "@chronopic/domain";

import { EditControls, type EditControlsProps } from "./edit-controls.js";
import { Filmstrip } from "./filmstrip.js";
import { formatTimestamp, MediaPreview } from "./lib/media.js";
import { MetadataGrid } from "./metadata-grid.js";
import { Badge, Button } from "./primitives.js";
import type { ViewerMode } from "./types.js";

export interface PhotoViewerOverlayProps extends EditControlsProps {
  mode: ViewerMode | null;
  photo: PhotoRecord | null;
  photos: PhotoRecord[];
  selectedPhotoId: string | null;
  aiEnabled: boolean;
  canNavigatePrevious: boolean;
  canNavigateNext: boolean;
  onClose: () => void;
  onPrevious: () => void;
  onNext: () => void;
  onSelectPhoto: (photoId: string) => void;
  onSwitchMode: (mode: ViewerMode) => void;
}

export function PhotoViewerOverlay(props: PhotoViewerOverlayProps) {
  if (!props.mode || !props.photo) {
    return null;
  }

  const activeIndex = props.photos.findIndex((record) => record.photo.id === props.selectedPhotoId);
  const indexLabel = activeIndex >= 0 ? `${activeIndex + 1} / ${props.photos.length}` : `${props.photos.length} items`;

  if (props.mode === "gallery") {
    return (
      <div className="fixed inset-0 z-50 bg-stone-950/96 text-stone-50 backdrop-blur-sm">
        <button aria-label="Close gallery view" className="absolute inset-0" onClick={props.onClose} type="button" />
        <div className="absolute inset-x-0 top-0 z-10 flex items-center justify-between px-5 py-4">
          <div className="flex items-center gap-3">
            <Badge className="border-stone-700 bg-stone-900/80 text-stone-200" tone="dark">
              Gallery View
            </Badge>
            <span className="text-sm text-stone-300">{indexLabel}</span>
          </div>
          <div className="flex items-center gap-2">
            <Button className="border-stone-700 bg-stone-900/80 text-stone-100 hover:bg-stone-800" onClick={() => props.onSwitchMode("detail")} variant="ghost">
              Detail View
            </Button>
            <Button className="border-stone-700 bg-stone-900/80 text-stone-100 hover:bg-stone-800" onClick={props.onClose} size="icon" variant="ghost">
              <X className="h-4 w-4" />
            </Button>
          </div>
        </div>

        <div className="relative z-10 grid h-full grid-rows-[1fr_auto]" onClick={(event) => event.stopPropagation()}>
          <div className="relative min-h-0 px-4 pt-20">
            <button
              className="absolute left-5 top-1/2 z-10 inline-flex h-12 w-12 -translate-y-1/2 items-center justify-center rounded-full border border-stone-700 bg-stone-900/80 text-stone-100 transition hover:bg-stone-800 disabled:cursor-not-allowed disabled:opacity-35 disabled:hover:bg-stone-900/80"
              disabled={!props.canNavigatePrevious}
              onClick={props.onPrevious}
              type="button"
            >
              <ArrowLeft className="h-5 w-5" />
            </button>
            <button
              className="absolute right-5 top-1/2 z-10 inline-flex h-12 w-12 -translate-y-1/2 items-center justify-center rounded-full border border-stone-700 bg-stone-900/80 text-stone-100 transition hover:bg-stone-800 disabled:cursor-not-allowed disabled:opacity-35 disabled:hover:bg-stone-900/80"
              disabled={!props.canNavigateNext}
              onClick={props.onNext}
              type="button"
            >
              <ArrowRight className="h-5 w-5" />
            </button>
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
                  <p className="text-sm font-semibold text-stone-100">{props.photo.photo.path.split("/").at(-1)}</p>
                  <p className="text-sm text-stone-400">{formatTimestamp(props.photo.metadata.datetime)}</p>
                </div>
                <Button className="border-stone-700 bg-stone-900/80 text-stone-100 hover:bg-stone-800" onClick={() => props.onSwitchMode("detail")} variant="ghost">
                  Open Inspector
                </Button>
              </div>
              <p className="text-xs text-stone-400">Esc close • Left/Right navigate • D detail • Click backdrop to exit</p>
              <Filmstrip onSelect={props.onSelectPhoto} photos={props.photos} selectedPhotoId={props.selectedPhotoId} tone="dark" />
            </div>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="fixed inset-0 z-50 bg-stone-950/72 p-4 backdrop-blur-sm">
      <button aria-label="Close detail view" className="absolute inset-0" onClick={props.onClose} type="button" />
      <div className="relative z-10 mx-auto grid h-full max-w-[1720px] gap-4 xl:grid-cols-[minmax(0,1fr)_420px]" onClick={(event) => event.stopPropagation()}>
        <div className="flex min-h-0 flex-col overflow-hidden rounded-[32px] border border-stone-800 bg-stone-950 text-stone-50 shadow-2xl">
          <div className="flex items-center justify-between border-b border-stone-800 px-5 py-4">
            <div className="flex items-center gap-3">
              <Badge className="border-stone-700 bg-stone-900/80 text-stone-200" tone="dark">
                Detail View
              </Badge>
              <span className="text-sm text-stone-300">{indexLabel}</span>
            </div>
            <div className="flex items-center gap-2">
              <Button
                className="border-stone-700 bg-stone-900/80 text-stone-100 hover:bg-stone-800 disabled:cursor-not-allowed disabled:opacity-35 disabled:hover:bg-stone-900/80"
                disabled={!props.canNavigatePrevious}
                onClick={props.onPrevious}
                variant="ghost"
              >
                <ArrowLeft className="h-4 w-4" />
                Previous
              </Button>
              <Button
                className="border-stone-700 bg-stone-900/80 text-stone-100 hover:bg-stone-800 disabled:cursor-not-allowed disabled:opacity-35 disabled:hover:bg-stone-900/80"
                disabled={!props.canNavigateNext}
                onClick={props.onNext}
                variant="ghost"
              >
                Next
                <ArrowRight className="h-4 w-4" />
              </Button>
              <Button className="border-stone-700 bg-stone-900/80 text-stone-100 hover:bg-stone-800" onClick={() => props.onSwitchMode("gallery")} variant="ghost">
                Gallery
              </Button>
              <Button className="border-stone-700 bg-stone-900/80 text-stone-100 hover:bg-stone-800" onClick={props.onClose} size="icon" variant="ghost">
                <X className="h-4 w-4" />
              </Button>
            </div>
          </div>

          <div className="grid min-h-0 flex-1 grid-rows-[1fr_auto] gap-4 p-4">
            <div className="min-h-0 overflow-hidden rounded-[28px] border border-stone-800 bg-stone-900">
              <div className="h-full w-full" onDoubleClick={() => props.onSwitchMode("gallery")}>
                <MediaPreview className="bg-stone-950" controls fit="contain" preferOriginal record={props.photo} />
              </div>
            </div>
            <p className="px-1 text-xs text-stone-400">Esc close • Left/Right navigate • G gallery • Double-click media to enter gallery</p>
            <Filmstrip onSelect={props.onSelectPhoto} photos={props.photos} selectedPhotoId={props.selectedPhotoId} tone="dark" />
          </div>
        </div>

        <div className="min-h-0 overflow-auto rounded-[32px] border border-stone-200/80 bg-white shadow-2xl">
          <div className="flex items-center justify-between border-b border-stone-200/80 px-5 py-4">
            <div>
              <p className="text-[11px] font-semibold uppercase tracking-[0.22em] text-stone-500">Inspector</p>
              <h2 className="mt-2 line-clamp-1 font-['Space_Grotesk','IBM_Plex_Sans',sans-serif] text-2xl font-semibold tracking-tight text-stone-950">
                {props.photo.photo.path.split("/").at(-1)}
              </h2>
            </div>
            <Badge tone={props.photo.indexState.error ? "danger" : "success"}>
              {props.photo.indexState.error ? "Indexed with error" : "Healthy"}
            </Badge>
          </div>
          <div className="grid gap-5 p-5">
            <MetadataGrid aiEnabled={props.aiEnabled} photo={props.photo} />
            <EditControls
              draftDatetime={props.draftDatetime}
              draftTags={props.draftTags}
              onDatetimeChange={props.onDatetimeChange}
              onRollback={props.onRollback}
              onSaveDatetime={props.onSaveDatetime}
              onSaveTags={props.onSaveTags}
              onTagsChange={props.onTagsChange}
            />
          </div>
        </div>
      </div>
    </div>
  );
}
