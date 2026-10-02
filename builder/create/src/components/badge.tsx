import * as React from "react";
import { Slot } from "@radix-ui/react-slot";
import { cva, type VariantProps } from "class-variance-authority";
import Utils from "../utils/Utility";

/**
 * Badge variants defined using class-variance-authority (CVA).
 * 
 * Variants:
 * - `variant` controls the color/style of the badge:
 *   - `default`: Primary badge
 *   - `secondary`: Secondary badge
 *   - `destructive`: Red/destructive badge
 *   - `outline`: Minimal, border-only badge
 */
const badgeVariants = cva(
  "inline-flex items-center justify-center rounded-md border px-2 py-0.5 text-xs font-medium w-fit whitespace-nowrap shrink-0 [&>svg]:size-3 gap-1 [&>svg]:pointer-events-none focus-visible:border-ring focus-visible:ring-ring/50 focus-visible:ring-[3px] aria-invalid:ring-destructive/20 dark:aria-invalid:ring-destructive/40 aria-invalid:border-destructive transition-[color,box-shadow] overflow-hidden",
  {
    variants: {
      variant: {
        default:
          "border-transparent bg-primary text-primary-foreground [a&]:hover:bg-primary/90",
        secondary:
          "border-transparent bg-secondary text-secondary-foreground [a&]:hover:bg-secondary/90",
        destructive:
          "border-transparent bg-destructive text-white [a&]:hover:bg-destructive/90 focus-visible:ring-destructive/20 dark:focus-visible:ring-destructive/40 dark:bg-destructive/60",
        outline:
          "text-foreground [a&]:hover:bg-accent [a&]:hover:text-accent-foreground",
      },
    },
    defaultVariants: {
      variant: "default",
    },
  },
);

interface BadgeProps
  extends React.ComponentProps<"span">,
    VariantProps<typeof badgeVariants> {
  /**
   * Use `Slot` to render as another component instead of `<span>`.
   * Useful for polymorphic components (e.g., <a>, <button>).
   */
  asChild?: boolean;
}

/**
 * `Badge` component.
 *
 * A small, inline label or tag that supports multiple visual variants.
 * - Supports `variant` via CVA.
 * - Can render as a native `<span>` or any other component using `asChild`.
 * - Designed to handle icons inside via `[&>svg]` rules.
 *
 * Example usage:
 * ```tsx
 * <Badge variant="destructive">Error</Badge>
 * <Badge asChild><a href="/link">Link Badge</a></Badge>
 * ```
 */
function Badge({
  className,
  variant,
  asChild = false,
  ...props
}: BadgeProps) {
  const Comp = asChild ? Slot : "span";

  return (
    <Comp
      data-slot="badge"
      className={Utils.cn(badgeVariants({ variant }), className)}
      {...props}
    />
  );
}

export { Badge };
