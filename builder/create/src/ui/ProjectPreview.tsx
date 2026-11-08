import Utils from '../utils/Utility';
import { useShiki } from '../utils/hooks'
import { useState, JSX, useRef, useEffect } from 'react';
import { Folder, File, ChevronRight, ChevronDown, X, Menu } from 'lucide-react';
import ProjectConfig, { ProjectStructure } from '../types/project_config';
import { Dialog, DialogContent } from '../components/dialog';
import { ScrollArea } from '../components/scroll-area';

/**
 * Props for the `ProjectPreviewModal` component.
 *
 * This interface defines the inputs required to display a preview of a
 * generated Dart project within a modal dialog. It encapsulates the
 * project configuration, visibility state, and user interaction callbacks.
 */
interface ProjectPreviewModalProps {
    /**
     * The current project configuration.
     *
     * Provides access to all project metadata and generation options via
     * `ProjectConfig`. This is used to extract the generated project
     * structure, file contents, and associated settings for rendering
     * a live preview inside the modal.
     */
    config: ProjectConfig;

    /**
     * Controls visibility of the modal.
     *
     * - `true` — The modal is visible/open.
     * - `false` — The modal is hidden/closed.
     *
     * Toggling this prop allows parent components to manage modal
     * presentation programmatically.
     */
    isOpen: boolean;

    /**
     * Callback function invoked to close the modal.
     *
     * Triggered when the user interacts with UI elements such as:
     * - the close button
     * - the backdrop outside the modal content
     *
     * Implementers should handle this by updating `isOpen` in the parent
     * component to `false` or otherwise hiding the modal.
     */
    onClose: () => void;
}

/**
 * A modal dialog that provides a **live preview of the project's file structure**.
 *
 * Features:
 * - File explorer with nested folder tree
 * - Syntax-highlighted file preview using Shiki
 * - Responsive layout with collapsible left panel
 * - Tabbed interface for multiple open files
 * - Footer showing currently active file
 *
 * This component allows developers to inspect the generated Dart project
 * before downloading it, giving full transparency into the scaffolded files
 * and structure created by Jetleaf.
 */
