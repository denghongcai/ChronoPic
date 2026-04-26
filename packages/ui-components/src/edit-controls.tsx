import { CalendarClock, Tags, Undo2 } from "lucide-react";

import { Button } from "./button.js";
import { useI18n } from "./i18n-provider.js";
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
  const { t } = useI18n();

  return (
    <div className="grid gap-4">
      {props.aiEnabled ? (
        <div className="grid gap-2">
          <Button className="w-full" disabled={props.isEnrichingSemantic} onClick={props.onEnrichSemantic} variant="outline" size="sm">
            {props.isEnrichingSemantic ? t("edit.generatingAiMetadata") : t("edit.generateAiMetadata")}
          </Button>
          <p className="text-xs text-stone-500">{t("edit.aiStatus", { status: props.aiStatus ?? "disabled" })}</p>
        </div>
      ) : null}

      <div className="space-y-1.5">
        <Label>{t("edit.name")}</Label>
        <Input
          placeholder={t("edit.namePlaceholder")}
          value={props.draftCaption}
          onChange={(e) => props.onCaptionChange(e.target.value)}
        />
      </div>
      <Button className="w-full" onClick={props.onSaveCaption} variant="secondary" size="sm">
        {t("edit.saveName")}
      </Button>

      <div className="space-y-1.5">
        <Label>{t("edit.tags")}</Label>
        <TagInput
          value={props.draftTags}
          onChange={props.onTagsChange}
          placeholder={t("edit.addTags")}
        />
      </div>
      <Button className="w-full" onClick={props.onSaveTags} variant="accent" size="sm">
        <Tags className="h-4 w-4" />
        {t("edit.saveTags")}
      </Button>

      <div className="space-y-1.5">
        <Label>{t("edit.datetime")}</Label>
        <Input
          type="datetime-local"
          value={props.draftDatetime}
          onChange={(e) => props.onDatetimeChange(e.target.value)}
        />
      </div>
      <div className="grid gap-2 sm:grid-cols-2">
        <Button onClick={props.onSaveDatetime} variant="secondary" size="sm">
          <CalendarClock className="h-4 w-4" />
          {t("edit.saveDatetime")}
        </Button>
        <Button onClick={props.onRollback} variant="outline" size="sm">
          <Undo2 className="h-4 w-4" />
          {t("actions.rollbackLatest")}
        </Button>
      </div>
    </div>
  );
}
