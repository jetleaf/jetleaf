import { Bug, Package, X } from 'lucide-react';
import { JSX, useRef, useEffect, useState } from 'react';
import Metric from '../types/metric';
import { useMobile } from '../utils/hooks';
import Utils from '../utils/Utility'
import { motion, AnimatePresence } from 'framer-motion';
import ProjectConfig from '../types/project_config';

/**
 * Extended props for the header component beyond basic statistics.
 *
 * These props provide access to project configuration data and package
 * management functionality required for the selected packages modal.
 */
interface ExtendedHeaderProps {
    /**
     * The project configuration data.
     *
     * Contains all project settings including:
     * - Project name, description, and ID
     * - Selected Jetleaf and Dart SDK versions
     * - List of currently selected packages
     * - Additional configuration options
     *
     * @remarks
     * Used by the selected packages modal to display and manage the
     * list of packages the user has selected for their project.
     */
    config: ProjectConfig;

    /**
     * Callback to remove a package from the selection.
     *
     * Triggered when a user clicks the remove button next to a package
     * in the selected packages modal.
     *
     * @param packageId - The unique identifier of the package to remove
     * @remarks
     * This should update the parent component's state to remove the
     * package from the selected packages list. The modal will then
     * re-render with the updated list.
     *
     * @example
     * ```typescript
     * const handleRemovePackage = (packageId: string) => {
     *   setSelectedPackages(prev => prev.filter(pkg => pkg.id !== packageId));
     * };
     * ```
     */
    onRemovePackage: (packageId: string) => void;
}

/**
 * Props for the header component showing metrics and issues.
 *
 * Used to pass live metric and issue count data along with loading states.
 */
interface ExtraHeaderProps {
    /** Latest project metric data, or `null` if not loaded */
    metric: Metric | null;

    /** True if the metric data is still loading */
    metricLoading: boolean;

    /** Current issue count, or `null` if not loaded */
    issues: number | null;

    /** True if the issue count is still loading */
    issuesLoading: boolean;
}

/**
 * Props for the `Header` component.
 *
 * Defines the data and callbacks needed to render the header section
 * of the application, including navigation controls and package selection
 * indicators.
 */
interface HeaderProps extends ExtraHeaderProps, ExtendedHeaderProps {
    /**
     * Number of currently selected packages in the project.
     *
     * Typically displayed as a badge or counter in the header, providing
     * users with a quick reference to how many packages have been chosen
     * for the project configuration.
     */
    selectedPackagesCount: number;
}

/**
 * Header component for the Jetleaf Start page.
 *
 * Displays:
 * - Navigation back button
 * - Project logo and title
 * - Number of selected packages (as a clickable badge)
 * - Header statistics (metrics and issues)
 *
 * The layout adapts for mobile and desktop:
 * - Mobile: Stacked layout with back button and badge on top, logo below
 * - Desktop: Single row with back button, logo, and badge aligned horizontally
 *
 * Features:
 * - Clickable package count badge that opens a modal to manage selected packages
 * - Responsive design with mobile-optimized header statistics
 * - Smooth hover and click animations on interactive elements
 * - Right-sided modal for package management with proper accessibility
 *
 * @param props - HeaderProps containing configuration, metrics, and callbacks
 *
 * @remarks
 * - Uses local state (`isModalOpen`) to control the visibility of the selected packages modal
 * - The floating badge uses a custom clipPath for its slanted design
 * - Modal is always in the DOM but visibility is controlled by CSS classes for smooth animations
 * - Includes keyboard navigation support (Enter/Space) for the badge
 *
 * @example
 * ```tsx
 * <Header
 *   selectedPackagesCount={3}
 *   config={projectConfig}
 *   onRemovePackage={handleRemovePackage}
 *   metric={metricData}
 *   metricLoading={false}
 *   issues={5}
 *   issuesLoading={false}
 * />
 * ```
 */
