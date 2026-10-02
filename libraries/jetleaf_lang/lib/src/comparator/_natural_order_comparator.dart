part of 'comparator.dart';

/// {@template natural_order_comparator}
/// A comparator that uses the natural order of [Comparable] objects.
///
/// This comparator delegates comparison to the `compareTo` method of [T],
/// which must implement [Comparable]. It provides a generic way to sort objects
/// in ascending order based on their inherent comparison logic.
///
/// ---
///
/// ### 📌 Example
///
/// ```dart
/// final list = [5, 3, 10, 1];
/// list.sort(const _NaturalOrderComparator<int>().compare);
/// print(list); // [1, 3, 5, 10]
/// ```
///
/// For custom objects:
/// ```dart
/// class Score implements Comparable<Score> {
///   final int value;
///   Score(this.value);
///
///   @override
///   int compareTo(Score other) => value.compareTo(other.value);
/// }
///
/// final scores = [Score(10), Score(3), Score(7)];
/// scores.sort(const _NaturalOrderComparator<Score>().compare);
/// print(scores.map((s) => s.value)); // [3, 7, 10]
/// ```
/// {@endtemplate}
@Generic(_NaturalOrderComparator)
class _NaturalOrderComparator<T> extends Comparator<T> {
  /// {@macro natural_order_comparator}
  const _NaturalOrderComparator();

  @override
  int compare(T a, T b) {
    try {
      // We cast to Comparable because T might be Comparable<num> (like int)
    // or Comparable<String> (like String), etc.
    // This relies on T being Comparable at runtime, consistent with Java's behavior.
    return (a as Comparable).compareTo(b);
    } on TypeError catch (_) {
      throw ComparatorException('Cannot compare $a and $b. $a is not comparable.');
    }
  }
}