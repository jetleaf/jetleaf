import { JSX, useEffect, useRef, useState } from 'react';
import { Input } from '../components/input';
import { Label } from '../components/label';
import { Textarea } from '../components/textarea';
import { Switch } from '../components/switch';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '../components/select';
import semver from 'semver';
import ProjectConfig, { JetleafVersion, ResourceFileExtension } from '../types/project_config';
import { PubDevPackage } from '../types/pubspec';
import Constants from '../utils/Constants'
import Utils from '../utils/Utility'
import { AlertCircle } from 'lucide-react';

/**
 * Props for the ProjectConfiguration component.
 */
interface ProjectConfigurationProps {
    /** Current project configuration object. */
    config: ProjectConfig;

    /**
     * Callback invoked whenever the project configuration changes.
     * Should receive the updated ProjectConfig object.
     */
    onConfigChange: (config: ProjectConfig) => void;

    /**
     * A mapping of field names to error messages.
     * Used to display validation errors next to inputs.
     */
    errors: Record<string, string>;
}

/**
 * ProjectConfiguration component allows users to configure a Dart project
 * generated with Jetleaf.
 *
 * Features:
 * - Edit project name and description
 * - Select Dart SDK and Jetleaf versions, with automatic compatibility checking
 * - Toggle options such as including example code, Dockerfile, and CI/CD configuration
 * - Automatically generates a safe project ID from the project name
 * - Handles caching and fetching Jetleaf versions from the API
 *
 * @param config - The current project configuration.
 * @param onConfigChange - Callback invoked when any field in the configuration changes.
 * @param errors - Validation errors for the fields.
 *
 * @example
 * <ProjectConfiguration
 *   config={projectConfig}
 *   onConfigChange={updatedConfig => setProjectConfig(updatedConfig)}
 *   errors={{ projectName: 'Project name is required' }}
 * />
 */
