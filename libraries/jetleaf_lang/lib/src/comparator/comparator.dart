import 'package:jetleaf_build/jetleaf_build.dart';

import '../exceptions.dart';

part '_reversed_comparator.dart';
part '_natural_order_comparator.dart';
part '_chained_comparator.dart';
part '_comparing_comparable_comparator.dart';
part '_comparing_comparator.dart';

/// {@template comparator}
/// An abstract class that imposes a total ordering on a collection of objects of type [T].
///
/// A `Comparator` can be used to:
/// - Sort lists (`List.sort(comparator)`).
/// - Control ordering in sorted collections (e.g., custom trees or ordered maps).
/// - Provide alternate sort logic for types that don’t implement `Comparable`.
///
/// This Dart class is inspired by Java's `java.util.Comparator`.
///
/// ---
///
/// ### 📌 Example Usage
///
/// ```dart
/// final Comparator<String> byLength = Comparator.comparing((s) => s.length);
///
/// final names = ['Alice', 'Bob', 'Christina'];
/// names.sort(byLength.compare);
///
/// print(names); // [Bob, Alice, Christina]
/// ```
///
/// You can also chain comparators:
///
/// ```dart
/// final byLengthThenAlphabet = Comparator.comparing((s) => s.length)
///     .thenComparing(Comparator.naturalOrder());
///
/// final list = ['Tom', 'Ann', 'Tim', 'Jim', 'Alex'];
/// list.sort(byLengthThenAlphabet.compare);
///
/// print(list); // [Ann, Jim, Tom, Tim, Alex]
/// ```
/// {@endtemplate}
@Generic(Comparator)
abstract class Comparator<T> {
  /// {@macro comparator}
  const Comparator();

  /// Compares two values of type [T] for order.
  ///
  /// Returns:
  /// - A negative number if `a < b`
  /// - `0` if `a == b`
  /// - A positive number if `a > b`
  ///
  /// This method must be implemented by subclasses or factory constructors.
  int compare(T a, T b);

  /// {@template comparator_reversed}
  /// Returns a comparator that imposes the reverse ordering of this comparator.
  ///
  /// The returned comparator evaluates `compare(b, a)` instead of `compare(a, b)`.
  ///
  /// --- 
  /// ### Example
  /// ```dart
  /// final ascending = Comparator.naturalOrder<int>();
  /// final descending = ascending.reversed();
  ///
  /// final list = [1, 2, 3];
  /// list.sort(descending.compare);
  /// print(list); // [3, 2, 1]
  /// ```
  /// {@endtemplate}
  Comparator<T> reversed() => _ReversedComparator(this);

  /// {@template comparator_then_comparing}
  /// Chains another comparator to be used if this comparator returns 0 (equality).
  ///
  /// If `compare(a, b)` returns 0, the `other` comparator will be used.
  ///
  /// ---
  /// ### Example
  /// ```dart
  /// final byLength = Comparator.comparing((s) => s.length);
  /// final thenAlpha = byLength.thenComparing(Comparator.naturalOrder<String>());
  ///
  /// final list = ['foo', 'bar', 'baz'];
  /// list.sort(thenAlpha.compare);
  /// print(list); // [bar, baz, foo]
  /// ```
  /// {@endtemplate}
  Comparator<T> thenComparing(Comparator<T> other) => _ChainedComparator(this, other);

  /// {@template comparator_then_comparing_comparable}
  /// Chains a comparator by extracting a `Comparable` key from each element.
  ///
  /// If this comparator returns 0, the key extractor will be used with natural ordering.
  ///
  /// ---
  /// ### Example
  /// ```dart
  /// final byNameLength = Comparator.comparing((s) => s.length);
  /// final thenByAlpha = byNameLength.thenComparingComparable((s) => s);
  ///
  /// final list = ['Ann', 'Tom', 'Bob'];
  /// list.sort(thenByAlpha.compare);
  /// print(list); // [Ann, Bob, Tom]
  /// ```
  /// {@endtemplate}
  Comparator<T> thenComparingComparable<U extends Comparable<U>>(U Function(T) keyExtractor) {
    return thenComparing(Comparator.comparing(keyExtractor));
  }

