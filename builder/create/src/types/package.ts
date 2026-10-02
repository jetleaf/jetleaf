import { PubDevPackage } from "./pubspec";

/**
 * Represents an internal application model of a Pub.dev package within the application context.
 * 
 * This class provides a structured representation of a Dart or Flutter package, normalizing data
 * received from the Pub.dev API into fields convenient for display, sorting, and dependency analysis.
 * It also includes helper methods to construct instances directly from the API response.
 * 
 * The `Package` class serves as the primary interface for interacting with package data, while
 * retaining a reference to the raw Pub.dev package object for advanced operations or extended metadata.
 */
export default class Package {
  /**
   * Creates a new `Package` instance with fully initialized fields.
   * 
   * @param id - A unique identifier for the package, typically the original package name from Pub.dev.
   * @param name - The display-friendly name of the package, with underscores replaced by spaces and capitalized.
   * @param description - The full descriptive text for the package, often taken from the pubspec.yaml description.
   * @param shortDescription - A concise summary of the package, suitable for UI listings or previews.
   * @param version - The latest published version string for this package.
   * @param repository - Optional URL of the package's source repository (e.g., GitHub link).
   * @param dependencies - A list of dependency package names extracted from the latest pubspec.
   * @param lastUpdated - ISO 8601 timestamp indicating the date of the latest published version.
   * @param category - Internal classification label for organizing packages (default is "Uncategorized").
   * @param pub - The original Pub.dev API response object for the package, stored for reference.
   */
  constructor(
    public id: string,
    public name: string,
    public description: string,
    public shortDescription: string,
    public version: string,
    public repository: string | undefined,
    public dependencies: string[],
    public lastUpdated: string,
    public category: string,
    public pub: PubDevPackage
  ) {}

  /**
   * Formats a raw package name into a more human-readable form.
   * 
   * - Replaces underscores with spaces.
   * - Capitalizes the first letter of each word.
   *
   * @param raw - The raw package name from Pub.dev.
   * @returns A formatted display name.
   * @internal
   */
  private static formatName(raw: string): string {
    return raw
      .replace(/_/g, " ")
      .replace(/\b\w/g, c => c.toUpperCase());
  }

  /**
   * Creates a `Package` instance from a `PubDevPackage` API response.
   * 
   * This static helper method extracts relevant fields from the Pub.dev API object
   * and constructs a fully-initialized `Package` instance suitable for internal use.
   * 
   * - Sets both `id` and `name` based on the raw package name, formatting the display name.
   * - Copies the description from the latest pubspec to both `description` and `shortDescription`.
   * - Extracts the dependency names as a string array from `pubspec.dependencies`.
   * - Assigns the publication timestamp from the latest version.
   * - Preserves the raw API object in the `pub` field for reference.
   *
   * @param data - The raw `PubDevPackage` object received from the Pub.dev API.
   * @returns A fully-populated `Package` instance ready for use in the application.
   * @example
   * const pkg = Package.fromApi(pubDevData);
   */
  static fromApi(data: PubDevPackage, category: string): Package {
    return new Package(
      data.name,
      Package.formatName(data.name),
      data.latest.pubspec.description,
      data.latest.pubspec.description,
      data.latest.version,
      data.latest.pubspec.repository,
      Object.keys(data.latest.pubspec.dependencies ?? {}),
      data.latest.published,
      category,
      data
    );
  }

  /**
   * Creates a `Package` instance from a plain JavaScript object, typically retrieved
   * from localStorage or another cache. This is useful for restoring cached packages
   * while maintaining full type safety and class methods.
   *
   * @param json - A plain object representing a `Package` (e.g., from JSON.parse).
   *               It should have the same shape as a serialized `Package`.
   * @returns A fully-typed `Package` instance.
   *
   * @example
   * const cachedJson = JSON.parse(localStorage.getItem('packageCache') || '[]');
   * const packages = cachedJson.map(pkgJson => Package.fromCache(pkgJson));
   */
  static fromCache(json: any): Package {
    return new Package(
      json.id,
      json.name,
      json.description,
      json.shortDescription,
      json.version,
      json.repository,
      json.dependencies,
      json.lastUpdated,
      json.category,
      json.pub
    );
  }
}