export default function ProjectConfiguration({ config, onConfigChange, errors }: ProjectConfigurationProps) {
    /**
     * State storing the list of available Jetleaf versions.
     *
     * - Initially an empty array
     * - Populated by `fetchPackage` when data is successfully loaded
     * - Used to display version options in the UI
     */
    const [jetleafVersions, setJetleafVersions] = useState<JetleafVersion[]>([]);

    /**
     * State indicating whether Jetleaf version data is currently being loaded.
     *
     * - Initially `true` to show loading state on component mount
     * - Set to `true` at the start of `fetchPackage`
     * - Set to `false` at the end of `fetchPackage` (both success and error cases)
     * - Used to display skeleton loaders or actual version cards
     */
    const [isLoading, setIsLoading] = useState<boolean>(true);

    // Use a ref to store the latest config
    const configRef = useRef(config);
    
    // Update the ref whenever config changes
    useEffect(() => {
        configRef.current = config;
    }, [config]);

    /**
     * Fetches Jetleaf package data from cache or API and processes it.
     *
     * This asynchronous function:
     * 1. Sets loading state to `true`
     * 2. Attempts to retrieve cached package data from localStorage
     * 3. Falls back to API request if no valid cache exists
     * 4. Transforms raw package data into `JetleafVersion` objects
     * 5. Updates component state with fetched versions
     * 6. Sets a default version if none is currently configured
     * 7. Handles errors gracefully and logs them to console
     * 8. Ensures loading state is set to `false` when complete
     *
     * @remarks
     * - Cache Strategy: Uses `Constants.MAIN_CACHE_KEY` for localStorage caching
     * - Data Transformation: Maps API response to `JetleafVersion` interface
     * - Error Handling: Logs errors but doesn't crash the component
     * - State Management: Updates `jetleafVersions` and potentially triggers `onConfigChange`
     * - Default Selection: If no version is configured, selects the latest available version
     *
     * @example
     * ```typescript
     * // Manual fetch trigger
     * fetchPackage();
     *
     * // In useEffect for initial load
     * useEffect(() => {
     *   fetchPackage();
     * }, []);
     * ```
     *
     * @throws
     * - Logs to console if fetch fails but doesn't throw to prevent UI crash
     */
    const fetchPackage = async () => {
        try {
            setIsLoading(true);

            const cached = localStorage.getItem(Constants.MAIN_CACHE_KEY);
            let pkg: PubDevPackage;

            try {
                const res = await fetch(`${Constants.BASE_API}/packages/main`);
                pkg = await res.json();
                localStorage.setItem(Constants.MAIN_CACHE_KEY, JSON.stringify({ timestamp: Date.now(), data: pkg }));
            } catch (_) {
                if (cached) {
                    const { data } = JSON.parse(cached) as { timestamp: number; data: PubDevPackage };
                    pkg = data;
                } else {
                    const res = await fetch(`${Constants.BASE_API}/packages/main`);
                    pkg = await res.json();
                    localStorage.setItem(Constants.MAIN_CACHE_KEY, JSON.stringify({ timestamp: Date.now(), data: pkg }));
                }
            }

            // const versions: JetleafVersion[] = pkg.versions.map(v => ({
            //   version: v.version,
            //   dartSdk: v.pubspec.environment?.sdk || '',
            //   pkgVersion: v,
            // }));
            const versions: JetleafVersion[] = [{
                version: pkg.latest.version,
                dartSdk: pkg.latest.pubspec.environment?.sdk || '',
                pkgVersion: pkg.latest
            }];

            setJetleafVersions(versions);

            if (!configRef.current.version || !configRef.current.version.version || !configRef.current.version.dartSdk) {
                const latest = pkg.latest;
                onConfigChange(configRef.current.cloneWith({
                    version: {
                        version: latest.version,
                        dartSdk: semver.minVersion(latest.pubspec.environment?.sdk || '')?.version || '',
                        pkgVersion: latest
                    }
                }));
            }
        } catch (err) {
            console.error('Failed to fetch Jetleaf package', err);
        } finally {
            setIsLoading(false);
        }
    };

    /**
     * Effect hook that fetches Jetleaf package data on component mount.
     *
     * - Runs once when the component is first rendered (empty dependency array)
     * - Calls `fetchPackage` to load and cache Jetleaf version data
     * - No cleanup function needed as fetch operations are async and can be abandoned
     *
     * @remarks
     * This ensures the component has the latest version data immediately on load.
     * The effect only runs on initial mount, not on subsequent re-renders.
     */
    useEffect(() => {
        fetchPackage();
    }, []);

    /**
     * Generic handler for updating any field in the project configuration.
     *
     * Creates a new configuration object with the specified field updated,
     * with special handling for `projectName` to automatically generate a project ID.
     *
     * @param field - The name of the field to update in ProjectConfig
     * @param value - The new value for the field
     *
     * @remarks
     * - Uses `config.cloneWith()` to create an immutable copy of the config
     * - When `projectName` is changed, automatically generates a corresponding
     *   `projectId` using `Utils.generateProjectId()`
     * - Delegates the updated configuration to the parent via `onConfigChange`
     *
     * @example
     * ```typescript
     * // Update description field
     * handleChange('description', 'A new project description');
     *
     * // Update projectName (also updates projectId)
     * handleChange('projectName', 'My New Project');
     * ```
     */
    const handleChange = (field: keyof ProjectConfig, value: any) => {
        let updatedConfig = configRef.current.cloneWith({ [field]: value });
        if (field === 'projectName' && typeof value === 'string') {
            updatedConfig = updatedConfig.cloneWith({ projectId: Utils.generateProjectId(value) });
        }
        onConfigChange(updatedConfig);
    };

    /**
     * Renders the Jetleaf version selection interface based on loading state.
     *
     * Determines what to display in the version selection area:
     * 1. **Loading State**: Shows skeleton cards while data is being fetched
     * 2. **Error State**: Shows error message with retry button if no versions are available
     * 3. **Success State**: Shows interactive version chips when data is loaded
     *
     * @returns JSX.Element representing the appropriate version display UI
     *
     * @remarks
     * - **Loading**: Displays 6 `VersionChipCardSkeleton` components in a flex wrap layout
     * - **Error**: Shows `JetleafVersionError` component with retry callback to `fetchPackage`
     * - **Success**: Maps `jetleafVersions` to `VersionChipCard` components with selection logic
     *
     * Version chip click handler:
     * - Updates the selected Jetleaf version
     * - Adjusts Dart SDK version if incompatible with the selected Jetleaf version
     * - Uses semver to validate and resolve version compatibility
     *
     * @example
     * ```typescript
     * // In JSX
     * {displayVersion()}
     * ```
     */
    const displayVersion = (): JSX.Element => {
        if (isLoading) {
            return (
                <div className='flex gap-3 items-center flex-wrap'>
                    {Array.from({ length: 6 }).map((_, i) => <VersionChipCardSkeleton key={i} />)}
                </div>
            );
        }

        if (jetleafVersions.length === 0) {
            return <JetleafVersionError onRefresh={() => fetchPackage()} />;
        }

        return (
            <div className='flex gap-3 items-center flex-wrap'>
                {jetleafVersions.map(version => (
                    <VersionChipCard
                        version={version}
                        key={version.version}
                        isSelected={version.version === config.version.version}
                        onClick={() => {
                            let dartVersion = config.version?.dartSdk || '';
                            if (!semver.satisfies(semver.minVersion(dartVersion)?.version || '', version.dartSdk)) {
                                dartVersion = semver.minVersion(version.dartSdk)?.version || '';
                            }

                            onConfigChange(config.cloneWith({
                                version: {
                                    ...version,
                                    dartSdk: dartVersion
                                }
                            }));
                        }}
                    />
                ))}
            </div>
        );
    };

    return (
        <div className="space-y-6">
            <h2 className="text-xl mb-6">Project Configuration</h2>

            {/* Project Name */}
            <div>
                <Label htmlFor="projectName">Project Name *</Label>
                <Input
                    id="projectName"
                    value={config.projectName}
                    onChange={e =>
                        onConfigChange(
                            config.cloneWith({
                                projectName: e.target.value,
                                projectId: Utils.generateProjectId(e.target.value),
                            })
                        )
                    }
                    className={`mt-2 ${errors.projectName ? 'border-red-500' : ''}`}
                />
                {errors.projectName && (
                    <p className="text-sm text-red-500 mt-1" style={{ fontSize: '11px' }}>
                        {errors.projectName}
                    </p>
                )}
            </div>

            {/* Project Description */}
            <div>
                <Label htmlFor="description">Description</Label>
                <Textarea
                    id="description"
                    placeholder="A brief description of your project"
                    value={config.description}
                    onChange={e => handleChange('description', e.target.value)}
                    rows={4}
                    className="mt-2"
                />
            </div>

            {/* Dart SDK and Jetleaf Version */}
            <Label htmlFor="dartAndJetleafVersion" className="mb-2">Jetleaf and Dart SDK Version</Label>
            {displayVersion()}

            {/* Additional Options */}
            <div className="pt-4 space-y-4 border-t">
                <h3 className="text-sm">Additional Options</h3>

                {[
                    { key: 'includeExamples', label: 'Include Example Code' },
                    { key: 'generateDockerfile', label: 'Generate Dockerfile' },
                    // { key: 'addCICD', label: 'Add CI/CD Configuration' },
                    { key: 'addAnalysisOptions', label: 'Add analysis options' },
                    { key: 'addGitIgnore', label: 'Add .gitignore' },
                ].map(({ key, label }) => (
                    <div key={key} className="flex items-center justify-between">
                        <Label htmlFor={key} className="cursor-pointer">{label}</Label>
                        <Switch
                            id={key}
                            checked={(config as any)[key]}
                            onCheckedChange={(checked: boolean) => handleChange(key as any, checked)}
                        />
                    </div>
                ))}
            </div>

            <div className="pt-4 space-y-2 border-t">
                <Label htmlFor="resourceFileExtension">Resource File Extension</Label>
                <Select
                    value={config.resourceFileExtension || ResourceFileExtension.YAML}
                    onValueChange={(value: ResourceFileExtension) => handleChange('resourceFileExtension', value)}
                >
                    <SelectTrigger id="resourceFileExtension" className="mt-2">
                        <SelectValue placeholder="Select resource file type" />
                    </SelectTrigger>
                    <SelectContent>
                        {Object.values(ResourceFileExtension).map((ext) => (
                            <SelectItem key={ext} value={ext}>
                                {ext.toUpperCase()}
                            </SelectItem>
                        ))}
                    </SelectContent>
                </Select>
            </div>
        </div>
    );
}

