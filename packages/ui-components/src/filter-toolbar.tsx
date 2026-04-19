import { SlidersHorizontal } from "lucide-react";
import type { ChangeEvent } from "react";

import type { PhotoFilter, PhotoFilterPatch } from "@chronopic/domain";

import { Badge } from "./badge.js";
import { Button } from "./button.js";
import { Input } from "./input.js";
import { Label } from "./label.js";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "./select.js";

const ALL_VALUE = "__all__";

function currentSortBy(value: PhotoFilter["sortBy"]): NonNullable<PhotoFilter["sortBy"]> {
  return value ?? "datetime";
}

function currentSortDirection(value: PhotoFilter["sortDirection"]): NonNullable<PhotoFilter["sortDirection"]> {
  return value ?? "desc";
}

function readInputValue(event: ChangeEvent<HTMLInputElement | HTMLTextAreaElement>): string {
  return event.target.value;
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
  return (
    <div className="space-y-4 rounded-[28px] border border-stone-200/70 bg-white/75 p-5 shadow-[0_20px_50px_-36px_rgba(15,23,42,0.24)] backdrop-blur-sm">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div className="space-y-1">
          <p className="text-[11px] font-semibold uppercase tracking-[0.22em] text-stone-400">Refine Results</p>
          <p className="text-sm text-stone-500">Search, sort, and narrow the current browse scope.</p>
        </div>
        <Badge tone="neutral">
          <SlidersHorizontal className="h-3.5 w-3.5" />
          Structured query
        </Badge>
      </div>
      <div className="grid gap-4 xl:grid-cols-[repeat(2,minmax(0,1fr))_repeat(3,minmax(0,0.8fr))]">
        <div className="space-y-2 xl:col-span-2">
          <Label>Quick Filters</Label>
          <div className="flex flex-wrap gap-2">
            <FilterToggle
              active={!props.filter.mimePrefix}
              label="All"
              onClick={() => props.onChange({ mimePrefix: undefined, offset: 0 })}
            />
            <FilterToggle
              active={props.filter.mimePrefix === "image/"}
              label="Photo"
              onClick={() => props.onChange({ mimePrefix: props.filter.mimePrefix === "image/" ? undefined : "image/", offset: 0 })}
            />
            <FilterToggle
              active={props.filter.mimePrefix === "video/"}
              label="Video"
              onClick={() => props.onChange({ mimePrefix: props.filter.mimePrefix === "video/" ? undefined : "video/", offset: 0 })}
            />
            <FilterToggle
              active={Boolean(props.filter.favorite)}
              label="Favorites"
              onClick={() => props.onChange({ favorite: props.filter.favorite ? undefined : true, offset: 0 })}
            />
            <FilterToggle
              active={Boolean(props.filter.hasGps)}
              label="With GPS"
              onClick={() => props.onChange({ hasGps: props.filter.hasGps ? undefined : true, offset: 0 })}
            />
          </div>
        </div>
        <div className="space-y-2">
          <Label>Type</Label>
          <Select
            onValueChange={(value) => props.onChange({ mimePrefix: value === ALL_VALUE ? undefined : value, offset: 0 })}
            value={props.filter.mimePrefix ?? ALL_VALUE}
          >
            <SelectTrigger>
              <SelectValue placeholder="All" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value={ALL_VALUE}>All</SelectItem>
              <SelectItem value="image/">Images</SelectItem>
              <SelectItem value="video/">Videos</SelectItem>
            </SelectContent>
          </Select>
        </div>
        <div className="space-y-2">
          <Label>Tag</Label>
          <Input
            onChange={(event) => props.onChange({ tag: readInputValue(event) || undefined, offset: 0 })}
            placeholder="Add tag..."
            type="text"
            value={props.filter.tag ?? ""}
          />
        </div>
        <div className="space-y-2">
          <Label>Sort</Label>
          <Select
            onValueChange={(value) => props.onChange({ sortBy: value as NonNullable<PhotoFilter["sortBy"]>, offset: 0 })}
            value={currentSortBy(props.filter.sortBy)}
          >
            <SelectTrigger>
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="datetime">Datetime</SelectItem>
              <SelectItem value="updatedAt">Updated</SelectItem>
              <SelectItem value="path">Path</SelectItem>
            </SelectContent>
          </Select>
        </div>
        <div className="space-y-2">
          <Label>Direction</Label>
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
              <SelectItem value="desc">Desc</SelectItem>
              <SelectItem value="asc">Asc</SelectItem>
            </SelectContent>
          </Select>
        </div>
        <div className="space-y-2">
          <Label>Status</Label>
          <div className="flex flex-wrap gap-2">
            <FilterToggle
              active={Boolean(props.filter.indexed)}
              label="Indexed"
              onClick={() => props.onChange({ indexed: props.filter.indexed ? undefined : true, offset: 0 })}
            />
            <FilterToggle
              active={Boolean(props.filter.hasError)}
              label="Errors"
              onClick={() => props.onChange({ hasError: props.filter.hasError ? undefined : true, offset: 0 })}
            />
          </div>
        </div>
      </div>
    </div>
  );
}
