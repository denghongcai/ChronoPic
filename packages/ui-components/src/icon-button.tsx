import type { ButtonHTMLAttributes, ReactNode } from "react";

import { Button } from "./button.js";
import { cn } from "./lib/cn.js";

export interface IconButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  icon: ReactNode;
  label: string;
  variant?: "default" | "ghost" | "outline";
  tone?: "light" | "dark";
  size?: "sm" | "md" | "lg";
}

export function IconButton({
  icon,
  label,
  variant = "ghost",
  tone = "light",
  size = "md",
  className,
  disabled,
  ...props
}: IconButtonProps) {
  const sizeClasses = {
    sm: "h-8 w-8",
    md: "h-10 w-10",
    lg: "h-12 w-12",
  };

  const baseClasses =
    tone === "dark"
      ? "border-stone-700 bg-stone-900/80 text-stone-100 hover:bg-stone-800 disabled:cursor-not-allowed disabled:opacity-35 disabled:hover:bg-stone-900/80"
      : "border-stone-300 bg-white text-stone-700 hover:bg-stone-100 disabled:cursor-not-allowed disabled:opacity-40 disabled:hover:bg-white";

  return (
    <Button
      aria-label={label}
      className={cn(sizeClasses[size], baseClasses, className)}
      disabled={disabled}
      type="button"
      variant={variant}
      {...props}
    >
      {icon}
    </Button>
  );
}
