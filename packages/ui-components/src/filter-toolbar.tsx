import { SlidersHorizontal } from "lucide-react";
import type { ChangeEvent } from "react";

import type { PhotoFilter, PhotoFilterPatch } from "@chronopic/domain";

import { Badge } from "./badge.js";
import { Button } from "./button.js";
import { useI18n } from "./i18n-provider.js";
import { Input } from "./input.js";
import { Label } from "./label.js";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "./select.js";

const ALL_VALUE = "__all__";
const AI_READY_VALUE = "__ai_completed__";
const AI_PENDING_VALUE = "__ai_pending__";
const AI_FAILED_VALUE = "__ai_failed__";
const AI_PROCESSING_VALUE = "__ai_processing__";

function currentSortBy(value: PhotoFilter["sortBy"]): NonNullable<PhotoFilter["sortBy"]> {
  return value ?? "datetime";
}

function currentSortDirection(value: PhotoFilter["sortDirection"]): NonNullable<PhotoFilter["sortDirection"]> {
  return value ?? "desc";
}

function readInputValue(event: ChangeEvent<HTMLInputElement | HTMLTextAreaElement>): string {
  return event.target.value;
}

function currentAIStatusValue(value: PhotoFilter["aiStatus"]): string {
  if (Array.isArray(value)) {
    return value[0] ?? ALL_VALUE;
  }

  return value ?? ALL_VALUE;
}

function toAIStatusFilter(value: string): PhotoFilter["aiStatus"] | undefined {
  if (value === ALL_VALUE) {
    return undefined;
  }

  if (value === AI_READY_VALUE) {
    return "completed";
  }

  if (value === AI_PENDING_VALUE) {
    return "pending";
  }

  if (value === AI_PROCESSING_VALUE) {
    return "processing";
  }

  if (value === AI_FAILED_VALUE) {
    return "failed";
  }

  return undefined;
}

function FilterToggle({ active, label, onClick }: { active: boolean; label: string; onClick: () => void }) {
  return (
    <Button onClick={onClick} size="sm" type="button" variant={active ? "accent" : "secondary"}>
      {label}
    </Button>
  );
}

export interface FilterToolbarProps {
  filter: PhotoFilter;
  onChange: (patch: PhotoFilterPatch) => void;
}