export default function Header(props: HeaderProps) {
    /**
     * State controlling the visibility of the selected packages modal.
     *
     * - `true`: Modal is visible (slides in from right)
     * - `false`: Modal is hidden (slides out to right)
     *
     * @remarks
     * Toggled by clicking the floating package count badge.
     * Modal remains in DOM but visibility controlled by CSS for smooth animations.
     */
    const [isModalOpen, setIsModalOpen] = useState(false);

    return (
        <>
            <header className="relative bg-white border-b border-gray-200 sticky top-0 z-10 shadow-sm overflow-visible">
                <div className="mx-auto px-4 py-4 flex items-center justify-between">
                    {/* Left */}
                    <div className="flex items-center gap-2">
                        <a href='https://jetleaf.hapnium.com' style={{ textDecoration: "none" }}>
                            <img alt="logo" src="logo.png" height={40} width={40} />
                        </a>
                        <div>
                            <h1 className="text-base font-medium">Jetleaf Framework</h1>
                            <p className="text-xs text-gray-500" style={{ fontSize: "11px" }}>
                                Configure and generate your project
                            </p>
                        </div>
                    </div>

                    {/* Right */}
                    <HeaderStats
                        metric={props.metric}
                        metricLoading={props.metricLoading}
                        issues={props.issues}
                        issuesLoading={props.issuesLoading}
                    />
                </div>

                {/* Floating slanted status badge - now clickable */}
                <div
                    className="
                        absolute
                        right-4
                        -bottom-4
                        px-4
                        py-1.5
                        text-xs
                        font-medium
                        tracking-wide
                        z-20
                        select-none
                        cursor-pointer
                        transition-all
                        duration-200
                        hover:scale-105
                        hover:shadow-lg
                        active:scale-95
                    "
                    style={{
                        fontSize: '12px',
                        clipPath: 'polygon(0% 0%, 92% 0%, 100% 100%, 8% 100%)',
                        background: 'linear-gradient(135deg, rgb(52, 150, 88), rgb(52, 150, 88))',
                        color: 'rgb(244, 244, 244)',
                        boxShadow: '0 4px 10px rgba(34,197,94,0.15), inset 0 0 0 1px rgba(255,255,255,0.25)',
                    }}
                    onClick={() => setIsModalOpen(true)}
                    role="button"
                    tabIndex={0}
                    aria-label={`View ${props.selectedPackagesCount} selected packages`}
                    onKeyDown={(e) => {
                        if (e.key === 'Enter' || e.key === ' ') {
                            e.preventDefault();
                            setIsModalOpen(true);
                        }
                    }}
                >
                    {props.selectedPackagesCount === 0 ? 'No' : props.selectedPackagesCount}{' '}
                    {props.selectedPackagesCount === 0 || props.selectedPackagesCount === 1 ? 'package' : 'packages'} selected
                </div>
            </header>

            {/* Selected Packages Modal - Always in DOM but visibility controlled by CSS */}
            <SelectedPackagesModal
                isOpen={isModalOpen}
                onClose={() => setIsModalOpen(false)}
                config={props.config}
                onRemovePackage={props.onRemovePackage}
            />
        </>
    );
}

/* -------------------------------------------------------
 * Header stat button with animated background & single tooltip
 * ----------------------------------------------------- */

/**
 * Props for the `HeaderStatButton` component, which displays
 * a single statistic button in the header with optional tooltip,
 * count, and click behavior.
 *
 * Each button typically represents a project metric, issue count,
 * or other header-level interactive data.
 */
interface HeaderStatButtonProps {
    /** The icon displayed on the button (typically a Lucide React icon) */
    icon: React.ReactNode;

    /** The text label displayed next to the icon */
    label: string;

    /** The numeric or string count displayed on the button */
    count: string;

    /** The tooltip text shown on hover when the button is inactive */
    tooltip: string;

    /** Tailwind CSS class defining the color of the button (e.g., "text-blue-500") */
    colorClass: string;

    /** Optional click handler when the button is clicked */
    onClick?: () => void;

    /** The currently active tooltip label, or `null` if no tooltip is active */
    activeTooltip: string | null;

    /** Whether the button should render a border */
    showBorder: boolean;

    /** If true, disables click interactions for this button */
    isClickDisabled: boolean;

    /** Function to update the currently active tooltip */
    setActiveTooltip: (label: string | null) => void;
}

