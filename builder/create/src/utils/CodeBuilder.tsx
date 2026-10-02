import Constants from './Constants'
import StringBuffer from "../components/StringBuffer";
import ProjectConfig, { ProjectStructure, ResourceFileExtension } from "../types/project_config";

/**
 * Options controlling how the project's main resource configuration
 * file is generated.
 *
 * These options provide the necessary context for constructing the
 * configuration content, including the project metadata, selected
 * file format, and feature toggles like web server support.
 */
interface BuildOptions {
  /**
   * The current project configuration.
   *
   * Provides:
   * - `projectId` — used as the base application name
   * - `resourceFileExtension` — controls the output format (`yaml`, `yml`, or `properties`)
   * - Other project metadata (versions, packages, etc.)
   */
  config: ProjectConfig;

  /**
   * Indicates whether web-specific configuration (HTTP server port and host)
   * should be included in the generated resource file.
   *
   * Typically true if the `jetleaf_web` package is selected.
   */
  showWeb: boolean;

  /**
   * The PascalCase class name generated from the project ID.
   *
   * Used for `jetleaf.application.name` in the resource file.
   */
  className?: string;
}

/**
 * Options used to control the content and features included in the generated
 * `main.dart` file for a Jetleaf project.
 */
interface MainBuildOptions {
  /**
   * The name of the root application class to be generated in `main.dart`.
   * Typically obtained from `getClassName()` to ensure a valid PascalCase
   * identifier derived from the project ID.
   */
  className: string;

  /**
   * Enables Jetleaf resource support.
   *
   * When `true`, the following are included in the generated `main.dart`:
   * - Import statement for `jetleaf_resource`
   * - `@EnableResource()` annotation on the application class
   */
  showResource?: boolean;

  /**
   * Enables Jetleaf scheduling support.
   *
   * When `true`, the following are included in the generated `main.dart`:
   * - Import statement for `jetleaf_scheduling`
   * - `@EnableScheduling()` annotation on the application class
   */
  showScheduling?: boolean;
}

/**
 * Options controlling which Jetleaf features are included in the generated
 * backend development guide.
 *
 * Each property is optional. When set to `true`, the corresponding feature
 * will be included; if `false` or omitted, the feature will be skipped.
 *
 * Properties:
 * - `showWeb` — Include web-specific features such as REST controllers and HTTP examples.
 * - `showScheduling` — Include scheduled task examples (background jobs, cron-like tasks).
 * - `showResource` — Include resource management and caching examples.
 * - `showValidation` — Include method parameter validation examples.
 * - `showRetry` — Include retry mechanism examples with backoff and recovery.
 * - `showData` — Include data access examples, repositories, and services.
 * - `showMonitor` — Include monitoring examples and monitored services.
 * - `resourceFileExtension` — Determines the file extension for configuration
 *   examples in the guide (`yaml`, `yml`, or `properties`).
 */
interface IntroductionToJetleafBuildOptions {
  /**
   * Include web-specific features such as REST controllers and HTTP examples.
   */
  showWeb?: boolean;

  /**
   * Include scheduled task examples (background jobs, cron-like tasks).
   */
  showScheduling?: boolean;

  /**
   * Include resource management features such as caching examples.
   */
  showResource?: boolean;

  /**
   * Include method parameter validation examples and annotations.
   */
  showValidation?: boolean;

  /**
   * Include retry mechanism examples with backoff and recovery.
   */
  showRetry?: boolean;

  /**
   * Include data access examples, repositories, and service patterns.
   */
  showData?: boolean;

  /**
   * Include monitoring examples and monitored services.
   */
  showMonitor?: boolean;

  /**
   * The classname for the project entry application
   */
  className?: string;
}

/**
 * `CodeBuilder` is a utility class providing **static methods** for generating
 * the contents of various project files in a Jetleaf Dart project.
 *
 * Responsibilities include:
 * - Creating standard project files like `README.md`, `GUIDE_TO_JETLEAF.md`, and `pubspec.yaml`.
 * - Structuring generated content consistently with project metadata.
 * - Centralizing file generation logic to keep project scaffolding maintainable.
 *
 * All methods are static, so the class does **not require instantiation**.
 *
 * @example
 * // Generate a README file for a project configuration
 * const readmeContent = CodeBuilder.buildReadme(config);
 *
 * // Generate a pubspec.yaml
 * const pubspecContent = CodeBuilder.buildPubSpec(config);
 */
export default class CodeBuilder {
  static buildCiWorkflow(config: ProjectConfig): string {
    return `
name: CI

on:
    push:
    branches: [ main ]
    pull_request:
    branches: [ main ]

jobs:
    test:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - uses: dart-lang/setup-dart@v1
        with:
        sdk: ${config.version.dartSdk}
    
    - name: Install dependencies
        run: dart pub get
    
    - name: Analyze
        run: dart analyze
    
    - name: Run tests
        run: dart test
    `.trimStart().trimEnd()
  }

  /**
   * Generates the default `analysis_options.yaml` configuration used for
   * Dart static analysis and linting.
   *
   * The generated configuration:
   * - Extends `package:lints/recommended.yaml`
   * - Enables consistent, idiomatic Dart style
   * - Suppresses a small set of commonly noisy analyzer warnings
   *
   * ## Purpose
   * This file ensures that newly generated projects start with a meaningful,
   * maintainable analysis baseline without requiring manual setup.
   *
   * ## Customization
   * The output includes commented sections that developers may enable to:
   * - Add additional lint rules
   * - Exclude specific paths from analysis
   * - Override analyzer behaviors
   *
   * The content is static and not dynamically derived from project settings.
   *
   * @returns A multi-line string representing the default analysis configuration.
   */
  static buildAnalysis(): string {
    return `
# This file configures the static analysis results for your project (errors,
# warnings, and lints).
#
# This enables the 'recommended' set of lints from \`package:lints\`.
# This set helps identify many issues that may lead to problems when running
# or consuming Dart code, and enforces writing Dart using a single, idiomatic
# style and format.
#
# If you want a smaller set of lints you can change this to specify
# 'package:lints/core.yaml'. These are just the most critical lints
# (the recommended set includes the core lints).
# The core lints are also what is used by pub.dev for scoring packages.

include: package:lints/recommended.yaml
analyzer:
  errors:
    constant_identifier_names: ignore
    library_private_types_in_public_api: ignore
    non_constant_identifier_names: ignore

# Uncomment the following section to specify additional rules.

# linter:
#   rules:
#     - camel_case_types

# analyzer:
#   exclude:
#     - path/to/excluded/files/**

# For more information about the core and recommended set of lints, see
# https://dart.dev/go/core-lints

# For additional information about configuring this file, see
# https://dart.dev/guides/language/analysis-options
`.trimStart().trimEnd()
  }

  /**
   * Generates the main resource configuration content for the project.
   *
   * This function produces a string for the application's main configuration
   * file, adapting the format based on the selected `resourceFileExtension`
   * and optionally including web server settings if `showWeb` is enabled.
   *
   * --- Behavior ---
   * 1. Determines file format:
   *    - `YAML` / `YML`: key-value pairs with colon syntax (`key: value`)
   *    - `PROPERTIES`: key-value pairs with equals syntax (`key=value`)
   *
   * 2. Writes mandatory application identifiers:
   *    - `application.name` — the project ID
   *    - `jetleaf.application.name` — the PascalCase class name
   *
   * 3. If web features are enabled (`showWeb === true`):
   *    - Adds a blank line for readability
   *    - Writes server configuration placeholders:
   *      - `server.port` → `${Constants.SERVER_PORT_NAME}`
   *      - `server.host` → `${Constants.SERVER_HOST_NAME}`
   *
   * --- Output ---
   * - Returns a string properly formatted for the selected resource file type.
   * - Automatically adjusts content to include/exclude web settings.
   *
   * @param {BuildOptions} options - The build options containing project metadata and feature flags.
   * @returns {string} The content of the resource configuration file (`.yaml`, `.yml`, or `.properties`).
   *
   * @example
   * // YAML output when showWeb is true
   * application.name: my_project
   * jetleaf.application.name: MyProject
   *
   * server.port: ${SERVER_PORT}
   * server.host: ${SERVER_HOST}
   */
  static buildApplicationResource(options: BuildOptions): string {
    const sb = new StringBuffer();
    const className = options.className;
    const config = options.config;
    const showWeb = options.showWeb;

    switch (config.resourceFileExtension) {
      case ResourceFileExtension.YAML:
      case ResourceFileExtension.YML:
        sb.writeln(`application.name: ${config.projectId}`);
        sb.writeln(`jetleaf.application.name: ${className}`);

        if (showWeb) {
          sb.writeln(); // blank line before server block
          sb.writeln(`server.port: \${${Constants.SERVER_PORT_NAME}}`);
          sb.writeln(`server.host: \${${Constants.SERVER_HOST_NAME}}`);
        }
        break;

      case ResourceFileExtension.PROPERTIES:
        sb.writeln(`application.name=${config.projectId}`);
        sb.writeln(`jetleaf.application.name=${className}`);

        if (showWeb) {
          sb.writeln(); // blank line before server block
          sb.writeln(`server.port=\${${Constants.SERVER_PORT_NAME}}`);
          sb.writeln(`server.host=\${${Constants.SERVER_HOST_NAME}}`);
        }
        break;
    }

    return sb.toString();
  }

