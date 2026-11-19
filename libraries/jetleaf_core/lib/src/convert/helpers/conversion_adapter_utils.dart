import 'dart:collection' as col;

import 'package:jetleaf_core/lang.dart';

/// {@template jetleaf_conversion_adapter_utils}
/// Utility class for converting generic or adaptable collections into strongly
/// typed collections based on Jetleaf [Class] metadata.
///
/// The [ConversionAdapterUtils] class provides static methods to transform
/// `Map`, `Set`, and `List` instances into type-safe versions while handling
/// standard Dart types, Jetleaf-specific types, and temporal types.
///
/// ### Purpose
/// - Provide central logic for adapting generic collections to typed collections.
/// - Facilitate seamless integration with the Jetleaf type system.
/// - Support nested collection conversion using [AdaptableList], [AdaptableMap],
///   and [AdaptableSet].
///
/// ### Features
/// - Type-safe adaptation of [Map] with key/value type resolution.
/// - Type-safe adaptation of [Set] and [List] based on component types.
/// - Supports Dart core types, Jetleaf types, and time-related types.
/// - Throws [IllegalArgumentException] if conversion cannot be performed.
///
/// ### Usage
/// ```dart
/// final adaptedMap = ConversionAdapterUtils.getMapResult(
///   Class<Map<String, int>>(), {'a': 1, 'b': 2},
/// );
///
/// final adaptedSet = ConversionAdapterUtils.getSetResult(
///   Class<Set<DateTime>>(), {DateTime.now()},
/// );
///
/// final adaptedList = ConversionAdapterUtils.getListResult(
///   Class<List<String>>(), ['a', 'b', 'c'],
/// );
/// ```
///
/// ### See Also
/// - [AdaptableList]
/// - [AdaptableMap]
/// - [AdaptableSet]
/// {@endtemplate}
final class ConversionAdapterUtils {
  /// {@macro jetleaf_conversion_adapter_utils}
  ConversionAdapterUtils._();