/**
 * A single statistic button displayed in the header.
 * 
 * This component shows an icon and a count, with an optional tooltip
 * that appears on hover. It supports interactive features like:
 * - Click handling (with optional disabled state)
 * - Tooltip auto-hide after 2 seconds
 * - Conditional border rendering
 * - Animated hover effects using Framer Motion
 * 
 * Props are defined in `HeaderStatButtonProps`.
 * @param {React.ReactNode} icon - The icon to display (typically a Lucide React icon)
 * @returns {JSX.Element} A styled header button with icon, count, and tooltip
 * @example <HeaderStatButton
  icon={<Eye />}
  label="Preview"
  count="42"
  tooltip="Number of previews"
  colorClass="text-blue-500"
  onClick={() => console.log("Clicked!")}
  activeTooltip={activeTooltip}
  showBorder={true}
  isClickDisabled={false}
  setActiveTooltip={setActiveTooltip}
/>
 */
function HeaderStatButton({
    icon,
    label,
    count,
    tooltip,
    colorClass,
    onClick,
    activeTooltip,
    showBorder,
    isClickDisabled,
    setActiveTooltip,
}: HeaderStatButtonProps): JSX.Element {
    /**
     * Ref for controlling the tooltip auto-hide timer.
     *
     * - `autoHideRef` stores the ID of the timer created by `window.setTimeout`.
     * - Initialized as `null`.
     * - Allows clearing or resetting the timer when the tooltip is shown or the component unmounts.
     */
    const autoHideRef = useRef<number | null>(null);

    /**
     * Boolean flag indicating whether the tooltip for this button is currently visible.
     *
     * - `tooltipVisible` is `true` when `activeTooltip` matches this button's `label`.
     * - Used to conditionally render and animate the tooltip.
     */
    const tooltipVisible = activeTooltip === label;

    /**
     * Handles mouse enter events on the button.
     *
     * Behavior:
     * 1. Sets this button's tooltip as the active tooltip using `setActiveTooltip(label)`.
     *    This closes any other tooltip immediately.
     * 2. Clears any existing auto-hide timer stored in `autoHideRef`.
     * 3. Sets a new timer that will automatically hide the tooltip after 2 seconds
     *    by calling `setActiveTooltip(null)`.
     */
    const handleMouseEnter = () => {
        // Close any other tooltip immediately
        setActiveTooltip(label);

        // Reset timer
        if (autoHideRef.current) {
            clearTimeout(autoHideRef.current);
        }

        // Auto-dismiss after 2 seconds
        autoHideRef.current = window.setTimeout(() => {
            setActiveTooltip(null);
        }, 2000);
    };

    /**
     * Cleanup effect to prevent memory leaks.
     *
     * Clears any active auto-hide timer when the component is unmounted.
     * This ensures that no pending `setActiveTooltip` calls run after unmount.
     */
    useEffect(() => {
        return () => {
            if (autoHideRef.current) {
                clearTimeout(autoHideRef.current);
            }
        };
    }, []);


    return (
        <div className="relative group">
            <motion.button
                type="button"
                onClick={() => { if (!isClickDisabled && onClick) onClick(); }}
                onMouseEnter={handleMouseEnter}
                className={`
                    relative flex items-center gap-1.5 px-3 py-1.5
                    rounded-md
                    ${showBorder ? "border-2 border-black" : ""}
                    text-xs font-medium overflow-hidden
                    ${!isClickDisabled ? "cursor-pointer" : ""}
                    ${isClickDisabled ? "opacity-50 cursor-not-allowed" : ""}
                `}
                style={{
                    backgroundColor: "#ffffff",
                }}
                initial={{
                    translateX: 0,
                    translateY: 0,
                    backgroundImage: "linear-gradient(to bottom, rgba(0,0,0,0.2) 0%, rgba(0,0,0,0.2) 100%)",
                    backgroundSize: "100% 0%",
                }}
                whileHover={{
                    translateX: 1,
                    translateY: 1,
                    backgroundSize: "100% 100%",
                }}
                transition={{
                    duration: 0.3,
                    ease: "easeOut"
                }}
            >
                {/* Button content */}
                <span className={`relative z-10 ${colorClass}`}>{icon}</span>
                <span className="relative z-10">{count}</span>
            </motion.button>

            {/* Tooltip */}
            <motion.div
                className="absolute right-0 top-9 bg-gray-800 text-white text-xs px-2 py-1 rounded shadow-md whitespace-nowrap z-50"
                initial={{ opacity: 0, scale: 0.95 }}
                animate={{
                    opacity: tooltipVisible ? 1 : 0,
                    scale: tooltipVisible ? 1 : 0.95
                }}
                transition={{ duration: 0.2 }}
                style={{ pointerEvents: tooltipVisible ? "auto" : "none" }}
            >
                {tooltip}
            </motion.div>
        </div>
    );
}

