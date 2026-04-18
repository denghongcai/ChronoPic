import { Search, SlidersHorizontal } from "lucide-react";
import type { ChangeEvent } from "react";

import type { PhotoFilter, PhotoFilterPatch } from "@chronopic/domain";

import { Badge } from "./badge.js";
import { Button } from "./button.js";
import { Input } from "./input.js";
import { Label } from "./label.js";
import { Panel } from "./panel.js";
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
    <Panel className="p-5">
      <div className="flex flex-col gap-5">
        <div className="flex flex-col gap-3 lg:flex-row lg:items-center lg:justify-between">
          <div className="space-y-1">
            <p className="text-[11px] font-semibold uppercase tracking-[0.22em] text-stone-500">Search & Filters</p>
            <h2 className="font-['Space_Grotesk','IBM_Plex_Sans',sans-serif] text-2xl font-semibold tracking-tight text-stone-950">
              Refine your media shelf
            </h2>
          </div>
          <Badge tone="neutral">
            <SlidersHorizontal className="h-3.5 w-3.5" />
            Structured query
          </Badge>
        </div>
        <div className="grid gap-4 xl:grid-cols-[minmax(0,1.7fr)_repeat(4,minmax(0,1fr))]">
          <div className="space-y-2">
            <Label>Search</Label>
            <div className="relative">
              <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-stone-400" />
              <Input
                className="pl-9"
                onChange={(event) => props.onChange({ query: readInputValue(event) || undefined, offset: 0 })}
                placeholder="path, caption, tag"
                type="search"
                value={props.filter.query ?? ""}
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
              placeholder="family"
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
        </div>
        <div className="flex flex-wrap gap-2">
          <FilterToggle
            active={Boolean(props.filter.favorite)}
            label="Favorites"
            onClick={() => props.onChange({ favorite: props.filter.favorite ? undefined : true, offset: 0 })}
          />
          <FilterToggle
            active={Boolean(props.filter.indexed)}
            label="Indexed only"
            onClick={() => props.onChange({ indexed: props.filter.indexed ? undefined : true, offset: 0 })}
          />
          <FilterToggle
            active={Boolean(props.filter.hasError)}
            label="Errors only"
            onClick={() => props.onChange({ hasError: props.filter.hasError ? undefined : true, offset: 0 })}
          />
          <FilterToggle
            active={Boolean(props.filter.hasGps)}
            label="With GPS"
            onClick={() => props.onChange({ hasGps: props.filter.hasGps ? undefined : true, offset: 0 })}
          />
        </div>
      </div>
    </Panel>
  );
}
