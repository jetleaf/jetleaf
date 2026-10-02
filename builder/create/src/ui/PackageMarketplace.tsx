import { useState, useEffect, useMemo, useRef, JSX } from 'react';
import { Input } from '../components/input';
import { AlertCircle, Check, Clock, Info, Search } from 'lucide-react';
import Package from '../types/package';
import PackageGroup from '../types/package_group';
import { PubDevPackage } from '../types/pubspec';
import { Badge } from '../components/badge';
import { Separator } from '../components/separator';
import Utils from '../utils/Utility'
import Constants from '../utils/Constants'

/**
 * Props for the `PackageMarketplace` component.
 *
 * Provides the data and callbacks required to display a list of packages,
 * handle user interactions (selecting/deselecting packages), and show
 * package details in a modal or separate view.
 */
interface PackageMarketplaceProps {
    /**
     * List of packages currently selected by the user.
     *
     * Used to highlight selected packages and manage toggling state.
     */
    selectedPackages: Package[];

    /**
     * Callback triggered when a package is toggled (selected or deselected).
     *
     * @param pkg - The package being toggled.
     * @remarks This should update the parent state so that `selectedPackages` stays in sync.
     */
    onTogglePackage: (pkg: Package) => void;

    /**
     * Callback triggered when a package details view is requested.
     *
     * @param pkg - The package for which to display details.
     * @remarks Typically opens a modal or navigates to a detailed view of the package.
     */
    onShowPackageDetails: (pkg: Package) => void;

    /**
     * Metrics data for packages.
     *
     * A record mapping package IDs to a numeric metric (e.g., usage count).
     * Can be used to show popularity, usage statistics, or other metrics.
     */
    packageMetrics: Record<string, number>;
}

/**
 * Displays a searchable, filterable marketplace of Dart packages.
 *
 * Features:
 * - Search bar to filter packages by name or description.
 * - Category badges to filter packages by group.
 * - Fetches package groups from API or localStorage cache with TTL.
 * - Displays loading states and empty states.
 * - Allows selecting/deselecting packages and viewing details via callbacks.
 * - Uses `PackageCard` components to display individual packages.
 *
 * @param selectedPackages - Packages currently selected.
 * @param onTogglePackage - Callback for toggling selection.
 * @param onShowPackageDetails - Callback for showing package details.
 */
