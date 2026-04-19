import * as React from "react";

import { cn } from "./lib/cn.js";

export function Input({ className, type, ...props }: React.ComponentProps<"input">) {
  return (
    <input
      className={cn(
        "flex h-11 w-full select-text rounded-xl border border-stone-200 bg-white px-3.5 py-2 text-sm text-stone-900 shadow-sm outline-none transition file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-stone-400 focus-visible:border-amber-400 focus-visible:ring-2 focus-visible:ring-amber-200 disabled:cursor-not-allowed disabled:opacity-50",
        className
      )}
      type={type}
      {...props}
    />
  );
}
