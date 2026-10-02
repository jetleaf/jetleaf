import { clsx, type ClassValue } from "clsx";
import { twMerge } from "tailwind-merge";

/**
 * `cn` Utility
 *
 * Combines multiple Tailwind CSS class strings or conditional classes
 * into a single string, intelligently merging conflicting Tailwind classes.
 *
 * @param inputs - List of class values (strings, arrays, or objects)
 * @returns Merged class string
 */
export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}