/* -------------------------------------------------------
 * Skeleton shimmer for HeaderStats buttons
 * ----------------------------------------------------- */

/**
 * Skeleton loader for header statistics.
 *
 * Displays a row of placeholder boxes to indicate loading state
 * for header buttons or metrics. Each box pulses to mimic content loading.
 *
 * @param {Object} props - Component props
 * @param {number} [props.count=2] - Number of skeleton boxes to render
 *
 * @returns {JSX.Element} A flex row of pulsing placeholder boxes
 *
 * @example
 * <HeaderStatSkeleton count={3} />
 */
function HeaderStatSkeleton({ count = 2 }: { count?: number }): JSX.Element {
    return (
        <div className="flex items-center gap-2">
            {Array.from({ length: count }).map((_, i) => (
                <div
                    key={i}
                    className="h-6 rounded-md bg-gray-200 animate-pulse border-2 border-gray-300"
                    style={{ width: "50px" }}
                />
            ))}
        </div>
    );
}

/* -------------------------------------------------------
 * HeaderStats main component
 * ----------------------------------------------------- */

/**
 * Header statistics component.
 *
 * Displays key project metrics (issues and generated projects) as interactive buttons
 * in the header. Supports desktop and mobile layouts with responsive behavior:
 * - Desktop: Buttons are rendered inline.
 * - Mobile: Buttons appear in a floating vertical panel.
 *
 * Tooltips are managed globally, ensuring only one is visible at a time.
 * Loading states are handled with `HeaderStatSkeleton` placeholders.
 *
 * @param {ExtraHeaderProps} props - Props for metric and issue counts with loading states
 * @param {Metric | null} props.metric - Project metric data, or `null` if unavailable
 * @param {boolean} props.metricLoading - Whether metric data is still loading
 * @param {number | null} props.issues - Current issue count, or `null` if unavailable
 * @param {boolean} props.issuesLoading - Whether issue count is still loading
 *
 * @returns {JSX.Element} A header stats section with metric buttons and tooltips
 *
 * @example
 * <HeaderStats
 *   metric={metric}
 *   metricLoading={metricLoading}
 *   issues={issues}
 *   issuesLoading={issuesLoading}
 * />
 */