export default function PackageMarketplace({ selectedPackages, onTogglePackage, onShowPackageDetails, packageMetrics }: PackageMarketplaceProps) {
    /**
     * Array of IDs for the currently selected packages.
     *
     * - Derived from the `selectedPackages` prop.
     * - Used to quickly check selection status without iterating the full package objects.
     */
    const selectedPackageIds = selectedPackages.map((pk) => pk.id);

    /**
     * Search query string for filtering packages in the marketplace.
     *
     * - Controlled state bound to a search input.
     * - Updates the displayed package list as the user types.
     */
    const [searchQuery, setSearchQuery] = useState('');

    /**
     * Selected package category for filtering the marketplace view.
     *
     * - Defaults to "All" to show packages across all categories.
     * - Updates when the user selects a different category from the filter UI.
     */
    const [selectedCategory, setSelectedCategory] = useState('All');

    /**
     * Groups of packages fetched and organized for display.
     *
     * - Type: `PackageGroup[]`
     * - Updated when packages are loaded or filtered.
     * - Each group contains a set of related packages (e.g., by category or topic).
     */
    const [groups, setGroups] = useState<PackageGroup[]>([]);

    /**
     * Loading flag for the marketplace data.
     *
     * - `true` when packages are being fetched or filtered.
     * - Used to show loading indicators (e.g., skeletons or spinners) in the UI.
     */
    const [loading, setLoading] = useState(true);

    /**
     * Computes the set of top-performing packages based on usage metrics.
     *
     * - Uses `useMemo` to memoize the result and recompute only when `packageMetrics` changes.
     * - `packageMetrics` is an object mapping package IDs to numeric counts (e.g., usage or popularity).
     *
     * Algorithm:
     * 1. Extract all metric values from `packageMetrics`.
     * 2. If there are no metrics, return an empty `Set`.
     * 3. Find the maximum count value (`maxCount`).
     * 4. Collect all package IDs whose count equals `maxCount`.
     * 5. Return the package IDs as a `Set<string>` for efficient lookup.
     *
     * Example:
     * ```ts
     * packageMetrics = { "pkg1": 5, "pkg2": 8, "pkg3": 8 }
     * topPackages = new Set(["pkg2", "pkg3"])
     * ```
     */
    const topPackages = useMemo(() => {
        const metrics = Object.values(packageMetrics);
        if (metrics.length === 0) return new Set<string>();

        const maxCount = Math.max(...metrics);

        const top = Object.entries(packageMetrics)
            .filter(([pkgId, count]) => count === maxCount)
            .map(([pkgId]) => pkgId);

        return new Set(top);
    }, [packageMetrics]);

    // Extract fetchGroups from useEffect to make it reusable:
    /**
     * Fetches and caches package groups for the marketplace.
     *
     * This asynchronous function:
     * 1. Sets loading state to `true`
     * 2. Attempts to retrieve cached package data from localStorage
     * 3. Falls back to API request if no valid cache exists
     * 4. Transforms raw API data into `PackageGroup` instances
     * 5. Updates component state with fetched groups
     * 6. Handles errors gracefully and logs them to console
     * 7. Ensures loading state is set to `false` when complete
     *
     * @remarks
     * - Cache Strategy: Uses `Constants.PACKAGES_CACHE_KEY` with TTL validation
     * - Data Transformation: Uses `PackageGroup.fromApi()` and `PackageGroup.fromCache()`
     * - Error Handling: Logs errors but doesn't crash the component
     * - State Management: Updates `groups` state and triggers re-render
     *
     * @example
     * ```typescript
     * // Manual fetch trigger
     * fetchGroups();
     *
     * // In useEffect for initial load
     * useEffect(() => {
     *   fetchGroups();
     * }, []);
     * ```
     */
    const fetchGroups = async () => {
        setLoading(true);
        try {
            const cached = localStorage.getItem(Constants.PACKAGES_CACHE_KEY);
            if (cached) {
                const { timestamp, data } = JSON.parse(cached);
                if (Date.now() - timestamp < Constants.CACHE_TTL && Array.isArray(data)) {
                    setGroups(data.map((g: any) => PackageGroup.fromCache(g)));
                    setLoading(false);
                    return;
                }
            }

            const res = await fetch(`${Constants.BASE_API}/packages`);
            const json: { group: string; packages: PubDevPackage[] }[] = await res.json();
            const transformed = json.map(group => PackageGroup.fromApi(group));
            setGroups(transformed);

            if (transformed.length !== 0) {
                localStorage.setItem(
                    Constants.PACKAGES_CACHE_KEY,
                    JSON.stringify({ timestamp: Date.now(), data: transformed })
                );
            }
        } catch (err) {
            console.error('Failed to fetch packages:', err);
        } finally {
            setLoading(false);
        }
    };

    // Updated useEffect to use the extracted function:
    useEffect(() => {
        fetchGroups();
    }, []);

    /**
     * Computes the unique category list for filtering packages.
     * Always includes "All" as the first category.
     */
    const categories = useMemo(() => {
        const cats = groups.map(g => g.name);
        return ['All', ...cats];
    }, [groups]);

    /**
     * Filters packages based on the search query and selected category.
     * Returns a flat list of packages across all groups.
     */
    const filteredPackages = useMemo(() => {
        return groups
            .flatMap(group => group.packages)
            .filter(pkg => {
                const matchesSearch =
                    pkg.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
                    pkg.description.toLowerCase().includes(searchQuery.toLowerCase()) ||
                    pkg.shortDescription.toLowerCase().includes(searchQuery.toLowerCase());

                const matchesCategory = selectedCategory === 'All' || pkg.category === selectedCategory;

                return matchesSearch && matchesCategory;
            });
    }, [groups, searchQuery, selectedCategory]);

    /**
     * Renders the package grid based on loading state, error state, and data availability.
     *
     * Determines what to display in the package grid area:
     * 1. **Loading State**: Shows skeleton cards while data is being fetched
     * 2. **Error State**: Shows error message with retry button if packages fail to load
     * 3. **Empty State**: Shows "no packages found" message when data loads but no packages exist
     * 4. **Search Results**: Shows filtered packages based on search query and category
     * 5. **Success State**: Shows interactive package cards when data is loaded and available
     *
     * @returns JSX.Element representing the appropriate package display UI
     *
     * @remarks
     * - **Loading**: Displays 6 `PackageCardSkeleton` components in a grid layout
     * - **Error**: Shows `PackageFetchError` component with retry callback to refetch packages
     * - **Empty**: Shows centered "No packages found" message with helpful suggestions
     * - **Search Filtered**: Shows filtered packages with count indicator in header
     * - **Success**: Maps `filteredPackages` to `PackageCard` components with selection logic
     *
     * The component handles the full lifecycle of package data fetching and display.
     */
    const displayPackages = (): JSX.Element => {
        if (loading) {
            return (
                <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
                    {Array.from({ length: 6 }).map((_, i) => <PackageCardSkeleton key={i} />)}
                </div>
            );
        }

        if (groups.length === 0) {
            return <PackageFetchError onRefresh={() => fetchGroups()} />;
        }

        if (filteredPackages.length === 0) {
            return (
                <div className="text-center py-12 text-gray-500">
                    <p className="text-lg">No packages found</p>
                    <p className="text-sm">Try adjusting your search or filters</p>
                </div>
            );
        }

        return (
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
                {filteredPackages.map(pkg => (
                    <PackageCard
                        key={pkg.id}
                        package={pkg}
                        isSelected={selectedPackageIds.includes(pkg.id)}
                        onToggle={() => onTogglePackage(pkg)}
                        onShowDetails={() => onShowPackageDetails(pkg)}
                        metricCount={packageMetrics[pkg.id] ?? 0}
                        isTop={topPackages.has(pkg.id)}
                    />
                ))}
            </div>
        );
    };

    return (
        <div className="space-y-6">
            <h2 className="text-xl mb-6">Package Marketplace</h2>

            {/* Search Bar */}
            <div className="relative">
                <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-5 h-5" />
                <Input
                    type="text"
                    placeholder="Search packages..."
                    value={searchQuery}
                    onChange={(e) => setSearchQuery(e.target.value)}
                    className="pl-10"
                    style={{ borderColor: "green" }}
                />
            </div>

            {/* Category Filters */}
            <div className="flex flex-wrap gap-2">
                {categories.map(category => (
                    <Badge
                        key={category}
                        variant={selectedCategory === category ? 'default' : 'outline'}
                        className="cursor-pointer hover:bg-green-100 transition-colors"
                        onClick={() => setSelectedCategory(category)}
                    >
                        {category}
                    </Badge>
                ))}
            </div>

            {/* Package Count - Updated to handle all states */}
            <div className="text-sm text-gray-600">
                {loading ? 'Loading packages...' : groups.length === 0
                    ? 'Failed to load packages'
                    : `Showing ${filteredPackages.length} ${filteredPackages.length === 1 ? 'package' : 'packages'}`
                }
            </div>

            {/* Package Grid - Now using the displayPackages function */}
            {displayPackages()}
        </div>
    );
}

