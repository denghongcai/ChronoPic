import type { LibrarySnapshot } from "@chronopic/domain";

import { Dialog, DialogContent, DialogDescription, DialogTitle } from "./dialog.js";
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
        <DialogTitle className="sr-only">Library settings</DialogTitle>
        <DialogDescription className="sr-only">
          Manage library folders, scan status, and indexing actions.
        </DialogDescription>
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