  /**
   * Generates a multi-stage Dockerfile string for building and running
   * the current Jetleaf project.
   *
   * This function constructs a Dockerfile with two distinct stages to
   * optimize build time, cache dependencies, and produce a small
   * runtime image for production deployment.
   *
   * --- Build Stage ---
   * 1. Uses the Dart SDK specified in `config.version.dartSdk` as the base image.
   * 2. Sets the working directory to `/app`.
   * 3. Copies only `pubspec.*` files initially to leverage Docker caching.
   * 4. Runs `dart pub get` to fetch project dependencies.
   * 5. Copies the rest of the project source files.
   * 6. Sets optional environment variables for build customization:
   *    - `JL_PATH_FOLDER` — Output folder for build artifacts (default: `build/`).
   *    - `JL_EXEC_NAME` — Executable name for the generated application.
   *    - `JL_BUILD_EXCLUDE` / `JL_BUILD_INCLUDE` — Optional patterns to exclude/include files.
   *    - `JL_BUILD_NO_INTERACT` — Controls whether build prompts are interactive.
   * 7. Runs the Jetleaf build command, skipping interactive prompts if `JL_BUILD_NO_INTERACT=true`.
   *
   * --- Runtime Stage ---
   * 1. Uses the same Dart SDK version as base.
   * 2. Sets the working directory to `/app`.
   * 3. Copies compiled artifacts from the build stage (`/app/build`) and `pubspec.*` files.
   * 4. Exposes the default HTTP port `8080`.
   * 5. Sets the entrypoint to run the compiled Jetleaf application:
   *    ```bash
   *    dart run build/<projectId>.dill
   *    ```
   *
   * --- Notes ---
   * - The multi-stage approach reduces the size of the final runtime image.
   * - Environment variables can be overridden at build or runtime.
   * - Ideal for production deployment or CI/CD pipelines.
   *
   * @param {ProjectConfig} config - The project configuration containing metadata
   *        like projectId and Dart SDK version.
   * @returns {string} A fully generated Dockerfile string ready to write to disk.
   *
   * @example
   * // Generates a Dockerfile for a project with Dart SDK 3.2
   * const dockerfile = buildDockerFile({
   *   projectId: "my_project",
   *   version: { dartSdk: "3.2" }
   * });
   */
  static buildDockerFile(config: ProjectConfig): string {
    return `
# --------------------------------------------------------------------------
# Stage 1: Build stage
# --------------------------------------------------------------------------
FROM dart:${config.version.dartSdk}-sdk AS build

# Set working directory
WORKDIR /app

# Copy pubspec files first for caching
COPY pubspec.* ./

# Get dependencies
RUN dart pub get

# Copy the rest of the source code
COPY . .

# Environment variables for non-interactive build (optional)
# Can be overridden at docker run/build time
ENV JL_PATH_FOLDER=build/
ENV JL_EXEC_NAME=${config.projectId}
ENV JL_BUILD_EXCLUDE=""
ENV JL_BUILD_INCLUDE=""
ENV JL_BUILD_NO_INTERACT=true

# Run Jetleaf build
# Use --no-interact if JL_BUILD_NO_INTERACT is true
RUN if [ "$JL_BUILD_NO_INTERACT" = "true" ]; then
    dart run jetleaf_cli:jl build --no-interact;
else
    dart run jetleaf_cli:jl build;
fi

# --------------------------------------------------------------------------
# Stage 2: Runtime stage (smaller image)
# --------------------------------------------------------------------------
FROM dart:${config.version.dartSdk}-sdk AS runtime

# Set working directory
WORKDIR /app

# Copy compiled build artifacts from build stage
COPY --from=build /app/build ./build
COPY --from=build /app/pubspec.* ./

# Expose the default port (change if needed)
EXPOSE 8080

# Entrypoint: run the compiled Jetleaf ${config.projectId}
CMD ["dart", "run", "build/${config.projectId}.dill"]
    `.trimStart().trimEnd()
  }

  /**
   * Generates the content of the `.env` file for the project.
   *
   * This file provides environment variables for local development
   * and runtime configuration, mainly for web-enabled Jetleaf projects.
   *
   * --- Behavior ---
   * 1. Generates content only if `showWeb` is `true`.
   * 2. Adds a comment identifying the project for clarity.
   * 3. Defines default server environment variables:
   *    - `SERVER_PORT` — default `8080`
   *    - `SERVER_HOST` — default `0.0.0.0`
   *
   * --- Output ---
   * - Returns a string suitable for writing directly to a `.env` file.
   * - Returns an empty string if `showWeb` is `false`.
   *
   * --- Example ---
   * ```env
   * # Environment variables for my_project
   * SERVER_PORT=8080
   * SERVER_HOST=0.0.0.0
   * ```
   *
   * @param {BuildOptions} options - Options controlling the generated environment file.
   * @returns {string} The content of the `.env` file or an empty string.
   */
  static buildEnv({ config, showWeb }: BuildOptions): string {
    const sb = new StringBuffer();
    const port = Constants.SERVER_PORT;
    const host = Constants.SERVER_HOST;

    // Only include env variables if showWeb is true
    if (showWeb) {
      sb.writeln(`# Environment variables for ${config.projectId}`);
      sb.writeln(`SERVER_PORT=${port}`);
      sb.writeln(`SERVER_HOST=${host}`);
    }

    return sb.toString();
  }

  /**
   * Generates the default contents for a `.gitignore` file.
   *
   * This file prevents temporary, generated, build, and environment-specific
   * artifacts from being committed to version control. The generated rules are
   * based on common Dart and Jetleaf project conventions.
   *
   * ## Includes
   * - `.dart_tool/`, `.packages`, and `build/` directories
   * - `pubspec.lock` (typically excluded for application projects)
   * - dotenv environment files (`.env*`)
   * - generated JavaScript output from `dart2js`
   * - Flutter-related plugin metadata files
   *
   * ## Notes
   * - The caller is responsible for deciding whether the file should be written,
   *   based on configuration options such as `addGitIgnore`.
   * - The content is static and does not vary by project type.
   *
   * @returns A multi-line string representing the `.gitignore` file contents.
   */
  static buildGitIgnore(): string {
    return `
# See https://www.dartlang.org/guides/libraries/private-files

# Files and directories created by pub
.dart_tool/
.packages
build/
# If you're building an application, you may want to check-in your pubspec.lock
pubspec.lock

# Directory created by dartdoc
# If you don't generate documentation locally you can remove this line.
# doc/api/

# dotenv environment variables file
.env*

# Avoid committing generated Javascript files:
*.dart.js
# Produced by the --dump-info flag.
*.info.json

.flutter-plugins
.flutter-plugins-dependencies  
    `.trimStart().trimEnd()
  }

  /**
   * Generates the full content of the `main.dart` entry point for a Jetleaf project.
   *
   * This function constructs:
   * 1. All required import statements (core and optional packages)
   * 2. The asynchronous `main` function to bootstrap the application
   * 3. Annotations relevant to the selected Jetleaf extensions
   * 4. The root application class with no internal members
   *
   * The generated code is syntactically valid Dart and fully ready to include in
   * the project structure.
   *
   * @param {MainBuildOptions} options Configuration options controlling
   *                                        imports, annotations, and class name.
   * @returns {string} A fully assembled `main.dart` file as a string.
   *
   * @example
   * ```ts
   * buildMainDart({
   *   className: "MyApp",
   *   showResource: true,
   *   showScheduling: true
   * });
   * ```
   *
   * This would output:
   * ```dart
   * import 'package:jetleaf/jetleaf.dart';
   * import 'package:jetleaf_resource/jetleaf_resource.dart;';
   * import 'package:jetleaf_scheduling/jetleaf_scheduling.dart;';
   *
   * Future<void> main(List<String> args) async {
   *   await JetleafApplication.run(MyApp(), args);
   * }
   *
   * @EnableResource()
   * @EnableScheduling()
   * @JetleafApplicationStarter()
   * class MyApp {}
   * ```
   */
  static buildMainDart(options: MainBuildOptions): string {
    const { className, showResource = false, showScheduling = false } = options;
    const sb = new StringBuffer();

    // Imports
    sb.writeln(`import 'package:jetleaf/jetleaf.dart';`);
    if (showResource) sb.writeln(`import 'package:jetleaf_resource/jetleaf_resource.dart';`);
    if (showScheduling) sb.writeln(`import 'package:jetleaf_scheduling/jetleaf_scheduling.dart';`);
    sb.writeln(); // blank line after imports

    // main function
    sb.writeln(`Future<void> main(List<String> args) async {`);
    sb.writeln(`  await JetleafApplication.run(${className}(), args);`);
    sb.writeln(`}`);
    sb.writeln(); // blank line before annotations

    // Annotations
    if (showResource) sb.writeln(`@EnableResource()`);
    if (showScheduling) sb.writeln(`@EnableScheduling()`);
    sb.writeln(`@JetleafApplicationStarter()`);

    // Class declaration
    sb.writeln(`class ${className} {}`);

    return sb.toString();
  }