/**
 * Props for the `VersionChipCard` component.
 *
 * Provides the data and callbacks required to display a Jetleaf version
 * with its corresponding Dart SDK version in a chip-style card format.
 */
interface VersionChipCardProps {
    /**
     * The Jetleaf version information to display.
     *
     * Includes properties such as version number and Dart SDK compatibility.
     */
    version: JetleafVersion;

    /**
     * Whether this version chip is currently selected by the user.
     *
     * Used to visually highlight the chip and manage selection state.
     */
    isSelected: boolean;

    /**
     * Callback triggered when the version chip is clicked.
     *
     * @remarks This should update the parent component's selected version state.
     */
    onClick: () => void;
}

/**
 * A compact, chip-style card component that displays a Jetleaf version
 * alongside its corresponding Dart SDK version.
 *
 * Features:
 * - Displays primary Jetleaf version number in a prominent, green-themed style
 * - Shows secondary Dart SDK version with Dart logo icon
 * - Includes subtle, rotated logo background image in bottom-right corner
 * - Visual selection state with border and background color changes
 * - Hover effects for enhanced interactivity
 *
 * @param version - The Jetleaf version data to display
 * @param isSelected - Whether this version is currently selected
 * @param onClick - Callback function triggered on chip click
 *
 * @remarks
 * - Uses a 25-degree rotated logo as a background element with 10% opacity
 * - Dart SDK version includes a small Dart logo SVG for visual consistency
 * - Selection state applies green-50 background and green-500 border
 * - Hover states provide subtle shadow and border color changes
 */
