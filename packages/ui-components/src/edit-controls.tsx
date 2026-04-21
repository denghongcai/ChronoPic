import { CalendarClock, Tags, Undo2 } from "lucide-react";

import { Button } from "./button.js";
import { Input } from "./input.js";
import { Label } from "./label.js";
import { TagInput } from "./tag-input.js";

export interface EditControlsProps {
  aiEnabled?: boolean;
  aiStatus?: string;
  isEnrichingSemantic?: boolean;
  draftTags: string[];
  draftCaption: string;
  draftDatetime: string;
  onTagsChange: (tags: string[]) => void;
  onCaptionChange: (caption: string) => void;
  onDatetimeChange: (value: string) => void;
  onSaveTags: () => void;
  onSaveCaption: () => void;
  onSaveDatetime: () => void;
  onEnrichSemantic?: () => void;
  onRollback: () => void;
}

export function EditControls(props: EditControlsProps) {
  return (
    <div className="grid gap-4">
      {props.aiEnabled ? (
        <div className="grid gap-2">
          <Button className="w-full" disabled={props.isEnrichingSemantic} onClick={props.onEnrichSemantic} variant="outline" size="sm">
            {props.isEnrichingSemantic ? "Generating AI Metadata..." : "Generate AI Metadata"}
          </Button>
          <p className="text-xs text-stone-500">AI status: {props.aiStatus ?? "disabled"}</p>
        </div>
      ) : null}

      <div className="space-y-1.5">
        <Label>Name</Label>
        <Input
          placeholder="Photo name or caption..."
          value={props.draftCaption}
          onChange={(e) => props.onCaptionChange(e.target.value)}
        />
      </div>
      <Button className="w-full" onClick={props.onSaveCaption} variant="secondary" size="sm">
        Save Name
      </Button>

      <div className="space-y-1.5">
        <Label>Tags</Label>
        <TagInput
          value={props.draftTags}
          onChange={props.onTagsChange}
          placeholder="Add tags..."
        />
      </div>
      <Button className="w-full" onClick={props.onSaveTags} variant="accent" size="sm">
        <Tags className="h-4 w-4" />
        Save Tags
      </Button>

      <div className="space-y-1.5">
        <Label>Datetime</Label>
        <Input
          type="datetime-local"
          value={props.draftDatetime}
          onChange={(e) => props.onDatetimeChange(e.target.value)}
        />
      </div>
      <div className="grid gap-2 sm:grid-cols-2">
        <Button onClick={props.onSaveDatetime} variant="secondary" size="sm">
          <CalendarClock className="h-4 w-4" />
          Save Datetime
        </Button>
        <Button onClick={props.onRollback} variant="outline" size="sm">
          <Undo2 className="h-4 w-4" />
          Rollback Latest
        </Button>
      </div>
    </div>
  );
}
