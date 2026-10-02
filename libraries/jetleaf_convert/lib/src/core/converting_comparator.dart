import 'package:jetleaf_lang/lang.dart';

import 'conversion_service.dart';
import 'converters.dart';
import '../helpers/_commons.dart';
import '../types/service_converter.dart';

/// {@template converting_comparator}
/// A comparator that compares source values of type [S] by first converting them
/// to another type [T] using a [Converter], then applying a [Comparator] on [T].
///
/// This is useful when you want to sort values based on a derived property or
/// a type transformation.
///
/// ---
///
/// ### 🔧 Example: Compare strings by their lengths
/// ```dart
/// final comparator = ConvertingComparator<String, int>(
///   Comparator.naturalOrder(),
///   Converter<String, int>((s) => s.length),
/// );
///
/// final list = ['pear', 'banana', 'kiwi'];
/// list.sort(comparator); // ['kiwi', 'pear', 'banana']
/// ```
///
/// You can also use the factory constructors:
///
/// ### 🔧 Using `withConverter` and a ConversionService:
/// ```dart
/// final service = DefaultConversionService();
/// final comparator = ConvertingComparator.withConverter<String, int>(
///   Comparator.naturalOrder(),
///   service,
///   Class<int>(),
/// );
/// ```
///
/// {@endtemplate}
@Generic(ConvertingComparator)
class ConvertingComparator<S, T> extends Comparator<S> {
  final Comparator<T> _comparator;
  final Converter<S, T> _converter;

  /// {@macro converting_comparator}
  ConvertingComparator(this._comparator, this._converter);

  /// {@macro converting_comparator}
  ///
  /// Uses [Comparator.naturalOrder] as the default comparator for [T].
  ConvertingComparator.converter(Converter<S, T> converter) : this(Comparator.naturalOrder(), converter);

  /// {@macro converting_comparator}
  ///
  /// Constructs a comparator using a [ConversionService] and a target type.
  ConvertingComparator.withConverter(Comparator<T> comparator, ConversionService conversionService, Class<T> targetType) 
    : this(comparator, ConversionServiceConverter(conversionService, targetType));

  @override
  int compare(S a, S b) {
    T c1 = _converter.convert(a);
    T c2 = _converter.convert(b);
    return _comparator.compare(c1, c2);
  }

  /// {@template map_entry_key_comparator}
  /// Creates a comparator that compares [MapEntry] objects by their keys.
  ///
  /// ---  
  /// ### 🔧 Example:
  /// ```dart
  /// final entries = [
  ///   MapEntry('c', 1),
  ///   MapEntry('a', 3),
  ///   MapEntry('b', 2),
  /// ];
  /// entries.sort(ConvertingComparator.mapEntryKeys((a, b) => a.compareTo(b)));
  /// // Sorted by key: a, b, c
  /// ```
  /// {@endtemplate}
  static ConvertingComparator<MapEntry<K, V>, K> mapEntryKeys<K, V>(Comparator<K> comparator) {
    return ConvertingComparator<MapEntry<K, V>, K>(comparator, _MapEntryKeyConverter<K, V>());
  }

  /// {@template map_entry_value_comparator}
  /// Creates a comparator that compares [MapEntry] objects by their values.
  ///
  /// ---  
  /// ### 🔧 Example:
  /// ```dart
  /// final entries = [
  ///   MapEntry('a', 3),
  ///   MapEntry('b', 1),
  ///   MapEntry('c', 2),
  /// ];
  /// entries.sort(ConvertingComparator.mapEntryValues((a, b) => a.compareTo(b)));
  /// // Sorted by value: 1, 2, 3
  /// ```
  /// {@endtemplate}
  static ConvertingComparator<MapEntry<K, V>, V> mapEntryValues<K, V>(Comparator<V> comparator) {
    return ConvertingComparator<MapEntry<K, V>, V>(comparator, _MapEntryValueConverter<K, V>());
  }
}

/// {@template map_entry_value_converter}
/// A simple converter that extracts the value from a [MapEntry].
///
/// Useful when transforming a stream, list, or iterable of `MapEntry<K, V>`
/// into a collection of values.
///
/// ---
///
/// ### 🔧 Example:
/// ```dart
/// final entry = MapEntry('name', 42);
/// final converter = _MapEntryValueConverter<String, int>();
/// print(converter.convert(entry)); // 42
/// ```
/// {@endtemplate}
@Generic(_MapEntryValueConverter)
class _MapEntryValueConverter<K, V> extends CommonConverter<MapEntry<K, V>, V> {
  /// {@macro map_entry_value_converter}
  @override
  V convert(MapEntry<K, V> source) => source.value;
}

/// {@template map_entry_key_converter}
/// A simple converter that extracts the key from a [MapEntry].
///
/// Useful when transforming a stream, list, or iterable of `MapEntry<K, V>`
/// into a collection of keys.
///
/// ---
///
/// ### 🔧 Example:
/// ```dart
/// final entry = MapEntry('name', 42);
/// final converter = _MapEntryKeyConverter<String, int>();
/// print(converter.convert(entry)); // 'name'
/// ```
/// {@endtemplate}
@Generic(_MapEntryKeyConverter)
class _MapEntryKeyConverter<K, V> extends CommonConverter<MapEntry<K, V>, K> {
  /// {@macro map_entry_key_converter}
  @override
  K convert(MapEntry<K, V> source) => source.key;
}