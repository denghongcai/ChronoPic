import * as React from "react";
import { CalendarClock, ImageUp, PencilLine, SquarePen, Trash2 } from "lucide-react";

import type { Memory, PhotoRecord } from "@chronopic/domain";

import { Badge } from "./badge.js";
import { Button } from "./button.js";
import { Dialog, DialogContent } from "./dialog.js";
import { IconButton } from "./icon-button.js";
import { Input } from "./input.js";
import { getMemoryDescriptionPreview } from "./lib/memory-description.js";
import { MemoryDescriptionEditor } from "./memory-description-editor.js";
import { Panel } from "./panel.js";
import { PhotoCard } from "./photo-card.js";
import { formatTimestamp, thumbnailUrl } from "./lib/media.js";

export interface MemoryDetailPageProps {
  memory: Memory;
  photos: PhotoRecord[];
  selectedPhotoId?: string | null;
  onSelectPhoto: (photoId: string) => void;
  onOpenDetail: (photoId: string) => void;
  onToggleFavorite: (photoId: string, favorite: boolean) => void;
  onRemovePhoto: (memoryId: string, photoId: string) => void;
  onRenameMemory: (memoryId: string, name: string) => void | Promise<void>;
  onSetCover: (memoryId: string, photoId: string) => void | Promise<void>;
  onDeleteMemory: (memoryId: string) => void;
  onSaveDescription: (memoryId: string, serializedDescription: string) => void;
}

