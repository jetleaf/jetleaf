import { clsx, type ClassValue } from "clsx";
import { twMerge } from "tailwind-merge";
import semver from 'semver';
import Package from '../types/package';
import { JSX } from "react";
import { Code, FileText, Terminal } from 'lucide-react';
import JSZip from 'jszip';
import { saveAs } from 'file-saver';
import ProjectConfig, { ProjectStructure } from '../types/project_config';

/**
 * Represents a validation error in the project configuration.
 */
export interface ValidationError {
    /** The field in the ProjectConfig that failed validation */
    field: string;

    /** A human-readable error message describing the issue */
    message: string;
}

/**
 * Represents a potential conflict between two selected packages.
 * Not currently used in validateProjectConfig but can be extended for cross-package conflicts.
 */
export interface ConflictWarning {
    /** Name of the first package in conflict */
    package1: string;

    /** Name of the second package in conflict */
    package2: string;

    /** A human-readable message describing the conflict */
    message: string;
}

/**
 * `Utils` is a static utility class containing commonly used helper functions
 * for Jetleaf projects, including class merging, formatting, validation, project
 * ID generation, file icons, and project downloads.
 *
 * All methods are static; no instance of `Utils` is required.
 */
export default class Utils {
    /**
     * Combines multiple Tailwind CSS class strings or conditional classes
     * into a single string, intelligently merging conflicting Tailwind classes.
     *
     * @param inputs - List of class values (strings, arrays, or objects)
     * @returns Merged class string
     */
    static cn(...inputs: ClassValue[]): string {
        return twMerge(clsx(inputs));
    }

    /**
     * Formats a number into a human-readable string with shorthand notation.
     *
     * - Numbers >= 1,000,000 are abbreviated with "m" (millions).
     * - Numbers >= 1,000 are abbreviated with "k" (thousands).
     * - Smaller numbers are returned as-is.
     * - Removes trailing ".0" for clean formatting.
     *
     * @param num - The number to format.
     * @returns A string representing the formatted number.
     *
     * @example
     * formatNumber(1500);       // "1.5k"
     * formatNumber(2000000);    // "2m"
     * formatNumber(500);        // "500"
     */
    static formatNumber(num: number): string {
        if (num >= 1_000_000) return (num / 1_000_000).toFixed(1).replace(/\.0$/, '') + 'm';
        if (num >= 1_000) return (num / 1_000).toFixed(1).replace(/\.0$/, '') + 'k';
        return num.toString();
    }

    /**
     * Validates a Dart project configuration generated with Jetleaf.
     *
     * This function checks:
     * 1. Project name and ID are valid and non-empty.
     * 2. The selected Jetleaf version is compatible with the selected Dart SDK.
     * 3. Each selected package's Dart SDK constraints are compatible with the selected Dart SDK.
     * 4. Each selected package's Jetleaf dependency constraints are compatible with the selected Jetleaf version.
     *
     * @param config - The ProjectConfig object to validate.
     * @returns An array of ValidationError objects describing each issue found. Returns an empty array if no errors are found.
     *
     * @example
     * const errors = validateProjectConfig(projectConfig);
     * if (errors.length > 0) {
     *   errors.forEach(e => console.error(`${e.field}: ${e.message}`));
     * }
     */
    static validateProjectConfig(config: ProjectConfig): ValidationError[] {
        const errors: ValidationError[] = [];

        // --- Project Name & ID validation ---
        if (!config.projectName.trim()) {
            errors.push({ field: 'projectName', message: 'Project name is required' });
        }
        if (!config.projectId.trim()) {
            errors.push({ field: 'projectId', message: 'Project ID is required' });
        } else if (!/^[a-z][a-z0-9_]*$/.test(config.projectId)) {
            errors.push({
                field: 'projectId',
                message: 'Project ID must start with a lowercase letter and contain only lowercase letters, numbers, and underscores',
            });
        }

        // --- Jetleaf + Dart SDK compatibility ---
        if (config.version) {
            const { dartSdk, pkgVersion } = config.version;

            if (!dartSdk || !pkgVersion) {
                errors.push({ field: 'version', message: 'Jetleaf version and Dart SDK must be selected' });
            } else if (!semver.satisfies(dartSdk, pkgVersion.pubspec.environment?.sdk || '', { includePrerelease: true })) {
                errors.push({
                    field: 'version',
                    message: `Selected Dart SDK (${dartSdk}) is incompatible with Jetleaf version ${pkgVersion.version} (requires ${pkgVersion.pubspec.environment?.sdk})`,
                });
            }
        }

        // --- Package compatibility ---
        const selectedPackages: Package[] = config.selectedPackages;
        if (config.version) {
            const selectedDart = config.version.dartSdk;
            const selectedJetleaf = config.version.version;

            selectedPackages.forEach(pkg => {
                const pkgDart = pkg.pub.latest.pubspec.environment?.sdk;
                if (pkgDart && !semver.satisfies(selectedDart, pkgDart, { includePrerelease: true })) {
                    errors.push({
                        field: 'packages',
                        message: `Package "${pkg.name}" requires Dart SDK ${pkgDart}, which is incompatible with selected Dart SDK ${selectedDart}`,
                    });
                }

                // Check direct Jetleaf dependency
                const jetleafConstraint = pkg.pub.latest.pubspec.dependencies?.['jetleaf'];
                if (jetleafConstraint && !semver.satisfies(selectedJetleaf, jetleafConstraint, { includePrerelease: true })) {
                    errors.push({
                        field: 'packages',
                        message: `Package "${pkg.name}" requires Jetleaf ${jetleafConstraint}, which is incompatible with selected Jetleaf version ${selectedJetleaf}`,
                    });
                }

                // Check nested Jetleaf dependency
                Object.entries(pkg.pub.latest.pubspec.dependencies || {}).forEach(([depName, depVersion]) => {
                    if (depName === 'jetleaf' && !semver.satisfies(selectedJetleaf, depVersion, { includePrerelease: true })) {
                        errors.push({
                            field: 'packages',
                            message: `Package "${pkg.name}" has a nested dependency on Jetleaf ${depVersion}, which is incompatible with selected Jetleaf version ${selectedJetleaf}`,
                        });
                    }
                });
            });
        }

        return errors;
    }