export function FilterToolbar(props: FilterToolbarProps) {
  const { t } = useI18n();

  return (
    <div className="space-y-4 rounded-[28px] border border-stone-200/70 bg-white/75 p-5 shadow-[0_20px_50px_-36px_rgba(15,23,42,0.24)] backdrop-blur-sm">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div className="space-y-1">
          <p className="text-[11px] font-semibold uppercase tracking-[0.22em] text-stone-400">{t("filter.title")}</p>
          <p className="text-sm text-stone-500">{t("filter.description")}</p>
        </div>
        <Badge tone="neutral">
          <SlidersHorizontal className="h-3.5 w-3.5" />
          {t("filter.structuredQuery")}
        </Badge>
      </div>
      <div className="grid gap-4 xl:grid-cols-[repeat(2,minmax(0,1fr))_repeat(3,minmax(0,0.8fr))]">
        <div className="space-y-2 xl:col-span-2">
          <Label>{t("filter.quickFilters")}</Label>
          <div className="flex flex-wrap gap-2">
            <FilterToggle
              active={!props.filter.mimePrefix}
              label={t("filter.all")}
              onClick={() => props.onChange({ mimePrefix: undefined, offset: 0 })}
            />
            <FilterToggle
              active={props.filter.mimePrefix === "image/"}
              label={t("filter.photo")}
              onClick={() => props.onChange({ mimePrefix: props.filter.mimePrefix === "image/" ? undefined : "image/", offset: 0 })}
            />
            <FilterToggle
              active={props.filter.mimePrefix === "video/"}
              label={t("filter.video")}
              onClick={() => props.onChange({ mimePrefix: props.filter.mimePrefix === "video/" ? undefined : "video/", offset: 0 })}
            />
            <FilterToggle
              active={Boolean(props.filter.favorite)}
              label={t("filter.favorites")}
              onClick={() => props.onChange({ favorite: props.filter.favorite ? undefined : true, offset: 0 })}
            />
            <FilterToggle
              active={Boolean(props.filter.hasGps)}
              label={t("filter.withGps")}
              onClick={() => props.onChange({ hasGps: props.filter.hasGps ? undefined : true, offset: 0 })}
            />
          </div>
        </div>
        <div className="space-y-2">
          <Label>{t("filter.type")}</Label>
          <Select
            onValueChange={(value) => props.onChange({ mimePrefix: value === ALL_VALUE ? undefined : value, offset: 0 })}
            value={props.filter.mimePrefix ?? ALL_VALUE}
          >
            <SelectTrigger>
              <SelectValue placeholder={t("filter.all")} />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value={ALL_VALUE}>{t("filter.all")}</SelectItem>
              <SelectItem value="image/">{t("filter.images")}</SelectItem>
              <SelectItem value="video/">{t("filter.videos")}</SelectItem>
            </SelectContent>
          </Select>
        </div>
        <div className="space-y-2">
          <Label>{t("filter.tag")}</Label>
          <Input
            onChange={(event) => props.onChange({ tag: readInputValue(event) || undefined, offset: 0 })}
            placeholder={t("filter.addTag")}
            type="text"
            value={props.filter.tag ?? ""}
          />
        </div>
        <div className="space-y-2">
          <Label>{t("filter.sort")}</Label>
          <Select
            onValueChange={(value) => props.onChange({ sortBy: value as NonNullable<PhotoFilter["sortBy"]>, offset: 0 })}
            value={currentSortBy(props.filter.sortBy)}
          >
            <SelectTrigger>
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="datetime">{t("filter.sort.datetime")}</SelectItem>
              <SelectItem value="updatedAt">{t("filter.sort.updated")}</SelectItem>
              <SelectItem value="path">{t("filter.sort.path")}</SelectItem>
            </SelectContent>
          </Select>
        </div>
        <div className="space-y-2">
          <Label>{t("filter.direction")}</Label>
          <Select
            onValueChange={(value) =>
              props.onChange({
                sortDirection: value as NonNullable<PhotoFilter["sortDirection"]>,
                offset: 0
              })
            }
            value={currentSortDirection(props.filter.sortDirection)}
          >
            <SelectTrigger>
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="desc">{t("filter.direction.desc")}</SelectItem>
              <SelectItem value="asc">{t("filter.direction.asc")}</SelectItem>
            </SelectContent>
          </Select>
        </div>
        <div className="space-y-2">
          <Label>{t("filter.status")}</Label>
          <div className="flex flex-wrap gap-2">
            <FilterToggle
              active={Boolean(props.filter.indexed)}
              label={t("filter.indexed")}
              onClick={() => props.onChange({ indexed: props.filter.indexed ? undefined : true, offset: 0 })}
            />
            <FilterToggle
              active={Boolean(props.filter.hasError)}
              label={t("filter.errors")}
              onClick={() => props.onChange({ hasError: props.filter.hasError ? undefined : true, offset: 0 })}
            />
          </div>
        </div>
        <div className="space-y-2">
          <Label>{t("filter.ai")}</Label>
          <Select
            onValueChange={(value) =>
              props.onChange({
                aiStatus: toAIStatusFilter(value),
                offset: 0,
              })
            }
            value={currentAIStatusValue(props.filter.aiStatus)}
          >
            <SelectTrigger>
              <SelectValue placeholder={t("filter.allAiStates")} />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value={ALL_VALUE}>{t("filter.allAiStates")}</SelectItem>
              <SelectItem value={AI_READY_VALUE}>{t("filter.aiReady")}</SelectItem>
              <SelectItem value={AI_PENDING_VALUE}>{t("filter.needsAi")}</SelectItem>
              <SelectItem value={AI_PROCESSING_VALUE}>{t("filter.processing")}</SelectItem>
              <SelectItem value={AI_FAILED_VALUE}>{t("filter.aiFailed")}</SelectItem>
            </SelectContent>
          </Select>
        </div>
      </div>
    </div>
  );
}
