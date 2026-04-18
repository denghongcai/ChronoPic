import type { LibrarySnapshot } from "@chronopic/domain";

import { Dialog, DialogContent } from "./dialog.js";
import { LibrarySidebar } from "./library-sidebar.js";

export interface LibraryDialogProps {
  open: boolean;
  snapshot: LibrarySnapshot;
  isScanning: boolean;
  onClose: () => void;
  onAddLibrary: () => void;
  onScanAll: () => void;
}

export function LibraryDialog({
  open,
  snapshot,
  isScanning,
  onClose,
  onAddLibrary,
  onScanAll,
}: LibraryDialogProps) {
  return (
    <Dialog modal onOpenChange={(o) => (!o ? onClose() : undefined)} open={open}>
      <DialogContent className="max-w-2xl p-0">
        <LibrarySidebar
          isScanning={isScanning}
          onAddLibrary={onAddLibrary}
          onScanAll={onScanAll}
          snapshot={snapshot}
        />
      </DialogContent>
    </Dialog>
  );
}
