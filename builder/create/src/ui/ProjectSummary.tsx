import { useState, JSX, useMemo } from 'react';
import { Button } from '../components/button';
import { Folder, File, Download, X, Loader2, LucideEye } from 'lucide-react';
import ProjectConfig, { ProjectStructure } from '../types/project_config';
import ProjectPreview from './ProjectPreview';
import Utils from '../utils/Utility';

/**
 * Props for the `ProjectSummary` component.
 *
 * @property config
 *   Instance of `ProjectConfig` containing all selected project options.
 *
 * @property onRemovePackage
 *   Callback fired when the user removes a selected package by its ID.
 *
 * @property onGenerate
 *   Executed when the user clicks the "Generate Project" button.
 *
 * @property isValid
 *   Indicates whether project configuration passes validation and
 *   determines button enabled/disabled state.
 */
interface ProjectSummaryProps {
    config: ProjectConfig;
    onRemovePackage: (packageId: string) => void;
    onGenerate: () => void;
    isValid: boolean;
}

/**
 * Displays a final summary view of the project configuration before generation.
 *
 * This component is the last step in the Jetleaf project creation flow. It provides:
 *
 * ✅ A list of all currently selected packages  
 * ✅ A live, auto-generated preview of the project’s folder/file structure  
 * ✅ A modal for expanded structure inspection  
 * ✅ A button to trigger project generation (disabled when validation fails)
 *
 * The component reacts dynamically to configuration changes and re-renders the
 * structure tree only when relevant fields change, improving performance via `useMemo`.
 *
 * ## Features
 *
 * - Shows selected package names and versions with the ability to remove items
 * - Renders a collapsible visual project structure using `ProjectConfig.buildStructure()`
 * - Includes file-type-specific icons for improved readability
 * - Allows opening a larger preview in a modal
 * - Prevents project generation when config is invalid
 *
 * ## Props
 * @param config - The current `ProjectConfig` instance representing all selected options
 * @param onRemovePackage - Callback fired when a package is removed from the selection
 * @param onGenerate - Trigger executed when the user confirms project generation
 * @param isValid - Whether the current configuration passes validation rules
 *
 * ## Example Usage
 * ```tsx
 * <ProjectSummary
 *   config={config}
 *   onRemovePackage={id => handleRemove(id)}
 *   onGenerate={generateProject}
 *   isValid={errors.length === 0}
 * />
 * ```
 *
 * ## Rendering Behavior
 *
 * - `structure` is rebuilt only when config fields affecting output change:
 *   - projectName
 *   - description
 *   - includeExamples
 *   - generateDockerfile
 *   - addCICD
 *   - selectedPackages
 *
 * - The generated structure is rendered recursively with indentation based on depth level.
 *
 * ## Accessibility
 * - Buttons include icons and text labels
 * - Package list supports truncated text for long names
 * - Preview modal can be opened and dismissed cleanly
 */