/**
 * Props for the `PackageCard` component.
 *
 * Provides all the data and callbacks required to render an individual
 * package in the marketplace, handle selection, and show detailed information.
 */
interface PackageCardProps {
    /**
     * The package data to display.
     *
     * Includes properties such as name, version, description, and last updated timestamp.
     */
    package: Package;

    /**
     * Whether this package is currently selected by the user.
     *
     * Used to visually highlight the card and manage selection state.
     */
    isSelected: boolean;

    /**
     * Callback triggered when the package card is clicked to toggle selection.
     *
     * @remarks This should update the parent component's selected packages state.
     */
    onToggle: () => void;

    /**
     * Callback triggered when the user performs a long press (or similar gesture)
     * to view package details.
     *
     * Typically opens a modal or navigates to a detailed view.
     */
    onShowDetails: () => void;

    /**
     * Optional metric count for this package.
     *
     * Can be used to show popularity, usage statistics, or other relevant metrics.
     */
    metricCount?: number;

    /**
     * Flag indicating whether this package is a top package based on metrics.
     *
     * Can be used to add a "Top" badge or highlight the package visually.
     */
    isTop?: boolean;
}

/**
 * A UI card component displaying information about a single Dart package.
 *
 * Features:
 * - Shows package name, version, last updated timestamp, and short description.
 * - Highlights when selected and shows a checkmark.
 * - Supports click to toggle selection.
 * - Supports long press (800ms) to trigger detailed view.
 * - Provides a tooltip explaining interactions on hover/click of the info icon.
 *
 * @param package - The package data to display.
 * @param isSelected - Whether the package is selected.
 * @param onToggle - Function to toggle selection state.
 * @param onShowDetails - Function to display detailed package information.
 */
