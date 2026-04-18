import { BlockNoteViewRaw as BlockNoteView, useCreateBlockNote } from "@blocknote/react";
import * as React from "react";

import { Button } from "./button.js";
import { Label } from "./label.js";
import { cn } from "./lib/cn.js";
import { parseMemoryBlocks } from "./lib/memory-description.js";

export interface MemoryDescriptionEditorProps {
  value: string | null;
  onSave: (serializedBlocks: string) => void;
}

export function MemoryDescriptionEditor({ value, onSave }: MemoryDescriptionEditorProps) {
  const initialBlocks = React.useMemo(() => parseMemoryBlocks(value), [value]);
  const editor = useCreateBlockNote({ initialContent: initialBlocks as never }, [value]);
  const [isDirty, setIsDirty] = React.useState(false);

  React.useEffect(() => {
    setIsDirty(false);
  }, [value]);

  function handleSave() {
    const serialized = JSON.stringify(editor.topLevelBlocks);
    onSave(serialized);
    setIsDirty(false);
  }

  return (
    <div className="space-y-3">
      <div className="flex items-center justify-between">
        <Label>Description</Label>
        <Button disabled={!isDirty} onClick={handleSave} size="sm" variant="accent">
          Save Description
        </Button>
      </div>
      <div className={cn("overflow-hidden rounded-[24px] border border-stone-200 bg-white shadow-sm")}>
        <BlockNoteView
          editor={editor as never}
          onChange={() => setIsDirty(true)}
          theme="light"
        />
      </div>
    </div>
  );
}
