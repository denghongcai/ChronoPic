import { cva, type VariantProps } from "class-variance-authority";
import * as React from "react";
import type { ButtonHTMLAttributes, HTMLAttributes, InputHTMLAttributes, TextareaHTMLAttributes } from "react";

import { cn } from "./lib/cn.js";

const buttonVariants = cva(
  "inline-flex items-center justify-center gap-2 whitespace-nowrap rounded-xl text-sm font-medium transition-all duration-200 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-amber-400 focus-visible:ring-offset-2 focus-visible:ring-offset-white disabled:pointer-events-none disabled:opacity-55",
  {
    variants: {
      variant: {
        default: "bg-stone-950 text-stone-50 shadow-sm hover:bg-stone-800 active:bg-stone-950",
        secondary: "bg-stone-100 text-stone-900 shadow-sm hover:bg-stone-200",
        outline: "border border-stone-200 bg-white text-stone-700 shadow-sm hover:bg-stone-50",
        ghost: "bg-transparent text-stone-700 hover:bg-stone-100",
        accent: "bg-amber-500 text-stone-950 shadow-sm hover:bg-amber-400"
      },
      size: {
        default: "h-10 px-4 py-2",
        sm: "h-9 px-3 text-xs",
        lg: "h-11 px-5 text-sm",
        icon: "h-10 w-10"
      }
    },
    defaultVariants: {
      variant: "default",
      size: "default"
    }
  }
);

export function Button({
  className,
  variant,
  size,
  ...props
}: ButtonHTMLAttributes<HTMLButtonElement> & VariantProps<typeof buttonVariants>) {
  return <button className={cn(buttonVariants({ variant, size }), className)} {...props} />;
}

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

export function FieldLabel({ children }: { children: React.ReactNode }) {
  return <span className="text-[11px] font-semibold uppercase tracking-[0.18em] text-stone-500">{children}</span>;
}

export function Input(props: InputHTMLAttributes<HTMLInputElement>) {
  return (
    <input
      {...props}
      className={cn(
        "h-11 rounded-xl border border-stone-200 bg-white px-3.5 text-sm text-stone-900 shadow-sm outline-none transition placeholder:text-stone-400 focus:border-amber-400 focus:ring-2 focus:ring-amber-200",
        props.className
      )}
    />
  );
}

export function Textarea(props: TextareaHTMLAttributes<HTMLTextAreaElement>) {
  return (
    <textarea
      {...props}
      className={cn(
        "min-h-28 rounded-xl border border-stone-200 bg-white px-3.5 py-3 text-sm text-stone-900 shadow-sm outline-none transition placeholder:text-stone-400 focus:border-amber-400 focus:ring-2 focus:ring-amber-200",
        props.className
      )}
    />
  );
}

const badgeVariants = cva(
  "inline-flex items-center gap-1 rounded-full border px-2.5 py-1 text-[11px] font-medium uppercase tracking-[0.14em]",
  {
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
  }
);

export function Badge({
  className,
  tone,
  ...props
}: HTMLAttributes<HTMLSpanElement> & VariantProps<typeof badgeVariants>) {
  return <span {...props} className={cn(badgeVariants({ tone }), className)} />;
}
