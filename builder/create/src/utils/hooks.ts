import { useState, useEffect, useRef, useCallback } from "react";
import { codeToHtml } from 'shiki'

/**
 * Custom React hook to detect if the current viewport matches a mobile breakpoint.
 *
 * @param breakpoint - The maximum width (in pixels) considered "mobile".
 *   Defaults to 640px.
 *
 * @returns A boolean `isMobile`:
 *   - `true` if the viewport width is less than the breakpoint.
 *   - `false` otherwise.
 *
 * Behavior:
 * 1. Sets initial state based on the current `window.innerWidth`.
 * 2. Listens for `resize` events and updates `isMobile` dynamically.
 * 3. Cleans up the event listener when the component unmounts.
 *
 * @example
 * const isMobile = useMobile(900);
 * if (isMobile) {
 *   // render mobile-specific layout
 * }
 */
export function useMobile(breakpoint: number = 640) {
    // State indicating whether the viewport is currently mobile
    const [isMobile, setIsMobile] = useState(() => typeof window !== "undefined" ? window.innerWidth < breakpoint : false)

    useEffect(() => {
        /**
         * Checks the window width and updates `isMobile`.
         */
        const update = () => {
            setIsMobile(window.innerWidth < breakpoint);
        };

        // Run immediately to initialize state
        update();

        // Listen for window resize events
        window.addEventListener("resize", update);

        // Cleanup listener on unmount
        return () => window.removeEventListener("resize", update);
    }, [breakpoint]);

    return isMobile;
}

/**
 * Custom React hook for polling asynchronous data at a fixed interval.
 *
 * @template T - The type of data returned by the fetcher function.
 *
 * @param fetcher - A function that returns a Promise resolving to the data to poll.
 * @param intervalMs - The polling interval in milliseconds.
 * @param enabled - Optional flag to enable/disable polling (default: true).
 *
 * @returns An object containing:
 *   - `data`: The latest fetched data, or `null` if not yet fetched.
 *   - `loading`: Boolean indicating whether the data is currently loading.
 *   - `refetch`: Function to manually trigger a fetch immediately.
 *
 * Behavior:
 * 1. Runs the fetcher immediately when the hook mounts.
 * 2. Polls the fetcher at the specified interval if `enabled` is true.
 * 3. Automatically skips polling when the document is hidden (tab inactive).
 * 4. Supports manual refetch via the returned `refetch` function.
 * 5. Cleans up timers and cancels pending updates on unmount.
 *
 * @example
 * ```ts
 * const { data, loading, refetch } = usePolling(fetchMetric, 30000);
 * ```
 */
export function usePolling<T>(fetcher: () => Promise<T>, intervalMs: number, enabled = true) {
    // Latest fetched data
    const [data, setData] = useState<T | null>(null);

    // Loading state for UI feedback
    const [loading, setLoading] = useState(true);

    // Store the latest fetcher in a ref to avoid stale closures
    const fetcherRef = useRef(fetcher);

    // Timer ID for setInterval
    const timerRef = useRef<number | null>(null);

    // Ref to track if the component is unmounted or polling canceled
    const cancelledRef = useRef(false);

    // Update fetcher ref on every render to ensure latest function is used
    useEffect(() => {
        fetcherRef.current = fetcher;
    });

    /**
     * Manually triggers a fetch outside the regular polling interval.
     */
    const refetch = useCallback(async () => {
        try {
            setLoading(true);
            const result = await fetcherRef.current();
            if (!cancelledRef.current) {
                setData(result);
                setLoading(false);
            }
        } catch (err) {
            if (!cancelledRef.current) {
                console.error("Polling error:", err);
                setLoading(false);
            }
        }
    }, []);

    /**
     * Main polling effect.
     *
     * - Runs the fetcher immediately.
     * - Sets up an interval to poll periodically.
     * - Skips polling if the tab is not visible.
     * - Cleans up the interval and cancels updates on unmount or when `enabled` changes.
     */
    useEffect(() => {
        if (!enabled) {
            // Clear timer if disabled
            if (timerRef.current) {
                clearInterval(timerRef.current);
                timerRef.current = null;
            }
            return;
        }

        cancelledRef.current = false;

        // Clear any existing timer
        if (timerRef.current) {
            clearInterval(timerRef.current);
            timerRef.current = null;
        }

        // Function to run the fetcher safely
        const run = async () => {
            if (cancelledRef.current) return;

            try {
                const result = await fetcherRef.current();
                if (!cancelledRef.current) {
                    setData(result);
                    setLoading(false);
                }
            } catch (err) {
                if (!cancelledRef.current) console.error("Polling error:", err);
            }
        };

        // Initial fetch
        run();

        // Set up interval
        timerRef.current = window.setInterval(() => {
            if (document.visibilityState === "visible") {
                run();
            }
        }, intervalMs);

        // Cleanup on unmount or interval change
        return () => {
            cancelledRef.current = true;
            if (timerRef.current) {
                clearInterval(timerRef.current);
                timerRef.current = null;
            }
        };
    }, [intervalMs, enabled]);

    // Return the latest data, loading state, and manual refetch function
    return { data, loading, refetch };
}

/**
 * A React hook that highlights source code using the Shiki syntax highlighter.
 *
 * This hook converts raw code strings into HTML with syntax highlighting
 * according to the specified language and theme. It is designed for
 * rendering code snippets in React components safely and efficiently.
 *
 * ## Parameters
 * @param code {string}  
 *   The raw source code to be highlighted.
 *
 * @param lang {string}  
 *   The programming language of the source code. Defaults to `'dart'`.
 *   Shiki uses this to apply proper syntax coloring.
 *
 * @param theme {string}  
 *   The Shiki theme to apply for highlighting. Defaults to `'vitesse-dark'`.
 *   You can pass any theme supported by Shiki.
 *
 * ## Behavior
 * - The hook asynchronously transforms the `code` into HTML using `Shiki`.
 * - It updates the returned value whenever `code`, `lang`, or `theme` changes.
 * - The result is a string of HTML with syntax highlighting applied.
 *
 * ## Returns
 * @returns {string}  
 *   HTML string containing the highlighted code. This can be safely rendered
 *   in a React component using `dangerouslySetInnerHTML`.
 *
 * ## Example
 * ```tsx
 * const highlightedCode = useShiki('void main() => print("Hello");', 'dart', 'vitesse-dark');
 * return <pre dangerouslySetInnerHTML={{ __html: highlightedCode }} />;
 * ```
 */
export function useShiki(code: string, lang: string = 'dart', theme: string = 'vitesse-dark'): string {
    const [html, setHtml] = useState<string>('')

    useEffect(() => {
        async function run() {
            const highlighted = await codeToHtml(code, {
                lang,
                theme
            })
            setHtml(highlighted)
        }
        run()
    }, [code, lang, theme])

    return html
}