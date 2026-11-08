/// {@template int_summary_statistics}
/// A state object for collecting summary statistics for a stream of `int` values.
///
/// It stores useful aggregate metrics including:
/// - `count`: number of values
/// - `sum`: total sum
/// - `min`: smallest value
/// - `max`: largest value
/// - `average`: arithmetic mean as a `double`
///
/// This class is useful in analytics, data reduction, or any operation that
/// needs statistical insights from a collection of integers.
///
/// ---
///
/// ### 📌 Example Usage
///
/// ```dart
/// final stats = IntSummaryStatistics(
///   4,        // count
///   26,       // sum
///   3,        // min
///   10,       // max
///   6.5,      // average
/// );
///
/// print(stats.max); // 10
/// print(stats); // IntSummaryStatistics{count=4, sum=26, min=3, max=10, average=6.5}
/// ```
/// {@endtemplate}
class IntSummaryStatistics {
  /// The total number of values included in the summary.
  final int count;

  /// The sum of all integer values.
  final int sum;

  /// The smallest value observed.
  final int min;

  /// The largest value observed.
  final int max;

  /// The arithmetic mean of all values (sum / count) as a double.
  final double average;

  /// {@macro int_summary_statistics}
  const IntSummaryStatistics(
    this.count,
    this.sum,
    this.min,
    this.max,
    this.average,
  );

  @override
  String toString() {
    return 'IntSummaryStatistics{count=$count, sum=$sum, min=$min, max=$max, average=$average}';
  }
}