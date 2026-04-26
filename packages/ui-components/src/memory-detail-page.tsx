import * as React from "react";
import { CalendarClock, ImageUp, PencilLine, Sparkles, Trash2, X } from "lucide-react";

import type { Memory, PhotoRecord } from "@chronopic/domain";

import { Badge } from "./badge.js";
import { Button } from "./button.js";
import { Dialog, DialogContent, DialogDescription, DialogTitle } from "./dialog.js";
import { IconButton } from "./icon-button.js";
import { Input } from "./input.js";
import { getMemoryDescriptionMarkdown, hasMemoryDescription } from "./lib/memory-description.js";
import { buildMemoryStorySections } from "./lib/memory-story.js";
import { MemoryDescriptionEditor } from "./memory-description-editor.js";
import { MemoryStoryBoard } from "./memory-story-board.js";
import { Panel } from "./panel.js";
import { PhotoCard } from "./photo-card.js";
import { formatTimestamp, thumbnailUrl } from "./lib/media.js";

const MarkdownPreview = React.lazy(async () => {
  const module = await import("@uiw/react-md-editor");
  const editor = module.default as unknown as { Markdown: React.ComponentType<{ source?: string }> };
  return { default: editor.Markdown };
});

export interface MemoryDetailPageProps {
  memory: Memory;
  photos: PhotoRecord[];
  isEnrichingSemantic?: boolean;
  selectedPhotoIds?: string[];
  selectedPhotoId?: string | null;
  onSelectPhoto: (photoId: string) => void;
  onToggleBatchSelect: (photoId: string) => void;
  onClearBatchSelection: () => void;
  onOpenDetail: (photoId: string) => void;
  onToggleFavorite: (photoId: string, favorite: boolean) => void;
  onRemovePhoto: (memoryId: string, photoId: string) => void;
  onRemoveSelection: (memoryId: string, photoIds: string[]) => void | Promise<void>;
  onRenameMemory: (memoryId: string, name: string) => void | Promise<void>;
  onSetCover: (memoryId: string, photoId: string) => void | Promise<void>;
  onDeleteMemory: (memoryId: string) => void | Promise<void>;
  onSaveDescription: (memoryId: string, serializedDescription: string) => void | Promise<void>;
  onEnrichSemantic?: (
    memoryId: string,
    context?: { name?: string | null; description?: string | null }
  ) => void | Promise<void>;
}

