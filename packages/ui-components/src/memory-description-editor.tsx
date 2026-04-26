import * as React from "react";

import { Button } from "./button.js";
import { useI18n } from "./i18n-provider.js";
import { Label } from "./label.js";
import { cn } from "./lib/cn.js";
import { getMemoryDescriptionMarkdown } from "./lib/memory-description.js";

type MarkdownEditorComponent = React.ComponentType<{
  autoFocus?: boolean;
  height?: number;
  onChange?: (value?: string) => void;
  preview?: "live" | "edit" | "preview";
  textareaProps?: React.TextareaHTMLAttributes<HTMLTextAreaElement>;
  value?: string;
}>;

const MarkdownEditor = React.lazy(async () => {
  const module = await import("@uiw/react-md-editor");
  return { default: module.default as unknown as MarkdownEditorComponent };
});

export interface MemoryDescriptionEditorProps {
  dirty?: boolean;
  value: string | null;
  onChange: (markdown: string) => void;
  onSave: (markdown: string) => void;
}

export function MemoryDescriptionEditor({ dirty = false, value, onChange, onSave }: MemoryDescriptionEditorProps) {
  const { t } = useI18n();
  const markdown = getMemoryDescriptionMarkdown(value);

  function handleSave() {
    onSave(markdown);
  }

  return (
    <div className="space-y-3">
      <div className="flex items-center justify-between">
        <Label>{t("memory.detail.description")}</Label>
        <Button disabled={!dirty} onClick={handleSave} size="sm" variant="accent">
          {t("memory.description.save")}
        </Button>
      </div>
      <div
        className={cn("overflow-hidden rounded-[24px] border border-stone-200 bg-white shadow-sm")}
        data-color-mode="light"
      >
        <React.Suspense fallback={<div className="min-h-40 px-4 py-3 text-sm text-stone-500">{t("memory.description.loadingEditor")}</div>}>
          <MarkdownEditor
            autoFocus
            height={360}
            onChange={(nextValue) => {
              const markdown = nextValue ?? "";
              onChange(markdown);
            }}
            preview="live"
            textareaProps={{
              placeholder: t("memory.description.placeholder"),
            }}
            value={markdown}
          />
        </React.Suspense>
      </div>
    </div>
  );
}