function PackageCard(card: PackageCardProps) {
    // References to manage timers for long press and tooltip auto-hide
    const timerRef = useRef<number | null>(null);
    const autoHideRef = useRef<number | null>(null);

    // Tooltip visibility state
    const [tooltipVisible, setTooltipVisible] = useState(false);

    /**
     * Initiates a timer for long press detection to show package details.
     * Triggered on mouse/touch start.
     */
    const handlePressStart = () => {
        timerRef.current = window.setTimeout(() => {
            card.onShowDetails();
        }, 800); // long press duration in milliseconds
    };

    /**
     * Cancels the long press timer.
     * Triggered on mouse/touch end or leave.
     */
    const handlePressEnd = () => {
        if (timerRef.current) {
            clearTimeout(timerRef.current);
            timerRef.current = null;
        }
    };

    /**
     * Handles click events to toggle package selection.
     */
    const handleClick = () => {
        card.onToggle();
    };

    /**
     * Toggles the visibility of the tooltip when the info icon is clicked.
     * Auto-hides the tooltip after 2 seconds.
     */
    const toggleTooltip = (e: React.MouseEvent) => {
        e.stopPropagation();
        setTooltipVisible(true);

        if (autoHideRef.current) clearTimeout(autoHideRef.current);
        autoHideRef.current = window.setTimeout(() => {
            setTooltipVisible(false);
        }, 2000);
    };

    // Clean up timers when component unmounts
    useEffect(() => {
        return () => {
            if (timerRef.current) clearTimeout(timerRef.current);
            if (autoHideRef.current) clearTimeout(autoHideRef.current);
        };
    }, []);

    return (
        <div
            className={`relative rounded-lg border-2 p-4 transition-all cursor-pointer flex flex-col overflow-hidden
                ${card.isSelected ? 'bg-green-50 border-green-500 shadow-md' : 'bg-white border-gray-200 hover:shadow-lg'}
            `}
            style={{
                borderColor: card.isSelected ? '#86efac' : '#e5e7eb',
                backgroundColor: card.isSelected ? '#f0fdf4' : 'white',
            }}
            key={card.package.id}
            onClick={handleClick}
            onMouseDown={handlePressStart}
            onMouseUp={handlePressEnd}
            onMouseLeave={handlePressEnd}
            onTouchStart={handlePressStart}
            onTouchEnd={handlePressEnd}
        >
            {/* Logo as background at bottom right */}
            <div className="absolute bottom-0 right-0 opacity-10 pointer-events-none">
                <img
                    alt="logo"
                    src="logo.png"
                    style={{
                        height: '80px',
                        width: '80px',
                        position: 'relative',
                        right: '-5px',
                        bottom: '-15px',
                        objectFit: 'contain',
                        transform: 'rotate(25deg)',
                    }}
                />
            </div>

            {/* Info button with tooltip */}
            <div className="absolute top-2 right-2 group z-10">
                <div className="relative">
                    <Info className="w-4 h-4 text-gray-400 cursor-pointer" onClick={toggleTooltip} />
                    <div
                        className={`absolute right-0 top-6 bg-gray-800 text-white text-xs px-2 py-1 rounded shadow-md whitespace-nowrap transition-all duration-200 z-50
                            ${tooltipVisible ? 'opacity-100 scale-100 pointer-events-auto' : 'opacity-0 scale-95 pointer-events-none'}
                        `}
                    >
                        Tap to select, hold to view details
                    </div>
                </div>
            </div>

            {/* Package name, version, and last updated */}
            <div className="flex items-center justify-between mb-2 relative z-10">
                <div className="flex flex-col flex-1 min-w-0">
                    <h3 className="text-sm font-semibold truncate flex items-center gap-2">
                        {card.package.name}
                        {card.isSelected && <Check className="w-4 h-4 text-green-600" />}
                    </h3>
                    <div className="flex items-center gap-2 text-gray-500" style={{ fontSize: '12px' }}>
                        <span>{card.package.version}</span>
                        <span className="flex items-center gap-1">
                            <Clock className="w-3 h-3 text-gray-400" />
                            {Utils.formatRelativeTime(card.package.lastUpdated)}
                        </span>
                    </div>
                </div>
            </div>

            {/* Package short description */}
            <p className="text-gray-700 line-clamp-2 relative z-10" style={{ fontSize: '14px' }}>{card.package.shortDescription}</p>

            <Separator className='mt-2 mb-2 relative z-10' />
            <div className="flex justify-between items-center text-gray-500 relative z-10" style={{ fontSize: '12px' }}>
                {/* Download count on the left */}
                {card.metricCount ? (
                    <span>
                        Used in {Utils.formatNumber(card.metricCount)} {card.metricCount === 1 ? 'project' : 'projects'}
                    </span>
                ) : <span>No usage yet</span>}

                {/* Most Used badge on the right */}
                {card.isTop && (
                    <Badge style={{ fontSize: '8px', padding: '2px 4px', borderRadius: '4px' }}>
                        Most Used
                    </Badge>
                )}
            </div>
        </div>
    );
}

