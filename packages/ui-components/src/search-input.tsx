import { Search } from "lucide-react";

import { Input } from "./input.js";
import { cn } from "./lib/cn.js";

export interface SearchInputProps {
  className?: string;
  placeholder?: string;
  value?: string;
  onValueChange?: (value: string) => void;
}

export function SearchInput({
  className,
  placeholder = "Search photos, places, people...",
  value,
  onValueChange,
}: SearchInputProps) {
  return (
    <div className={cn("relative", className)}>
      <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-stone-400" />
      <Input
        className="pl-9"
        onChange={(e) => onValueChange?.(e.target.value)}
        placeholder={placeholder}
        type="search"
        value={value ?? ""}
      />
    </div>
  );
}
