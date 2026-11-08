import "./styles/index.css";
import "./styles/globals.css"

import { createRoot, type Root } from "react-dom/client";
import { Toaster } from './components/sonner';
import { Eye, Settings } from "lucide-react";
import { AnimatePresence, motion } from "framer-motion";
import { Dialog, DialogPortal, DialogOverlay, DialogContent } from "./components/dialog";
import { ScrollArea } from "./components/scroll-area";
import { useState, useMemo, useEffect } from "react";
import { toast } from "sonner";
import Metric from "./types/metric";
import Package from "./types/package";
import ProjectConfig from "./types/project_config";
import { PubDevPackage } from "./types/pubspec";
import { useMobile, usePolling } from "./utils/hooks";
import Constants from "./utils/Constants";
import Utils from "./utils/Utility";
import Header from './ui/Header'
import ProjectConfiguration from "./ui/ProjectConfiguration";
import PackageMarketplace from "./ui/PackageMarketplace";
import ProjectSummary from "./ui/ProjectSummary";
import PackageInformation from './ui/PackageInformation'

/**
 * The root container for the React application.
 *
 * This element is used as the mount point for the React tree.
 */
const container = document.getElementById("root")!;

/**
 * The React 18 root object created with `createRoot()`.
 *
 * Used to render the main `<App />` component. Stored globally
 * on `window.__react_root` to support Hot Module Replacement (HMR)
 * without creating multiple roots for the same container.
 */
let root: Root;

/**
 * Initialize the React root.
 *
 * - Creates a new root if one does not already exist (first load).
 * - Reuses the existing root from `window.__react_root` if present (HMR reloads).
 */
if (!(window as any).__react_root) {
    root = createRoot(container);
    (window as any).__react_root = root; // store globally for HMR
} else {
    root = (window as any).__react_root;
}

/**
 * Render the main application into the root.
 *
 * This will mount the `<App />` component into the container,
 * or update it if already mounted (e.g., during HMR).
 */
root.render(<App />);

/**
 * Represents the currently active mobile panel in the bottom floating menu.
 *
 * Possible values:
 * - `"config"` → Shows the Project Configuration panel
 * - `"summary"` → Shows the Project Summary / Preview panel
 * - `null` → No mobile panel is currently open
 */
type MobilePanel = "config" | "summary" | null;

/**
 * Defines a single action/button in the mobile floating menu.
 *
 * Properties:
 * - `key` – the `MobilePanel` this button controls; clicking the button
 *    will open or switch to the corresponding panel.
 * - `label` – the text label displayed next to the button icon.
 * - `Icon` – a React component (typically from `lucide-react`) used as
 *    the button icon.
 */
type MobileAction = {
    key: MobilePanel;
    label: string;
    Icon: React.ComponentType<{ className?: string }>;
};

/**
 * Configuration array for the mobile floating action buttons.
 *
 * Each entry corresponds to a panel that can be opened from the bottom
 * menu on small screens. This array is used to dynamically render the
 * buttons, ensuring consistency between UI and state.
 *
 * Current entries:
 * - `"config"` → Config button with Settings icon
 * - `"summary"` → Preview button with Eye icon
 */
const mobileActions: MobileAction[] = [
    {
        key: "config",
        label: "Config",
        Icon: Settings,
    },
    {
        key: "summary",
        label: "Preview",
        Icon: Eye,
    },
];

/**
 * The main page for configuring and generating a new Dart project using Jetleaf.
 *
 * This component acts as the central workspace and orchestrates:
 * - live project configuration editing
 * - package discovery and selection
 * - validation of user-provided settings
 * - project download generation
 * - modal presentation of package details
 *
 * The UI is structured into a 3-column responsive layout:
 *
 * **Left:** Project configuration form  
 * **Center:** Package marketplace with search and filtering  
 * **Right:** Live project summary with generation controls
 *
 * State flows downward into child components, while updates propagate back
 * through controlled callbacks to maintain a single source of truth.
 */