  /// Converts a generic [Map] into a typed [Map<K, V>] based on [targetType].
  ///
  /// This method examines the key and value types from the provided [Class]
  /// and returns a corresponding strongly typed map using [AdaptableMap].
  ///
  /// Supports conversion for:
  /// - **Dart core types:** `String`, `int`, `double`, `bool`, `num`, `BigInt`, `Runes`, `Uri`, `RegExp`, `Pattern`, `Enum`
  /// - **Jetleaf types:** `Integer`, `Long`, `Float`, `BigInteger`, `BigDecimal`, `Character`, `Short`, `Double`, `Boolean`, `Url`, `Uuid`, `Byte`, `Locale`, `Currency`
  /// - **Time types:** `DateTime`, `LocalDateTime`, `LocalDate`, `LocalTime`, `ZonedDateTime`, `ZoneId`, `Duration`
  ///
  /// Throws [IllegalArgumentException] if the map cannot be adapted.
  ///
  /// Example:
  /// ```dart
  /// final map = {'a': 1, 'b': 2};
  /// final adapted = ConversionAdapterUtils.getMapResult(
  ///   Class<Map<String, int>>(), map
  /// );
  /// ```
  static Object getMapResult(Class targetType, Map<Object, Object> targetMap) {
    final result = AdaptableMap()..addEntries(targetMap.entries);

    final key = targetType.keyType();
    final value = targetType.componentType();

    if (key != null && value != null) {
      // String keys
      if (key.getType() == String) {
        if (value.getType() == String) return result.adapt<String, String>();

        // String and default dart types
        if (value.getType() == int) return result.adapt<String, int>();
        if (value.getType() == double) return result.adapt<String, double>();
        if (value.getType() == bool) return result.adapt<String, bool>();
        if (value.getType() == num) return result.adapt<String, num>();
        if (value.getType() == BigInt) return result.adapt<String, BigInt>();
        if (value.getType() == Runes) return result.adapt<String, Runes>();
        if (value.getType() == Uri) return result.adapt<String, Uri>();
        if (value.getType() == RegExp) return result.adapt<String, RegExp>();
        if (value.getType() == Pattern) return result.adapt<String, Pattern>();
        if (value.getType() == Enum) return result.adapt<String, Enum>();
        if (value.getType() == BigInt) return result.adapt<String, BigInt>();

        // String and Jetleaf dart types
        if (value.getType() == Integer) return result.adapt<String, Integer>();
        if (value.getType() == Long) return result.adapt<String, Long>();
        if (value.getType() == Float) return result.adapt<String, Float>();
        if (value.getType() == BigInteger) return result.adapt<String, BigInteger>();
        if (value.getType() == BigDecimal) return result.adapt<String, BigDecimal>();
        if (value.getType() == Character) return result.adapt<String, Character>();
        if (value.getType() == Short) return result.adapt<String, Short>();
        if (value.getType() == Double) return result.adapt<String, Double>();
        if (value.getType() == Boolean) return result.adapt<String, Boolean>();
        if (value.getType() == Url) return result.adapt<String, Url>();
        if (value.getType() == Uuid) return result.adapt<String, Uuid>();
        if (value.getType() == Byte) return result.adapt<String, Byte>();
        if (value.getType() == Locale) return result.adapt<String, Locale>();
        if (value.getType() == Currency) return result.adapt<String, Currency>();

        // String and Time types
        if (value.getType() == DateTime) return result.adapt<String, DateTime>();
        if (value.getType() == LocalDateTime) return result.adapt<String, LocalDateTime>();
        if (value.getType() == LocalDate) return result.adapt<String, LocalDate>();
        if (value.getType() == LocalTime) return result.adapt<String, LocalTime>();
        if (value.getType() == ZoneId) return result.adapt<String, ZoneId>();
        if (value.getType() == ZonedDateTime) return result.adapt<String, ZonedDateTime>();
        if (value.getType() == Duration) return result.adapt<String, Duration>();
      }

      // Int keys
      if (key.getType() == int) {
        if (value.getType() == int) return result.adapt<int, int>();

        if (value.getType() == String) return result.adapt<int, String>();
        if (value.getType() == double) return result.adapt<int, double>();
        if (value.getType() == bool) return result.adapt<int, bool>();
        if (value.getType() == num) return result.adapt<int, num>();
        if (value.getType() == BigInt) return result.adapt<int, BigInt>();
        if (value.getType() == Runes) return result.adapt<int, Runes>();
        if (value.getType() == Uri) return result.adapt<int, Uri>();
        if (value.getType() == RegExp) return result.adapt<int, RegExp>();
        if (value.getType() == Pattern) return result.adapt<int, Pattern>();
        if (value.getType() == Enum) return result.adapt<int, Enum>();
        
        if (value.getType() == Integer) return result.adapt<int, Integer>();
        if (value.getType() == Long) return result.adapt<int, Long>();
        if (value.getType() == Float) return result.adapt<int, Float>();
        if (value.getType() == Double) return result.adapt<int, Double>();
        if (value.getType() == BigInteger) return result.adapt<int, BigInteger>();
        if (value.getType() == BigDecimal) return result.adapt<int, BigDecimal>();
        if (value.getType() == Character) return result.adapt<int, Character>();
        if (value.getType() == Short) return result.adapt<int, Short>();
        if (value.getType() == Boolean) return result.adapt<int, Boolean>();
        if (value.getType() == Url) return result.adapt<int, Url>();
        if (value.getType() == Uuid) return result.adapt<int, Uuid>();
        if (value.getType() == Byte) return result.adapt<int, Byte>();
        if (value.getType() == Locale) return result.adapt<int, Locale>();
        if (value.getType() == Currency) return result.adapt<int, Currency>();

        if (value.getType() == DateTime) return result.adapt<int, DateTime>();
        if (value.getType() == LocalDateTime) return result.adapt<int, LocalDateTime>();
        if (value.getType() == LocalDate) return result.adapt<int, LocalDate>();
        if (value.getType() == LocalTime) return result.adapt<int, LocalTime>();
        if (value.getType() == ZoneId) return result.adapt<int, ZoneId>();
        if (value.getType() == ZonedDateTime) return result.adapt<int, ZonedDateTime>();
        if (value.getType() == Duration) return result.adapt<int, Duration>();
      }

      // ---------------- Double keys ----------------
      if (key.getType() == double) {
        if (value.getType() == double) return result.adapt<double, double>();

        if (value.getType() == String) return result.adapt<double, String>();
        if (value.getType() == int) return result.adapt<double, int>();
        if (value.getType() == bool) return result.adapt<double, bool>();
        if (value.getType() == num) return result.adapt<double, num>();
        if (value.getType() == BigInt) return result.adapt<double, BigInt>();
        if (value.getType() == Runes) return result.adapt<double, Runes>();
        if (value.getType() == Uri) return result.adapt<double, Uri>();
        if (value.getType() == RegExp) return result.adapt<double, RegExp>();
        if (value.getType() == Pattern) return result.adapt<double, Pattern>();
        if (value.getType() == Enum) return result.adapt<double, Enum>();

        if (value.getType() == Integer) return result.adapt<double, Integer>();
        if (value.getType() == Long) return result.adapt<double, Long>();
        if (value.getType() == Float) return result.adapt<double, Float>();
        if (value.getType() == Double) return result.adapt<double, Double>();
        if (value.getType() == BigInteger) return result.adapt<double, BigInteger>();
        if (value.getType() == BigDecimal) return result.adapt<double, BigDecimal>();
        if (value.getType() == Character) return result.adapt<double, Character>();
        if (value.getType() == Short) return result.adapt<double, Short>();
        if (value.getType() == Boolean) return result.adapt<double, Boolean>();
        if (value.getType() == Url) return result.adapt<double, Url>();
        if (value.getType() == Uuid) return result.adapt<double, Uuid>();
        if (value.getType() == Byte) return result.adapt<double, Byte>();
        if (value.getType() == Locale) return result.adapt<double, Locale>();
        if (value.getType() == Currency) return result.adapt<double, Currency>();

        if (value.getType() == DateTime) return result.adapt<double, DateTime>();
        if (value.getType() == LocalDateTime) return result.adapt<double, LocalDateTime>();
        if (value.getType() == LocalDate) return result.adapt<double, LocalDate>();
        if (value.getType() == LocalTime) return result.adapt<double, LocalTime>();
        if (value.getType() == ZoneId) return result.adapt<double, ZoneId>();
        if (value.getType() == ZonedDateTime) return result.adapt<double, ZonedDateTime>();
        if (value.getType() == Duration) return result.adapt<double, Duration>();
      }

      // ---------------- Bool keys ----------------
      if (key.getType() == bool) {
        if (value.getType() == bool) return result.adapt<bool, bool>();

        if (value.getType() == String) return result.adapt<bool, String>();
        if (value.getType() == int) return result.adapt<bool, int>();
        if (value.getType() == double) return result.adapt<bool, double>();
        if (value.getType() == num) return result.adapt<bool, num>();
        if (value.getType() == BigInt) return result.adapt<bool, BigInt>();
        if (value.getType() == Runes) return result.adapt<bool, Runes>();
        if (value.getType() == Uri) return result.adapt<bool, Uri>();
        if (value.getType() == RegExp) return result.adapt<bool, RegExp>();
        if (value.getType() == Pattern) return result.adapt<bool, Pattern>();
        if (value.getType() == Enum) return result.adapt<bool, Enum>();

        if (value.getType() == Integer) return result.adapt<bool, Integer>();
        if (value.getType() == Long) return result.adapt<bool, Long>();
        if (value.getType() == Float) return result.adapt<bool, Float>();
        if (value.getType() == Double) return result.adapt<bool, Double>();
        if (value.getType() == BigInteger) return result.adapt<bool, BigInteger>();
        if (value.getType() == BigDecimal) return result.adapt<bool, BigDecimal>();
        if (value.getType() == Character) return result.adapt<bool, Character>();
        if (value.getType() == Short) return result.adapt<bool, Short>();
        if (value.getType() == Boolean) return result.adapt<bool, Boolean>();
        if (value.getType() == Url) return result.adapt<bool, Url>();
        if (value.getType() == Uuid) return result.adapt<bool, Uuid>();
        if (value.getType() == Byte) return result.adapt<bool, Byte>();
        if (value.getType() == Locale) return result.adapt<bool, Locale>();
        if (value.getType() == Currency) return result.adapt<bool, Currency>();

        if (value.getType() == DateTime) return result.adapt<bool, DateTime>();
        if (value.getType() == LocalDateTime) return result.adapt<bool, LocalDateTime>();
        if (value.getType() == LocalDate) return result.adapt<bool, LocalDate>();
        if (value.getType() == LocalTime) return result.adapt<bool, LocalTime>();
        if (value.getType() == ZoneId) return result.adapt<bool, ZoneId>();
        if (value.getType() == ZonedDateTime) return result.adapt<bool, ZonedDateTime>();
        if (value.getType() == Duration) return result.adapt<bool, Duration>();
      }

      // ---------------- Num keys ----------------
      if (key.getType() == num) {
        if (value.getType() == num) return result.adapt<num, num>();

        if (value.getType() == String) return result.adapt<num, String>();
        if (value.getType() == int) return result.adapt<num, int>();
        if (value.getType() == double) return result.adapt<num, double>();
        if (value.getType() == bool) return result.adapt<num, bool>();
        if (value.getType() == BigInt) return result.adapt<num, BigInt>();
        if (value.getType() == Runes) return result.adapt<num, Runes>();
        if (value.getType() == Uri) return result.adapt<num, Uri>();
        if (value.getType() == RegExp) return result.adapt<num, RegExp>();
        if (value.getType() == Pattern) return result.adapt<num, Pattern>();
        if (value.getType() == Enum) return result.adapt<num, Enum>();

        if (value.getType() == Integer) return result.adapt<num, Integer>();
        if (value.getType() == Long) return result.adapt<num, Long>();
        if (value.getType() == Float) return result.adapt<num, Float>();
        if (value.getType() == Double) return result.adapt<num, Double>();
        if (value.getType() == BigInteger) return result.adapt<num, BigInteger>();
        if (value.getType() == BigDecimal) return result.adapt<num, BigDecimal>();
        if (value.getType() == Character) return result.adapt<num, Character>();
        if (value.getType() == Short) return result.adapt<num, Short>();
        if (value.getType() == Boolean) return result.adapt<num, Boolean>();
        if (value.getType() == Url) return result.adapt<num, Url>();
        if (value.getType() == Uuid) return result.adapt<num, Uuid>();
        if (value.getType() == Byte) return result.adapt<num, Byte>();
        if (value.getType() == Locale) return result.adapt<num, Locale>();
        if (value.getType() == Currency) return result.adapt<num, Currency>();

        if (value.getType() == DateTime) return result.adapt<num, DateTime>();
        if (value.getType() == LocalDateTime) return result.adapt<num, LocalDateTime>();
        if (value.getType() == LocalDate) return result.adapt<num, LocalDate>();
        if (value.getType() == LocalTime) return result.adapt<num, LocalTime>();
        if (value.getType() == ZoneId) return result.adapt<num, ZoneId>();
        if (value.getType() == ZonedDateTime) return result.adapt<num, ZonedDateTime>();
        if (value.getType() == Duration) return result.adapt<num, Duration>();
      }

      // ---------------- DateTime keys ----------------
      if (key.getType() == DateTime) {
        if (value.getType() == DateTime) return result.adapt<DateTime, DateTime>();

        if (value.getType() == String) return result.adapt<DateTime, String>();
        if (value.getType() == int) return result.adapt<DateTime, int>();
        if (value.getType() == double) return result.adapt<DateTime, double>();
        if (value.getType() == bool) return result.adapt<DateTime, bool>();
        if (value.getType() == num) return result.adapt<DateTime, num>();
        if (value.getType() == BigInt) return result.adapt<DateTime, BigInt>();
        if (value.getType() == Runes) return result.adapt<DateTime, Runes>();
        if (value.getType() == Uri) return result.adapt<DateTime, Uri>();
        if (value.getType() == RegExp) return result.adapt<DateTime, RegExp>();
        if (value.getType() == Pattern) return result.adapt<DateTime, Pattern>();
        if (value.getType() == Enum) return result.adapt<DateTime, Enum>();

        if (value.getType() == Integer) return result.adapt<DateTime, Integer>();
        if (value.getType() == Long) return result.adapt<DateTime, Long>();
        if (value.getType() == Float) return result.adapt<DateTime, Float>();
        if (value.getType() == Double) return result.adapt<DateTime, Double>();
        if (value.getType() == BigInteger) return result.adapt<DateTime, BigInteger>();
        if (value.getType() == BigDecimal) return result.adapt<DateTime, BigDecimal>();
        if (value.getType() == Character) return result.adapt<DateTime, Character>();
        if (value.getType() == Short) return result.adapt<DateTime, Short>();
        if (value.getType() == Boolean) return result.adapt<DateTime, Boolean>();
        if (value.getType() == Url) return result.adapt<DateTime, Url>();
        if (value.getType() == Uuid) return result.adapt<DateTime, Uuid>();
        if (value.getType() == Byte) return result.adapt<DateTime, Byte>();
        if (value.getType() == Locale) return result.adapt<DateTime, Locale>();
        if (value.getType() == Currency) return result.adapt<DateTime, Currency>();

        if (value.getType() == LocalDateTime) return result.adapt<DateTime, LocalDateTime>();
        if (value.getType() == LocalDate) return result.adapt<DateTime, LocalDate>();
        if (value.getType() == LocalTime) return result.adapt<DateTime, LocalTime>();
        if (value.getType() == ZoneId) return result.adapt<DateTime, ZoneId>();
        if (value.getType() == ZonedDateTime) return result.adapt<DateTime, ZonedDateTime>();
        if (value.getType() == Duration) return result.adapt<DateTime, Duration>();
      }

      if (key.getType() != Object || value.getType() != Object) {
        final keyReifier = MaterializedLibrary.lookupTypeReifier(
          type: key.getType(),
          name: key.getName(),
        );
        final valReifier = MaterializedLibrary.lookupTypeReifier(
          type: value.getType(),
          name: value.getName(),
        );
        if (keyReifier != null && valReifier != null) {
          return keyReifier.createMapWithValue(valReifier, targetMap);
        }
      }
    }

    // Fallback: when key/value are Object/Dynamic (raw types), return the result as-is.
    // Any declared `HashMap` target resolves to Jetleaf's class at runtime —
    // build a Jetleaf HashMap so the result satisfies the requested type.
    if (targetType.getType() == HashMap || targetType.getType().toString().startsWith('HashMap')) {
      // Match the parameterised Jetleaf HashMap requested by the caller when
      // both key and value are `Object`; otherwise return the raw dynamic pair.
      if (targetType.keyType()?.getType() == Object && targetType.componentType()?.getType() == Object) {
        return HashMap<Object, Object>.from(targetMap);
      }
      return HashMap<dynamic, dynamic>.from(targetMap);
    }
    if (targetType.getType() == col.LinkedHashMap || targetType.getType().toString().startsWith('LinkedHashMap')) {
      return col.LinkedHashMap.from(targetMap);
    }
    if (!targetType.isAssignableTo(Class<Map>(null, PackageNames.DART))) {
      return targetMap;
    }
    return result;
  }

