import { BellIcon } from "lucide-react";

import { Avatar } from "./avatar.js";
import { Button } from "./button.js";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "./dropdown-menu.js";
import { SearchInput } from "./search-input.js";
import { cn } from "./lib/cn.js";

export interface HeaderProps {
  className?: string;
  searchQuery?: string;
  onSearchChange?: (query: string) => void;
  onOpenLibrarySettings?: () => void;
}

export function Header({
  className,
  searchQuery,
  onSearchChange,
  onOpenLibrarySettings,
}: HeaderProps) {
  return (
    <header
      className={cn(
        "flex h-16 items-center gap-4 border-b border-stone-200/80 bg-white/90 px-5 backdrop-blur-sm",
        className
      )}
    >
      {/* Logo */}
      <div className="flex h-9 w-9 items-center justify-center rounded-xl bg-amber-400 shrink-0">
        <span className="font-['Space_Grotesk','IBM_Plex_Sans',sans-serif] text-lg font-bold text-amber-900">
          C
        </span>
      </div>

      {/* Right side: search + notification + user */}
      <div className="ml-auto flex items-center gap-3">
        <SearchInput
          className="w-72"
          onValueChange={onSearchChange ?? (() => {})}
          value={searchQuery ?? ""}
        />
        <Button className="h-9 w-9 p-0 shrink-0" size="sm" variant="ghost">
          <BellIcon className="h-4 w-4" />
        </Button>

        <DropdownMenu>
          <DropdownMenuTrigger asChild>
            <button className="focus:outline-none shrink-0" type="button">
              <Avatar fallback="U" />
            </button>
          </DropdownMenuTrigger>
          <DropdownMenuContent align="end">
            <DropdownMenuLabel>My Account</DropdownMenuLabel>
            <DropdownMenuSeparator />
            <DropdownMenuItem onClick={onOpenLibrarySettings}>
              Library Settings
            </DropdownMenuItem>
            <DropdownMenuItem>Preferences</DropdownMenuItem>
            <DropdownMenuSeparator />
            <DropdownMenuItem>Sign Out</DropdownMenuItem>
          </DropdownMenuContent>
        </DropdownMenu>
      </div>
    </header>
  );
}
