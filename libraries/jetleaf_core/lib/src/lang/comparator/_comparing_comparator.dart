part of 'comparator.dart';

/// {@template comparing_comparator}
/// A comparator that compares objects by extracting a key of type [U] from each object of type [T],
/// and then comparing those keys using a provided [Comparator] for [U].
///
/// This is useful when you want to sort objects by a derived field or value that
/// requires a custom comparator (instead of natural ordering).
///
/// ---
///
/// ### 📌 Example
///
/// ```dart
/// class Product {
///   final String name;
///   final double price;
///
///   Product(this.name, this.price);
/// }
///
/// final byPriceDescending = Comparator.comparingWith<Product, double>(
///   (product) => product.price,
///   Comparator.reverseOrder(),
/// );
///
/// final products = [
///   Product('Pen', 1.5),
///   Product('Notebook', 3.0),
///   Product('Bag', 10.0),
/// ];
///
/// products.sort(byPriceDescending.compare);
/// print(products.map((p) => p.name)); // [Bag, Notebook, Pen]
/// ```
/// {@endtemplate}
@Generic(_ComparingComparator)
class _ComparingComparator<T, U> extends Comparator<T> {
  /// Extracts a key of type [U] from an object of type [T].
  final U Function(T) _keyExtractor;

  /// A comparator for comparing extracted keys of type [U].
  final Comparator<U> _keyComparator;

  /// {@macro comparing_comparator}
  _ComparingComparator(this._keyExtractor, this._keyComparator);

  @override
  int compare(T a, T b) {
    return _keyComparator.compare(_keyExtractor(a), _keyExtractor(b));
  }
}