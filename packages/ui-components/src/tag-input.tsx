import { X } from "lucide-react";
import * as React from "react";

import { Badge } from "./badge.js";
import { cn } from "./lib/cn.js";
import { Input } from "./input.js";

export interface TagInputProps {
  value: string[];
  onChange: (tags: string[]) => void;
  placeholder?: string;
  className?: string;
}

export function TagInput({ value, onChange, placeholder = "Add tag...", className }: TagInputProps) {
  const [inputValue, setInputValue] = React.useState("");

  function removeTag(index: number) {
    onChange(value.filter((_, i) => i !== index));
  }

  function commitInput() {
    const trimmed = inputValue.trim();
    if (trimmed && !value.includes(trimmed)) {
      onChange([...value, trimmed]);
    }
    setInputValue("");
  }

  function handleKeyDown(e: React.KeyboardEvent<HTMLInputElement>) {
    if (e.key === "Enter" || e.key === ",") {
      e.preventDefault();
      commitInput();
    } else if (e.key === "Backspace" && inputValue === "" && value.length > 0) {
      removeTag(value.length - 1);
    }
  }

  return (
    <div
      className={cn(
        "flex min-h-[48px] flex flex-wrap items-center gap-1.5 rounded-xl border border-stone-200 bg-white px-3 py-2.5 text-sm shadow-sm transition focus-within:border-amber-400 focus-within:ring-2 focus-within:ring-amber-200",
        className
      )}
    >
      {value.map((tag, i) => (
        <Badge key={i} tone="info" className="gap-1 pr-1">
          {tag}
          <button
            className="ml-0.5 flex h-3.5 w-3.5 items-center justify-center rounded-full text-stone-500 hover:bg-stone-200 hover:text-stone-700"
            onClick={() => removeTag(i)}
            type="button"
            aria-label={`Remove ${tag}`}
          >
            <X className="h-2.5 w-2.5" />
          </button>
        </Badge>
      ))}
      <input
        className="min-w-[80px] flex-1 border-none bg-transparent py-0.5 text-sm outline-none placeholder:text-stone-400"
        value={inputValue}
        onChange={(e) => setInputValue(e.target.value)}
        onKeyDown={handleKeyDown}
        onBlur={commitInput}
        placeholder={value.length === 0 ? placeholder : undefined}
      />
    </div>
  );
}