  /**
   * Generates the contents of the `pubspec.yaml` file for the project.
   *
   * This method dynamically assembles the project’s package metadata and
   * dependency list based on the current `ProjectConfig` settings.
   *
   * --- Behavior ---
   * 1. Sets basic project metadata:
   *    - `name` — from `config.projectId`
   *    - `description` — from `config.description` or defaults to `"A new Jetleaf project"`
   *    - `version` — from `config.version.version`
   *
   * 2. Configures the Dart SDK version constraint using `config.version.dartSdk`.
   *
   * 3. Adds dependencies:
   *    - Always includes the core `jetleaf` package with its configured version.
   *    - Adds additional packages from `config.selectedPackages` (name and version).
   *
   * 4. Adds development dependencies:
   *    - `test` — for unit testing
   *    - `lints` — for standard code linting
   *    - Optional Jetleaf devtool package if present
   *
   * 5. Ensures reproducible builds:
   *    - Dependency versions are interpolated directly from metadata
   *    - Prevents empty or undefined entries
   *
   * --- Output ---
   * - Returns a string containing the fully assembled `pubspec.yaml` content.
   * - The string must be written to disk to create a valid Dart project file.
   *
   * --- Example ---
   * ```yaml
   * name: my_project
   * description: A new Jetleaf project
   * version: 1.0.0
   * environment:
   *   sdk: '>=3.0.0 <4.0.0'
   *
   * dependencies:
   *   jetleaf: ^1.0.0
   *   jetleaf_web: ^1.2.0
   *
   * dev_dependencies:
   *   test: ^1.20.0
   *   lints: ^2.0.0
   *   jetleaf_cli: ^1.0.0
   * ```
   *
   * @param {ProjectConfig} config - The project configuration containing metadata,
   *                                 selected packages, and versioning information.
   * @returns {string} The complete `pubspec.yaml` content ready to be written.
   */
  static buildPubSpec(config: ProjectConfig): string {
    const sb = new StringBuffer();

    // Basic project info
    sb.writeln(`name: ${config.projectId}`);
    sb.writeln(`description: ${config.description}`);
    sb.writeln(`version: 1.0.0`);
    sb.writeln(); // blank line before environment

    // Environment
    sb.writeln(`environment:`);
    sb.writeln(`  sdk: '${CodeBuilder.getVersion(config.version.dartSdk)}'`);
    sb.writeln(); // blank line before dependencies

    // Dependencies
    sb.writeln(`dependencies:`);
    sb.writeln(`  jetleaf: ${CodeBuilder.getVersion(config.version.version)}`);
    for (const pkg of config.selectedPackages) {
      sb.writeln(`  ${pkg.id}: ${CodeBuilder.getVersion(pkg.version)}`);
    }
    sb.writeln(); // blank line before dev_dependencies

    let testDependency = "test: ^1.24.0";

    if (config.version.pkgVersion.pubspec.dev_dependencies) {
      testDependency = `test: ${config.version.pkgVersion.pubspec.dev_dependencies["test"]}`
    }

    let lintsDependency = "lints: ^2.1.0";

    if (config.version.pkgVersion.pubspec.dev_dependencies) {
      lintsDependency = `lints: ${config.version.pkgVersion.pubspec.dev_dependencies["lints"]}`
    }

    // Dev dependencies
    sb.writeln(`dev_dependencies:`);
    sb.writeln(`  ${testDependency}`);
    sb.writeln(`  ${lintsDependency}`);

    if (config.devtool) {
      sb.writeln("  build_runner: ^2.10.1");
      sb.writeln(`  ${config.devtool.name}: ${CodeBuilder.getVersion(config.devtool.latest.version)}`);
    }

    return sb.toString();
  }

  /**
   * Normalizes a dependency version string by ensuring it follows Dart's
   * caret‐syntax (`^x.y.z`) for semantic versioning.
   *
   * This helper is used when generating `pubspec.yaml` dependency entries,
   * guaranteeing that versions are formatted consistently.
   *
   * --- Behavior ---
   * - If the provided `version` **already starts with `^`**, it is returned unchanged.
   * - If it **does not start with `^`**, the function prepends `^` to the version.
   *
   * This ensures:
   * - Cleaner `pubspec.yaml` output
   * - Avoids accidental mixing of caret and non-caret syntax
   * - Supports Dart best practices for dependency version ranges
   *
   * @param version The raw version string (e.g., `"1.2.3"` or `"^1.2.3"`).
   * @returns The normalized version string beginning with `^`.
   *
   * @example
   * getVersion("1.0.0");   // "^1.0.0"
   * getVersion("^2.5.1");  // "^2.5.1"
   */
  private static getVersion(version: string): string {
    return !version.startsWith("^") ? `^${version}` : version;
  }

  /**
   * Generates the full `README.md` content for a Jetleaf project.
   *
   * This function constructs a comprehensive README file based on the provided
   * project configuration and selected features. It includes sections such as:
   * 
   * 1. **Project Header** — Displays the project name and description.
   * 2. **Getting Started** — Lists prerequisites and installation steps.
   * 3. **Running the Application** — Explains interceptable methods, proxy generation,
   *    and server startup instructions.
   * 4. **Included Packages** — Shows all selected Dart packages with versions and
   *    short descriptions.
   * 5. **Project Structure** — Outputs a tree representation of files and folders
   *    generated by `buildStructure()`.
   * 6. **Optional Docker** — Provides Docker build and run instructions if
   *    `generateDockerfile` is enabled.
   * 7. **Documentation** — Links to the official Jetleaf documentation.
   * 8. **License** — Marks the project under MIT License.
   *
   * @param {BuildOptions} options - Configuration and runtime options for generating the README.
   * @returns {string} The complete `README.md` content ready to write to disk.
   */
  static buildReadme(options: BuildOptions): string {
    const sb = new StringBuffer();
    const config = options.config;
    const port = Constants.SERVER_PORT;
    const host = Constants.SERVER_HOST;
    const showWeb = options.showWeb;

    // Project header
    sb.writeln(`# ${config.projectName}`);
    sb.writeln();

    if (config.description) {
      sb.writeln(config.description);
      sb.writeln();
    }

    // Badges (optional but nice)
    sb.writeln(`![Dart Version](https://img.shields.io/badge/Dart-${config.version.dartSdk}-blue)`);
    sb.writeln(`![Jetleaf](https://img.shields.io/badge/Jetleaf-${config.version.version}-green)`);
    sb.writeln();

    // Quick links
    sb.writeln('## Quick Links');
    sb.writeln('- [Getting Started](#getting-started)');
    sb.writeln('- [Project Structure](#project-structure)');
    sb.writeln('- [Development](#development)');
    sb.writeln('- [Jetleaf Documentation](#jetleaf-documentation)');
    sb.writeln();

    // Getting started
    sb.writeln(`## Getting Started`);
    sb.writeln();
    sb.writeln(`### Prerequisites`);
    sb.writeln(`- Dart SDK ${config.version.dartSdk} or later`);
    sb.writeln(`- Jetleaf ${config.version.version} or later`);
    sb.writeln();

    sb.writeln(`### Installation`);
    sb.writeln();
    sb.writeln('```bash');
    sb.writeln('dart pub get');
    sb.writeln('```');
    sb.writeln();

    sb.writeln(`### Running the Application`);
    sb.writeln();
    sb.writeln('#### Development Mode (Recommended)');
    sb.writeln('```bash');
    sb.writeln('jl dev');
    sb.writeln('```');
    sb.writeln();
    sb.writeln('#### Standard Dart Run');
    sb.writeln('```bash');
    sb.writeln('dart run');
    sb.writeln('```');
    sb.writeln();
    sb.writeln(`The server will start on http://${host}:${port}`);
    sb.writeln();

    sb.writeln('### Making Classes Interceptable');
    sb.writeln();
    sb.writeln('For AOP functionality, make your classes interceptable:');
    sb.writeln();
    sb.writeln('**Option 1: Generate Proxies**');
    sb.writeln('```bash');
    sb.writeln('jl proxy');
    sb.writeln('```');
    sb.writeln('> Note: Classes must not be final, base, or abstract, and methods must return `Future`.');
    sb.writeln();
    sb.writeln('**Option 2: Use Interceptable Mixin**');
    sb.writeln('```dart');
    sb.writeln('class MyService with Interceptable {');
    sb.writeln('  Future<String> myMethod() async {');
    sb.writeln('    return when(() async {');
    sb.writeln('      // Your method logic here');
    sb.writeln('      return "result";');
    sb.writeln('    });');
    sb.writeln('  }');
    sb.writeln('}');
    sb.writeln('```');
    sb.writeln();

    // Project structure
    sb.writeln(`## Project Structure`);
    sb.writeln();
    sb.writeln('```');
    CodeBuilder.buildStructureTree(sb, config.buildStructure(false));
    sb.writeln('```');
    sb.writeln();

    sb.writeln('**Key Directories:**');
    sb.writeln('- `lib/` - Application source code');
    sb.writeln('- `resources/` - Configuration files');
    sb.writeln('- `test/` - Unit and integration tests');
    sb.writeln();

    // Included packages
    if (config.selectedPackages.length > 0) {
      sb.writeln(`## Included Packages`);
      sb.writeln();
      for (const pkg of config.selectedPackages) {
        sb.writeln(`- **${pkg.name}** (${pkg.version}): ${pkg.shortDescription}`);
      }
      sb.writeln();
    }

    // Development
    sb.writeln('## Development');
    sb.writeln();
    sb.writeln('### Testing');
    sb.writeln('```bash');
    sb.writeln('dart test');
    sb.writeln('```');
    sb.writeln();

    sb.writeln('### Code Analysis');
    sb.writeln('```bash');
    sb.writeln('dart analyze');
    sb.writeln('```');
    sb.writeln();

    sb.writeln('### Formatting');
    sb.writeln('```bash');
    sb.writeln('dart format .');
    sb.writeln('```');
    sb.writeln();

    // Optional Docker
    if (config.generateDockerfile) {
      sb.writeln(`## Docker Support`);
      sb.writeln();
      sb.writeln('Build and run with Docker:');
      sb.writeln();
      sb.writeln('```bash');
      sb.writeln(`docker build -t ${config.projectId} .`);
      sb.writeln(`docker run -p ${port}:${port} ${config.projectId}`);
      sb.writeln('```');
      sb.writeln();
    }

    // Optional CI/CD
    if (config.addCICD) {
      sb.writeln('## CI/CD');
      sb.writeln();
      sb.writeln('This project includes GitHub Actions workflow for continuous integration.');
      sb.writeln('See `.github/workflows/ci.yml` for details.');
      sb.writeln();
    }

    // Jetleaf Documentation Link
    sb.writeln('## Jetleaf Documentation');
    sb.writeln();
    sb.writeln('For complete Jetleaf framework documentation, see:');
    sb.writeln();
    sb.writeln('1. [Official Documentation](https://jetleaf.hapnium.com/docs)');
    sb.writeln('2. [GitHub Repository](https://github.com/jetleaf/jetleaf)');
    sb.writeln('3. [Complete Guide](./JETLEAF_GUIDE.md) (generated in config project)');
    sb.writeln();

    sb.writeln('### Key Concepts');
    sb.writeln('- **Dependency Injection**: `@Service`, `@Component`, `@Autowired`');
    sb.writeln('- **Configuration**: `application.yaml`, `@Configuration`, `@Value`');
    sb.writeln('- **Lifecycle**: `@PostConstruct`, `@PreDestroy`');
    sb.writeln('- **Profiles**: `@Profile`, environment-specific configuration');
    sb.writeln();

    // Environment Variables
    if (showWeb) {
      sb.writeln('## Environment Configuration');
      sb.writeln();
      sb.writeln('Configuration can be customized via:');
      sb.writeln();
      sb.writeln('1. **Environment Variables**:');
      sb.writeln('   ```bash');
      sb.writeln(`   export port=${port}`);
      sb.writeln(`   export host=${host}`);
      sb.writeln('   ```');
      sb.writeln();
      sb.writeln('2. **Command Line Arguments**:');
      sb.writeln('   ```bash');
      sb.writeln(`   dart run -- --jetleaf.profiles.active=production`);
      sb.writeln('   ```');
      sb.writeln();
      sb.writeln('3. **Configuration Files**: See `resources/` directory');
      sb.writeln();
    }

    // License
    sb.writeln(`## License`);
    sb.writeln();
    sb.writeln(`${config.projectName} is MIT licensed.`);
    sb.writeln('Jetleaf framework is also MIT licensed.');

    return sb.toString();
  }

