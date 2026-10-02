import Package from "./package";
import { PackageVersion, PubDevPackage } from "./pubspec";
import CodeBuilder from "../utils/CodeBuilder";

/**
 * Represents the file extension used for Jetleaf resource configuration files.
 *
 * This value determines the format of files placed inside the project's
 * `resources/` directory (e.g., `application.yaml`, `application.properties`).
 *
 * Users can select their preferred format, and the project generator will
 * create resource files accordingly.
 */
export enum ResourceFileExtension {
  /**
   * Standard YAML format (`.yaml`).
   * Recommended for most Jetleaf projects and widely supported by tools.
   */
  YAML = "yaml",

  /**
   * Short-form YAML extension (`.yml`).
   * Functionally identical to `.yaml` but uses a shorter extension.
   */
  YML = "yml",

  /**
   * Java-style key–value format (`.properties`).
   * Useful for developers familiar with `.properties` files or integrating
   * with Java-based tooling.
   */
  PROPERTIES = "properties",
}

const SERVER_HOST = "localhost"
const SERVER_PORT = 8080

/**
 * Represents a node in the generated Dart project file tree.
 *
 * A `ProjectStructure` can be either a **file** or a **folder**, allowing the entire
 * project structure to be modeled as a recursive hierarchy. This is used during
 * project scaffolding, export operations, and UI previews of generated output.
 *
 * - When `option` is `"file"`, the node contains textual content and no children.
 * - When `option` is `"folder"`, the node may have nested `children` and its
 *   `content` field is ignored.
 *
 * This structure enables:
 * - multi-level directory generation (`lib/`, `bin/`, `test/`)
 * - templated file creation (e.g., `main.dart`, CI configs)
 * - dynamic project customization based on user selections
 * - serialization for downloads (e.g., ZIP archive creation)
 */
export interface ProjectStructure {
  /**
   * Determines whether the node represents a file or a folder.
   *
   * `"file"` — A concrete file that will be written to disk.  
   * `"folder"` — A directory used to group nested files and folders.
   *
   * Rules:
   * - If `"folder"`, `children` may be defined and `content` is ignored.
   * - If `"file"`, `children` must NOT be provided.
   *
   * @example "file"
   * @example "folder"
   */
  type: 'file' | 'folder';

  /**
   * The textual content of the file.
   *
   * This field is **only applicable when `type` is `"file"`**.
   * The content is written exactly as provided, without formatting or mutation.
   *
   * Examples of usage:
   * - Dart source (`"void main() {}"`)
   * - YAML configuration (`"sdk: '>=3.3.0 <4.0.0'"`)
   * - Documentation or README text
   *
   * When `type` is `"folder"`, this value should be an empty string or omitted.
   *
   * @example "void main() => print('Hello');"
   */
  content?: string;

  /**
   * The name of the file or folder, excluding directory paths.
   *
   * For files, the name should include the proper extension.  
   * For folders, the name represents the directory label.
   *
   * Examples:
   * - `"main.dart"` — file in `lib/`
   * - `"lib"` — root Dart source directory
   * - `"test"` — unit test folder
   *
   * @example "pubspec.yaml"
   * @example "bin"
   */
  name: string;

  /**
   * Recursive list of nested files and folders.
   *
   * Only used when `type` is `"folder"`. Each child is another `ProjectStructure`,
   * allowing deeply nested structures such as:
   *
   * ```
   * {
   *   type: "folder",
   *   name: "lib",
   *   children: [
   *     { type: "file", name: "main.dart", content: "void main() {}" }
   *   ]
   * }
   * ```
   *
   * Notes:
   * - Must be omitted or undefined when `type` is `"file"`.
   * - Allows unlimited nesting depth.
   * - Useful for building template trees before filesystem output.
   *
   * @example
   * [
   *   { type: "file", name: "routes.dart", content: "// routes here" },
   *   { type: "folder", name: "controllers", children: [] }
   * ]
   */
  children?: ProjectStructure[];
}

/**
 * Represents a specific version of the Jetleaf tool along with its
 * associated Dart SDK constraints and package metadata.
 *
 * This interface is useful for tracking Jetleaf releases, ensuring
 * compatibility with Dart SDK versions, and referencing the full
 * package information from Pub.dev.
 */
export interface JetleafVersion {
  /**
   * The semantic version number of Jetleaf.
   *
   * Follows standard semantic versioning conventions (MAJOR.MINOR.PATCH).
   * Example: `"1.0.0"`.
   */
  version: string;