export default function ProjectPreview({ config, isOpen, onClose }: ProjectPreviewModalProps) {
    /**
     * Currently selected file in the preview.
     * Can be null if no file is selected yet.
     */
    const [selectedFile, setSelectedFile] = useState<ProjectStructure | null>(null);

    /**
     * Array of open file tabs.
     * Supports multiple files being previewed simultaneously.
     */
    const [tabs, setTabs] = useState<ProjectStructure[]>([]);

    /**
     * Currently active tab for file preview.
     */
    const [activeTab, setActiveTab] = useState<ProjectStructure | null>(null);

    /**
     * Controls visibility of the left-hand file explorer panel.
     */
    const [isLeftPanelOpen, setIsLeftPanelOpen] = useState(true);

    /**
     * Tracks which folders are expanded in the file explorer.
     * Keyed by the full folder path.
     */
    const [expandedFolders, setExpandedFolders] = useState<Record<string, boolean>>({});

    /**
     * Tracks whether the screen is in "mobile mode" (responsive detection).
     * Affects layout and drawer behavior.
     */
    const [isMobile, setIsMobile] = useState(false);

    /**
     * Ref for scrolling tab elements into view.
     */
    const tabsRef = useRef<HTMLDivElement>(null);

    /**
     * Tracks which tab close button is currently hovered for styling.
     */
    const [hoveredCloseTab, setHoveredCloseTab] = useState<string | null>(null);

    /**
     * Extracts the hierarchical project structure from the configuration.
     */
    const structure = config.buildStructure();

    /**
     * Responsive detection for mobile layouts.
     * Automatically collapses the left panel on smaller screens.
     */
    useEffect(() => {
        const update = () => {
            const mobile = window.innerWidth < 900;
            setIsMobile(mobile);
            setIsLeftPanelOpen(!mobile);
        };
        update();
        window.addEventListener('resize', update);
        return () => window.removeEventListener('resize', update);
    }, []);

    /**
     * Determines the programming language for Shiki syntax highlighting.
     * Handles file extensions, special filenames (Dockerfile, .gitignore, .env),
     * and prevents unsupported languages.
     */
    const resolveLang = () => {
        if (!selectedFile?.name) return "text";

        const name = selectedFile.name.toLowerCase();

        if (name === "dockerfile") return "docker";
        if (name === ".gitignore" || name === "gitignore") return "text";
        if (name === ".env" || name === "env") return "text";

        const ext = name.split('.').pop() || "text";

        const langMap: Record<string, string> = {
            dockerfile: "docker",
            yml: "yaml",
            yaml: "yaml",
            js: "javascript",
            ts: "typescript",
            gitignore: "text",
            env: "text"
        };

        const unsupported = new Set([
            "gitignore",
            "dockerfile",
            "env",
            "properties",
            "cfg"
        ]);

        return unsupported.has(langMap[ext] || ext) ? "text" : (langMap[ext] || ext);
    };

    /**
     * Shiki syntax-highlighted HTML string of the selected file.
     */
    const highlightedCode = useShiki(selectedFile?.content || "", resolveLang(), "github-light");

    /**
     * Toggles folder expansion in the file explorer.
     */
    const toggleFolder = (path: string) => setExpandedFolders(prev => ({ ...prev, [path]: !prev[path] }));

    /**
     * Opens a file for preview.
     * Adds it to tabs if not already present and sets it as active.
     */
    const openFile = (file: ProjectStructure) => {
        setSelectedFile(file);

        setTabs(prev => {
            const exists = prev.find(t => t.name === file.name && t.type === file.type);
            if (!exists) return [...prev, file];
            return prev;
        });

        setActiveTab(file);

        setTimeout(() => {
            const container = tabsRef.current;
            if (container) {
                const activeEl = container.querySelector(`#tab-${file.name}`);
                if (activeEl) (activeEl as HTMLElement).scrollIntoView({ behavior: 'smooth', inline: 'nearest' });
            }
        }, 0);
    };

    /**
     * Closes a file tab.
     * If the active tab is closed, automatically selects the last remaining tab.
     */
    const closeTab = (file: ProjectStructure) => {
        setTabs(prev => prev.filter(t => !(t.name === file.name && t.type === file.type)));

        setTimeout(() => {
            setActiveTab(prevActive => {
                if (!prevActive) return null;
                if (prevActive.name === file.name && prevActive.type === file.type) {
                    const remaining = tabs.filter(t => !(t.name === file.name && t.type === file.type));
                    const next = remaining[remaining.length - 1] || null;
                    setSelectedFile(next);
                    return next;
                }
                return prevActive;
            });
        }, 0);
    };

    /**
     * Recursively renders the project tree for the left-hand explorer panel.
     *
     * @param node - The current folder/file node.
     * @param level - Indentation level for nested folders.
     * @param parentPath - Path of parent folder to generate unique keys.
     */
    const renderTree = (node: ProjectStructure, level = 0, parentPath = ''): JSX.Element => {
        const nodePath = parentPath ? `${parentPath}/${node.name}` : node.name;
        const isFolder = node.type === 'folder';
        const isExpanded = expandedFolders[nodePath] ?? true;
        const isSelected = selectedFile?.name === node.name && selectedFile?.type === node.type;

        return (
            <div key={nodePath}>
                <div
                    onClick={() => (isFolder ? toggleFolder(nodePath) : openFile(node))}
                    style={{
                        display: 'flex',
                        alignItems: 'center',
                        gap: 6,
                        padding: '6px 8px',
                        cursor: 'pointer',
                        backgroundColor: isSelected ? '#094771' : 'transparent',
                        borderLeft: isSelected ? '4px solid #14b8a6' : '4px solid transparent',
                        color: isSelected ? '#ffffff' : '#55855eff',
                        paddingLeft: level * 14,
                        borderRadius: 4,
                        userSelect: 'none'
                    }}
                >
                    {isFolder && (isExpanded ? <ChevronDown style={{ width: 16, height: 16, color: '#55855eff' }} /> : <ChevronRight style={{ width: 16, height: 16, color: '#55855eff' }} />)}

                    {/* icon resolution */}
                    {(() => {
                        for (const key in Utils.FILE_ICONS) {
                            if (node.name.endsWith(key) || node.name === key) return Utils.FILE_ICONS[key];
                        }
                        return isFolder ? <Folder style={{ width: 16, height: 16, color: '#55855eff' }} /> : <File style={{ width: 16, height: 16, color: '#55855eff' }} />;
                    })()}

                    <span style={{ whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                        {node.name}
                    </span>
                </div>

                {isFolder && isExpanded && node.children?.map(child => renderTree(child, level + 1.5, nodePath))}
            </div>
        );
    };

    return (
        <Dialog open={isOpen} onOpenChange={onClose}>
            <DialogContent
                style={{
                    padding: 0,
                    margin: 0,
                    width: '100%',
                    maxWidth: 1600,
                    height: '100vh',
                    display: 'flex',
                    flexDirection: 'column',
                    overflow: 'hidden',
                    gap: 0
                }}
                hideCloseButton={true}
            >
                {/* Header panel */}
                <div
                    style={{
                        display: 'flex',
                        justifyContent: 'space-between',
                        alignItems: 'center',
                        padding: '6px 12px',
                        backgroundColor: '#fff',
                        borderBottom: '1px solid #374151',
                    }}
                >
                    <div style={{ display: 'flex', alignItems: 'center' }}>
                        <img src="logo.png" alt="Jetleaf" width={20} height={20} />
                        <span style={{ marginLeft: 8, fontWeight: 600, fontSize: 12, color: '#1f411fff' }}>Jetleaf</span>
                    </div>

                    <div style={{ display: 'flex', gap: 8 }}>
                        <button
                            onClick={onClose}
                            title='close'
                            type='button'
                            style={{
                                width: 15,
                                height: 15,
                                display: 'flex',
                                justifyContent: 'center',
                                alignItems: 'center',
                                background: '#e63946',
                                borderRadius: '50%',
                                border: 'none',
                                color: '#fff',
                                cursor: "pointer"
                            }}
                        ></button>
                    </div>
                </div>

                {/* Main content */}
                <div style={{ display: 'flex', flex: 1, overflow: 'hidden', position: 'relative' }}>
                    {isMobile && isLeftPanelOpen && (
                        <div onClick={() => setIsLeftPanelOpen(false)} style={{ position: 'absolute', inset: 0, backgroundColor: 'rgba(0,0,0,0.35)', zIndex: 15 }} />
                    )}

                    {/* Left Explorer Panel */}
                    <div style={{
                        position: isMobile ? 'absolute' : 'relative',
                        top: 0,
                        left: 0,
                        height: '100%',
                        width: 320,
                        overflowY: 'auto',
                        backgroundColor: isMobile ? "#ffff" : "",
                        borderRight: '1px solid #374151',
                        color: '#d1d5db',
                        transform: isLeftPanelOpen ? 'translateX(0)' : 'translateX(-100%)',
                        transition: 'transform 0.22s ease',
                        zIndex: 20
                    }}>
                        <div style={{ padding: '10px 12px', fontSize: 12, fontWeight: 600, color: '#9ca3af', textTransform: 'uppercase', letterSpacing: 1 }}>
                            Explorer
                        </div>
                        <ScrollArea style={{ height: 'calc(100% - 40px)', padding: '0 8px 8px 8px' }}>
                            {renderTree(structure)}
                        </ScrollArea>
                    </div>

                    {/* Center File Preview */}
                    <div style={{ flex: 1, display: 'flex', flexDirection: 'column', overflow: 'hidden', fontFamily: 'monospace', fontSize: 14, position: 'relative' }}>
                        {/* Tab bar */}
                        <div ref={tabsRef} style={{ display: 'flex', alignItems: 'center', overflowX: 'hidden', gap: 8, alignSelf: 'stretch' }}>
                            {isMobile && (
                                <Menu onClick={() => setIsLeftPanelOpen(true)} style={{ width: 20, height: 20, color: '#fefefeff', cursor: 'pointer', marginRight: 6, flexShrink: 0, padding: 2, borderRadius: 4, backgroundColor: "#02b036ff" }} />
                            )}

                            <div className="no-scrollbar" style={{ display: 'flex', overflowX: 'auto', scrollbarWidth: 'none', msOverflowStyle: 'none' }}>
                                {tabs.map(tab => {
                                    const isActive = activeTab?.name === tab.name && activeTab?.type === tab.type;
                                    const isHover = hoveredCloseTab === tab.name;

                                    const fileIcon = (() => {
                                        for (const key in Utils.FILE_ICONS) {
                                            if (tab.name.endsWith(key) || tab.name === key) return Utils.FILE_ICONS[key];
                                        }
                                        return <File style={{ width: 14, height: 14, color: isActive ? '#ffffff' : '#d1d5db' }} />;
                                    })();

                                    return (
                                        <div key={`${tab.name}-${tab.type}`} id={`tab-${tab.name}`} onClick={() => { setActiveTab(tab); setSelectedFile(tab); }}
                                            style={{ display: 'flex', alignItems: 'center', padding: '6px 10px', cursor: 'pointer', backgroundColor: isActive ? '#ffffff' : '#e8e8e8ff', color: isActive ? '#131313' : '#464646ff', borderRight: '1px solid #374151', borderBottom: isActive ? 'none' : '1px solid #374151', whiteSpace: 'nowrap', userSelect: 'none' }}>
                                            <span style={{ marginRight: 6, display: 'flex', alignItems: 'center' }}>{fileIcon}</span>
                                            <span style={{ fontSize: 12, maxWidth: 160, overflow: 'hidden', textOverflow: 'ellipsis' }}>{tab.name}</span>
                                            <X onClick={(e) => { e.stopPropagation(); closeTab(tab); }} onMouseEnter={() => setHoveredCloseTab(tab.name)} onMouseLeave={() => setHoveredCloseTab(null)} style={{ width: 18, height: 18, marginLeft: 8, padding: 2, cursor: 'pointer', color: '#5e5f62ff', transition: 'color 0.15s ease', backgroundColor: isHover ? "#9ca3af" : "transparent", borderRadius: isHover ? "4px" : "" }} />
                                        </div>
                                    );
                                })}
                            </div>
                        </div>

                        {/* Editor Area */}
                        <div style={{ flex: 1, display: 'flex', overflow: 'auto' }}>
                            {selectedFile ? <div style={{ flex: 1, overflow: 'auto', padding: '0 12px' }} dangerouslySetInnerHTML={{ __html: highlightedCode }} /> : <div style={{ padding: 16, color: '#6b7280' }}>Select a file to preview</div>}
                        </div>
                    </div>
                </div>

                {/* Footer */}
                <div style={{ height: 28, backgroundColor: '#ffffffbd', color: '#1f411fff', display: 'flex', alignItems: 'center', padding: '0 12px', fontSize: 12, userSelect: 'none', borderTop: '1px solid #374151' }}>
                    <span style={{ fontWeight: 600, marginRight: 8 }}>Jetleaf Project Preview</span>
                    <span style={{ opacity: 0.9 }}>•</span>
                    <span style={{ marginLeft: 8 }}>{activeTab?.name || selectedFile?.name || 'Idle'}</span>
                </div>
            </DialogContent>
        </Dialog>
    );
}