  /**
   * Recursively appends a textual tree representation of the project structure
   * to the given `StringBuffer`.
   *
   * This helper method is used internally by `buildReadme()` to display the
   * directory and file hierarchy in a visually appealing tree format.
   *
   * --- Behavior ---
   * - Uses `├──`, `└──`, and `│` characters to represent folder nesting.
   * - Adds trailing `/` for folders.
   * - Recursively descends into folders to display nested children.
   * - Handles root node separately to avoid unnecessary connector characters.
   *
   * @param sb
   *   The `StringBuffer` instance used to accumulate lines of the tree.
   * @param node
   *   The current `ProjectStructure` node (file or folder) being processed.
   * @param prefix
   *   The string prefix used to properly align tree branches at the current
   *   recursion depth. Typically starts as an empty string for the root.
   */
  private static buildStructureTree(sb: StringBuffer, node: ProjectStructure, prefix: string = '', isLast: boolean = true, isRoot: boolean = true,) {
    // Handle root node differently
    if (isRoot) {
      sb.writeln(`${node.name}/`);
    } else {
      const connector = isLast ? '└── ' : '├── ';
      const nameWithSuffix = node.type === 'folder' ? `${node.name}/` : node.name;
      sb.writeln(`${prefix}${connector}${nameWithSuffix}`);
    }

    if (node.type === 'folder' && node.children?.length) {
      const lastIndex = node.children.length - 1;

      node.children.forEach((child, i) => {
        const childIsLast = i === lastIndex;

        // Build new prefix for child lines
        const childPrefix = prefix + (isRoot ? '' : isLast ? '    ' : '│   ');

        // Recurse with correct parameters
        CodeBuilder.buildStructureTree(sb, child, childPrefix, childIsLast, false);
      });
    }
  }

