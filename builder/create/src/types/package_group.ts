import Package from "./package";
import { PubDevPackage } from "./pubspec";

/**
 * Represents a group of packages in the marketplace.
 *
 * Each group has a simple name (e.g., "Networking", "State Management")
 * and a list of `Package` instances belonging to that group.
 */
export default class PackageGroup {
  /**
   * Human-readable name for the group
   */
  constructor(
    public name: string,
    public packages: Package[]
  ) {}

  /**
   * Creates a `PackageGroup` from the API response.
   * 
   * The API is expected to return an object like:
   * {
   *   name: string,
   *   packages: PubDevPackage[]
   * }
   *
   * This method converts each raw `PubDevPackage` into a `Package` using `Package.fromApi`.
   *
   * @param data - API response for a group
   * @returns A fully-typed `PackageGroup` instance
   */
  static fromApi(data: { group: string; packages: PubDevPackage[] }): PackageGroup {
    const pkgList = data.packages.map(pkg => Package.fromApi(pkg, data.group));
    return new PackageGroup(data.group, pkgList);
  }

  /**
   * Creates a `PackageGroup` from a cached JSON object.
   * 
   * The cache is expected to store:
   * {
   *   name: string,
   *   packages: any[]
   * }
   *
   * Each package is restored via `Package.fromCache`.
   *
   * @param json - Cached JSON object for a group
   * @returns A `PackageGroup` instance
   */
  static fromCache(json: any): PackageGroup {
    const pkgList = Array.isArray(json.packages)
      ? json.packages.map((pkgJson: any) => Package.fromCache(pkgJson))
      : [];
    return new PackageGroup(json.name, pkgList);
  }
}