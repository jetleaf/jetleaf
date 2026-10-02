import * as React from "react";
import { Slot } from "@radix-ui/react-slot";
import { cva, type VariantProps } from "class-variance-authority";
import { cn } from "../utils/utils";

/**
 * Button variants defined using class-variance-authority (CVA).
 * 
 * Variants:
 * - `variant` controls the color/style of the button:
 *   - `default`: Primary button
 *   - `destructive`: Red/destructive action
 *   - `outline`: Outlined button
 *   - `secondary`: Secondary button
 *   - `ghost`: Minimal background
 *   - `link`: Styled as text link
 * 
 * - `size` controls the dimensions and spacing:
 *   - `default`: Standard height/padding
 *   - `sm`: Small button
 *   - `lg`: Large button
 *   - `icon`: Square icon button
 */
const buttonVariants = cva(
  "inline-flex items-center justify-center gap-2 whitespace-nowrap rounded-md text-sm font-medium transition-all disabled:pointer-events-none disabled:opacity-50 [&_svg]:pointer-events-none [&_svg:not([class*='size-'])]:size-4 shrink-0 [&_svg]:shrink-0 outline-none focus-visible:border-ring focus-visible:ring-ring/50 focus-visible:ring-[3px] aria-invalid:ring-destructive/20 dark:aria-invalid:ring-destructive/40 aria-invalid:border-destructive",
  {
    variants: {
      variant: {
        default: "bg-primary text-primary-foreground hover:bg-primary/90",
        destructive:
          "bg-destructive text-white hover:bg-destructive/90 focus-visible:ring-destructive/20 dark:focus-visible:ring-destructive/40 dark:bg-destructive/60",
        outline:
          "border bg-background text-foreground hover:bg-accent hover:text-accent-foreground dark:bg-input/30 dark:border-input dark:hover:bg-input/50",
        secondary:
          "bg-secondary text-secondary-foreground hover:bg-secondary/80",
        ghost:
          "hover:bg-accent hover:text-accent-foreground dark:hover:bg-accent/50",
        link: "text-primary underline-offset-4 hover:underline",
      },
      size: {
        default: "h-9 px-4 py-2 has-[>svg]:px-3",
        sm: "h-8 rounded-md gap-1.5 px-3 has-[>svg]:px-2.5",
        lg: "h-10 rounded-md px-6 has-[>svg]:px-4",
        icon: "size-9 rounded-md",
      },
    },
    defaultVariants: {
      variant: "default",
      size: "default",
    },
  },
);


interface ButtonProps
  extends React.ComponentProps<"button">,
    VariantProps<typeof buttonVariants> {
  /**
   * Use Slot as child component instead of native <button>.
   * Useful for polymorphic components (e.g., passing <a> or <Link>).
   */
  asChild?: boolean;
}

/**
 * `Button` component.
 *
 * A fully customizable, polymorphic button with built-in variants and sizes.
 * - Supports `variant` and `size` via CVA.
 * - Can render as a native `<button>` or a `Slot` component via `asChild`.
 * - Integrates utility function `cn` for merging class names.
 *
 * Example usage:
 * ```tsx
 * <Button variant="destructive" size="lg">Delete</Button>
 * <Button asChild><a href="/path">Link Button</a></Button>
 * ```
 */
function Button({
  className,
  variant,
  size,
  asChild = false,
  ...props
}: ButtonProps) {
  const Comp = asChild ? Slot : "button";

  return (
    <Comp
      data-slot="button"
      style={{ cursor: "pointer" }}
      className={cn(buttonVariants({ variant, size, className }))}
      {...props}
    />
  );
}

export { Button };