  /**
   * Generates a comprehensive Jetleaf Backend Development Guide as a Markdown string.
   *
   * This function dynamically assembles a detailed README-style guide based on the
   * project's selected packages and configuration. It includes setup instructions,
   * code examples, and feature-specific sections, showing only the parts relevant
   * to the features enabled.
   *
   * --- Core Responsibilities ---------------------------------------------------
   *
   * 1. **Dynamic Table of Contents**
   *    - Only includes sections that are enabled by the project's packages.
   *
   * 2. **Core Components**
   *    - Dependency injection patterns
   *    - Service and class scaffolding
   *
   * 3. **Configuration Management**
   *    - YAML or properties configuration examples
   *    - Generated configuration classes
   *
   * 4. **Feature-specific Sections**
   *    - REST Controllers & Web/HTTP examples (`showWeb`)
   *    - Scheduled Tasks (`showScheduling`)
   *    - Caching (`showResource`)
   *    - Validation (`showValidation`)
   *    - Retry Mechanism (`showRetry`)
   *    - Rate Limiting (`showResource`)
   *    - Data Access (`showData`)
   *    - Monitoring (`showMonitor`)
   *
   * 5. **Best Practices**
   *    - Constructor injection
   *    - Interceptable classes
   *    - Organized project structure by feature
   *
   * 6. **Next Steps**
   *    - Recommendations for extending the project and reviewing generated code
   *
   * --- Output Characteristics --------------------------------------------------
   *
   * - Fully Markdown-formatted string
   * - Sections and examples match enabled features
   * - Includes real Dart and YAML examples for all applicable features
   * - Structured for readability with headings, code blocks, and numbered sections
   *
   * --- Intended Usage ----------------------------------------------------------
   *
   * - Provide developers a ready-to-use development guide embedded in the
   *   generated project
   * - Serve as a reference for Jetleaf project setup, coding patterns, and
   *   configuration conventions
   * - Highlight features that have been included based on the selected packages
   *
   * @param {IntroductionToJetleafBuildOptions} options Optional feature flags controlling which
   *                                      sections to include in the guide.
   * @returns {string} The complete Markdown content of the Jetleaf Backend
   *                   Development Guide.
   */
  static buildJetleafIntroduction(config: ProjectConfig, options: IntroductionToJetleafBuildOptions = {}): string {
    const {
      showWeb = false,
      showScheduling = false,
      showResource = false,
      showValidation = false,
      showRetry = false,
      showData = false,
      showMonitor = false,
      className = ""
    } = options;

    const sb = new StringBuffer();

    sb.writeln('# Jetleaf Backend Development Guide');
    sb.writeln();
    sb.writeln('This guide covers essential patterns for building backends with Jetleaf. Your project is already configured - here\'s how to extend it.');
    sb.writeln();

    // Build sections dynamically
    const sections: { title: string, enabled: boolean }[] = [
      { title: 'Core Components', enabled: true },
      { title: 'Configuration Management', enabled: true },
      { title: 'REST Controllers', enabled: showWeb },
      { title: 'Web & HTTP', enabled: showWeb },
      { title: 'Scheduled Tasks', enabled: showScheduling },
      { title: 'Caching', enabled: showResource },
      { title: 'Validation', enabled: showValidation },
      { title: 'Retry Mechanism', enabled: showRetry },
      { title: 'Rate Limiting', enabled: showResource },
      { title: 'Data Access', enabled: showData },
      { title: 'Monitoring', enabled: showMonitor },
    ];

    // Table of Contents
    sb.writeln('## Contents');
    let sectionNumber = 1;
    sections.forEach((section, index) => {
      if (section.enabled) {
        const anchor = section.title.toLowerCase().replace(/[^a-z0-9]+/g, '-');
        sb.writeln(`${sectionNumber}. [${section.title}](#${anchor})`);
        sectionNumber++;
      }
    });
    sb.writeln();

    // Now write each section with proper numbering
    let currentSection = 1;

    // 1. Core Components
    sb.writeln(`## ${currentSection}. Core Components`);
    currentSection++;
    sb.writeln();
    sb.writeln('### Services with Dependency Injection');
    sb.writeln('```dart');
    sb.writeln('import \'package:jetleaf/jetleaf.dart\';');
    sb.writeln();
    sb.writeln('@Service()');
    sb.writeln('class UserService {');
    sb.writeln('  Future<User> getUser(String id) async {');
    sb.writeln('    // Business logic here');
    sb.writeln('    return User(id: id, name: "John Doe");');
    sb.writeln('  }');
    sb.writeln('}');
    sb.writeln();
    sb.writeln('@Service()');
    sb.writeln('@RequiredAll()  // Auto-injects all dependencies');
    sb.writeln('class OrderService {');
    sb.writeln('  final UserService userService;');
    sb.writeln('  final PaymentService paymentService;');
    sb.writeln('  ');
    sb.writeln('  // Constructor injection');
    sb.writeln('  const OrderService(this.userService, this.paymentService);');
    sb.writeln('}');
    sb.writeln('```');
    sb.writeln();

    // 2. Configuration Management
    sb.writeln(`## ${currentSection}. Configuration Management`);
    currentSection++;
    sb.writeln();
    sb.writeln('### YAML Configuration (`resources/application.yaml`)');
    sb.writeln('```yaml');
    sb.writeln('application:');
    sb.writeln(`  name: ${config.projectId}`);
    sb.writeln('');
    sb.writeln('jetleaf:');
    sb.writeln('  application:');
    sb.writeln(`    name: ${className}`);
    sb.writeln('```');
    sb.writeln();
    sb.writeln('### Configuration Classes');
    sb.writeln('```dart');
    sb.writeln('@Configuration()');
    sb.writeln('class AppConfig {');
    sb.writeln('  @Pod()  // Creates a managed bean');
    sb.writeln('  DatabaseConfig databaseConfig(');
    sb.writeln('    @Value(\'#{database.host:localhost}\') String host,');
    sb.writeln('    @Value(\'#{database.port:5432}\') int port');
    sb.writeln('  ) {');
    sb.writeln('    return DatabaseConfig(host: host, port: port);');
    sb.writeln('  }');
    sb.writeln('}');
    sb.writeln('```');
    sb.writeln();

    // 3. REST Controllers (only if web is enabled)
    if (sections[2].enabled) { // REST Controllers
      sb.writeln(`## ${currentSection}. REST Controllers`);
      currentSection++;
      sb.writeln();
      sb.writeln('### Basic Controller');
      sb.writeln('```dart');
      sb.writeln('import \'package:jetleaf/jetleaf.dart\';');
      sb.writeln('import \'package:jetleaf_web/jetleaf_web.dart\';');
      sb.writeln();
      sb.writeln('@RestController("/users")');
      sb.writeln('class UserController {');
      sb.writeln('  final UserService userService;');
      sb.writeln('  ');
      sb.writeln('  UserController(this.userService);');
      sb.writeln('  ');
      sb.writeln('  @GetMapping("/{id}")');
      sb.writeln('  Future<ResponseBody<User>> getUser(@PathVariable() String id) async {');
      sb.writeln('    final user = await userService.getUser(id);');
      sb.writeln('    return ResponseBody.of(HttpStatus.OK, user);');
      sb.writeln('  }');
      sb.writeln('  ');
      sb.writeln('  @PostMapping()');
      sb.writeln('  Future<ResponseBody<User>> createUser(@RequestBody() User user) async {');
      sb.writeln('    final created = await userService.create(user);');
      sb.writeln('    return ResponseBody.created(\'/users/\${created.id}\', created);');
      sb.writeln('  }');
      sb.writeln('}');
      sb.writeln('```');
      sb.writeln();

      sb.writeln('### Complex Request Handling');
      sb.writeln('```dart');
      sb.writeln('@PostMapping(');
      sb.writeln('  consumes: [MediaType.APPLICATION_JSON, MediaType.MULTIPART_FORM_DATA]');
      sb.writeln(')');
      sb.writeln('Future<ResponseBody<Store>> createStore(');
      sb.writeln('  @RequestBody() Store store,');
      sb.writeln('  @RequestPart("logo") MultipartFile? logo,');
      sb.writeln('  @RequestPart("document") Part? document,');
      sb.writeln(') async {');
      sb.writeln('  // Handle both JSON body and multipart files');
      sb.writeln('  final created = store.copyWith(logo: logo, document: document);');
      sb.writeln('  return ResponseBody.of(HttpStatus.CREATED, created);');
      sb.writeln('}');
      sb.writeln('```');
      sb.writeln();
    }

    // 4. Web & HTTP (only if web is enabled)
    if (sections[3].enabled) { // Web & HTTP
      sb.writeln(`## ${currentSection}. Web & HTTP`);
      currentSection++;
      sb.writeln();
      sb.writeln('### Making HTTP Requests');
      sb.writeln('```dart');
      sb.writeln('@Service()');
      sb.writeln('@RequiredAll()');
      sb.writeln('class ExternalApiService {');
      sb.writeln('  final RestClient rest;');
      sb.writeln('  ');
      sb.writeln('  ExternalApiService(this.rest);');
      sb.writeln('  ');
      sb.writeln('  Future<String> fetchData() async {');
      sb.writeln('    final response = await rest');
      sb.writeln('      .get()');
      sb.writeln('      .uri("https://api.example.com/data")');
      sb.writeln('      .execute((resp) async => resp.getBody().readAsString());');
      sb.writeln('    ');
      sb.writeln('    return response;');
      sb.writeln('  }');
      sb.writeln('}');
      sb.writeln('```');
      sb.writeln();
    }

    // 5. Scheduled Tasks (only if scheduling is enabled)
    if (sections[4].enabled) { // Scheduled Tasks
      sb.writeln(`## ${currentSection}. Scheduled Tasks`);
      currentSection++;
      sb.writeln();
      sb.writeln('### Basic Scheduling');
      sb.writeln('```dart');
      sb.writeln('import \'package:jetleaf/jetleaf.dart\';');
      sb.writeln('import \'package:jetleaf_scheduling/jetleaf_scheduling.dart\';');
      sb.writeln();
      sb.writeln('@Service()');
      sb.writeln('class ScheduledTasks {');
      sb.writeln('  // Run every 10 seconds');
      sb.writeln('  @Scheduled(fixedRate: Duration(seconds: 10))');
      sb.writeln('  Future<void> cleanupTask() async {');
      sb.writeln('    print(\'Running cleanup task at \${DateTime.now()}\');');
      sb.writeln('  }');
      sb.writeln('  ');
      sb.writeln('  // Run every minute using cron syntax');
      sb.writeln('  @Scheduled(type: CronType.EVERY_MINUTE)');
      sb.writeln('  Future<void> reportTask() async {');
      sb.writeln('    print(\'Generating report at \${DateTime.now()}\');');
      sb.writeln('  }');
      sb.writeln('}');
      sb.writeln('```');
      sb.writeln();

      sb.writeln('### Combined with HTTP Requests');
      sb.writeln('```dart');
      sb.writeln('@Service()');
      sb.writeln('@RequiredAll()');
      sb.writeln('class RestTestService {');
      sb.writeln('  final RestClient rest;');
      sb.writeln('  ');
      sb.writeln('  RestTestService(this.rest);');
      sb.writeln('  ');
      sb.writeln('  @Scheduled(fixedRate: Duration(seconds: 30))');
      sb.writeln('  Future<void> sendHeartbeat() async {');
      sb.writeln('    print(\'Sending heartbeat...\');');
      sb.writeln('    final body = {');
      sb.writeln('      "timestamp": DateTime.now().toIso8601String(),');
      sb.writeln('      "status": "alive"');
      sb.writeln('    };');
      sb.writeln('    ');
      sb.writeln('    final response = await rest');
      sb.writeln('      .post()');
      sb.writeln('      .uri("https://httpbin.org/post")');
      sb.writeln('      .body(body)');
      sb.writeln('      .execute((resp) async => resp.getBody().readAsString());');
      sb.writeln('    ');
      sb.writeln('    print(\'Response: $response\');');
      sb.writeln('  }');
      sb.writeln('}');
      sb.writeln('```');
      sb.writeln();
    }

    // 6. Caching (only if resource package is enabled)
    if (sections[5].enabled) { // Caching
      sb.writeln(`## ${currentSection}. Caching`);
      currentSection++;
      sb.writeln();
      sb.writeln('### Cache Annotations with Interceptable');
      sb.writeln('```dart');
      sb.writeln('import \'package:jetleaf/jetleaf.dart\';');
      sb.writeln('import \'package:jetleaf_resource/jetleaf_resource.dart\';');
      sb.writeln();
      sb.writeln('@Service()');
      sb.writeln('final class CacheService with Interceptable {');
      sb.writeln('  // Cache result for 5 minutes');
      sb.writeln('  @Cacheable({"users"}, ttl: Duration(minutes: 5))');
      sb.writeln('  Future<User> getUser(String email) async => when(() async {');
      sb.writeln('    print("Fetching from database: $email");');
      sb.writeln('    // Expensive database call');
      sb.writeln('    await Future.delayed(Duration(milliseconds: 200));');
      sb.writeln('    return User(email: email, name: "Cached User");');
      sb.writeln('  }, this, \'getUser\', ExecutableArgument.positional([email]));');
      sb.writeln('  ');
      sb.writeln('  // Update cache after execution');
      sb.writeln('  @CachePut({"users"}, ttl: Duration(minutes: 2))');
      sb.writeln('  Future<User> addUser(User user) async => when(() async {');
      sb.writeln('    print("Adding user to database: \${user.email}");');
      sb.writeln('    // Add to database');
      sb.writeln('    await Future.delayed(Duration(milliseconds: 100));');
      sb.writeln('    return user;');
      sb.writeln('  }, this, \'addUser\', ExecutableArgument.positional([user.email]));');
      sb.writeln('  ');
      sb.writeln('  // Remove from cache');
      sb.writeln('  @CacheEvict({"users"}, beforeInvocation: true)');
      sb.writeln('  Future<void> removeUser(User user) async => when(() async {');
      sb.writeln('    print("Removing user: \${user.email}");');
      sb.writeln('    // Remove from database');
      sb.writeln('    await Future.delayed(Duration(milliseconds: 50));');
      sb.writeln('  }, this, \'removeUser\', ExecutableArgument.positional([user.email]));');
      sb.writeln('}');
      sb.writeln('```');
      sb.writeln();
    }

    // 7. Validation (only if validation package is enabled)
    if (sections[6].enabled) { // Validation
      sb.writeln(`## ${currentSection}. Validation`);
      currentSection++;
      sb.writeln();
      sb.writeln('### Method Parameter Validation');
      sb.writeln('```dart');
      sb.writeln('import \'package:jetleaf/jetleaf.dart\';');
      sb.writeln('import \'package:jetleaf_validation/jetleaf_validation.dart\';');
      sb.writeln();
      sb.writeln('@Service()');
      sb.writeln('class ValidationService {');
      sb.writeln('  // Validate method parameters');
      sb.writeln('  @Validated()');
      sb.writeln('  Future<User?> getUser(@NotNull() String id) async {');
      sb.writeln('    print("Fetching user: $id");');
      sb.writeln('    return User(name: "Validated User", email: "user@example.com");');
      sb.writeln('  }');
      sb.writeln('  ');
      sb.writeln('  // Multiple validations');
      sb.writeln('  Future<void> saveUser(');
      sb.writeln('    @Validated() @NotEmpty() String name,');
      sb.writeln('    @Validated() @Email() String emailAddress,');
      sb.writeln('  ) async {');
      sb.writeln('    print("Saving user: $name, $emailAddress");');
      sb.writeln('  }');
      sb.writeln('}');
      sb.writeln('```');
      sb.writeln();
    }

    // 8. Retry Mechanism (only if retry package is enabled)
    if (sections[7].enabled) { // Retry Mechanism
      sb.writeln(`## ${currentSection}. Retry Mechanism`);
      currentSection++;
      sb.writeln();
      sb.writeln('### Automatic Retry with Backoff');
      sb.writeln('```dart');
      sb.writeln('import \'package:jetleaf/jetleaf.dart\';');
      sb.writeln('import \'package:jetleaf_retry/jetleaf_retry.dart\';');
      sb.writeln();
      sb.writeln('@Service()');
      sb.writeln('@RequiredAll()');
      sb.writeln('class RetryService {');
      sb.writeln('  final RestClient rest;');
      sb.writeln('  ');
      sb.writeln('  RetryService(this.rest);');
      sb.writeln('  ');
      sb.writeln('  @Retryable(');
      sb.writeln('    maxAttempts: 5,');
      sb.writeln('    backoff: Backoff(delay: 500, multiplier: 2.0, maxDelay: 5000),');
      sb.writeln('    retryFor: [Exception],');
      sb.writeln('    label: \'api-call\',');
      sb.writeln('  )');
      sb.writeln('  Future<void> callExternalApi() async {');
      sb.writeln('    print("Calling external API...");');
      sb.writeln('    final response = await rest');
      sb.writeln('      .get()');
      sb.writeln('      .uri("https://api.example.com/unstable")');
      sb.writeln('      .execute((resp) async => resp.getBody().readAsString());');
      sb.writeln('    ');
      sb.writeln('    print("Response: $response");');
      sb.writeln('  }');
      sb.writeln('  ');
      sb.writeln('  // Recovery method for failed retries');
      sb.writeln('  @Recover(label: \'api-call\')');
      sb.writeln('  Future<void> apiRecovery(Exception e) async {');
      sb.writeln('    print("API call failed, executing recovery: $e");');
      sb.writeln('    // Fallback logic here');
      sb.writeln('  }');
      sb.writeln('}');
      sb.writeln('```');
      sb.writeln();
    }

    // 9. Rate Limiting (only if resource package is enabled)
    if (sections[8].enabled) { // Rate Limiting
      sb.writeln(`## ${currentSection}. Rate Limiting`);
      currentSection++;
      sb.writeln();
      sb.writeln('### Annotated Rate Limiting');
      sb.writeln('```dart');
      sb.writeln('import \'package:jetleaf/jetleaf.dart\';');
      sb.writeln('import \'package:jetleaf_resource/jetleaf_resource.dart\';');
      sb.writeln();
      sb.writeln('@Service()');
      sb.writeln('final class RateLimitService with Interceptable {');
      sb.writeln('  // 5 requests per minute');
      sb.writeln('  @RateLimit({"userRegistration"}, limit: 5, window: Duration(minutes: 1))');
      sb.writeln('  Future<User> registerUser(User user) async => when(() async {');
      sb.writeln('    print("Registering user: \${user.email}");');
      sb.writeln('    await Future.delayed(Duration(milliseconds: 100));');
      sb.writeln('    return user;');
      sb.writeln('  }, this, \'registerUser\', ExecutableArgument.positional([user.email]));');
      sb.writeln('  ');
      sb.writeln('  // Custom key generator based on IP');
      sb.writeln('  @RateLimit(');
      sb.writeln('    {"loginAttempts"}, ');
      sb.writeln('    limit: 10, ');
      sb.writeln('    window: Duration(hours: 1),');
      sb.writeln('    keyGenerator: \'ipBasedKeyGenerator\'');
      sb.writeln('  )');
      sb.writeln('  Future<LoginResponse> login(');
      sb.writeln('    String email, ');
      sb.writeln('    String password, ');
      sb.writeln('    String ipAddress');
      sb.writeln('  ) async => when(() async {');
      sb.writeln('    print("Login attempt for: $email from IP: $ipAddress");');
      sb.writeln('    // Authentication logic');
      sb.writeln('    return LoginResponse.success(user: User(email: email));');
      sb.writeln('  }, this, \'login\', ExecutableArgument.positional([email, password, ipAddress]));');
      sb.writeln('}');
      sb.writeln('```');
      sb.writeln();
    }

    // 10. Data Access (only if data package is enabled)
    if (sections[9].enabled) { // Data Access
      sb.writeln(`## ${currentSection}. Data Access`);
      currentSection++;
      sb.writeln();
      sb.writeln('### Repository Pattern');
      sb.writeln('```dart');
      sb.writeln('import \'package:jetleaf/jetleaf.dart\';');
      sb.writeln('import \'package:jetleaf_data/jetleaf_data.dart\';');
      sb.writeln();
      sb.writeln('@Repository()');
      sb.writeln('class UserRepository extends CrudRepository<User, String> {');
      sb.writeln('  // Auto-generated CRUD operations');
      sb.writeln('  // findById(id), save(entity), delete(entity), etc.');
      sb.writeln('}');
      sb.writeln();
      sb.writeln('@Service()');
      sb.writeln('class UserService {');
      sb.writeln('  final UserRepository repository;');
      sb.writeln('  ');
      sb.writeln('  UserService(this.repository);');
      sb.writeln('  ');
      sb.writeln('  Future<User> getUser(String id) async {');
      sb.writeln('    return await repository.findById(id);');
      sb.writeln('  }');
      sb.writeln('}');
      sb.writeln('```');
      sb.writeln();
    }

    // 11. Monitoring (only if monitor package is enabled)
    if (sections[10].enabled) { // Monitoring
      sb.writeln(`## ${currentSection}. Monitoring`);
      currentSection++;
      sb.writeln();
      sb.writeln('### Monitoring Services');
      sb.writeln('```dart');
      sb.writeln('import \'package:jetleaf/jetleaf.dart\';');
      sb.writeln('import \'package:jetleaf_monitor/jetleaf_monitor.dart\';');
      sb.writeln();
      sb.writeln('@Monitor()  // Enable monitoring for this class');
      sb.writeln('@Primary()');
      sb.writeln('@Component()');
      sb.writeln('@RequiredAll()');
      sb.writeln('class MonitoredService implements PackageService {');
      sb.writeln('  // All method calls are automatically monitored');
      sb.writeln('  Future<void> performTask() async {');
      sb.writeln('    await Future.delayed(Duration(milliseconds: 100));');
      sb.writeln('  }');
      sb.writeln('}');
      sb.writeln();
      sb.writeln('// Access monitoring data via REST');
      sb.writeln('@RestController("/monitor")');
      sb.writeln('class PerformanceController {');
      sb.writeln('  final MonitoringService _monitoringService;');
      sb.writeln('  ');
      sb.writeln('  PerformanceController(this._monitoringService);');
      sb.writeln('  ');
      sb.writeln('  @GetMapping("/{name}")');
      sb.writeln('  Future<ResponseBody<Performance>> getPerformance(');
      sb.writeln('    @PathVariable() String name');
      sb.writeln('  ) async {');
      sb.writeln('    final performance = _monitoringService.getPerformance(name);');
      sb.writeln('    if (performance != null) {');
      sb.writeln('      return ResponseBody.of(HttpStatus.OK, performance);');
      sb.writeln('    }');
      sb.writeln('    return ResponseBody.notFound();');
      sb.writeln('  }');
      sb.writeln('}');
      sb.writeln('```');
      sb.writeln();
    }

    // Best Practices (always shown, no number)
    sb.writeln('## Best Practices');
    sb.writeln();
    sb.writeln('### 1. Use Constructor Injection');
    sb.writeln('```dart');
    sb.writeln('// Good');
    sb.writeln('@Service()');
    sb.writeln('class OrderService {');
    sb.writeln('  final UserService userService;');
    sb.writeln('  ');
    sb.writeln('  OrderService(this.userService); // Explicit dependency');
    sb.writeln('}');
    sb.writeln();
    sb.writeln('// Also good (auto-inject)');
    sb.writeln('@Service()');
    sb.writeln('@RequiredAll()');
    sb.writeln('class OrderService {');
    sb.writeln('  late UserService userService; // Auto-injected');
    sb.writeln('}');
    sb.writeln('```');
    sb.writeln();

    sb.writeln('### 2. Make Classes Interceptable for AOP');
    sb.writeln('```dart');
    sb.writeln('@Service()');
    sb.writeln('final class MyService with Interceptable {');
    sb.writeln('  @RateLimit({"api"})');
    sb.writeln('  Future<String> apiCall() async => when(() async {');
    sb.writeln('    // Your logic here');
    sb.writeln('    return "result";');
    sb.writeln('  }, this, \'apiCall\');');
    sb.writeln('}');
    sb.writeln('```');
    sb.writeln();

    sb.writeln('### 3. Organize by Feature');
    sb.writeln('```');
    sb.writeln('lib/');
    sb.writeln('├── features/');
    sb.writeln('│   ├── users/');
    sb.writeln('│   │   ├── user_service.dart');
    sb.writeln('│   │   ├── user_controller.dart');
    sb.writeln('│   │   └── user_model.dart');
    sb.writeln('│   ├── orders/');
    sb.writeln('│   └── products/');
    sb.writeln('├── core/         # Shared infrastructure');
    sb.writeln('└── config/       # Configuration classes');
    sb.writeln('```');
    sb.writeln();

    sb.writeln('## Next Steps');
    sb.writeln();
    sb.writeln('1. **Explore your project structure** in the `lib/` directory');
    sb.writeln(`2. **Check the configuration** in \`resources/application.${config.resourceFileExtension.toString().toLowerCase()}\``);
    sb.writeln('3. **Run the application** with `dart run` or `jl dev`');
    sb.writeln('4. **Review generated examples** in the `lib/` folder');
    sb.writeln('5. **Add your services** and controllers following the patterns above');
    sb.writeln();
    sb.writeln('For complete documentation, visit [Jetleaf Documentation](https://jetleaf.hapnium.com/docs).');

    return sb.toString();
  }

