import Generated from './generated';

/**
 * Represents the metrics of generated items within the Jetleaf framework.
 *
 * Contains the total count of generated items and a detailed list
 * of each generated item. Useful for reporting, analytics, and tracking
 * generation operations.
 *
 * Example:
 * ```ts
 * const generatedItems = [
 *   new Generated({
 *     name: "Item1",
 *     description: "First item",
 *     jetleaf: "core",
 *   }),
 * ];
 *
 * const metric = new Metric(generatedItems.length, generatedItems);
 * ```
 */
export default class Metric {
  /**
   * The total number of generated items.
   *
   * This value should generally match `generated.length`.
   */
  constructor(
    public totalCount: number,
    public generated: Generated[]
  ) {}

  /**
   * Creates a `Metric` instance from an API response.
   *
   * Expected API format:
   * ```json
   * {
   *   "total_count": 2,
   *   "generated": [ ... ]
   * }
   * ```
   */
  static fromApi(data: any): Metric {
    const result = Array.isArray(data.generated)
      ? data.generated.map((item: any) => Generated.fromApi(item))
      : [];

    return new Metric(
      Number(data.total_count ?? result.length),
      result
    );
  }
}