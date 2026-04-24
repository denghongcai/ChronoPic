import { Node } from "@tiptap/core";
import { EditorContent, useEditor } from "@tiptap/react";
import * as React from "react";

import { Button } from "./button.js";
import { Label } from "./label.js";
import { cn } from "./lib/cn.js";
import { getMemoryDescriptionHtml } from "./lib/memory-description.js";

const DocumentNode = Node.create({
  name: "doc",
  topNode: true,
  content: "block+",
});

const ParagraphNode = Node.create({
  name: "paragraph",
  group: "block",
  content: "text*",
  parseHTML() {
    return [{ tag: "p" }];
  },
  renderHTML({ HTMLAttributes }) {
    return ["p", HTMLAttributes, 0];
  },
});

const TextNode = Node.create({
  name: "text",
  group: "inline",
});

export interface MemoryDescriptionEditorProps {
  value: string | null;
  onSave: (serializedBlocks: string) => void;
}

export function MemoryDescriptionEditor({ value, onSave }: MemoryDescriptionEditorProps) {
  const [isDirty, setIsDirty] = React.useState(false);
  const initialHtml = React.useMemo(() => getMemoryDescriptionHtml(value), [value]);
  const editor = useEditor(
    {
      extensions: [DocumentNode, ParagraphNode, TextNode],
      content: initialHtml,
      editorProps: {
        attributes: {
          class: "min-h-40 px-4 py-3 text-sm leading-7 text-stone-700 outline-none",
        },
      },
      onUpdate: () => setIsDirty(true),
    },
    [initialHtml]
  );

  React.useEffect(() => {
    setIsDirty(false);
  }, [value]);

  function handleSave() {
    if (!editor) {
      return;
    }

    const serialized = editor.getHTML();
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
        {editor ? <EditorContent editor={editor} /> : null}
      </div>
    </div>
  );
}
