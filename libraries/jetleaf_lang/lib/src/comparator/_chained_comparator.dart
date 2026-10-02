part of 'comparator.dart';

/// {@template chained_comparator}
/// A comparator that chains two comparators together: [_first] and [_second].
///
/// The [_first] comparator is applied first. If it returns a non-zero result,
/// that result is returned. Otherwise, the [_second] comparator is used as a
/// tiebreaker.
///
/// This is useful for multi-level sorting—e.g., by last name, then by first name.
///
/// ---
///
/// ### 📌 Example
///
/// ```dart
/// class Person {
///   final String firstName;
///   final String lastName;
///
///   Person(this.firstName, this.lastName);
/// }
///
/// final byLastName = Comparator.comparing<Person, String>((p) => p.lastName);
/// final byFirstName = Comparator.comparing<Person, String>((p) => p.firstName);
///
/// final chained = byLastName.thenComparing(byFirstName);
///
/// final people = [
///   Person('Alice', 'Smith'),
///   Person('Bob', 'Smith'),
///   Person('Charlie', 'Brown'),
/// ];
///
/// people.sort(chained.compare);
/// print(people.map((p) => '${p.firstName} ${p.lastName}'));
/// // Charlie Brown, Alice Smith, Bob Smith
/// ```
/// {@endtemplate}
@Generic(_ChainedComparator)
class _ChainedComparator<T> extends Comparator<T> {
  /// The first comparator to apply.
  final Comparator<T> _first;

  /// The second comparator used only if the first returns 0 (equal).
  final Comparator<T> _second;

  /// {@macro chained_comparator}
  _ChainedComparator(this._first, this._second);

  @override
  int compare(T a, T b) {
    final result = _first.compare(a, b);
    return result != 0 ? result : _second.compare(a, b);
  }
}