  /**
   * The Dart SDK version constraint required by this Jetleaf version.
   *
   * Extracted from the `environment.sdk` field of the Jetleaf pubspec.yaml.
   * Ensures that projects generated with this version are compatible with
   * the appropriate Dart SDK.
   *
   * Example: `">=3.3.0 <4.0.0"`.
   */
  dartSdk: string;

  /**
   * The full `PackageVersion` object corresponding to this Jetleaf release.
   *
   * Contains detailed metadata including version, pubspec, archive URL,
   * checksum, and published timestamp. This allows referencing all
   * information about the Jetleaf package from Pub.dev.
   */
  pkgVersion: PackageVersion;
}

/**
 * Represents the configuration settings for a generated Dart project using Jetleaf.
 *
 * This class encapsulates all project metadata and generation options necessary
 * for scaffolding, configuring, and maintaining a Dart project. It acts as the
 * single source of truth for project setup, influencing directory structure,
 * pubspec configuration, integration of optional packages, inclusion of development
 * tools, CI/CD configuration, Docker support, and example code templates.
 * 
 * By using this class, developers can ensure consistency across generated projects,
 * reproduce builds reliably, and extend the project setup process programmatically.
 */
export default class ProjectConfig {
  /**
   * The name of the Dart project.
   * Used for creating project directories, configuring import paths, and naming packages.
   * Must follow Dart package naming conventions (lowercase letters, underscores allowed).
   * @example "my_dart_app"
   */
  projectName: string;

  /**
   * A concise description of the project.
   * Typically used in README files, pubspec.yaml metadata, and project documentation.
   * Helps other developers quickly understand the purpose of the project.
   * @example "A Dart application for managing tasks efficiently."
   */
  description: string;

  /**
   * A unique identifier for the project.
   * Used internally for tracking, analytics, CI/CD pipelines, or integration with other tools.
   * Ensures each project instance is distinguishable in a larger system or organization.
   * @example "proj_12345"
   */
  projectId: string;

  /**
   * Whether to include example code in the generated project.
   * Provides demonstration scripts, sample modules, and usage templates.
   * Useful for onboarding new developers or illustrating best practices.
   */
  includeExamples: boolean;

  /**
   * The Jetleaf devtool package.
   * 
   * This is the package that handles proxy generation and command line tools
   */
  devtool?: PubDevPackage;

  /**
   * Whether to generate a Dockerfile for containerizing the project.
   * Facilitates consistent deployment in containerized environments and cloud platforms.
   */
  generateDockerfile: boolean;

  /**
   * Whether to add CI/CD pipeline configuration for automated building, testing, and deployment.
   * Helps maintain high quality and faster release cycles.
   */
  addCICD: boolean;

  /**
   * Specifies the default file extension for Jetleaf resource configuration files.
   *
   * This setting determines the format of files generated inside the `resources/`
   * directory. By default, it is set to use the standard YAML format.
   *
   * @example
   * resourceFileExtension = ResourceFileExtension.YAML
   */
  resourceFileExtension: ResourceFileExtension;

  /**
   * Whether to generate a `.gitignore` file in the project root.
   *
   * When enabled, a standard Dart-focused `.gitignore` file will be included
   * to prevent temporary, build, tooling, and environment files from being
   * committed to version control.
   *
   * ## Purpose
   * - Ensures clean repository history
   * - Avoids accidental commits of generated artifacts
   * - Supports common Dart, Jetleaf, and tooling conventions
   *
   * ## Typical Contents
   * - `.dart_tool/`, `.packages`, `build/`
   * - `pubspec.lock` (optional depending on use case)
   * - `.env*` files
   * - generated JavaScript artifacts from `dart2js`
   *
   * This option is recommended for nearly all projects unless the consumer
   * intends to manage ignore rules manually.
   *
   * @example
   * config.addGitIgnore = true;
   */
  addGitIgnore: boolean;

  /**
   * Whether to include an `analysis_options.yaml` file for Dart static analysis.
   *
   * When enabled, a default configuration is generated that:
   * - Extends the recommended lint rules from `package:lints`
   * - Provides a consistent baseline for code style and best practices
   * - Allows customization of analyzer behavior and lint exclusions
   *
   * ## Benefits
   * - Helps prevent common coding issues early
   * - Encourages idiomatic Dart usage
   * - Improves maintainability across teams
   *
   * ## Default Behavior
   * - Includes: `include: package:lints/recommended.yaml`
   * - Suppresses a few common false-positive warnings
   * - Can be modified safely by the project owner after generation
   *
   * @example
   * config.addAnalysisOptions = false;
   */
  addAnalysisOptions: boolean;