  /// Converts a generic [Set] into a typed [Set<E>] based on [targetType].
  ///
  /// Uses the [componentType] of [targetType] to determine the element type.
  /// Returns a strongly typed [Set] using [AdaptableSet].
  ///
  /// Supports the same Dart, Jetleaf, and time types as [getMapResult].
  ///
  /// Example:
  /// ```dart
  /// final set = {1, 2, 3};
  /// final adapted = ConversionAdapterUtils.getSetResult(
  ///   Class<Set<int>>(), set
  /// );
  /// ```
  static Object getSetResult(Class targetType, Set<Object> targetSet) {
    final result = AdaptableSet()..addAll(targetSet);

    final value = targetType.componentType();
    if (value != null) {
      // String values
      if (value.getType() == String) return result.adapt<String>();

      // Default dart types
      if (value.getType() == int) return result.adapt<int>();
      if (value.getType() == double) return result.adapt<double>();
      if (value.getType() == bool) return result.adapt<bool>();
      if (value.getType() == num) return result.adapt<num>();
      if (value.getType() == BigInt) return result.adapt<BigInt>();
      if (value.getType() == Runes) return result.adapt<Runes>();
      if (value.getType() == Uri) return result.adapt<Uri>();
      if (value.getType() == RegExp) return result.adapt<RegExp>();
      if (value.getType() == Pattern) return result.adapt<Pattern>();
      if (value.getType() == Enum) return result.adapt<Enum>();

      // Jetleaf dart types
      if (value.getType() == Integer) return result.adapt<Integer>();
      if (value.getType() == Long) return result.adapt<Long>();
      if (value.getType() == Float) return result.adapt<Float>();
      if (value.getType() == BigInteger) return result.adapt<BigInteger>();
      if (value.getType() == BigDecimal) return result.adapt<BigDecimal>();
      if (value.getType() == Character) return result.adapt<Character>();
      if (value.getType() == Short) return result.adapt<Short>();
      if (value.getType() == Double) return result.adapt<Double>();
      if (value.getType() == Boolean) return result.adapt<Boolean>();
      if (value.getType() == Url) return result.adapt<Url>();
      if (value.getType() == Uuid) return result.adapt<Uuid>();
      if (value.getType() == Byte) return result.adapt<Byte>();
      if (value.getType() == Locale) return result.adapt<Locale>();
      if (value.getType() == Currency) return result.adapt<Currency>();

      // Time types
      if (value.getType() == DateTime) return result.adapt<DateTime>();
      if (value.getType() == LocalDateTime) return result.adapt<LocalDateTime>();
      if (value.getType() == LocalDate) return result.adapt<LocalDate>();
      if (value.getType() == LocalTime) return result.adapt<LocalTime>();
      if (value.getType() == ZoneId) return result.adapt<ZoneId>();
      if (value.getType() == ZonedDateTime) return result.adapt<ZonedDateTime>();
      if (value.getType() == Duration) return result.adapt<Duration>();

      final reifier = MaterializedLibrary.lookupTypeReifier(
        type: value.getType(),
        name: value.getName(),
      );
      if (reifier != null) {
        return reifier.createSet(targetSet);
      }
    }

    return result;
  }

