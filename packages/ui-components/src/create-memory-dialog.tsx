import * as React from "react";
import { FolderPlus } from "lucide-react";

import { Button } from "./button.js";
import { Dialog, DialogClose, DialogContent, DialogDescription, DialogOverlay, DialogPortal, DialogTitle } from "./dialog.js";
import { Input } from "./input.js";
import { useI18n } from "./i18n-provider.js";
import { Label } from "./label.js";

export interface CreateMemoryDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onConfirm: (name: string) => void | Promise<void>;
}

export function CreateMemoryDialog({ open, onOpenChange, onConfirm }: CreateMemoryDialogProps) {
  const { t } = useI18n();
  const [name, setName] = React.useState("");
  const [submitting, setSubmitting] = React.useState(false);

  React.useEffect(() => {
    if (open) {
      setName("");
      setSubmitting(false);
    }
  }, [open]);

  async function handleConfirm() {
    const trimmed = name.trim();
    if (!trimmed) return;
    setSubmitting(true);

    try {
      await onConfirm(trimmed);
      onOpenChange(false);
    } catch {
      // The caller surfaces the actual failure message; keep the dialog open for correction/retry.
    } finally {
      setSubmitting(false);
    }
  }

  function handleKeyDown(e: React.KeyboardEvent<HTMLInputElement>) {
    if (e.key === "Enter") {
      e.preventDefault();
      void handleConfirm();
    }
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogPortal>
        <DialogOverlay />
        <DialogContent className="fixed inset-0 z-50 flex items-center justify-center outline-none">
          <div className="flex w-full max-w-sm flex-col gap-5 rounded-3xl border border-stone-200/80 bg-white p-6 shadow-xl">
            <div className="flex items-center gap-3">
              <div className="flex h-10 w-10 items-center justify-center rounded-2xl bg-amber-50 text-amber-700">
                <FolderPlus className="h-5 w-5" />
              </div>
              <div>
                <DialogTitle className="text-base font-semibold text-stone-950">{t("memories.createDialogTitle")}</DialogTitle>
                <DialogDescription className="mt-0.5 text-sm text-stone-500">
                  {t("memories.createDialogDescription")}
                </DialogDescription>
              </div>
            </div>

            <div className="space-y-1.5">
              <Label htmlFor="memory-name">{t("memories.nameLabel")}</Label>
              <Input
                id="memory-name"
                placeholder={t("memories.namePlaceholder")}
                value={name}
                onChange={(e) => setName(e.target.value)}
                onKeyDown={handleKeyDown}
                autoFocus
              />
            </div>

            <div className="flex justify-end gap-2.5">
              <DialogClose asChild>
                <Button variant="outline" type="button">{t("actions.cancel")}</Button>
              </DialogClose>
              <Button
                onClick={() => void handleConfirm()}
                disabled={!name.trim() || submitting}
                variant="accent"
                type="button"
              >
                {t("actions.create")}
              </Button>
            </div>
          </div>
        </DialogContent>
      </DialogPortal>
    </Dialog>
  );
}
