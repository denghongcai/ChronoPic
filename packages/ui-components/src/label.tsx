import * as LabelPrimitive from "@radix-ui/react-label";
import { cva } from "class-variance-authority";
import type * as React from "react";

import { cn } from "./lib/cn.js";

const labelVariants = cva("select-none text-[11px] font-semibold uppercase tracking-[0.18em] text-stone-500");

export function Label({
  className,
  ...props
}: React.ComponentProps<typeof LabelPrimitive.Root>) {
  return <LabelPrimitive.Root className={cn(labelVariants(), className)} {...props} />;
}
