import type * as React from "react";

import { cn } from "./lib/cn.js";

export interface AvatarProps {
  className?: string;
  fallback?: string;
  src?: string;
}

export function Avatar({ className, fallback, src }: AvatarProps) {
  return (
    <div
      className={cn(
        "relative flex h-9 w-9 shrink-0 overflow-hidden rounded-full bg-stone-200",
        className
      )}
    >
      {src ? (
        <img alt="" className="h-full w-full object-cover" src={src} />
      ) : (
        <span className="flex h-full w-full items-center justify-center text-xs font-semibold text-stone-600">
          {fallback ?? "U"}
        </span>
      )}
    </div>
  );
}