/**
 * `PackageCardSkeleton` is a placeholder UI component used to indicate
 * that a package card is loading. It mimics the structure of a real package
 * card using skeleton elements, giving users a visual cue while data is
 * being fetched.
 *
 * --- Structure ---
 * 1. **Container**
 *    - `div` with padding, border, rounded corners, and a white background.
 *    - Uses `animate-pulse` to provide a pulsating loading effect.
 * 
 * 2. **Top-right icon placeholder**
 *    - Small square in the top-right corner to simulate an info or action icon.
 *
 * 3. **Header section**
 *    - Flex container with:
 *      - **Title skeleton** — rectangular placeholder for package name.
 *      - **Version and last updated skeletons** — two smaller rectangles simulating metadata.
 *
 * 4. **Description section**
 *    - Two horizontal skeleton bars representing the package description.
 *    - The first spans full width, the second spans three-quarters.
 *
 * --- Usage ---
 * ```tsx
 * <PackageCardSkeleton />
 * ```
 *
 * This component is typically displayed while the actual package data
 * is being loaded from an API.
 */
function PackageCardSkeleton() {
    return (
        <div className="relative rounded-lg border-2 p-4 bg-white border-gray-200 animate-pulse">
            {/* top right info icon placeholder */}
            <div className="absolute top-2 right-2 w-4 h-4 bg-gray-200 rounded" />

            <div className="flex items-center justify-between mb-2">
                <div className="flex flex-col flex-1 min-w-0 gap-2">
                    {/* title */}
                    <div className="h-4 w-32 bg-gray-200 rounded" />

                    {/* version + last updated */}
                    <div className="flex items-center gap-2">
                        <div className="h-3 w-12 bg-gray-200 rounded" />
                        <div className="h-3 w-20 bg-gray-200 rounded" />
                    </div>
                </div>
            </div>

            {/* description */}
            <div className="h-4 w-full bg-gray-200 rounded mb-2" />
            <div className="h-4 w-3/4 bg-gray-200 rounded" />
        </div>
    );
}

/**
 * Props for the `PackageFetchError` component.
 *
 * Provides a callback function to handle retry attempts when package data
 * fails to load.
 */
interface PackageFetchErrorProps {
    /**
     * Callback triggered when the user clicks the retry button.
     *
     * Typically re-attempts fetching package data from the API.
     */
    onRefresh: () => void;
}

/**
 * Error alert component displayed when package data cannot be loaded.
 *
 * Features:
 * - Prominent red-themed error styling with icon
 * - Clear error message explaining the issue
 * - Actionable retry button to attempt fetching data again
 * - Appropriate sizing and styling for the marketplace context
 *
 * @param onRefresh - Callback function to retry fetching packages
 *
 * @remarks
 * - Uses AlertCircle icon from lucide-react for visual error indication
 * - Includes descriptive text with troubleshooting suggestions
 * - Provides "Retry" button as primary call to action
 * - Designed with red color scheme (bg-red-50, text-red-600, border-red-200)
 *
 * @example
 * <PackageFetchError onRefresh={() => refetchPackages()} />
 */
function PackageFetchError(error: PackageFetchErrorProps) {
    return (
        <div className="text-red-600 bg-red-50 border border-red-200 rounded-lg p-6 text-center">
            <div className="flex items-center justify-center gap-2 mb-2">
                <AlertCircle className="w-6 h-6" />
                <span className="font-medium" style={{ fontSize: "14px" }}>Unable to load packages</span>
            </div>
            <p className="text-sm text-red-500 mb-4">
                Failed to fetch package data. Please check your connection and try again.
            </p>
            <button
                type='button'
                onClick={error.onRefresh}
                className="px-4 py-2 bg-red-100 hover:bg-red-200 text-red-700 rounded-md transition-colors cursor-pointer font-medium"
                style={{ fontSize: "12px" }}
            >
                Retry Loading Packages
            </button>
        </div>
    );
}