  /// Converts a generic [List] into a typed [List<E>] based on [targetType].
  ///
  /// This method examines the [componentType] of [targetType] and returns
  /// a corresponding strongly typed list using [AdaptableList].
  ///
  /// Supports conversion for Dart core types, Jetleaf-specific types, and
  /// time-related types.
  ///
  /// Example:
  /// ```dart
  /// final list = ['a', 'b', 'c'];
  /// final adapted = ConversionAdapterUtils.getListResult(
  ///   Class<List<String>>(), list
  /// );
  /// ```
  static Object getListResult(Class targetType, List<Object> targetList) {
    final result = AdaptableList()..addAll(targetList);

    final value = targetType.componentType();
    if (value != null) {
      // String values
      if (value.getType() == String) return result.adapt<String>();

      // Default dart types
      if (value.getType() == int) return result.adapt<int>();
      if (value.getType() == double) return result.adapt<double>();
      if (value.getType() == bool) return result.adapt<bool>();
      if (value.getType() == num) return result.adapt<num>();
      if (value.getType() == BigInt) return result.adapt<BigInt>();
      if (value.getType() == Runes) return result.adapt<Runes>();
      if (value.getType() == Uri) return result.adapt<Uri>();
      if (value.getType() == RegExp) return result.adapt<RegExp>();
      if (value.getType() == Pattern) return result.adapt<Pattern>();
      if (value.getType() == Enum) return result.adapt<Enum>();

      // Jetleaf dart types
      if (value.getType() == Integer) return result.adapt<Integer>();
      if (value.getType() == Long) return result.adapt<Long>();
      if (value.getType() == Float) return result.adapt<Float>();
      if (value.getType() == BigInteger) return result.adapt<BigInteger>();
      if (value.getType() == BigDecimal) return result.adapt<BigDecimal>();
      if (value.getType() == Character) return result.adapt<Character>();
      if (value.getType() == Short) return result.adapt<Short>();
      if (value.getType() == Double) return result.adapt<Double>();
      if (value.getType() == Boolean) return result.adapt<Boolean>();
      if (value.getType() == Url) return result.adapt<Url>();
      if (value.getType() == Uuid) return result.adapt<Uuid>();
      if (value.getType() == Byte) return result.adapt<Byte>();
      if (value.getType() == Locale) return result.adapt<Locale>();
      if (value.getType() == Currency) return result.adapt<Currency>();

      // Time types
      if (value.getType() == DateTime) return result.adapt<DateTime>();
      if (value.getType() == LocalDateTime) return result.adapt<LocalDateTime>();
      if (value.getType() == LocalDate) return result.adapt<LocalDate>();
      if (value.getType() == LocalTime) return result.adapt<LocalTime>();
      if (value.getType() == ZoneId) return result.adapt<ZoneId>();
      if (value.getType() == ZonedDateTime) return result.adapt<ZonedDateTime>();
      if (value.getType() == Duration) return result.adapt<Duration>();

      final reifier = MaterializedLibrary.lookupTypeReifier(
        type: value.getType(),
        name: value.getName(),
      );
      if (reifier != null) {
        return reifier.createList(targetList);
      }
    }

    return result;
  }
}