  /**
   * List of additional Dart packages selected to include in the project.
   * Each `Package` object contains metadata, dependencies, version information, and related details.
   * These packages will be automatically added to the pubspec.yaml and installed during setup.
   */
  selectedPackages: Package[];

  /**
   * The Jetleaf version selected for scaffolding this project.
   *
   * This field indicates which version of Jetleaf should be used when generating
   * the project files, templates, and structure. It is separate from the general
   * `jetleafVersion`, which may represent the version used to run the generator itself.
   */
  version: JetleafVersion;

  /**
   * Indicates whether the project is currently being generated.
   *
   * This flag is used by the UI to:
   * - disable actions during generation
   * - show loading indicators
   * - prevent duplicate generate requests
   *
   * This value is NOT persisted and only exists during runtime.
   */
  isGenerating: boolean;

  /**
   * Constructs a new ProjectConfig instance with the specified configuration values.
   * 
   * @param projectName - The name of the project, used for directories and package names.
   * @param description - Short textual description of the project.
   * @param projectId - Unique identifier for the project.
   * @param version - The Jetleaf version selected for scaffolding the project.
   * @param includeExamples - Whether to include example code.
   * @param devtool - The developer tools package.
   * @param generateDockerfile - Whether to generate a Dockerfile.
   * @param addCICD - Whether to add CI/CD configuration.
   * @param selectedPackages - List of additional Dart packages to include.
   * @param addGitIgnore - Whether to include gitignore file.
   * @param addAnalysisOptions - Whether to include analysis file.
   * @param resourceFileExtension - The particular extension to use for the resources file
   */
  constructor(
    projectName: string,
    description: string,
    projectId: string,
    includeExamples: boolean,
    generateDockerfile: boolean,
    addCICD: boolean,
    selectedPackages: Package[],
    version: JetleafVersion,
    addGitIgnore: boolean,
    addAnalysisOptions: boolean,
    devtool?: PubDevPackage,
    resourceFileExtension?: ResourceFileExtension,
    isGenerating: boolean = false
  ) {
    this.projectName = projectName;
    this.description = description;
    this.projectId = projectId;
    this.version = version;
    this.includeExamples = includeExamples;
    this.devtool = devtool;
    this.generateDockerfile = generateDockerfile;
    this.addCICD = addCICD;
    this.selectedPackages = selectedPackages;
    this.addGitIgnore = addGitIgnore;
    this.addAnalysisOptions = addAnalysisOptions;
    this.resourceFileExtension = resourceFileExtension ?? ResourceFileExtension.YAML;
    this.isGenerating = isGenerating;
  }

  /**
   * Creates a new ProjectConfig instance with default values.
   * 
   * Default values:
   * - `projectName`, `description`, `projectId`: empty strings
   * - `dartSdkVersion`: '3.2.0'
   * - `jetleafVersion`: '2.5.0'
   * - `includeExamples`: true
   * - `devtool`: true
   * - `generateDockerfile`: false
   * - `addCICD`: false
   * - `selectedPackages`: empty array
   *
   * This method provides a ready-to-use configuration object for new projects,
   * allowing developers to override defaults as needed.
   *
   * @returns A ProjectConfig instance populated with default values.
   */
  static default(): ProjectConfig {
    return new ProjectConfig(
      '',
      'A new Jetleaf project',
      '',
      false,
      true,
      false,
      [],
      {
        dartSdk: '',
        version: '',
        pkgVersion: {
          version: "",
          archive_sha256: "",
          archive_url: "",
          published: "",
          pubspec: {
            name: "",
            description: "",
            version: ""
          }
        }
      },
      true,
      true,
      undefined,
      undefined,
      false
    );
  }

