/**
 * Represents a single generated item and its associated metadata.
 *
 * Provides identifiers, descriptive information, related Jetleaf module,
 * and optional associated packages.
 */
export default class Generated {
  /**
   * Creates a `Generated` instance.
   *
   * `id` is optional because it is often assigned server-side.
   */
  constructor({
    id = 0,
    name,
    description,
    jetleaf,
    packages = [],
    createdAt,
  }: {
    id?: number;
    name: string;
    description: string;
    jetleaf: string;
    packages?: string[];
    createdAt?: Date;
  }) {
    this.id = id;
    this.name = name;
    this.description = description;
    this.jetleaf = jetleaf;
    this.packages = packages;
    this.createdAt = createdAt;
  }

  /** Unique numeric identifier (server-managed) */
  public id: number;

  /** Human-readable name of the generated item */
  public name: string;

  /** Description explaining the purpose of the generated item */
  public description: string;

  /** Jetleaf module or subpackage this item belongs to */
  public jetleaf: string;

  /** Optional list of associated package names */
  public packages: string[];

  /** Creation timestamp */
  public createdAt?: Date;

  /**
   * Creates a `Generated` instance from an API response.
   *
   * Expected API format:
   * ```json
   * {
   *   "id": 1,
   *   "name": "UserController",
   *   "description": "...",
   *   "jetleaf": "core",
   *   "packages": ["auth", "database"],
   *   "created_at": "2024-05-12T14:32:10.000Z"
   * }
   * ```
   */
  static fromApi(data: any): Generated {
    return new Generated({
      id: Number(data.id ?? 0),
      name: data.name ?? "",
      description: data.description ?? "",
      jetleaf: data.jetleaf ?? "",
      packages: Array.isArray(data.packages) ? data.packages.map(String) : [],
      createdAt: data.created_at ? new Date(data.created_at) : undefined,
    });
  }

  /**
   * Converts the model into a format suitable for database insertion
   * (e.g., Supabase).
   */
  toTable(): Record<string, any> {
    return {
      name: this.name,
      description: this.description,
      jetleaf: this.jetleaf,
      packages: this.packages,
      created_at: (this.createdAt ?? new Date()).toISOString(),
    };
  }
}