export function MemoryDetailPage({
  memory,
  photos,
  isEnrichingSemantic = false,
  selectedPhotoIds = [],
  selectedPhotoId,
  onSelectPhoto,
  onToggleBatchSelect,
  onClearBatchSelection,
  onOpenDetail,
  onToggleFavorite,
  onRemovePhoto,
  onRemoveSelection,
  onRenameMemory,
  onSetCover,
  onDeleteMemory,
  onSaveDescription,
  onEnrichSemantic,
	}: MemoryDetailPageProps) {
	  const coverUrl = thumbnailUrl(memory.coverThumbnailPath);
	  const descriptionMarkdown = getMemoryDescriptionMarkdown(memory.description);
	  const [editingDescription, setEditingDescription] = React.useState(false);
	  const [aiSuggestionsOpen, setAiSuggestionsOpen] = React.useState(false);
	  const [renaming, setRenaming] = React.useState(false);
  const [selectionMode, setSelectionMode] = React.useState(false);
  const [deleteConfirmOpen, setDeleteConfirmOpen] = React.useState(false);
  const [removeSelectedConfirmOpen, setRemoveSelectedConfirmOpen] = React.useState(false);
	  const [pendingRemovalPhotoId, setPendingRemovalPhotoId] = React.useState<string | null>(null);
	  const [draftName, setDraftName] = React.useState(memory.name);
	  const [draftDescription, setDraftDescription] = React.useState(descriptionMarkdown);
	  const hasDescription = hasMemoryDescription(memory.description);
  const hasBatchSelection = selectedPhotoIds.length > 0;
  const isSelecting = selectionMode || hasBatchSelection;
  const selectedRecord = React.useMemo(
    () => photos.find((record) => record.photo.id === selectedPhotoId) ?? null,
    [photos, selectedPhotoId]
  );
  const pendingRemovalRecord = React.useMemo(
    () => photos.find((record) => record.photo.id === pendingRemovalPhotoId) ?? null,
    [pendingRemovalPhotoId, photos]
  );
  const storySections = React.useMemo(() => buildMemoryStorySections(photos), [photos]);

  React.useEffect(() => {
    setDraftName(memory.name);
  }, [memory.name]);

  React.useEffect(() => {
    setDraftDescription(descriptionMarkdown);
  }, [descriptionMarkdown]);

  React.useEffect(() => {
    onClearBatchSelection();
    setSelectionMode(false);
  }, [memory.id]);

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
                    <button
                      className="mt-2 block rounded-[18px] text-left font-['Space_Grotesk','IBM_Plex_Sans',sans-serif] text-4xl font-semibold tracking-tight text-stone-950 transition hover:text-amber-700 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-amber-300"
                      onClick={() => setRenaming(true)}
                      type="button"
                    >
                      {memory.name}
                    </button>
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
                  <IconButton
                    icon={<Sparkles className="h-4 w-4" />}
                    label="AI Suggestions"
                    onClick={() => setAiSuggestionsOpen(true)}
                    size="sm"
                    variant="ghost"
                  />
                  <IconButton
                    icon={<Trash2 className="h-4 w-4" />}
                    label="Delete Memory"
                    onClick={() => setDeleteConfirmOpen(true)}
                    size="sm"
                    variant="ghost"
                  />
                </div>
              </div>

              <div className="space-y-3">
                <p className="text-[11px] font-semibold uppercase tracking-[0.22em] text-stone-500">Description</p>
                <button
                  className="w-full rounded-[24px] border border-stone-200 bg-white px-5 py-4 text-left shadow-sm transition hover:border-stone-300 hover:bg-stone-50"
                  onClick={() => setEditingDescription(true)}
                  type="button"
                >
                  {hasDescription ? (
                    <div className="prose-memory text-sm leading-7 text-stone-600" data-color-mode="light">
                      <React.Suspense fallback={<p>{descriptionMarkdown}</p>}>
                        <MarkdownPreview source={descriptionMarkdown} />
                      </React.Suspense>
                    </div>
                  ) : (
                    <p className="text-sm leading-7 text-stone-600">Add context, story beats, and notes for this memory.</p>
                  )}
                </button>
              </div>

            </div>
          </div>
        </div>
      </Panel>

      <Dialog onOpenChange={setAiSuggestionsOpen} open={aiSuggestionsOpen}>
        <DialogContent className="flex items-center justify-center p-6">
          <DialogTitle className="sr-only">AI suggestions for {memory.name}</DialogTitle>
          <DialogDescription className="sr-only">
            Generate and apply optional AI suggestions for this memory title, description, and tags.
          </DialogDescription>
          <div className="relative w-full max-w-3xl rounded-[28px] border border-stone-200 bg-white p-6 shadow-2xl">
            <IconButton
              className="absolute right-4 top-4"
              icon={<X className="h-4 w-4" />}
              label="Close AI suggestions"
              onClick={() => setAiSuggestionsOpen(false)}
              size="sm"
              variant="ghost"
            />
            <div className="mb-5 pr-12">
              <div className="flex flex-wrap items-center gap-2">
                <p className="text-[11px] font-semibold uppercase tracking-[0.22em] text-stone-500">AI Suggestions</p>
                <Badge tone={memory.aiStatus === "completed" ? "success" : memory.aiStatus === "failed" ? "danger" : "neutral"}>
                  {memory.aiStatus}
                </Badge>
              </div>
              <div>
                <h2 className="mt-2 font-['Space_Grotesk','IBM_Plex_Sans',sans-serif] text-2xl font-semibold tracking-tight text-stone-950">
                  {memory.name}
                </h2>
                <p className="mt-2 max-w-xl text-sm leading-6 text-stone-500">
                  Generate optional title and description suggestions. Nothing is applied until you choose it.
                </p>
              </div>
            </div>

            <div className="flex flex-col gap-4">
              <div className="flex flex-wrap items-center justify-between gap-3 rounded-[20px] border border-stone-200 bg-stone-50/70 px-4 py-3">
                <p className="text-sm leading-6 text-stone-600">
                  Suggestions use the photos already inside this memory.
                </p>
                <Button
                  disabled={!onEnrichSemantic || isEnrichingSemantic || photos.length === 0}
                  onClick={() => void onEnrichSemantic?.(memory.id)}
                  size="sm"
                  variant="outline"
                >
                  <Sparkles className="h-4 w-4" />
                  {isEnrichingSemantic ? "Generating..." : "Generate Suggestions"}
                </Button>
              </div>

              {memory.generatedName || memory.generatedDescription || memory.generatedLabels.length > 0 ? (
                <div className="space-y-4 rounded-[20px] border border-stone-200 bg-white px-4 py-4 shadow-sm">
                  {memory.generatedName ? (
                    <div className="space-y-2">
                      <p className="text-[11px] font-semibold uppercase tracking-[0.18em] text-stone-500">Suggested Title</p>
                      <div className="flex flex-wrap items-center justify-between gap-3">
                        <p className="text-lg font-semibold text-stone-950">{memory.generatedName}</p>
                        <Button
                          disabled={memory.generatedName === memory.name}
                          onClick={() => void onRenameMemory(memory.id, memory.generatedName as string)}
                          size="sm"
                          variant="outline"
                        >
                          Apply Title
                        </Button>
                      </div>
                    </div>
                  ) : null}

                  {memory.generatedDescription ? (
                    <div className="space-y-2">
                      <p className="text-[11px] font-semibold uppercase tracking-[0.18em] text-stone-500">Suggested Summary</p>
                      <p className="text-sm leading-7 text-stone-600">{memory.generatedDescription}</p>
                      <div>
                        <Button
                          disabled={memory.generatedDescription === memory.description}
                          onClick={() => void onSaveDescription(memory.id, memory.generatedDescription as string)}
                          size="sm"
                          variant="outline"
                        >
                          Use as Description
                        </Button>
                      </div>
                    </div>
                  ) : null}

                  {memory.generatedLabels.length > 0 ? (
                    <div className="space-y-2">
                      <p className="text-[11px] font-semibold uppercase tracking-[0.18em] text-stone-500">AI Tags</p>
                      <div className="flex flex-wrap gap-2">
                        {memory.generatedLabels.map((label) => (
                          <Badge key={label} tone="neutral">
                            {label}
                          </Badge>
                        ))}
                      </div>
                    </div>
                  ) : null}
                </div>
              ) : memory.aiStatus === "failed" ? (
                <p className="text-sm leading-6 text-rose-600">{memory.aiError ?? "AI story generation failed."}</p>
              ) : (
                <p className="text-sm leading-6 text-stone-500">
                  No suggestions generated yet.
                </p>
              )}
            </div>
          </div>
        </DialogContent>
      </Dialog>

      <MemoryStoryBoard
        onOpenSection={(photoId) => {
          onSelectPhoto(photoId);
          onOpenDetail(photoId);
        }}
        sections={storySections}
      />

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
          <DialogTitle className="sr-only">Edit memory description</DialogTitle>
          <DialogDescription className="sr-only">
            Edit the rich text description for {memory.name}.
          </DialogDescription>
          <div className="w-full max-w-4xl rounded-[28px] border border-stone-200 bg-white p-6 shadow-2xl">
            <div className="mb-5 flex items-start justify-between gap-4">
              <div>
                <p className="text-[11px] font-semibold uppercase tracking-[0.22em] text-stone-500">Description</p>
                <h2 className="mt-2 font-['Space_Grotesk','IBM_Plex_Sans',sans-serif] text-2xl font-semibold tracking-tight text-stone-950">
                  {memory.name}
                </h2>
              </div>
              <Button onClick={() => setEditingDescription(false)} size="sm" variant="ghost">
                Close
              </Button>
            </div>
            <div className="mb-4 rounded-[20px] border border-stone-200 bg-stone-50/70 px-4 py-3">
              <div className="flex flex-wrap items-center justify-between gap-3">
                <p className="text-sm leading-6 text-stone-600">
                  {draftDescription.trim() ? "Use AI to refine the current description draft." : "Use AI to generate a starting description from this memory."}
                </p>
                <Button
	                  disabled={!onEnrichSemantic || isEnrichingSemantic || photos.length === 0}
                  onClick={() => void onEnrichSemantic?.(memory.id, { description: draftDescription })}
                  size="sm"
                  variant="outline"
                >
                  <Sparkles className="h-4 w-4" />
                  {isEnrichingSemantic ? "Generating..." : draftDescription.trim() ? "Optimize Description" : "Generate Description"}
                </Button>
              </div>
              {memory.generatedDescription ? (
                <div className="mt-3 space-y-2 rounded-[16px] border border-stone-200 bg-white p-3">
                  <p className="text-[11px] font-semibold uppercase tracking-[0.18em] text-stone-500">AI suggestion</p>
                  <p className="text-sm leading-6 text-stone-600">{memory.generatedDescription}</p>
                  <Button onClick={() => setDraftDescription(memory.generatedDescription ?? "")} size="sm" variant="outline">
                    Use suggestion
                  </Button>
                </div>
              ) : null}
            </div>
	            <MemoryDescriptionEditor
	              dirty={draftDescription !== descriptionMarkdown}
	              onChange={setDraftDescription}
              onSave={async (serializedDescription) => {
                await onSaveDescription(memory.id, serializedDescription);
                setEditingDescription(false);
              }}
              value={draftDescription}
            />
          </div>
        </DialogContent>
      </Dialog>

      <Dialog onOpenChange={setRenaming} open={renaming}>
        <DialogContent className="flex items-center justify-center p-6">
          <DialogTitle className="sr-only">Edit memory title</DialogTitle>
          <DialogDescription className="sr-only">
            Update the title for {memory.name}.
          </DialogDescription>
          <div className="w-full max-w-xl rounded-[28px] border border-stone-200 bg-white p-6 shadow-2xl">
            <div className="mb-5 flex items-start justify-between gap-4">
              <div>
                <p className="text-[11px] font-semibold uppercase tracking-[0.22em] text-stone-500">Title</p>
                <h2 className="mt-2 font-['Space_Grotesk','IBM_Plex_Sans',sans-serif] text-2xl font-semibold tracking-tight text-stone-950">
                  Update title
                </h2>
              </div>
              <Button onClick={() => setRenaming(false)} size="sm" variant="ghost">
                Close
              </Button>
            </div>
            <div className="space-y-4">
              <div className="rounded-[20px] border border-stone-200 bg-stone-50/70 px-4 py-3">
                <div className="flex flex-wrap items-center justify-between gap-3">
                  <p className="text-sm leading-6 text-stone-600">
                    {draftName.trim() ? "Use AI to refine the current title draft." : "Use AI to generate a title from this memory."}
                  </p>
                  <Button
                    disabled={!onEnrichSemantic || isEnrichingSemantic || photos.length === 0}
                    onClick={() => void onEnrichSemantic?.(memory.id, { name: draftName })}
                    size="sm"
                    variant="outline"
                  >
                    <Sparkles className="h-4 w-4" />
                    {isEnrichingSemantic ? "Generating..." : draftName.trim() ? "Optimize Title" : "Generate Title"}
                  </Button>
                </div>
                {memory.generatedName ? (
                  <div className="mt-3 flex flex-wrap items-center justify-between gap-3 rounded-[16px] border border-stone-200 bg-white p-3">
                    <div>
                      <p className="text-[11px] font-semibold uppercase tracking-[0.18em] text-stone-500">AI suggestion</p>
                      <p className="mt-1 text-base font-semibold text-stone-950">{memory.generatedName}</p>
                    </div>
                    <Button onClick={() => setDraftName(memory.generatedName ?? "")} size="sm" variant="outline">
                      Use suggestion
                    </Button>
                  </div>
                ) : null}
              </div>
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
                  onClick={async () => {
                    await onRenameMemory(memory.id, draftName.trim());
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
          <div className="flex items-center gap-2">
            <Button
              onClick={() => {
                if (isSelecting) {
                  onClearBatchSelection();
                  setSelectionMode(false);
                  return;
                }

                setSelectionMode(true);
              }}
              size="sm"
              variant={isSelecting ? "accent" : "outline"}
            >
              {isSelecting ? "Done" : "Select"}
            </Button>
            <Badge tone="neutral">{photos.length} visible</Badge>
          </div>
        </div>
        <div className="p-5">
          {hasBatchSelection ? (
            <div className="mb-4 flex flex-wrap items-center justify-between gap-3 rounded-[24px] border border-rose-200 bg-rose-50 px-4 py-3">
              <div className="flex items-center gap-2">
                <Badge tone="danger">{selectedPhotoIds.length} selected</Badge>
                <p className="text-sm font-medium text-rose-950">Batch actions for photos in this memory</p>
              </div>
              <div className="flex items-center gap-2">
                <Button
                  onClick={() => {
                    setRemoveSelectedConfirmOpen(true);
                  }}
                  size="sm"
                  variant="accent"
                >
                  <Trash2 className="h-4 w-4" />
                  Remove Selected
                </Button>
                <Button onClick={onClearBatchSelection} size="sm" variant="outline">
                  Clear Selection
                </Button>
              </div>
            </div>
          ) : null}
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
                  batchSelected={selectedPhotoIds.includes(record.photo.id)}
                  key={record.photo.id}
                  onOpenDetail={() => {
                    if (!isSelecting) {
                      onOpenDetail(record.photo.id);
                    }
                  }}
                  onSecondaryAction={(photoId) => setPendingRemovalPhotoId(photoId)}
                  onSelect={() => {
                    if (isSelecting) {
                      onToggleBatchSelect(record.photo.id);
                      return;
                    }

                    onSelectPhoto(record.photo.id);
                  }}
                  {...(isSelecting ? { onToggleBatchSelect } : {})}
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

      <Dialog onOpenChange={setDeleteConfirmOpen} open={deleteConfirmOpen}>
        <DialogContent className="flex items-center justify-center p-6">
          <DialogTitle className="sr-only">Delete memory</DialogTitle>
          <DialogDescription className="sr-only">
            Confirm deleting the memory {memory.name} while keeping the underlying photos in the library.
          </DialogDescription>
          <div className="w-full max-w-lg rounded-[28px] border border-stone-200 bg-white p-6 shadow-2xl">
            <div className="space-y-3">
              <p className="text-[11px] font-semibold uppercase tracking-[0.22em] text-stone-500">Delete Memory</p>
              <h2 className="font-['Space_Grotesk','IBM_Plex_Sans',sans-serif] text-2xl font-semibold tracking-tight text-stone-950">
                Delete {memory.name}?
              </h2>
              <p className="text-sm leading-6 text-stone-500">
                This removes the memory container and its curated grouping. Photos stay in the library, but the memory itself will be deleted.
              </p>
            </div>
            <div className="mt-6 flex justify-end gap-2">
              <Button onClick={() => setDeleteConfirmOpen(false)} variant="ghost">
                Cancel
              </Button>
              <Button
                onClick={async () => {
                  await onDeleteMemory(memory.id);
                  setDeleteConfirmOpen(false);
                }}
                variant="accent"
              >
                Delete Memory
              </Button>
            </div>
          </div>
        </DialogContent>
      </Dialog>

      <Dialog onOpenChange={setRemoveSelectedConfirmOpen} open={removeSelectedConfirmOpen}>
        <DialogContent className="flex items-center justify-center p-6">
          <DialogTitle className="sr-only">Remove selected photos</DialogTitle>
          <DialogDescription className="sr-only">
            Confirm removing the currently selected photos from {memory.name}.
          </DialogDescription>
          <div className="w-full max-w-lg rounded-[28px] border border-stone-200 bg-white p-6 shadow-2xl">
            <div className="space-y-3">
              <p className="text-[11px] font-semibold uppercase tracking-[0.22em] text-stone-500">Remove Selected</p>
              <h2 className="font-['Space_Grotesk','IBM_Plex_Sans',sans-serif] text-2xl font-semibold tracking-tight text-stone-950">
                Remove {selectedPhotoIds.length} selected photo{selectedPhotoIds.length === 1 ? "" : "s"} from {memory.name}?
              </h2>
              <p className="text-sm leading-6 text-stone-500">
                This only removes the selected photos from this memory. The original media stays in your library and can still belong to other memories.
              </p>
            </div>
            <div className="mt-6 flex justify-end gap-2">
              <Button onClick={() => setRemoveSelectedConfirmOpen(false)} variant="ghost">
                Cancel
              </Button>
              <Button
                onClick={async () => {
                  await onRemoveSelection(memory.id, selectedPhotoIds);
                  setSelectionMode(false);
                  setRemoveSelectedConfirmOpen(false);
                }}
                variant="accent"
              >
                Remove Selected
              </Button>
            </div>
          </div>
        </DialogContent>
      </Dialog>

      <Dialog onOpenChange={(open) => !open && setPendingRemovalPhotoId(null)} open={Boolean(pendingRemovalPhotoId)}>
        <DialogContent className="flex items-center justify-center p-6">
          <DialogTitle className="sr-only">Remove photo from memory</DialogTitle>
          <DialogDescription className="sr-only">
            Confirm removing the selected photo from {memory.name}.
          </DialogDescription>
          <div className="w-full max-w-lg rounded-[28px] border border-stone-200 bg-white p-6 shadow-2xl">
            <div className="space-y-3">
              <p className="text-[11px] font-semibold uppercase tracking-[0.22em] text-stone-500">Remove Photo</p>
              <h2 className="font-['Space_Grotesk','IBM_Plex_Sans',sans-serif] text-2xl font-semibold tracking-tight text-stone-950">
                Remove this photo from {memory.name}?
              </h2>
              <p className="text-sm leading-6 text-stone-500">
                {pendingRemovalRecord
                  ? `${pendingRemovalRecord.photo.path.split("/").at(-1)} will be removed from this memory only.`
                  : "This removes the photo from the memory only."}
              </p>
            </div>
            <div className="mt-6 flex justify-end gap-2">
              <Button onClick={() => setPendingRemovalPhotoId(null)} variant="ghost">
                Cancel
              </Button>
              <Button
                onClick={async () => {
                  if (pendingRemovalPhotoId) {
                    await onRemovePhoto(memory.id, pendingRemovalPhotoId);
                  }
                  setPendingRemovalPhotoId(null);
                }}
                variant="accent"
              >
                Remove Photo
              </Button>
            </div>
          </div>
        </DialogContent>
      </Dialog>
    </div>
  );
}
