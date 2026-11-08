"use client";

import * as React from "react";
import * as LabelPrimitive from "@radix-ui/react-label";
import Utils from "../utils/Utility";

/**
 * Label component.
 *
 * A styled, accessible label wrapper using Radix UI's `LabelPrimitive`.
 * Provides default styling, disabled state handling, and works with form inputs.
 *
 * Props:
 * - `className` (string): Additional custom class names
 * - Any props accepted by `LabelPrimitive.Root`
 *
 * Features:
 * - Flex container with gap support
 * - Small text size, medium font weight
 * - Disabled state styling (opacity and pointer-events)
 * - Works with `peer-disabled` for input accessibility
 *
 * Example usage:
 * ```tsx
 * <Label htmlFor="email">Email Address</Label>
 * <input id="email" type="email" />
 * ```
 */
function Label({
  className,
  ...props
}: React.ComponentProps<typeof LabelPrimitive.Root>) {
  return (
    <LabelPrimitive.Root
      data-slot="label"
      className={Utils.cn(
        "flex items-center gap-2 text-sm leading-none font-medium select-none group-data-[disabled=true]:pointer-events-none group-data-[disabled=true]:opacity-50 peer-disabled:cursor-not-allowed peer-disabled:opacity-50",
        className,
      )}
      {...props}
    />
  );
}

export { Label };