  /**
   * Creates a new `ProjectConfig` instance based on the current one, while
   * applying a selective set of updated properties.
   *
   * This method enables immutable-style updates without mutating the original
   * configuration object. Only the fields provided in `updates` are replaced;
   * all other values are preserved from the existing instance.
   *
   * ## When to Use
   * - Updating configuration in UI state management
   * - Applying step-based wizard updates
   * - Regenerating project structures after option changes
   * - Preserving history for undo/redo operations
   *
   * ## Behavior
   * - Constructs a new `ProjectConfig` using the current instance's values
   * - Merges provided updates via `Object.assign`
   * - Automatically rebuilds `structure` if relevant properties change
   *   (e.g., `includeExamples`, `selectedPackages`, `generateDockerfile`)
   *
   * ## Example
   * ```ts
   * const updated = config.cloneWith({
   *   devtool: false,
   *   selectedPackages: [...config.selectedPackages, newPkg]
   * });
   * ```
   *
   * @param updates
   *   A partial set of `ProjectConfig` fields to override in the cloned instance.
   *   Omitted properties retain their original values.
   *
   * @returns A new `ProjectConfig` containing merged configuration values.
   *
   * @note The original instance remains unchanged.
   * @note Deep cloning is not performed—arrays and objects are reused unless replaced.
   */
  cloneWith(updates: Partial<ProjectConfig>): ProjectConfig {
    return Object.assign(
      new ProjectConfig(
        this.projectName,
        this.description,
        this.projectId,
        this.includeExamples,
        this.generateDockerfile,
        this.addCICD,
        this.selectedPackages,
        this.version,
        this.addGitIgnore,
        this.addAnalysisOptions,
        this.devtool,
        this.resourceFileExtension,
        this.isGenerating
      ),
      updates
    );
  }

  /**
   * Generates a PascalCase class name derived from the current project identifier.
   *
   * This method ensures that the resulting class name is always a valid and
   * predictable Dart class identifier, even if the original value contains
   * special characters, spacing, or unconventional casing.
   *
   * Behavior details:
   *
   * 1. If `projectId` exists and contains non-whitespace characters:
   *    - All non-alphanumeric sequences are replaced with spaces
   *      (e.g., `"my-app_123"` → `"my app 123"`).
   *    - The string is split into individual words.
   *    - Empty values are discarded to avoid invalid segments.
   *    - Each word is transformed into PascalCase by:
   *        - Uppercasing the first character
   *        - Lowercasing the remaining characters
   *      (e.g., `"my APP"` → `"MyApp"`).
   *    - The transformed words are concatenated without delimiters.
   *
   * 2. If `projectId` is missing or only whitespace:
   *    - Falls back to the default class name:
   *      `"ExampleApplication"`.
   *
   * This ensures that the generated class name:
   * - Never starts with a lowercase character
   * - Contains only alphanumeric characters
   * - Has no separators or symbols
   * - Avoids invalid Dart identifiers due to punctuation
   *
   * @returns {string} A sanitized PascalCase class name suitable for Dart source files.
   */
  private getClassName(): string {
    const toPascalCase = (value: string) =>
      value
        .replace(/[^a-zA-Z0-9]+/g, ' ')
        .split(' ')
        .filter(Boolean)
        .map(w => w[0].toUpperCase() + w.slice(1).toLowerCase())
        .join('');

    return this.projectId?.trim() ? `${toPascalCase(this.projectId)}Application` : 'ExampleApplication';
  }

  /**
   * Indicates whether the project should include Jetleaf's resource support features.
   *
   * This computed property evaluates the currently selected packages and returns
   * `true` only when a package with the identifier `"jetleaf_resource"` has been added.
   *
   * Intended usage:
   * - Controls conditional code generation
   * - Determines whether resource-related boilerplate should be emitted
   * - Enables additional configuration fields in the project setup UI
   *
   * Additional notes:
   * - No assumptions are made about version compatibility
   * - Matching is strictly ID-based, not by name or metadata
   *
   * @returns {boolean} `true` if the resource package is selected, otherwise `false`.
   */
  private get showResource(): boolean {
    return this.selectedPackages.some(pk => pk.id === 'jetleaf_resource');
  }

  /**
   * Indicates whether the project should include Jetleaf's web support features.
   *
   * This computed property checks the currently selected packages and returns
   * `true` only when a package with the identifier `"jetleaf_web"` is present.
   *
   * Intended usage:
   * - Controls conditional web-specific code generation
   * - Determines whether web-related boilerplate should be emitted
   * - Enables additional configuration fields in the project setup UI
   *
   * Additional notes:
   * - No assumptions are made about version compatibility
   * - Matching is strictly ID-based, not by name or metadata
   *
   * @returns {boolean} `true` if the web package is selected, otherwise `false`.
   */
  private get showWeb(): boolean {
    return this.selectedPackages.some(pk => pk.id === "jetleaf_web");
  }