  /**
   * Generates a string containing a Dart example for data access using Jetleaf.
   *
   * This example demonstrates how to define a repository class for the `User` entity
   * using the `jetleaf_data` package.
   *
   * Features included in the generated code:
   * 1. **Imports**
   *    - `jetleaf` — core framework functionality.
   *    - `jetleaf_data` — provides repository and CRUD utilities.
   *    - `../core/common_infrastructure.dart` — imports common example entities like `User`.
   *
   * 2. **UserRepository class**
   *    - Decorated with `@Repository()` to indicate a data repository.
   *    - Extends `CrudRepository<User, String>` to automatically gain default
   *      CRUD methods (`findById`, `save`, `delete`, etc.).
   *    - Provides a ready-to-use data access layer for the `User` entity without
   *      manually implementing CRUD operations.
   *
   * --- Usage ---
   * ```dart
   * final userRepository = UserRepository();
   * final user = await userRepository.findById("user123");
   * ```
   *
   * @returns {string} A string containing Dart source code for a Jetleaf data example.
   */
  static buildDataExample(): string {
    return `
import 'package:jetleaf_data/annotation.dart';
import 'package:jetleaf_data/jetleaf_data.dart';

import '../core/common_infrastructure.dart';

/// Just this, provides you with access to default methods defined by \`jetleaf_data\`
@Repository()
class UserRepository extends CrudRepository<User, String> {}`.trimStart().trimEnd();
  }

