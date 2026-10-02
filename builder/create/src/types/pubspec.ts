/**
 * Represents a package entry retrieved from the Pub.dev API.
 * This interface provides metadata about a published Dart or Flutter package,
 * including its latest release information and full version history.
 *
 * Each package includes a reference to the most recent version as well as
 * a collection of all previously published versions.
 */
export interface PubDevPackage {
  /**
   * The official package name as registered on Pub.dev.
   *
   * This value is unique across the ecosystem and is used for publishing,
   * dependency resolution, and search indexing.
   *
   * @example "http"
   */
  name: string;

  /**
   * Metadata describing the latest available published version of the package.
   *
   * This field reflects the newest release returned by Pub.dev and includes
   * version number, pubspec content, publication timestamp, and archive data.
   */
  latest: PackageVersion;

  /**
   * A complete list of all versions published to Pub.dev for this package.
   *
   * Versions are ordered from newest to oldest as provided by the API.
   * Each entry contains its own pubspec and release metadata.
   */
  versions: PackageVersion[];
}

/**
 * Represents a specific published version of a Pub.dev package.
 *
 * Each version contains:
 * - semantic version identifier
 * - pubspec metadata for that exact release
 * - downloadable archive reference
 * - checksum for verification
 * - publication timestamp
 */
export interface PackageVersion {
  /**
   * The semantic version number assigned to this release.
   *
   * Follows standard semantic versioning format such as:
   * `MAJOR.MINOR.PATCH[-prerelease][+build]`.
   *
   * @example "1.2.3"
   * @example "2.0.0-dev.1"
   */
  version: string;

  /**
   * The pubspec configuration associated with this version.
   *
   * This value reflects the exact pubspec.yaml at the time this version was
   * published and may differ from the latest version's pubspec.
   */
  pubspec: Pubspec;

  /**
   * A direct URL pointing to the downloadable source archive for the package
   * at this version.
   *
   * Archives are typically compressed as `.tar.gz` files.
   * This link may be used to install, analyze, or mirror the package.
   *
   * @example "https://pub.dev/packages/http/versions/1.2.0.tar.gz"
   */
  archive_url: string;

  /**
   * The SHA-256 checksum of the source archive.
   *
   * Used to validate integrity during download and installation.
   * Ensures the archive has not been modified or corrupted.
   *
   * @example "9f2b9d3f0c4bb7c71d7e6c..."
   */
  archive_sha256: string;

  /**
   * The timestamp indicating when this version was published to Pub.dev.
   *
   * Formatted as an ISO 8601 string (`YYYY-MM-DDTHH:mm:ss.sssZ`).
   *
   * @example "2024-05-12T14:32:10.000Z"
   */
  published: string; // ISO timestamp
}

/**
 * Represents the contents of a pubspec.yaml file for a Dart or Flutter package.
 *
 * The pubspec defines metadata, dependencies, environment constraints,
 * and additional configuration relevant to package consumers and tooling.
 */
export interface Pubspec {
  /**
   * The declared package name inside the pubspec.
   *
   * This must match the name used when publishing and importing.
   * @example "flutter_hooks"
   */
  name: string;

  /**
   * A human-readable summary of the package's purpose and functionality.
   *
   * Displayed on Pub.dev and in package search results.
   */
  description: string;

  /**
   * The package version defined in the pubspec.
   *
   * This value corresponds to a tagged release and must increment
   * according to semantic versioning rules.
   * @example "0.18.5"
   */
  version: string;

  /**
   * Optional homepage URL associated with the package.
   *
   * Typically links to a marketing site, organization page, or docs portal.
   * @example "https://example.com/project"
   */
  homepage?: string;

  /**
   * Optional link to the source repository.
   *
   * Commonly a GitHub, GitLab, or Bitbucket URL.
   * @example "https://github.com/google/dartsdk"
   */
  repository?: string;

  /**
   * Optional link to the issue tracker where bugs and feature requests are managed.
   * @example "https://github.com/org/repo/issues"
   */
  issue_tracker?: string;

  /**
   * Optional link to hosted documentation.
   *
   * May reference API docs, guides, or external manuals.
   */
  documentation?: string;

  /**
   * Optional list of topic tags used for classification on Pub.dev.
   *
   * Helps improve discoverability and categorization.
   * @example ["networking", "http", "client"]
   */
  topics?: string[];

  /**
   * Optional list of keyword tags used for search relevance.
   *
   * May overlap with `topics` but is more search-oriented.
   */
  keywords?: string[];

  /**
   * Dart and Flutter environment constraints defined in the pubspec.
   *
   * Most commonly specifies minimum and maximum supported SDK versions.
   *
   * @example { sdk: ">=3.3.0 <4.0.0" }
   */
  environment?: Record<string, string>;

  /**
   * A map of required runtime dependencies and their version constraints.
   *
   * Keys are package names, values are version ranges.
   *
   * @example { "http": "^1.2.0" }
   */
  dependencies?: Record<string, string>;

  /**
   * A map of development-only dependencies.
   *
   * These are used for tooling, testing, or code generation and are not
   * included when consuming the package as a dependency.
   *
   * @example { "build_runner": "^2.4.0" }
   */
  dev_dependencies?: Record<string, string>;
}