export default function App() {
    /**
     * The current working project configuration.
     * Initialized using the default factory and updated incrementally as the user interacts.
     */
    const [config, setConfig] = useState<ProjectConfig>(ProjectConfig.default());

    /**
     * Stores the package currently selected for modal detail display.
     * `null` indicates no active modal content.
     */
    const [selectedPackageForDetails, setSelectedPackageForDetails] = useState<Package | null>(null);

    /**
     * Controls visibility of the package details modal.
     */
    const [isModalOpen, setIsModalOpen] = useState(false);

    /**
     * Determines if the current viewport width is considered mobile.
     *
     * Uses the custom `useMobile` hook with a breakpoint of 900px.
     * Returns `true` if the viewport width is less than or equal to 900px,
     * otherwise `false`. This is used to conditionally render mobile-specific
     * UI elements, like floating panels or simplified layouts.
     */
    const isMobile = useMobile(900);

    /**
     * State to track which mobile panel is currently open.
     *
     * - `mobilePanel` can be:
     *   - `"config"` → Project Configuration panel
     *   - `"summary"` → Project Summary / Preview panel
     *   - `null` → no panel is open
     * - `setMobilePanel` is the setter function to open or close a panel.
     */
    const [mobilePanel, setMobilePanel] = useState<MobilePanel>(null);

    /**
     * Fetches the latest metric data from the API.
     *
     * This asynchronous function:
     * 1. Sends a GET request to `${Constants.BASE_API}/metric`.
     * 2. Parses the JSON response.
     * 3. Logs the raw JSON to the console for debugging purposes.
     * 4. Throws an error if the response is not OK (status not 2xx).
     * 5. Converts the JSON into a `Metric` instance using `Metric.fromApi`.
     *
     * @returns {Promise<Metric>} A promise that resolves to a Metric object.
     * @throws {Error} If the API response is not OK.
     */
    async function fetchMetric(): Promise<Metric> {
        const res = await fetch(`${Constants.BASE_API}/metric`);
        const json = await res.json();

        if (!res.ok) throw new Error("Metric fetch failed");
        return Metric.fromApi(json); // Metric
    }

    /**
     * Fetches the total number of open issues across all repositories
     * in the Jetleaf GitHub organization.
     *
     * This asynchronous function:
     * 1. Sends a GET request to the GitHub API endpoint for organization repositories.
     * 2. Validates that the HTTP response status is OK (2xx).
     * 3. Parses the JSON response into an array of repository objects.
     * 4. Validates that the response is an array.
     * 5. Iterates over each repository and sums the `open_issues` count.
     * 6. Logs errors to the console and returns a fallback value if the request fails.
     *
     * @returns {Promise<number>} A promise that resolves to the total number of open issues.
     *                            Returns `0` if the request fails or the response is invalid.
     */
    async function fetchIssuesCount(): Promise<number> {
        const GITHUB_API_URL = "https://api.github.com/orgs/jetleaf/repos";

        try {
            const response = await fetch(GITHUB_API_URL);

            if (!response.ok) {
                throw new Error(`GitHub API error: ${response.status}`);
            }

            const repos = await response.json();

            // Validate that we received an array
            if (!Array.isArray(repos)) {
                throw new Error("Invalid response format - expected array of repositories");
            }

            // Calculate total open issues
            let totalIssues = 0;
            for (const repo of repos) {
                // Ensure the property exists and is a number
                if (repo.open_issues !== undefined && typeof repo.open_issues === 'number') {
                    totalIssues += repo.open_issues;
                }
            }

            return totalIssues;

        } catch (error) {
            console.error("Failed to fetch issues count:", error);
            return 0; // return 0 as fallback value
        }
    }

    /**
     * Fetches the latest project metrics every 30 seconds.
     *
     * Returns an object containing:
     * - `data: metric` → The latest `Metric` object (or `undefined` if not loaded)
     * - `loading: metricLoading` → `true` while fetching, otherwise `false`
     * - `refetch: refetchMetric` → Function to manually refetch metrics
     */
    const { data: metric, loading: metricLoading, refetch: refetchMetric } = usePolling<Metric>(fetchMetric, 30_000);

    /**
     * Fetches the current issue count every 60 seconds.
     *
     * Returns an object containing:
     * - `data: issues` → The issue count (or `undefined` if not loaded)
     * - `loading: issuesLoading` → `true` while fetching, otherwise `false`
     */
    const { data: issues, loading: issuesLoading } = usePolling(fetchIssuesCount, 60_000);

    /**
     * Computes a lookup table of package usage counts from the latest metrics.
     *
     * - `packageMetrics[pkgId]` → Number of times the package appears in `metric.generated`
     * - Returns an empty object if `metric` is not yet loaded.
     *
     * This is memoized with `useMemo` to avoid recalculating on every render.
     */
    const packageMetrics = useMemo(() => {
        if (!metric) return {};

        const counts: Record<string, number> = {};

        // Each Generated object contains a `packages` array
        metric.generated.forEach(g => {
            g.packages.forEach(pkgId => {
                counts[pkgId] = (counts[pkgId] ?? 0) + 1;
            });
        });

        return counts;
    }, [metric]);

    /**
     * Loads the Jetleaf development tool package once on component mount.
     *
     * Behavior:
     * 1. Attempts to read a cached package from `localStorage`.
     * 2. If cached, uses the cached value.
     * 3. If not cached, fetches from `${Constants.BASE_API}/packages/jetleaf_cli` and stores in `localStorage`.
     * 4. Updates the project configuration (`config`) to include the devtool package.
     * 5. Logs an error if the fetch fails.
     *
     * This ensures that the DevTool package is always available without repeatedly hitting the network.
     */
    useEffect(() => {
        const fetchPackage = async () => {
            try {
                const cached = localStorage.getItem(Constants.DEV_TOOL_CACHE_KEY);
                let pkg: PubDevPackage;

                if (cached) {
                    const { data } = JSON.parse(cached) as { timestamp: number; data: PubDevPackage };
                    pkg = data;
                } else {
                    const res = await fetch(`${Constants.BASE_API}/packages/jetleaf_cli`);
                    pkg = await res.json();
                    localStorage.setItem(Constants.DEV_TOOL_CACHE_KEY, JSON.stringify({ timestamp: Date.now(), data: pkg }));
                }

                setConfig(prev => prev.cloneWith({ devtool: pkg }));
            } catch (err) {
                console.error('Failed to fetch Jetleaf package', err);
            }
        };

        fetchPackage();
    }, []);

    /**
     * Validates the current configuration and transforms validation results
     * into a lookup object keyed by field name.
     *
     * This allows child components to easily map errors to form inputs.
     */
    const validationErrors = useMemo(() => {
        const errors = Utils.validateProjectConfig(config);
        return errors.reduce((acc, error) => {
            acc[error.field] = error.message;
            return acc;
        }, {} as Record<string, string>);
    }, [config]);

    /**
     * Indicates whether the current configuration is eligible for project generation.
     * Validation requires:
     * - no validation errors
     * - a non-empty project name
     */
    const isValid = Object.keys(validationErrors).length === 0 && config.projectName.trim() !== '';

    /**
     * Toggles a package in the selected package list.
     *
     * - Adds the package if not already selected
     * - Removes it if it exists
     *
     * @param pkg - The package the user interacted with.
     */
    const handleTogglePackage = (pkg: Package) => {
        setConfig(prev => {
            const isSelected = prev.selectedPackages.some(p => p.id === pkg.id);

            return prev.cloneWith({
                selectedPackages: isSelected
                    ? prev.selectedPackages.filter(p => p.id !== pkg.id)
                    : [...prev.selectedPackages, pkg]
            });
        });
    };

    /**
     * Removes a package by its identifier from the current configuration.
     *
     * @param pkgId - The unique ID of the package to remove.
     */
    const handleRemovePackage = (pkgId: string) => {
        setConfig(prev => prev.cloneWith({ selectedPackages: prev.selectedPackages.filter(p => p.id !== pkgId) }));
    };

    /**
     * Opens the package details modal for the selected package.
     *
     * @param pkg - The package to display in the modal.
     */
    const handleShowPackageDetails = (pkg: Package) => {
        setSelectedPackageForDetails(pkg);
        setIsModalOpen(true);
    };

    /**
     * Generates the current project if the configuration is valid.
     *
     * This asynchronous function orchestrates the full project generation workflow:
     *
     * 1. **Validation Check**  
     *    - Immediately returns if the configuration is invalid (`!isValid`)  
     *    - Prevents duplicate generation if `config.isGenerating` is true
     *
     * 2. **Set Generating State**  
     *    - Updates `config.isGenerating` to `true` to indicate generation is in progress
     *
     * 3. **Update Metrics**  
     *    - Sends a POST request to `${Constants.BASE_API}/metric/update`  
     *    - Payload includes:
     *       - `name`: Project ID
     *       - `description`: Project description
     *       - `jetleaf`: Jetleaf version
     *       - `packages`: List of selected package IDs
     *
     * 4. **Download Project**  
     *    - Calls `downloadProject(config)` to trigger client-side download of the generated project
     *
     * 5. **Refresh Metrics**  
     *    - Calls `refetchMetric()` to update live metric data
     *
     * 6. **Reset Configuration**  
     *    - Resets the configuration to defaults while preserving the Jetleaf version
     *
     * 7. **Toast Notifications**  
     *    - On success: Shows a green toast confirming the project is ready to download  
     *    - On error: Shows a red toast indicating generation failed
     *
     * 8. **Finalize**  
     *    - Regardless of success or failure, sets `config.isGenerating` back to `false`
     *
     * @async
     * @function
     * @returns {Promise<void>} A promise that resolves when generation is complete.
     */
    const handleGenerate = async (): Promise<void> => {
        if (!isValid) return;
        if (config.isGenerating) return;

        setConfig(c => c.cloneWith({ isGenerating: true }));

        try {
            await fetch(`${Constants.BASE_API}/metric/update`, {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                },
                body: JSON.stringify({
                    name: config.projectId,
                    description: config.description,
                    jetleaf: config.version.version,
                    packages: config.selectedPackages.map(p => p.id),
                }),
            });

            Utils.downloadProject(config);
            await refetchMetric()
            setConfig(ProjectConfig.default().cloneWith({ version: config.version }));

            toast.success('Project generated successfully!', {
                description: `${config.projectName} is ready to download.`,
            });
        } catch {
            toast.error('Failed to generate project', {
                description: 'Please try again or contact support.',
            });
        } finally {
            setConfig(c => c.cloneWith({ isGenerating: false }));
        }
    };

    return (
        <>
            <div className="min-h-screen bg-gray-50">
                {/* Header section containing navigation and project summary badge */}
                <Header
                    selectedPackagesCount={config.selectedPackages.length}
                    metric={metric}
                    metricLoading={metricLoading}
                    issues={issues}
                    issuesLoading={issuesLoading}
                    onRemovePackage={handleRemovePackage}
                    config={config}
                />

                {/* Main content with 3-column layout */}
                <div className="max-w-[1800px] mx-auto px-4 py-4">
                    <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">

                        {/* Project configuration panel */}
                        {!isMobile && (
                            <div className="lg:col-span-3">
                                <div className="bg-white rounded-lg shadow-sm p-4 sticky top-24 border border-gray-200">
                                    <ProjectConfiguration
                                        config={config}
                                        onConfigChange={setConfig}
                                        errors={validationErrors}
                                    />
                                </div>
                            </div>
                        )}

                        {/* Package discovery pane */}
                        <div className="lg:col-span-6">
                            <div className="">
                                <PackageMarketplace
                                    selectedPackages={config.selectedPackages}
                                    onTogglePackage={handleTogglePackage}
                                    onShowPackageDetails={handleShowPackageDetails}
                                    packageMetrics={packageMetrics}
                                />
                            </div>
                        </div>

                        {/* Live summary and generate controls */}
                        {!isMobile && (
                            <div className="lg:col-span-3">
                                <div className="bg-white rounded-lg shadow-sm p-4 sticky top-24 border border-gray-200">
                                    <ProjectSummary
                                        config={config}
                                        onRemovePackage={handleRemovePackage}
                                        onGenerate={handleGenerate}
                                        isValid={isValid}
                                    />
                                </div>
                            </div>
                        )}
                    </div>
                </div>

                {/* Package details modal */}
                <PackageInformation
                    package={selectedPackageForDetails}
                    isOpen={isModalOpen}
                    onClose={() => setIsModalOpen(false)}
                    isSelected={
                        selectedPackageForDetails
                            ? config.selectedPackages.some(p => p.id === selectedPackageForDetails.id)
                            : false
                    }
                    onToggle={() => {
                        if (selectedPackageForDetails) {
                            handleTogglePackage(selectedPackageForDetails);
                        }
                    }}
                />

                <AnimatePresence>
                    {isMobile && mobilePanel && (
                        <Dialog open onOpenChange={() => setMobilePanel(null)}>
                            <DialogPortal>
                                <DialogOverlay>
                                    <DialogContent className="p-0 border-none bg-transparent shadow-none">
                                        <motion.div
                                            initial={{ y: "100%" }}
                                            animate={{ y: 0 }}
                                            exit={{ y: "100%" }}
                                            transition={{ type: "spring", damping: 25, stiffness: 300 }}
                                            className="bg-white rounded-t-xl overflow-y-auto touch-pan-y overscroll-contain"
                                            style={{ maxHeight: "85vh", borderRadius: "12px" }}
                                            drag="y"
                                            dragConstraints={{ top: 0 }}
                                            onDragEnd={(e, info) => {
                                                if (info.offset.y > 120) setMobilePanel(null);
                                            }}
                                        >
                                            <ScrollArea style={{ height: 'calc(100% - 1px)' }}>
                                                <div className="p-4">
                                                    {mobilePanel === "config" && (
                                                        <ProjectConfiguration
                                                            config={config}
                                                            onConfigChange={setConfig}
                                                            errors={validationErrors}
                                                        />
                                                    )}

                                                    {mobilePanel === "summary" && (
                                                        <ProjectSummary
                                                            config={config}
                                                            onRemovePackage={handleRemovePackage}
                                                            onGenerate={handleGenerate}
                                                            isValid={isValid}
                                                        />
                                                    )}
                                                </div>
                                            </ScrollArea>
                                        </motion.div>
                                    </DialogContent>
                                </DialogOverlay>
                            </DialogPortal>
                        </Dialog>
                    )}
                </AnimatePresence>

                {isMobile && (
                    <div className="fixed bottom-0 left-4 z-50 flex">
                        {mobileActions.map(({ key, label, Icon }, index) => (
                            <button
                                key={key}
                                type='button'
                                onClick={() => setMobilePanel(key)}
                                className={`
                                    flex items-center gap-2
                                    bg-gray-50 hover:bg-white
                                    px-3 py-2
                                    text-gray-700 hover:text-gray-900
                                    text-xs font-medium
                                    transition-all duration-150
                                    border border-gray-300
                                    hover:shadow-md hover:border-gray-400 hover:-translate-x-0.5
                                `}
                                style={{ fontSize: "12px" }}
                            >
                                <Icon className="h-4 w-4" />
                                {label}
                            </button>
                        ))}
                    </div>
                )}

            </div>
            <Toaster />
        </>
    );
}