  /**
   * Generates a string containing common example classes used across
   * a Jetleaf application.
   *
   * The returned code defines:
   *
   * 1. **User class**
   *    - Represents a typical user entity.
   *    - Fields:
   *      - `name` (required) — the user's full name.
   *      - `email` (required) — the user's email address.
   *      - `age` (optional) — the user's age.
   *      - `password` (optional) — the user's password (usually omitted in responses).
   *    - Constructor enforces required fields while allowing optional ones.
   *
   * 2. **Store class**
   *    - Represents a simple store entity.
   *    - Fields:
   *      - `id` (required) — unique identifier for the store.
   *      - `name` (required) — the store's name.
   *    - Constructor enforces both fields.
   *
   * 3. **ApiResponse<T> class**
   *    - Generic wrapper for API responses.
   *    - Fields:
   *      - `success` (required) — indicates if the operation was successful.
   *      - `message` (required) — human-readable response message.
   *      - `data` (optional) — generic payload containing the actual response.
   *    - Useful for standardizing REST or service responses across the app.
   *
   * --- Usage ---
   * ```dart
   * final user = User(name: "Alice", email: "alice@example.com");
   * final store = Store(id: "1", name: "SuperStore");
   * final response = ApiResponse<User>(success: true, message: "Fetched user", data: user);
   * ```
   *
   * @returns {string} A string containing the Dart source code for common example classes.
   */
  static buildCommonExample(): string {
    return `
/// Common infrastructure classes used across the application
class User {
  final String name;
  final String email;
  final int? age;
  final String? password;
  
  User({
    required this.name,
    required this.email,
    this.age,
    this.password,
  });
}

class Store {
  final String id;
  final String name;
  
  Store({required this.id, required this.name});
}

/// Common response wrapper
class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  
  ApiResponse({required this.success, required this.message, this.data});
}`.trimStart().trimEnd();
  }

  /**
   * Generates a string containing a Dart example for a monitored service using Jetleaf.
   *
   * This code demonstrates how to define a service whose method calls are automatically
   * monitored using the `jetleaf_monitor` package.
   *
   * Features:
   * 1. **Imports**
   *    - `jetleaf` — core framework.
   *    - `jetleaf_monitor` — enables automatic monitoring.
   *
   * 2. **MonitoredService class**
   *    - Decorated with `@Monitor()` to enable monitoring for all method calls.
   *    - Decorated with `@Primary()`, `@Component()`, and `@RequiredAll()` to
   *      indicate it is the primary monitored service with all dependencies auto-injected.
   *    - Includes example methods:
   *      - `performTask()` — simulates a short task.
   *      - `processData(String input)` — simulates processing and returns a string.
   *
   * --- Usage ---
   * ```dart
   * final service = MonitoredService();
   * await service.performTask();
   * final result = await service.processData("input");
   * ```
   *
   * @returns {string} Dart source code string for a monitored service example.
   */
  static buildMonitorExample(): string {
    return `
import 'package:jetleaf/jetleaf.dart';
import 'package:jetleaf_monitor/jetleaf_monitor.dart';

@Monitor()
@Primary()
@Component()
@RequiredAll()
class MonitoredService {
  Future<void> performTask() async {
    await Future.delayed(Duration(milliseconds: 50));
  }
  
  Future<String> processData(String input) async {
    await Future.delayed(Duration(milliseconds: 100));
    return 'Processed: \$input';
  }
}`.trimStart().trimEnd();
  }

  /**
   * Generates a string containing a Dart example for a REST controller
   * exposing monitoring data.
   *
   * This controller demonstrates how to create a Jetleaf web endpoint
   * that returns performance metrics for monitored services.
   *
   * Features:
   * 1. **Imports**
   *    - `jetleaf` — core framework.
   *    - `jetleaf_monitor` — access to monitoring services and data.
   *    - `jetleaf_web` — web controller and HTTP annotations.
   *
   * 2. **PerformanceController class**
   *    - Decorated with `@RestController('/monitor')` to expose endpoints under `/monitor`.
   *    - Uses `@RequiredAll()` to auto-inject dependencies.
   *    - Defines a `GET /{name}` endpoint to retrieve performance data:
   *      - Returns `ResponseBody<Performance>` with `HttpStatus.OK` if data exists.
   *      - Returns `ResponseBody.notFound()` if no data is available.
   *
   * --- Usage ---
   * ```dart
   * final controller = PerformanceController(monitoringService);
   * final response = await controller.getPerformance("MonitoredService");
   * ```
   *
   * @returns {string} Dart source code string for a monitoring REST controller example.
   */
  static buildMonitorControllerExample(): string {
    return `
import 'package:jetleaf/jetleaf.dart';
import 'package:jetleaf_monitor/jetleaf_monitor.dart';
import 'package:jetleaf_web/jetleaf_web.dart';

@RequiredAll()
@RestController('/monitor')
class PerformanceController {
  final MonitoringService _monitoringService;
  
  PerformanceController(this._monitoringService);
  
  @GetMapping(path: '/{name}')
  Future<ResponseBody<Performance>> getPerformance(
    @PathVariable() String name
  ) async {
    final performance = _monitoringService.getPerformance(name);
    if (performance != null) {
      return ResponseBody.of(HttpStatus.OK, performance);
    }
    return ResponseBody.notFound();
  }
}`.trimStart().trimEnd();
  }

  /**
   * Generates a Dart example demonstrating caching using Jetleaf's `@Cacheable` annotation.
   *
   * This example illustrates how to define a service method whose results are automatically cached.
   *
   * Features:
   * 1. Imports:
   *    - `jetleaf` — core framework.
   *    - `jetleaf_resource` — caching utilities and annotations.
   * 2. `CacheService` class:
   *    - Decorated with `@Service()` to register as an injectable service.
   *    - Uses the `Interceptable` mixin to allow method interception for caching.
   *    - `getUser(String email)` method:
   *      - Decorated with `@Cacheable({'users'}, ttl: Duration(minutes: 5))`.
   *      - Demonstrates caching a `User` object for 5 minutes.
   *      - Uses `when()` helper to wrap method logic.
   *
   * @returns {string} Dart code string for a caching service example.
   */
  static buildCacheExample(): string {
    return `
import 'package:jetleaf/jetleaf.dart';
import 'package:jetleaf_resource/jetleaf_resource.dart';

import '../core/common_infrastructure.dart';

@Service()
final class CacheService with Interceptable {
  @Cacheable({'users'}, ttl: Duration(minutes: 5))
  Future<User> getUser(String email) async => when(() async {
    print('Fetching user: \$email from database');
    await Future.delayed(Duration(milliseconds: 100));
    return User(name: 'Cached User', email: email);
  }, this, 'getUser', ExecutableArgument.positional([email]));
}`.trimStart().trimEnd();
  }