function VersionChipCard(card: VersionChipCardProps) {
    return (
        <div
            className={`
                flex items-center gap-1 cursor-pointer relative overflow-hidden border-2 transition-all cursor-pointer
                ${card.isSelected ? 'bg-green-50 border-green-500 shadow-md' : 'bg-white border-gray-200 hover:shadow-lg'}
            `}
            style={{
                padding: "5px",
                borderRadius: "6px",
            }}
            onClick={card.onClick}
        >
            {/* Logo as background at bottom right */}
            <div className="absolute bottom-0 right-0 opacity-10 pointer-events-none">
                <img
                    alt="logo"
                    src="logo.png"
                    style={{
                        height: '50px',
                        width: '50px',
                        position: 'relative',
                        right: '-5px',
                        bottom: '-10px',
                        objectFit: 'contain',
                        transform: 'rotate(25deg)',
                    }}
                />
            </div>

            {/* Version information */}
            <div className="flex flex-col gap-1 relative z-10">
                {/* Jetleaf Version */}
                <span className="text-sm text-green-700 font-semibold">
                    {card.version.version}
                </span>

                {/* Dart Version */}
                <div className="flex items-center gap-1">
                    <div style={{ height: "12px", width: "12px" }}>
                        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 640 640">
                            <path d="M442.6 142.9C439.8 142.8 437 142.7 434.1 142.7L170 142.7L313.2 70.7C320.6 66.3 332 64 343.6 64C357.1 64 373 73.2 380.6 80.8L442.6 142.8L442.6 142.9zM171.3 160.5L434.1 160.5C450.1 160.5 459.5 161.9 469.5 169.8L576 276.2L576 485L496.7 485.7L171.3 160.5zM160.5 437L160.5 174.8L484.3 498.6L485 576L272.8 576L174.7 477.8C163.4 466.5 160.5 462.5 160.5 437zM142.7 169.3L142.7 437C142.7 440.3 142.8 443.3 142.9 446.1L80.9 384.1C70.5 373.3 64 358.3 64 343.6C64 336.8 67.9 326.1 70.7 320L142.7 169.3z" />
                        </svg>
                    </div>
                    <span className="text-gray-700" style={{ fontSize: "11px" }}>
                        {card.version.dartSdk}
                    </span>
                </div>
            </div>
        </div>
    );
}

