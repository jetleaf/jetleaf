"use client";

import * as React from "react";
import * as SeparatorPrimitive from "@radix-ui/react-separator";
import Utils from "../utils/Utility";

/**
 * Separator Component
 *
 * A visual divider used to separate content either horizontally or vertically.
 * Built on top of Radix UI's SeparatorPrimitive.
 *
 * Props:
 * - `orientation` ("horizontal" | "vertical") – direction of the separator. Default: "horizontal".
 * - `decorative` (boolean) – if true, the separator is purely visual (ignored by screen readers). Default: true.
 * - `className` – additional custom class names.
 */
function Separator({
  className,
  orientation = "horizontal",
  decorative = true,
  ...props
}: React.ComponentProps<typeof SeparatorPrimitive.Root>) {
  return (
    <SeparatorPrimitive.Root
      data-slot="separator-root"
      decorative={decorative}
      orientation={orientation}
      className={Utils.cn(
        "bg-border shrink-0 data-[orientation=horizontal]:h-px data-[orientation=horizontal]:w-full data-[orientation=vertical]:h-full data-[orientation=vertical]:w-px",
        className,
      )}
      {...props}
    />
  );
}

export { Separator };