export default function ProjectSummary({ config, onRemovePackage, onGenerate, isValid }: ProjectSummaryProps) {
    /**
     * Tracks whether the structure preview modal is open.
     */
    const [isPreviewOpen, setIsPreviewOpen] = useState(false);

    /**
     * Convenience reference to selected packages stored in the configuration.
     */
    const selectedPackages = config.selectedPackages;

    /**
     * Resolves the correct icon for a given file or folder entry.
     *
     * @param name - The filename (e.g., `main.dart`, `pubspec.yaml`)
     * @param type - Whether the entry is a `file` or `folder`
     *
     * @returns The corresponding JSX icon component
     *
     * Resolution order:
     * 1. Folder → folder icon
     * 2. Exact match in `Utils.FILE_ICONS`
     * 3. Extension match (e.g., `.dart`)
     * 4. Fallback generic file icon
     */
    const getFileIcon = (name: string, type: 'file' | 'folder') => {
        if (type === 'folder') return <Folder className="w-4 h-4 text-blue-400 flex-shrink-0" />;

        // Try to find an icon from Utils.FILE_ICONS
        for (const key in Utils.FILE_ICONS) {
            if (name.endsWith(key) || name === key) {
                const IconComponent = Utils.FILE_ICONS[key];
                // Return the icon with consistent sizing
                return IconComponent;
            }
        }

        // Fallback to generic file icon
        return <File className="w-4 h-4 text-gray-400 flex-shrink-0" />;
    };

    /**
     * Computes the generated project structure from the configuration.
     *
     * Memoized to prevent unnecessary recomputation. Rebuilds only when
     * properties affecting the file tree change.
     *
     * @returns A `ProjectStructure` root node representing the full tree.
     */
    const structure = useMemo(() => {
        return config.buildStructure();
    }, [
        config.projectName,
        config.description,
        config.includeExamples,
        config.generateDockerfile,
        config.addCICD,
        config.selectedPackages,
        config.addAnalysisOptions,
        config.addGitIgnore,
        config.version,
        config.resourceFileExtension
    ]);

    /**
     * Recursively renders a visual representation of a `ProjectStructure` node.
     *
     * @param node - The current folder or file entry
     * @param level - Depth index used for indentation (default: `0`)
     *
     * @returns A rendered JSX element representing the node and its children
     */
    const renderTree = (node: ProjectStructure, level = 0): JSX.Element => {
        const marginLeft = level * 14;

        return (
            <div key={node.name} style={{ margin: "5px 0" }}>
                <div className="flex items-center gap-2" style={{ marginLeft }}>
                    {getFileIcon(node.name, node.type)}
                    <span className="truncate text-sm leading-tight">
                        {node.name}{node.type === 'folder' ? '/' : ''}
                    </span>
                </div>

                {node.children?.map(child => renderTree(child, level + 1.8))}
            </div>
        );
    };

    return (
        <div className="space-y-6">
            <h2 className="text-xl mb-6">Project Summary</h2>

            {/* Selected Packages */}
            {selectedPackages.length === 0 ? (<span></span>) : (
                <div>
                    <h3 className="text-sm mb-3">{selectedPackages.length} Selected Packages</h3>
                    <div className="space-y-2">
                        {selectedPackages.map(pkg => (
                            <div
                                key={pkg.id}
                                className="flex items-center justify-between p-3 bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors"
                            >
                                <div className="flex-1 min-w-0">
                                    <p className="text-sm truncate">{pkg.name}</p>
                                    <p className="text-xs text-gray-500">{pkg.version}</p>
                                </div>
                                <Button variant="ghost" size="sm" onClick={() => onRemovePackage(pkg.id)}>
                                    <X className="w-4 h-4" />
                                </Button>
                            </div>
                        ))}
                    </div>
                </div>
            )}

            {/* Project Structure Preview */}
            <div>
                <h3 className="text-sm mb-2">Project Structure</h3>
                <div className="bg-gray-900 text-gray-100 p-4 rounded-lg text-sm font-mono overflow-auto max-h-64">
                    {renderTree(structure)}
                </div>
            </div>

            {/* Generate Button */}
            <div className="sticky bottom-0 pt-4 bg-white gap-2 flex flex-col">
                <Button className="w-full py-2 text-sm cursor-pointer" size="sm" style={{ fontSize: "12px" }} onClick={() => setIsPreviewOpen(true)} disabled={!isValid}>
                    <LucideEye className="w-5 h-5 mr-2" />
                    Preview Project
                </Button>
                <Button className="w-full py-2 text-sm cursor-pointer" size="sm" style={{ fontSize: "12px" }} onClick={onGenerate} disabled={!isValid}>
                    {config.isGenerating ? (
                        <>
                            <Loader2 className="w-5 h-5 mr-2 animate-spin" />
                            Generating…
                        </>
                    ) : (
                        <>
                            <Download className="w-5 h-5 mr-2" />
                            Generate Project
                        </>
                    )}
                </Button>

                {!isValid && (
                    <p className="text-sm text-red-500 text-center mt-2" style={{ fontSize: "11px" }}>
                        Fix validation errors before generating
                    </p>
                )}
            </div>

            {/* Preview Modal */}
            <ProjectPreview config={config} isOpen={isPreviewOpen} onClose={() => setIsPreviewOpen(false)} />
        </div>
    );
}