/**
 * `VersionChipCardSkeleton` is a placeholder UI component used to indicate
 * that version chip cards are loading. It mimics the structure of a real
 * version chip card using skeleton elements, giving users a visual cue while
 * version data is being fetched.
 *
 * --- Structure ---
 * 1. **Container**
 *    - `div` with padding, border, rounded corners, and a white background.
 *    - Uses `animate-pulse` to provide a pulsating loading effect.
 *
 * 2. **Version information section**
 *    - Flex column container with:
 *      - **Primary version skeleton** - rectangular placeholder for Jetleaf version
 *      - **Secondary Dart SDK skeleton** - smaller rectangular placeholder with icon placeholder
 *
 * 3. **Dart icon placeholder**
 *    - Small square to simulate the Dart logo icon
 *
 * --- Usage ---
 * ```tsx
 * <VersionChipCardSkeleton />
 * ```
 *
 * This component is typically displayed while actual version data
 * is being loaded from an API.
 */
function VersionChipCardSkeleton() {
    return (
        <div className="border-2 border-gray-200 bg-white rounded-lg p-1 animate-pulse">
            <div className="flex flex-col gap-1">
                {/* Jetleaf version skeleton */}
                <div className="h-3 w-16 bg-gray-200 rounded" />

                {/* Dart SDK version skeleton with icon */}
                <div className="flex items-center gap-2">
                    <div className="h-3 w-3 bg-gray-200 rounded" />
                    <div className="h-3 w-12 bg-gray-200 rounded" />
                </div>
            </div>
        </div>
    );
}

/**
 * Props for the `JetleafVersionError` component.
 *
 * Provides a callback function to handle retry attempts when Jetleaf version
 * data fails to load.
 */
interface ErrorProps {
    /**
     * Callback triggered when the user clicks the retry button.
     *
     * Typically re-attempts fetching Jetleaf version data from the API.
     */
    onRefresh: () => void;
}

/**
 * Error alert component displayed when Jetleaf version data cannot be loaded.
 *
 * Features:
 * - Prominent red-themed error styling with icon
 * - Clear error message explaining the issue
 * - Actionable retry button to attempt fetching data again
 * - Responsive text sizing for compact display
 *
 * @param onRefresh - Callback function to retry fetching Jetleaf versions
 *
 * @remarks
 * - Uses AlertCircle icon from lucide-react for visual error indication
 * - Includes descriptive text with troubleshooting suggestions
 * - Provides "Request again" button as primary call to action
 * - Designed with red color scheme (bg-red-50, text-red-600, border-red-200)
 * - Uses smaller font sizes (12px, 10px, 11px) for compact display
 *
 * @example
 * <JetleafVersionError onRefresh={() => refetchVersions()} />
 */
function JetleafVersionError(error: ErrorProps) {
    return (
        <div className="text-red-600 bg-red-50 border border-red-200 rounded-lg p-4">
            <div className="flex items-center gap-2 mb-1">
                <AlertCircle className="w-5 h-5" />
                <span className="font-medium" style={{ fontSize: "12px" }}>Unable to load Jetleaf versions</span>
            </div>
            <p className="text-sm text-red-500" style={{ fontSize: "10px" }}>
                Please refresh to try again. If the issue persists, check your connection or contact support.
            </p>
            <button
                type='button'
                onClick={error.onRefresh}
                className="mt-2 px-3 py-1 text-sm bg-red-100 hover:bg-red-200 text-red-700 rounded-md transition-colors cursor-pointer"
                style={{ fontSize: "11px" }}
            >
                Request again
            </button>
        </div>
    );
}