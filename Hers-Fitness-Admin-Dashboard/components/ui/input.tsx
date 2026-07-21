import * as React from "react";

import { cn } from "@/lib/utils";

export function Input({
  className,
  ...props
}: React.InputHTMLAttributes<HTMLInputElement>) {
  return (
    <input
      className={cn(
        "flex h-14 w-full rounded-2xl border border-[#e0e0e0] bg-white px-12 text-base text-[#121212] outline-none transition-shadow placeholder:text-[#7a7a7a] focus:border-[#f7869a] focus:ring-4 focus:ring-[#f7869a]/20",
        className,
      )}
      {...props}
    />
  );
}
