import type { HTMLAttributes } from "react";

import { cn } from "./lib/cn.js";

export function Panel(props: HTMLAttributes<HTMLDivElement>) {
  return (
    <section
      {...props}
      className={cn(
        "rounded-[28px] border border-stone-200/70 bg-white/82 shadow-[0_24px_80px_-52px_rgba(17,24,39,0.35)] backdrop-blur",
        props.className
      )}
    />
  );
}