  /**
   * Indicates whether the project should include Jetleaf's retry feature.
   *
   * Evaluates the selected packages and returns `true` only if `"jetleaf_retry"`
   * is present. Useful for generating code that automatically retries failed
   * operations or API calls.
   *
   * @returns {boolean} `true` if the retry package is selected, otherwise `false`.
   */
  private get showRetry(): boolean {
    return this.selectedPackages.some(pk => pk.id === "jetleaf_retry");
  }

  /**
   * Indicates whether the project should include Jetleaf's validation utilities.
   *
   * Returns `true` only when `"jetleaf_validation"` is selected. Enables
   * conditional code generation for data validation, input checks, or schema
   * enforcement.
   *
   * @returns {boolean} `true` if the validation package is selected, otherwise `false`.
   */
  private get showValidation(): boolean {
    return this.selectedPackages.some(pk => pk.id === "jetleaf_validation");
  }

  /**
   * Indicates whether the project should include Jetleaf's data management features.
   *
   * Returns `true` only when `"jetleaf_data"` is selected. Enables scaffolding
   * for repositories, DAOs, or database access layers.
   *
   * @returns {boolean} `true` if the data package is selected, otherwise `false`.
   */
  private get showData(): boolean {
    return this.selectedPackages.some(pk => pk.id === "jetleaf_data");
  }

  /**
   * Indicates whether the project should include Jetleaf's monitoring utilities.
   *
   * Returns `true` only when `"jetleaf_monitor"` is selected. Useful for
   * generating instrumentation, logging, metrics, or health-check scaffolding.
   *
   * @returns {boolean} `true` if the monitoring package is selected, otherwise `false`.
   */
  private get showMonitor(): boolean {
    return this.selectedPackages.some(pk => pk.id === "jetleaf_monitor");
  }

  /**
   * Determines whether Jetleaf scheduling functionality should be enabled for the project.
   *
   * This getter checks the currently selected dependency list and returns `true`
   * only when the `"jetleaf_scheduling"` package is present.
   *
   * Typical downstream effects:
   * - Includes generated scheduling scaffold code
   * - Adds necessary imports and setup logic
   * - May enable cron-style job configuration in the resulting project
   *
   * Design considerations:
   * - Remains reactive without requiring manual updates
   * - Prevents accidental inclusion of scheduling logic when unused
   *
   * @returns {boolean} `true` if the scheduling package is selected, otherwise `false`.
   */
  private get showScheduling(): boolean {
    return this.selectedPackages.some(pk => pk.id === 'jetleaf_scheduling');
  }