  /**
   * Generates a Dart example demonstrating rate-limiting using Jetleaf's `@RateLimit` annotation.
   *
   * This example shows how to restrict access to a service method.
   *
   * Features:
   * 1. Imports:
   *    - `jetleaf` — core framework.
   *    - `jetleaf_resource` — rate-limiting annotations and helpers.
   * 2. `RateLimitService` class:
   *    - Decorated with `@Service()` and `Interceptable`.
   *    - `getUser(String email)` method:
   *      - Decorated with `@RateLimit({'api'}, limit: 10, window: Duration(minutes: 1))`.
   *      - Limits calls to 10 per minute per user.
   *
   * @returns {string} Dart code string for a rate-limiting service example.
   */
  static buildRateLimitExample(): string {
    return `
import 'package:jetleaf/jetleaf.dart';
import 'package:jetleaf_resource/jetleaf_resource.dart';

import '../core/common_infrastructure.dart';

@Service()
final class RateLimitService with Interceptable {
  @RateLimit({'api'}, limit: 10, window: Duration(minutes: 1))
  Future<User> getUser(String email) async => when(() async {
    print('Rate limited getUser for: \$email');
    return User(name: 'Rate Limited User', email: email);
  }, this, 'getUser', ExecutableArgument.positional([email]));
}`.trimStart().trimEnd();
  }

  /**
   * Generates a Dart example demonstrating the use of Jetleaf's retry mechanism.
   *
   * This example illustrates how to automatically retry failing operations with
   * exponential backoff and a recovery method.
   *
   * Features:
   * 1. Imports:
   *    - `jetleaf` — core framework.
   *    - `jetleaf_retry` — retry annotations and utilities.
   * 2. `RetryService` class:
   *    - Decorated with `@Service()` and `@RequiredAll()` to register as a fully injectable service.
   *    - `unstableOperation()` method:
   *      - Decorated with `@Retryable(...)`:
   *        - `maxAttempts: 3` — maximum number of retry attempts.
   *        - `backoff: Backoff(delay: 1000, multiplier: 2.0)` — exponential backoff configuration.
   *        - `retryFor: [Exception]` — retry only for specific exception types.
   *        - `label: 'api-call'` — labels the retry policy for recovery mapping.
   *      - Simulates occasional failures (fails 1 out of 3 times).
   *    - `fallbackOperation(Exception e)` method:
   *      - Decorated with `@Recover(label: 'api-call')`.
   *      - Invoked automatically when all retry attempts fail.
   *      - Prints a fallback message including the caught exception.
   *
   * Usage:
   * - Demonstrates best practices for resilient services in Jetleaf.
   * - Shows both retryable operation and recovery handling.
   *
   * @returns {string} Dart code string for a retryable service example.
   */
  static buildRetryExample(): string {
    return `
import 'package:jetleaf/jetleaf.dart';
import 'package:jetleaf_retry/jetleaf_retry.dart';

@Service()
@RequiredAll()
class RetryService {
  @Retryable(
    maxAttempts: 3,
    backoff: Backoff(delay: 1000, multiplier: 2.0),
    retryFor: [Exception],
    label: 'api-call',
  )
  Future<void> unstableOperation() async {
    print('Attempting unstable operation...');
    // Simulate occasional failure
    if (DateTime.now().second % 3 == 0) {
      throw Exception('Temporary failure');
    }
  }
  
  @Recover(label: 'api-call')
  Future<void> fallbackOperation(Exception e) async {
    print('Fallback executed: \$e');
  }
}`.trimStart().trimEnd();
  }

  /**
   * Generates a Dart example demonstrating Jetleaf's scheduling capabilities.
   *
   * This example shows how to define periodic and cron-based tasks using the
   * `jetleaf_scheduling` package.
   *
   * Features:
   * 1. Imports:
   *    - `jetleaf` — core framework.
   *    - `jetleaf_scheduling` — scheduling annotations and utilities.
   * 2. `ScheduledTasks` class:
   *    - Decorated with `@Service()` to register as an injectable service.
   *    - `periodicTask()` method:
   *      - Decorated with `@Scheduled(fixedRate: Duration(seconds: 30))`.
   *      - Executes every 30 seconds.
   *      - Logs execution timestamp.
   *    - `cleanupTask()` method:
   *      - Decorated with `@Scheduled(type: CronType.EVERY_MINUTE)`.
   *      - Executes once per minute based on cron type.
   *      - Logs execution timestamp.
   *
   * Usage:
   * - Illustrates how to define recurring background tasks in Jetleaf.
   * - Supports both fixed-rate and cron-style scheduling.
   *
   * @returns {string} Dart code string for a scheduling example.
   */
  static buildSchedulingExample(): string {
    return `
import 'package:jetleaf/jetleaf.dart';
import 'package:jetleaf_scheduling/jetleaf_scheduling.dart';

@Service()
class ScheduledTasks {
  @Scheduled(fixedRate: Duration(seconds: 30))
  Future<void> periodicTask() async {
    print('Periodic task executed at \${DateTime.now()}');
  }
  
  @Scheduled(type: CronType.EVERY_MINUTE)
  Future<void> cleanupTask() async {
    print('Cleanup task executed at \${DateTime.now()}');
  }
}`.trimStart().trimEnd();
  }

  /**
   * Generates a Dart example demonstrating Jetleaf's validation features.
   *
   * This example shows how to use the `jetleaf_validation` package to enforce
   * constraints on method parameters and service methods.
   *
   * Features:
   * 1. Imports:
   *    - `jetleaf` — core framework.
   *    - `jetleaf_validation` — provides annotations like `@Validated`, `@NotNull`, `@NotEmpty`, and `@Email`.
   * 2. `ValidationService` class:
   *    - Decorated with `@Service()` to register as an injectable service.
   *    - `getUser(String id)` method:
   *      - Annotated with `@Validated()` to enable validation.
   *      - Parameter `id` annotated with `@NotNull()` to ensure a non-null value.
   *      - Returns a `User` object with a generated email based on the ID.
   *    - `createUser(String name, String email)` method:
   *      - Annotated with `@Validated()` to enable validation.
   *      - Parameter `name` annotated with `@NotEmpty()` to ensure a non-empty string.
   *      - Parameter `email` annotated with `@Email()` to ensure a valid email format.
   *      - Logs the creation of a new user.
   *
   * Usage:
   * - Illustrates how to enforce runtime validation of method parameters in a Jetleaf service.
   * - Supports common constraints like non-null, non-empty, and email format.
   *
   * @returns {string} Dart code string for a validation example.
   */
  static buildValidationExample(): string {
    return `
import 'package:jetleaf/jetleaf.dart';
import 'package:jetleaf_validation/jetleaf_validation.dart';

import '../core/common_infrastructure.dart';

@Service()
class ValidationService {
  @Validated()
  Future<User?> getUser(@NotNull() String id) async {
    return User(name: 'Validated User', email: '\$id@example.com');
  }
  
  Future<void> createUser(
    @Validated() @NotEmpty() String name,
    @Validated() @Email() String email,
  ) async {
    print('Creating user: \$name, \$email');
  }
}`.trimStart().trimEnd();
  }

  /**
   * Generates a Dart example of a REST controller for managing `Store` entities.
   *
   * This example demonstrates how to define routes, handle HTTP GET and POST requests,
   * and use Jetleaf's web annotations.
   *
   * Features:
   * 1. Imports:
   *    - `jetleaf` — core framework.
   *    - `jetleaf_web` — provides web-related annotations like `@RestController`, `@GetMapping`, `@PostMapping`.
   * 2. `StoreController` class:
   *    - Decorated with `@RestController('/stores')` to define the base path.
   *    - `getStore(String id)` method:
   *      - Handles GET requests at `/stores/{id}`.
   *      - Uses `@PathVariable()` to extract the `id` from the URL.
   *      - Returns a `ResponseBody<Store>` with HTTP status 200 and example data.
   *    - `createStore(Store store)` method:
   *      - Handles POST requests at `/stores`.
   *      - Uses `@RequestBody()` to map incoming JSON to a `Store` object.
   *      - Returns a `ResponseBody.created()` with the new resource URI.
   *
   * @returns {string} Dart code string defining a sample store controller.
   */
  static buildStoreController(): string {
    return `
import 'package:jetleaf_web/jetleaf_web.dart';

import '../core/common_infrastructure.dart';

@RestController('/stores')
class StoreController {
  @GetMapping(path: '/{id}')
  Future<ResponseBody<Store>> getStore(@PathVariable() String id) async {
    final store = Store(id: id, name: 'Example Store');
    return ResponseBody.of(HttpStatus.OK, store);
  }
  
  @PostMapping()
  Future<ResponseBody<Store>> createStore(@RequestBody() Store store) async {
    // Save store logic here
    return ResponseBody.ok(store);
  }
}`.trimStart().trimEnd();
  }

  /**
   * Generates a Dart example demonstrating how to call external APIs using Jetleaf's `RestClient`.
   *
   * Features:
   * 1. Imports:
   *    - `jetleaf` — core framework.
   *    - `jetleaf_web` — provides HTTP client support via `RestClient`.
   * 2. `ExternalApiService` class:
   *    - Decorated with `@Service()` and `@RequiredAll()` for dependency injection.
   *    - Injects a `RestClient` instance for HTTP requests.
   *    - `fetchData()` method:
   *      - Makes a GET request to an external API (`https://jsonplaceholder.typicode.com/todos/1`).
   *      - Uses `.execute()` with a callback to read the response body as a string.
   *      - Returns the fetched data as a `Future<String>`.
   *
   * @returns {string} Dart code string for an external API service example.
   */
  static buildExternalApiServiceExample(): string {
    return `
import 'package:jetleaf/jetleaf.dart';
import 'package:jetleaf_web/jetleaf_web.dart';

@Service()
@RequiredAll()
class ExternalApiService {
  final RestClient rest;
  
  ExternalApiService(this.rest);
  
  Future<String> fetchData() async {
    final response = await rest
      .get()
      .uri('https://jsonplaceholder.typicode.com/todos/1')
      .execute((resp) async => resp.getBody().readAsString());
    
    return response ?? "";
  }
}`.trimStart().trimEnd();
  }
}
