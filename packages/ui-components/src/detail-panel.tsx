import { ImageIcon } from "lucide-react";

import type { PhotoRecord } from "@chronopic/domain";

import { Badge } from "./badge.js";
import { Button } from "./button.js";
import { EditControls, type EditControlsProps } from "./edit-controls.js";
import { MediaPreview } from "./lib/media.js";
import { MetadataGrid } from "./metadata-grid.js";
import { Panel } from "./panel.js";

export interface DetailPanelProps extends EditControlsProps {
  photo: PhotoRecord | null;
  aiEnabled: boolean;
  onOpenDetail: () => void;
  onOpenGallery: () => void;
}

export function DetailPanel(props: DetailPanelProps) {
  if (!props.photo) {
    return (
      <Panel className="grid min-h-[620px] place-items-center px-6 py-12">
        <div className="max-w-xs space-y-3 text-center">
          <ImageIcon className="mx-auto h-12 w-12 text-stone-400" />
          <h3 className="text-lg font-semibold text-stone-900">Select a photo to inspect metadata</h3>
          <p className="text-sm leading-6 text-stone-500">
            The selection panel keeps the grid context. Open detail or gallery mode for focused viewing.
          </p>
        </div>
      </Panel>
    );
  }

  return (
    <Panel className="overflow-hidden">
      <div className="flex items-center justify-between border-b border-stone-200/70 px-5 py-4">
        <div>
          <p className="text-[11px] font-semibold uppercase tracking-[0.22em] text-stone-500">Selection Inspector</p>
          <h2 className="mt-2 line-clamp-1 font-['Space_Grotesk','IBM_Plex_Sans',sans-serif] text-2xl font-semibold tracking-tight text-stone-950">
            {props.photo.photo.path.split("/").at(-1)}
          </h2>
        </div>
        <Badge tone={props.photo.indexState.error ? "danger" : "success"}>
          {props.photo.indexState.error ? "Indexed with error" : "Healthy"}
        </Badge>
      </div>
      <div className="grid gap-5 p-5">
        <div className="overflow-hidden rounded-[24px] border border-stone-200 bg-stone-100">
          <div className="relative aspect-[1.08]">
            <MediaPreview fit="contain" preferOriginal record={props.photo} />
          </div>
        </div>

        <div className="grid gap-2 sm:grid-cols-2">
          <Button onClick={props.onOpenDetail} variant="accent">
            Open Detail View
          </Button>
          <Button onClick={props.onOpenGallery} variant="outline">
            Open Gallery View
          </Button>
        </div>

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
    </Panel>
  );
}