  /**
   * Generates the full file and folder hierarchy for the Dart project.
   *
   * This method constructs a complete `ProjectStructure` tree based on the
   * current `ProjectConfig` settings. The resulting structure represents the
   * entire output directory of the generated project and is suitable for:
   * - rendering previews in the UI
   * - exporting ZIP archives
   * - writing files to disk during scaffolding
   *
   * ## Structure Overview
   * The generated root folder is named after `projectId` (or `"project_name"` if
   * no ID is provided). Inside this root, the following directories and files
   * may be included:
   *
   * ### `lib/`
   * Contains all Dart source files. Its contents depend on configuration:
   *
   * - Always includes:
   *   - `main.dart` — base entrypoint file
   *
   * - When `includeExamples` is enabled:
   *   - `routes/`
   *     - `example_routes.dart` — example route definitions
   *
   * ### `resources/`
   * Optional resource directory.
   *
   * - When `includeExamples` is enabled:
   *   - `application.yaml` — sample config file
   *
   * ### `pubspec.yaml`
   * Automatically assembled using:
   * - `projectName`
   * - `selectedPackages` (each package added as a dependency)
   *
   * ### `README.md`
   * Auto-generated from:
   * - `projectName`
   * - `description`
   *
   * ### `Dockerfile`
   * Included only when `generateDockerfile` is `"true"`.
   *
   * ### `.github/workflows/ci.yml`
   * Included only when `addCICD` is `"true"`.
   *
   * ## Sorting Behavior
   * Every folder's children are:
   * 1. Sorted alphabetically by name
   * 2. Recursively sorted for stable, deterministic output
   *
   * This ensures consistent ordering across exports and previews.
   *
   * ## Helper Functions
   * - `folder(name, children)`  
   *   Creates a folder node and automatically sorts its children.
   *
   * - `file(name, content)`  
   *   Creates a file node with raw text content.
   *
   * ## Returns
   * A `ProjectStructure` object representing the root of the fully constructed
   * project tree.
   *
   * @returns {ProjectStructure} The root folder of the Dart project's structure.
   */
  buildStructure(includeReadme = true): ProjectStructure {
    // Helpers to build file/folder nodes
    const folder = (name: string, children: ProjectStructure[] = []): ProjectStructure => ({ name, type: 'folder', children: children });
    const file = (name: string, content = ''): ProjectStructure => ({ name, type: 'file', content });

    const libStructure: ProjectStructure[] = []

    libStructure.push(
      folder('core', [
        file('common_infrastructure.dart', CodeBuilder.buildCommonExample())
      ])
    )

    // Add example files for each enabled package
    if (this.showWeb) {
      libStructure.push(
        folder('controllers', [
          file('store_controller.dart', CodeBuilder.buildStoreController())
        ])
      );
      libStructure.push(
        folder('services', [
          file('external_api_service.dart', CodeBuilder.buildExternalApiServiceExample())
        ])
      );
    }

    if (this.showScheduling) {
      libStructure.push(
        folder('scheduled_tasks', [
          file('rest_test_service.dart', CodeBuilder.buildSchedulingExample())
        ])
      );
    }

    if (this.showResource) {
      libStructure.push(
        folder('resource', [
          file('cache_service.dart', CodeBuilder.buildCacheExample()),
          file('rate_limit_service.dart', CodeBuilder.buildRateLimitExample()),
        ])
      );
    }

    if (this.showValidation) {
      libStructure.push(
        folder('validation', [
          file('validation_service.dart', CodeBuilder.buildValidationExample())
        ])
      );
    }

    if (this.showRetry) {
      libStructure.push(
        folder('retry', [
          file('retry_service.dart', CodeBuilder.buildRetryExample())
        ])
      );
    }

    if (this.showData) {
      libStructure.push(
        folder('data', [
          file('user_repository.dart', CodeBuilder.buildDataExample())
        ])
      );
    }

    if (this.showMonitor && this.showWeb) {
      libStructure.push(
        folder('monitor', [
          file('monitored_service.dart', CodeBuilder.buildMonitorExample()),
          file('performance_controller.dart', CodeBuilder.buildMonitorControllerExample())
        ])
      );
    }

    const libChildren: ProjectStructure[] = [
      ...(this.includeExamples ? libStructure : []),
      file('main.dart', CodeBuilder.buildMainDart({
        className: this.getClassName(),
        showResource: this.showResource,
        showScheduling: this.showScheduling
      }))
    ];

    const resourcesChildren: ProjectStructure[] = [
      file(`application.${this.resourceFileExtension.toString().toLowerCase()}`, CodeBuilder.buildApplicationResource({
        config: this,
        showWeb: this.showWeb,
        className: this.getClassName()
      }))
    ];

    const rootChildren: ProjectStructure[] = [
      ...(this.addCICD ? [
        folder('.github', [
          folder('workflows', [file('ci.yml', CodeBuilder.buildCiWorkflow(this))])
        ])
      ] : []),
      folder('lib', libChildren),
      folder('resources', resourcesChildren),
      ...(this.showWeb ? [file('.env', CodeBuilder.buildEnv({ config: this, showWeb: this.showWeb }))] : []),
      ...(this.addGitIgnore ? [file('.gitignore', CodeBuilder.buildGitIgnore())] : []),
      ...(this.addAnalysisOptions ? [file('analysis_options.yaml', CodeBuilder.buildAnalysis())] : []),
      ...(this.generateDockerfile ? [file('Dockerfile', CodeBuilder.buildDockerFile(this))] : []),
      file('pubspec.yaml', CodeBuilder.buildPubSpec(this)),
      file('GUIDE_TO_JETLEAF.md', CodeBuilder.buildJetleafIntroduction(this, {
        showData: this.showData,
        showMonitor: this.showMonitor,
        showResource: this.showResource,
        showRetry: this.showRetry,
        showScheduling: this.showScheduling,
        showValidation: this.showValidation,
        showWeb: this.showWeb,
        className: this.getClassName()
      })),
      ...(includeReadme ? [file('README.md', CodeBuilder.buildReadme({ config: this, showWeb: this.showWeb }))] : []),
    ];

    return folder(this.projectId || 'project_name', rootChildren);
  }
}