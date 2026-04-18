import { CalendarClock, Tags, Undo2 } from "lucide-react";

import { Button, FieldLabel, Input, Textarea } from "./primitives.js";

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
      <label className="space-y-2">
        <FieldLabel>Tags</FieldLabel>
        <Textarea onChange={(event) => props.onTagsChange(event.target.value)} rows={3} value={props.draftTags} />
      </label>
      <Button className="w-full" onClick={props.onSaveTags} variant="accent">
        <Tags className="h-4 w-4" />
        Save Tags
      </Button>
      <label className="space-y-2">
        <FieldLabel>Datetime</FieldLabel>
        <Input onChange={(event) => props.onDatetimeChange(event.target.value)} type="datetime-local" value={props.draftDatetime} />
      </label>
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