    /**
     * Generates a normalized, safe project identifier string based on a given project name.
     *
     * This function is useful for creating internal IDs for Dart projects that:
     * - Can be used as directory names
     * - Can be used as package names or references
     * - Avoid invalid characters or leading/trailing underscores
     *
     * Transformation steps:
     * 1. Converts the input `projectName` to lowercase.
     * 2. Replaces any sequence of non-alphanumeric characters with a single underscore `_`.
     * 3. Removes any leading characters that are not letters (`a-z`).
     * 4. Removes trailing underscores.
     *
     * Examples:
     * ```ts
     * generateProjectId("My Dart App");      // "my_dart_app"
     * generateProjectId("123 Awesome App!"); // "awesome_app"
     * generateProjectId("__Hello World__");  // "hello_world"
     * ```
     *
     * @param projectName - The raw project name input.
     * @returns A normalized, lowercase, underscore-separated string suitable as a project ID.
     */
    static generateProjectId(projectName: string): string {
        return projectName
            .toLowerCase()
            .replace(/[^a-z0-9]+/g, '_')
            .replace(/^[^a-z]+/, '')
            .replace(/_+$/g, '');
    }

    /**
     * Converts a given date string into a human-readable relative time string.
     * 
     * The function calculates the difference between the current time and the provided date,
     * then returns a relative time description such as "2 days ago", "3 hours ago", or "Just now".
     *
     * The calculation approximates months as 30 days and years as 365 days.
     *
     * @param dateString - The input date as a string in a format recognized by `Date`.
     * @returns A string representing the relative time from now.
     *
     * @example
     * formatRelativeTime('2024-11-20T12:00:00Z'); // "2 days ago" (if today is 2024-11-22)
     * @example
     * formatRelativeTime('2024-11-22T11:45:00Z'); // "15 minutes ago"
     */
    static formatRelativeTime(dateString: string): string {
        const date = new Date(dateString);
        const now = new Date();
        const diff = now.getTime() - date.getTime();

        const seconds = Math.floor(diff / 1000);
        const minutes = Math.floor(seconds / 60);
        const hours = Math.floor(minutes / 60);
        const days = Math.floor(hours / 24);
        const months = Math.floor(days / 30);
        const years = Math.floor(days / 365);

        if (years > 0) return `${years} year${years > 1 ? 's' : ''} ago`;
        if (months > 0) return `${months} month${months > 1 ? 's' : ''} ago`;
        if (days > 0) return `${days} day${days > 1 ? 's' : ''} ago`;
        if (hours > 0) return `${hours} hour${hours > 1 ? 's' : ''} ago`;
        if (minutes > 0) return `${minutes} minute${minutes > 1 ? 's' : ''} ago`;

        return 'Just now';
    }

    /**
     * Mapping of filename extensions and special identifiers to UI icons.
     *
     * Keys support:
     * - file extension match (e.g., `.dart`)
     * - exact filename match (e.g., `Dockerfile`)
     *
     * Used by `getFileIcon()` to determine which icon to display
     * when rendering the project structure tree.
     */
    static FILE_ICONS: Record<string, JSX.Element> = {
        '.dart': <Code className="w-4 h-4 flex-shrink-0 text-blue-400" />,
        '.yaml': <FileText className="w-4 h-4 flex-shrink-0 text-green-400" />,
        '.yml': <FileText className="w-4 h-4 flex-shrink-0 text-green-400" />,
        '.md': <FileText className="w-4 h-4 flex-shrink-0 text-gray-300" />,
        '.gitignore': <FileText className="w-4 h-4 flex-shrink-0 text-gray-400" />,
        'Dockerfile': <Terminal className="w-4 h-4 flex-shrink-0 text-orange-400" />,
        'pubspec.yaml': <FileText className="w-4 h-4 flex-shrink-0 text-green-400" />,
        'ci.yml': <FileText className="w-4 h-4 flex-shrink-0 text-yellow-400" />
    };

    /**
     * Generates a zip file from a ProjectConfig and triggers a download in the browser.
     *
     * @param config - The ProjectConfig instance used to generate the project structure.
     * @param zipFileName - Optional filename for the downloaded zip. Defaults to projectId.zip
     */
    static async downloadProject(config: ProjectConfig, zipFileName?: string) {
        /**
         * Recursively adds a ProjectStructure node to a JSZip folder.
         *
         * @param zipFolder - The current JSZip folder to add files/folders to.
         * @param node - A ProjectStructure node representing a file or folder.
         */
        const addNodeToZip = (zipFolder: JSZip, node: ProjectStructure) => {
            if (node.type === 'file') {
                zipFolder.file(node.name, node.content || '');
            } else if (node.type === 'folder' && node.children) {
                const folder = zipFolder.folder(node.name);
                node.children.forEach(child => addNodeToZip(folder!, child));
            }
        };

        const structure: ProjectStructure = config.buildStructure();

        const zip = new JSZip();

        // Recursively add the project structure to the zip
        addNodeToZip(zip, structure);

        // Generate the zip as a Blob
        const blob = await zip.generateAsync({ type: 'blob' });

        // Trigger download
        saveAs(blob, zipFileName || `${config.projectId || 'project_name'}.zip`);
    }
}