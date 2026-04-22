import { cva, type VariantProps } from "class-variance-authority";
import type * as React from "react";

import { cn } from "./lib/cn.js";

const badgeVariants = cva("inline-flex select-none items-center gap-1 rounded-full border px-2.5 py-1 text-[11px] font-medium uppercase tracking-[0.14em]", {
  variants: {
    tone: {
      neutral: "border-stone-200 bg-stone-100 text-stone-600",
      success: "border-emerald-200 bg-emerald-50 text-emerald-700",
      warn: "border-amber-200 bg-amber-50 text-amber-700",
      danger: "border-rose-200 bg-rose-50 text-rose-700",
      info: "border-sky-200 bg-sky-50 text-sky-700",
      dark: "border-stone-700 bg-stone-900/80 text-stone-200"
    }
  },
  defaultVariants: {
    tone: "neutral"
  }
});

export type BadgeTone = NonNullable<VariantProps<typeof badgeVariants>["tone"]>;

export function Badge({
  className,
  tone,
  ...props
}: React.HTMLAttributes<HTMLDivElement> & VariantProps<typeof badgeVariants>) {
  return <div className={cn(badgeVariants({ tone }), className)} {...props} />;
}
