import * as React from "react";

import { cn } from "@/lib/utils";

type ButtonProps = React.ButtonHTMLAttributes<HTMLButtonElement> & {
  variant?: "default" | "ghost" | "outline";
  size?: "default" | "icon";
};

export function Button({
  className,
  variant = "default",
  size = "default",
  ...props
}: ButtonProps) {
  return (
    <button
      className={cn(
        "inline-flex items-center justify-center whitespace-nowrap rounded-lg text-sm font-medium transition-colors focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-[#f7869a]/30 disabled:pointer-events-none disabled:opacity-50",
        variant === "default" && "bg-[#f7869a] text-white hover:bg-[#f2738b]",
        variant === "ghost" && "bg-transparent text-[#121212] hover:bg-[#fdf2f4]",
        variant === "outline" &&
          "border border-[#e0e0e0] bg-white text-[#121212] hover:bg-[#f7f7f7]",
        size === "default" && "h-12 px-4 py-3",
        size === "icon" && "size-10",
        className,
      )}
      {...props}
    />
  );
}