export function MemoryDetailPage({
  memory,
  photos,
  selectedPhotoId,
  onSelectPhoto,
  onOpenDetail,
  onToggleFavorite,
  onRemovePhoto,
  onRenameMemory,
  onSetCover,
  onDeleteMemory,
  onSaveDescription,
}: MemoryDetailPageProps) {
  const coverUrl = thumbnailUrl(memory.coverThumbnailPath);
  const [editingDescription, setEditingDescription] = React.useState(false);
  const [renaming, setRenaming] = React.useState(false);
  const [draftName, setDraftName] = React.useState(memory.name);
  const descriptionPreview = getMemoryDescriptionPreview(memory.description);
  const selectedRecord = React.useMemo(
    () => photos.find((record) => record.photo.id === selectedPhotoId) ?? null,
    [photos, selectedPhotoId]
  );

  React.useEffect(() => {
    setDraftName(memory.name);
  }, [memory.name]);

  return (
    <div className="space-y-6">
      <Panel className="overflow-hidden">
        <div className="grid gap-6 p-6 lg:grid-cols-[320px_minmax(0,1fr)]">
          <div className="overflow-hidden rounded-[28px] border border-stone-200 bg-stone-100">
            <div className="aspect-[1.2] overflow-hidden bg-gradient-to-br from-amber-100 via-stone-100 to-sky-100">
              {coverUrl ? (
                <img alt={memory.name} className="h-full w-full object-cover" src={coverUrl} />
              ) : (
                <div className="grid h-full place-items-center text-stone-400">
                  <PencilLine className="h-10 w-10" />
                </div>
              )}
            </div>
          </div>
          <div className="space-y-5">
            <div className="space-y-5">
              <div className="flex items-start justify-between gap-4">
                <div className="space-y-3">
                  <div className="flex items-center gap-2">
                    <Badge tone="neutral">{memory.photoCount} photos</Badge>
                    <Badge tone="info">{memory.source}</Badge>
                  </div>
                  <div>
                    <p className="text-[11px] font-semibold uppercase tracking-[0.22em] text-stone-500">Memory Detail</p>
                    <h1 className="mt-2 font-['Space_Grotesk','IBM_Plex_Sans',sans-serif] text-4xl font-semibold tracking-tight text-stone-950">
                      {memory.name}
                    </h1>
                    <p className="mt-3 inline-flex items-center gap-2 text-sm text-stone-500">
                      <CalendarClock className="h-4 w-4" />
                      Updated {formatTimestamp(memory.updatedAt)}
                    </p>
                    {memory.coverPhotoId ? (
                      <p className="mt-2 text-xs font-medium uppercase tracking-[0.18em] text-stone-400">
                        Custom cover selected
                      </p>
                    ) : null}
                  </div>
                </div>
                <div className="flex items-center gap-2">
                  <Button onClick={() => setRenaming(true)} size="sm" variant="outline">
                    <SquarePen className="h-4 w-4" />
                    Rename
                  </Button>
                  <IconButton
                    icon={<Trash2 className="h-4 w-4" />}
                    label="Delete Memory"
                    onClick={() => onDeleteMemory(memory.id)}
                    size="sm"
                    variant="ghost"
                  />
                </div>
              </div>

              <div className="space-y-3">
                <div className="flex items-center justify-between">
                  <p className="text-[11px] font-semibold uppercase tracking-[0.22em] text-stone-500">Description</p>
                  <Button onClick={() => setEditingDescription(true)} size="sm" variant="outline">
                    <SquarePen className="h-4 w-4" />
                    Edit Description
                  </Button>
                </div>
                <button
                  className="w-full rounded-[24px] border border-stone-200 bg-white px-5 py-4 text-left shadow-sm transition hover:border-stone-300 hover:bg-stone-50"
                  onClick={() => setEditingDescription(true)}
                  type="button"
                >
                  <p className="text-sm leading-7 text-stone-600">
                    {descriptionPreview || "Add context, story beats, and notes for this memory."}
                  </p>
                </button>
              </div>
            </div>
          </div>
        </div>
      </Panel>

      <Panel className="overflow-hidden">
        <div className="flex items-center justify-between border-b border-stone-200/70 px-5 py-4">
          <div>
            <p className="text-[11px] font-semibold uppercase tracking-[0.22em] text-stone-500">Memory Actions</p>
            <h2 className="mt-2 font-['Space_Grotesk','IBM_Plex_Sans',sans-serif] text-2xl font-semibold tracking-tight text-stone-950">
              Manage this memory
            </h2>
          </div>
          <Badge tone={selectedRecord ? "info" : "neutral"}>
            {selectedRecord ? `Selected ${selectedRecord.photo.path.split("/").at(-1)}` : "Select a photo below"}
          </Badge>
        </div>
        <div className="grid gap-4 p-5 md:grid-cols-[minmax(0,1fr)_auto] md:items-center">
          <div className="space-y-2">
            <p className="text-sm font-medium text-stone-900">Cover photo</p>
            <p className="text-sm leading-6 text-stone-500">
              Select a photo from this memory and set it as the cover so list cards and the detail header show a stable hero image.
            </p>
          </div>
          <Button
            disabled={!selectedRecord || selectedRecord.photo.id === memory.coverPhotoId}
            onClick={() => selectedRecord && onSetCover(memory.id, selectedRecord.photo.id)}
            variant="accent"
          >
            <ImageUp className="h-4 w-4" />
            Set Selected as Cover
          </Button>
        </div>
      </Panel>

      <Dialog onOpenChange={setEditingDescription} open={editingDescription}>
        <DialogContent className="flex items-center justify-center p-6">
          <div className="w-full max-w-4xl rounded-[28px] border border-stone-200 bg-white p-6 shadow-2xl">
            <div className="mb-5 flex items-start justify-between gap-4">
              <div>
                <p className="text-[11px] font-semibold uppercase tracking-[0.22em] text-stone-500">Edit Description</p>
                <h2 className="mt-2 font-['Space_Grotesk','IBM_Plex_Sans',sans-serif] text-2xl font-semibold tracking-tight text-stone-950">
                  {memory.name}
                </h2>
              </div>
              <Button onClick={() => setEditingDescription(false)} size="sm" variant="ghost">
                Close
              </Button>
            </div>
            <MemoryDescriptionEditor
              onSave={(serializedDescription) => {
                onSaveDescription(memory.id, serializedDescription);
                setEditingDescription(false);
              }}
              value={memory.description}
            />
          </div>
        </DialogContent>
      </Dialog>

      <Dialog onOpenChange={setRenaming} open={renaming}>
        <DialogContent className="flex items-center justify-center p-6">
          <div className="w-full max-w-xl rounded-[28px] border border-stone-200 bg-white p-6 shadow-2xl">
            <div className="mb-5 flex items-start justify-between gap-4">
              <div>
                <p className="text-[11px] font-semibold uppercase tracking-[0.22em] text-stone-500">Rename Memory</p>
                <h2 className="mt-2 font-['Space_Grotesk','IBM_Plex_Sans',sans-serif] text-2xl font-semibold tracking-tight text-stone-950">
                  Update title
                </h2>
              </div>
              <Button onClick={() => setRenaming(false)} size="sm" variant="ghost">
                Close
              </Button>
            </div>
            <div className="space-y-4">
              <div className="space-y-2">
                <p className="text-[11px] font-semibold uppercase tracking-[0.18em] text-stone-500">Memory Name</p>
                <Input
                  onChange={(event) => setDraftName(event.target.value)}
                  placeholder="Memory title"
                  value={draftName}
                />
              </div>
              <div className="flex justify-end gap-2">
                <Button onClick={() => setRenaming(false)} variant="ghost">
                  Cancel
                </Button>
                <Button
                  disabled={!draftName.trim() || draftName.trim() === memory.name}
                  onClick={() => {
                    onRenameMemory(memory.id, draftName.trim());
                    setRenaming(false);
                  }}
                  variant="accent"
                >
                  Save Name
                </Button>
              </div>
            </div>
          </div>
        </DialogContent>
      </Dialog>

      <Panel className="overflow-hidden">
        <div className="flex items-center justify-between border-b border-stone-200/70 px-5 py-4">
          <div>
            <p className="text-[11px] font-semibold uppercase tracking-[0.22em] text-stone-500">Memory Photos</p>
            <h2 className="mt-2 font-['Space_Grotesk','IBM_Plex_Sans',sans-serif] text-2xl font-semibold tracking-tight text-stone-950">
              Photos inside this memory
            </h2>
          </div>
          <Badge tone="neutral">{photos.length} visible</Badge>
        </div>
        <div className="p-5">
          {photos.length === 0 ? (
            <div className="grid min-h-[240px] place-items-center rounded-[24px] border border-dashed border-stone-300 bg-stone-50/70 px-6 text-center">
              <div className="max-w-sm space-y-3">
                <h3 className="text-lg font-semibold text-stone-900">This memory is empty</h3>
                <p className="text-sm leading-6 text-stone-500">Add photos to this memory from browsing and viewer flows to build its story.</p>
              </div>
            </div>
          ) : (
            <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-3 2xl:grid-cols-4">
              {photos.map((record) => (
                <PhotoCard
                  key={record.photo.id}
                  onOpenDetail={() => onOpenDetail(record.photo.id)}
                  onSecondaryAction={(photoId) => onRemovePhoto(memory.id, photoId)}
                  onSelect={() => onSelectPhoto(record.photo.id)}
                  onToggleFavorite={onToggleFavorite}
                  record={record}
                  secondaryActionLabel="Remove from Memory"
                  selected={selectedPhotoId === record.photo.id}
                  showHoverActions
                />
              ))}
            </div>
          )}
        </div>
      </Panel>
    </div>
  );
}