  /// {@template comparator_then_comparing_with}
  /// Chains a comparator by extracting a key with [keyExtractor] and comparing it
  /// using the given [keyComparator].
  ///
  /// ---
  /// ### Example
  /// ```dart
  /// final byNameLength = Comparator.comparing((s) => s.length);
  /// final thenByLastChar = byNameLength.thenComparingWith(
  ///   (s) => s[s.length - 1],
  ///   Comparator.naturalOrder(),
  /// );
  ///
  /// final names = ['Joe', 'Jim', 'Jon'];
  /// names.sort(thenByLastChar.compare);
  /// print(names); // [Jim, Jon, Joe]
  /// ```
  /// {@endtemplate}
  Comparator<T> thenComparingWith<U>(U Function(T) keyExtractor, Comparator<U> keyComparator) {
    return thenComparing(_ComparingComparator(keyExtractor, keyComparator));
  }

  // ------------------ Static Factory Methods ------------------

  /// {@template comparator_natural_order}
  /// Creates a comparator that compares `Comparable` objects in natural ascending order.
  ///
  /// Suitable for any type that implements `Comparable`.
  ///
  /// ---
  /// ### Example
  /// ```dart
  /// final comp = Comparator.naturalOrder<int>();
  /// final numbers = [5, 1, 3];
  /// numbers.sort(comp.compare);
  /// print(numbers); // [1, 3, 5]
  /// ```
  /// {@endtemplate}
  static Comparator<T> naturalOrder<T>() => _NaturalOrderComparator<T>();

  /// {@template comparator_reverse_order}
  /// Creates a comparator that compares `Comparable` objects in reverse (descending) order.
  ///
  /// ---
  /// ### Example
  /// ```dart
  /// final comp = Comparator.reverseOrder<String>();
  /// final list = ['a', 'c', 'b'];
  /// list.sort(comp.compare);
  /// print(list); // [c, b, a]
  /// ```
  /// {@endtemplate}
  static Comparator<T> reverseOrder<T>() => _NaturalOrderComparator<T>().reversed();

  /// {@template comparator_comparing}
  /// Creates a comparator based on a `Comparable` key extracted from each element.
  ///
  /// Useful when sorting objects that have a comparable field but do not implement `Comparable`.
  ///
  /// ---
  /// ### Example
  /// ```dart
  /// class User {
  ///   final int age;
  ///   User(this.age);
  /// }
  ///
  /// final byAge = Comparator.comparing<User, int>((user) => user.age);
  /// final users = [User(40), User(20)];
  /// users.sort(byAge.compare);
  /// print(users.map((u) => u.age)); // [20, 40]
  /// ```
  /// {@endtemplate}
  static Comparator<T> comparing<T, U extends Comparable<U>>(U Function(T) keyExtractor) => _ComparingComparableComparator(keyExtractor);

  /// {@template comparator_comparing_with}
  /// Creates a comparator based on a key extractor and a custom comparator for the key.
  ///
  /// Allows sorting by derived values that require special ordering rules.
  ///
  /// ---
  /// ### Example
  /// ```dart
  /// class Item {
  ///   final String name;
  ///   Item(this.name);
  /// }
  ///
  /// final byLastCharDesc = Comparator.comparingWith<Item, String>(
  ///   (item) => item.name[item.name.length - 1],
  ///   Comparator.reverseOrder(),
  /// );
  ///
  /// final items = [Item('Box'), Item('Ball'), Item('Bat')];
  /// items.sort(byLastCharDesc.compare);
  /// print(items.map((i) => i.name)); // [Bat, Box, Ball]
  /// ```
  /// {@endtemplate}
  static Comparator<T> comparingWith<T, U>(U Function(T) keyExtractor, Comparator<U> keyComparator) => _ComparingComparator(keyExtractor, keyComparator);
}