function HeaderStats({ metric, metricLoading, issues, issuesLoading }: ExtraHeaderProps): JSX.Element {
    /**
     * Determines if the current viewport is considered mobile.
     *
     * Uses the custom `useMobile` hook. Returns `true` if the viewport
     * width is below the defined mobile breakpoint, otherwise `false`.
     * Can be used to conditionally render mobile-specific UI elements.
     */
    const isMobile = useMobile();

    /**
     * State for managing the currently active tooltip in the header.
     *
     * - Only one tooltip is visible at a time.
     * - `activeTooltip` holds the label of the currently visible tooltip, or `null` if none.
     * - `setActiveTooltip` is the setter function used to update the active tooltip.
     */
    const [activeTooltip, setActiveTooltip] = useState<string | null>(null);

    /**
     * Boolean flag indicating whether the header data is still loading.
     *
     * - True if either `metricLoading` or `issuesLoading` is true.
     * - Used to conditionally render loading states or skeletons.
     */
    const loading = metricLoading || issuesLoading;

    /**
     * Formatted total metric count for display in the header.
     *
     * - Uses `Utils.formatNumber` to convert the raw metric total into a user-friendly string.
     * - Defaults to "0" if `metric` is null or `metric.totalCount` is undefined.
     */
    const generatedCount = Utils.formatNumber(metric?.totalCount ?? 0);

    /**
     * Formatted issue count for display in the header.
     *
     * - Uses `Utils.formatNumber` to convert the raw issue count into a user-friendly string.
     * - Defaults to "0" if `issues` is null or undefined.
     */
    const issueCount = Utils.formatNumber(issues ?? 0);

    /**
     * Render the skeleton loader if the data is still loading.
     *
     * - Uses `HeaderStatSkeleton` to display placeholder boxes
     *   instead of the actual metrics.
     */
    if (loading) return <HeaderStatSkeleton />;

    /**
     * Header statistic buttons for desktop and mobile views.
     *
     * An array of `<HeaderStatButton />` components representing key metrics:
     * - "Issues" button: shows the current open GitHub issues.
     * - "Generated" button: shows the total number of generated projects.
     *
     * Each button handles its own tooltip visibility and click behavior.
     * The `showBorder` prop is disabled on mobile to reduce visual clutter.
     */
    const buttons = [
        /**
         * "Issues" button
         *
         * - Icon: Bug
         * - Label: "Issues"
         * - Count: Formatted `issueCount`
         * - Tooltip: "Open GitHub issues"
         * - Color: Yellow
         * - Opens GitHub issues page in a new tab when clicked
         * - Tooltip controlled via `activeTooltip` state
         * - Disabled if `issueCount` is "0"
         */
        <HeaderStatButton
            key="issues"
            icon={<Bug className="w-4 h-4 fill-current" />}
            label="Issues"
            count={issueCount}
            tooltip="Open GitHub issues"
            colorClass="text-yellow-500"
            onClick={() => window.open("https://github.com/jetleaf/jetleaf/issues", "_blank")}
            activeTooltip={activeTooltip}
            showBorder={!isMobile}
            isClickDisabled={issueCount === "0"}
            setActiveTooltip={setActiveTooltip}
        />,

        /**
         * "Generated" button
         *
         * - Icon: Package
         * - Label: "Generated"
         * - Count: Formatted `generatedCount`
         * - Tooltip: Shows number of generated projects, or a default message if none
         * - Color: Green
         * - Disabled click behavior (set `isClickDisabled` to true)
         * - Tooltip controlled via `activeTooltip` state
         */
        <HeaderStatButton
            key="generated"
            icon={<Package className="w-4 h-4 fill-current" />}
            label="Generated"
            count={generatedCount}
            showBorder={!isMobile}
            tooltip={metric?.generated ? `${generatedCount} generated projects` : "No projects generated yet"}
            colorClass="text-green-600"
            onClick={() => {
                return;
            }}
            isClickDisabled={true}
            activeTooltip={activeTooltip}
            setActiveTooltip={setActiveTooltip}
        />,
    ];

    return (
        <div className="relative flex items-center gap-2">
            {/* Desktop buttons */}
            {!isMobile && buttons}

            {/* Floating panel */}
            {isMobile && (
                <div
                    className={`
                        fixed top-1/2 right-0 w-40 bg-white
                        rounded-md shadow-lg flex flex-col p-2
                        transform -translate-y-1/2
                        transition-transform duration-300
                        translate-x-0 opacity-100
                        z-50
                    `}
                >
                    {buttons}
                </div>
            )}

        </div>
    );
}

/**
 * Props for the `SelectedPackagesModal` component.
 *
 * Provides the data and callbacks needed to display and manage selected packages
 * in a right-sided modal/drawer interface.
 */
interface SelectedPackagesModalProps extends ExtendedHeaderProps {
    /**
     * Whether the modal is currently visible.
     *
     * Controls the visibility of the modal/drawer.
     */
    isOpen: boolean;

    /**
     * Callback to close the modal.
     *
     * Typically triggered when clicking outside the modal or on a close button.
     */
    onClose: () => void;
}

