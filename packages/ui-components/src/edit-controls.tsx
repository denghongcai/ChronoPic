import { CalendarClock, Tags, Undo2 } from "lucide-react";

import { Button } from "./button.js";
import { Input } from "./input.js";
import { Label } from "./label.js";
import { Textarea } from "./textarea.js";

export interface EditControlsProps {
  draftTags: string;
  draftDatetime: string;
  onTagsChange: (value: string) => void;
  onDatetimeChange: (value: string) => void;
  onSaveTags: () => void;
  onSaveDatetime: () => void;
  onRollback: () => void;
}

export function EditControls(props: EditControlsProps) {
  return (
    <div className="grid gap-4">
      <div className="space-y-2">
        <Label>Tags</Label>
        <Textarea onChange={(event) => props.onTagsChange(event.target.value)} rows={3} value={props.draftTags} />
      </div>
      <Button className="w-full" onClick={props.onSaveTags} variant="accent">
        <Tags className="h-4 w-4" />
        Save Tags
      </Button>
      <div className="space-y-2">
        <Label>Datetime</Label>
        <Input onChange={(event) => props.onDatetimeChange(event.target.value)} type="datetime-local" value={props.draftDatetime} />
      </div>
      <div className="grid gap-2 sm:grid-cols-2">
        <Button onClick={props.onSaveDatetime} variant="secondary">
          <CalendarClock className="h-4 w-4" />
          Save Datetime
        </Button>
        <Button onClick={props.onRollback} variant="outline">
          <Undo2 className="h-4 w-4" />
          Rollback Latest
        </Button>
      </div>
    </div>
  );
}
