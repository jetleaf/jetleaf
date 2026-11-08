import { Dialog, DialogContent, DialogTitle, DialogDescription, DialogHeader } from '../components/dialog';
import { ScrollArea } from '../components/scroll-area';
import { Separator } from '../components/separator';
import { ExternalLink, GitBranch, Clock } from 'lucide-react';
import { Button } from '../components/button';
import Utils from '../utils/Utility'
import Package from '../types/package';
import { Badge } from '../components/badge';

/**
 * Props for the `PackageInformation` component.
 */
interface PackageDetailModalProps {
    /** The package to display details for. Null means no package is selected. */
    package: Package | null;

    /** Controls whether the modal is currently open. */
    isOpen: boolean;

    /** Callback to close the modal. */
    onClose: () => void;

    /** Whether the package is currently selected in the project. */
    isSelected: boolean;

    /** Callback to toggle the package selection state in the project. */
    onToggle: () => void;
}

/**
 * Modal dialog displaying detailed information about a Dart package.
 *
 * Features:
 * - Shows package name, short description, version, last updated timestamp.
 * - Displays badges for topics, keywords, dependencies, dev dependencies, and repository status.
 * - Scrollable content area for long lists of topics, keywords, versions, and dependencies.
 * - Footer buttons to add/remove the package to/from the project and view the repository.
 * - Integrates with the parent component for selection state and closing the modal.
 *
 * @param package - The package to display in the modal.
 * @param isOpen - Whether the modal is open.
 * @param onClose - Callback to close the modal.
 * @param isSelected - Whether the package is currently selected.
 * @param onToggle - Callback to toggle the package selection.
 */
export default function PackageInformation({ package: pkg, isOpen, onClose, isSelected, onToggle }: PackageDetailModalProps) {
    /**
     * Guard clause to handle missing package data.
     *
     * - If `pkg` is null or undefined, the component/function returns `null`.
     * - Ensures that subsequent code does not throw errors when accessing properties.
     */
    if (!pkg) return null;

    /**
     * Extracts the latest pubspec information from the package data.
     *
     * - `latestPubspec` contains metadata for the most recent version of the package.
     */
    const latestPubspec = pkg.pub.latest.pubspec;

    /**
     * Extracts keywords from the latest pubspec.
     *
     * - Defaults to an empty array if `keywords` is undefined or null.
     * - Keywords typically describe the package and help with searching/filtering.
     */
    const keywords = latestPubspec.keywords ?? [];

    /**
     * Extracts topics from the latest pubspec.
     *
     * - Defaults to an empty array if `topics` is undefined or null.
     * - Topics categorize the package for discovery purposes.
     */
    const topics = latestPubspec.topics ?? [];

    return (
        <Dialog open={isOpen} onOpenChange={onClose}>
            <DialogContent className="max-w-4xl max-h-[90vh]">
                <DialogHeader>
                    <DialogTitle className="text-3xl mb-2">{pkg.name}</DialogTitle>
                    <DialogDescription className="text-base">{pkg.shortDescription}</DialogDescription>
                </DialogHeader>

                {/* Header badges */}
                <div className="flex gap-2 flex-wrap mb-4">
                    <Badge variant="outline" className="bg-blue-50 text-blue-700">v{pkg.version}</Badge>

                    <Badge variant="outline" className="bg-gray-50 text-gray-700 flex items-center gap-1">
                        <Clock className="w-3 h-3" />
                        {Utils.formatRelativeTime(pkg.lastUpdated)}
                    </Badge>

                    {latestPubspec.repository && (
                        <Badge variant="outline" className="bg-purple-50 text-purple-700">Repository linked</Badge>
                    )}
                </div>

                <Separator />

                {/* Scrollable content */}
                <ScrollArea className="h-[400px] pr-4">
                    <div className="space-y-6 max-w-full overflow-hidden">

                        {/* Topics */}
                        {topics.length > 0 && (
                            <>
                                <section className="space-y-3 break-words">
                                    <h3 className="text-l font-bold">Topics</h3>
                                    <div className="flex flex-wrap gap-2">
                                        {topics.map(t => (<Badge key={t} variant="outline" className="bg-blue-50 text-blue-700">{t}</Badge>))}
                                    </div>
                                </section>
                                <Separator />
                            </>
                        )}

                        {/* Keywords */}
                        {keywords.length > 0 && (
                            <>
                                <section className="space-y-3 break-words">
                                    <h3 className="text-l font-bold">Keywords</h3>
                                    <div className="flex flex-wrap gap-2">
                                        {keywords.map(k => (<Badge key={k} variant="outline" className="bg-green-50 text-green-700" >{k}</Badge>))}
                                    </div>
                                </section>
                                <Separator />
                            </>
                        )}

                        {/* Versions */}
                        {pkg.pub.versions.length > 0 && (
                            <>
                                <section className="space-y-3 break-words">
                                    <h3 className="text-l font-bold">Versions</h3>
                                    <div className="space-y-2">
                                        {pkg.pub.versions.map(v => (
                                            <div key={v.version} className="text-sm text-gray-700 break-words">
                                                <span className="font-semibold">{v.version}</span>
                                                <span className="text-gray-500 ml-2">{Utils.formatRelativeTime(v.published)}</span>
                                            </div>
                                        ))}
                                    </div>
                                </section>
                                <Separator />
                            </>
                        )}

                        {/* Dependencies */}
                        {latestPubspec.dependencies &&
                            Object.keys(latestPubspec.dependencies).length > 0 && (
                                <>
                                    <section className="space-y-3 break-words">
                                        <h3 className="text-l font-bold">Dependencies</h3>
                                        <div className="flex flex-wrap gap-2">
                                            {Object.keys(latestPubspec.dependencies).map(dep => (<Badge key={dep} variant="outline">{dep}</Badge>))}
                                        </div>
                                    </section>
                                    <Separator />
                                </>
                            )}

                        {/* Dev Dependencies */}
                        {latestPubspec.dev_dependencies &&
                            Object.keys(latestPubspec.dev_dependencies).length > 0 && (
                                <>
                                    <section className="space-y-3 break-words">
                                        <h3 className="text-l font-bold">Dev Dependencies</h3>
                                        <div className="flex flex-wrap gap-2">
                                            {Object.keys(latestPubspec.dev_dependencies).map(dep => (
                                                <Badge key={dep} variant="outline" className="bg-yellow-50 text-yellow-700">{dep}</Badge>
                                            ))}
                                        </div>
                                    </section>
                                    <Separator />
                                </>
                            )}

                    </div>
                </ScrollArea>

                <Separator />

                {/* Footer buttons */}
                <div className="flex gap-3">
                    <Button
                        className="flex-1"
                        variant={isSelected ? "default" : "outline"}
                        onClick={() => {
                            onToggle();
                            onClose();
                        }}
                    >
                        {isSelected ? "Remove from Project" : "Add to Project"}
                    </Button>

                    {pkg.repository && (
                        <Button variant="outline" onClick={() => window.open(pkg.repository, "_blank")}>
                            <GitBranch className="w-4 h-4 mr-2" />
                            View Repository
                            <ExternalLink className="w-4 h-4 ml-2" />
                        </Button>
                    )}
                </div>

            </DialogContent>
        </Dialog>
    );
}