/**
 * A right-sided modal/drawer component that displays selected packages.
 *
 * Features:
 * - Slides in from the right side of the screen with smooth framer-motion animations
 * - Shows list of selected packages with ability to remove them
 * - Empty state when no packages are selected
 * - Smooth animations for opening/closing using AnimatePresence
 * - Clicking outside the modal closes it (via overlay)
 * 
 * @param {SelectedPackagesModalProps} prop - The prop data
 *
 * @remarks
 * - Uses framer-motion for professional animations
 * - AnimatePresence handles enter/exit animations
 * - Includes backdrop overlay that closes the modal when clicked
 * - Responsive design that works on mobile and desktop
 * - Clean, minimal UI with clear remove actions
 */
function SelectedPackagesModal(prop: SelectedPackagesModalProps) {
    const selectedPackages = prop.config.selectedPackages;

    // Prevent body scroll when modal is open
    useEffect(() => {
        if (prop.isOpen) {
            document.body.style.overflow = 'hidden';
        } else {
            document.body.style.overflow = 'auto';
        }

        return () => {
            document.body.style.overflow = 'auto';
        };
    }, [prop.isOpen]);

    return (
        <AnimatePresence>
            {/* Modal/drawer */}
            {prop.isOpen && (
                <motion.div
                    key="modal"
                    initial={{ x: '100%' }}
                    animate={{ x: 0 }}
                    exit={{ x: '100%' }}
                    transition={{
                        type: "tween",
                        duration: 0.3,
                        ease: "easeInOut"
                    }}
                    className="fixed right-0 top-0 h-full w-full max-w-md bg-white shadow-xl z-50 flex flex-col"
                    onClick={(e) => e.stopPropagation()}
                >
                    {/* Header */}
                    <div className="flex items-center justify-between p-4 border-b bg-green-100">
                        <div>
                            <h2 className="text-lg font-semibold text-green-700" style={{ fontSize: "16px" }}>Selected Packages</h2>
                            <p className="text-sm text-gray-500" style={{ fontSize: "12px" }}>
                                {selectedPackages.length === 0 
                                    ? 'No selected package'
                                    : `${selectedPackages.length} selected ${selectedPackages.length === 1 ? 'package' : 'packages'}`}
                            </p>
                        </div>
                        <button
                            onClick={prop.onClose}
                            type='button'
                            className="p-2 hover:bg-gray-100 rounded-full transition-colors cursor-pointer"
                            aria-label="Close modal"
                        >
                            <X className="w-5 h-5" />
                        </button>
                    </div>

                    {/* Content */}
                    <div className="flex-1 overflow-y-auto p-2">
                        {selectedPackages.length === 0 ? (
                            <div className="text-center py-12">
                                <Package className="w-12 h-12 text-gray-300 mx-auto mb-3" />
                                <p className="text-gray-500 mb-2">No packages selected</p>
                                <p className="text-sm text-gray-400">
                                    Go to the marketplace and select packages to add them here
                                </p>
                                <button
                                    onClick={prop.onClose}
                                    type='button'
                                    className="mt-6 px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors"
                                    style={{ fontSize: "12px" }}
                                >
                                    Close & Select Packages
                                </button>
                            </div>
                        ) : (
                            <div className="space-y-3">
                                {selectedPackages.map(pkg => (
                                    <div
                                        key={pkg.id}
                                        className="flex items-center justify-between p-2 bg-gray-50 rounded-lg group"
                                    >
                                        <div className="flex-1 min-w-0">
                                            <p className="text-sm font-medium truncate">{pkg.name}</p>
                                            <p className="text-xs text-gray-500">{pkg.version}</p>
                                            <p className="text-xs text-gray-400 truncate mt-1">{pkg.shortDescription}</p>
                                        </div>
                                        <button
                                            onClick={() => prop.onRemovePackage(pkg.id)}
                                            type='button'
                                            className="cursor-pointer p-1.5 text-gray-400 hover:text-red-600 hover:bg-gray-100 rounded-full transition-colors opacity-0 group-hover:opacity-100"
                                            aria-label={`Remove ${pkg.name}`}
                                        >
                                            <X className="w-4 h-4" />
                                        </button>
                                    </div>
                                ))}
                            </div>
                        )}
                    </div>
                </motion.div>
            )}
        </AnimatePresence>
    );
}