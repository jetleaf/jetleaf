import 'dart:collection' as col;

import 'package:jetleaf_lang/lang.dart';

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
      if (key == Class<String>() || key.getType() is String) {
        if (value == Class<String>() || value.getType() is String) return result.adapt<String, String>();

        // String and default dart types
        if (value == Class<int>() || value.getType() is int) return result.adapt<String, int>();
        if (value == Class<double>() || value.getType() is double) return result.adapt<String, double>();
        if (value == Class<bool>() || value.getType() is bool) return result.adapt<String, bool>();
        if (value == Class<num>() || value.getType() is num) return result.adapt<String, num>();
        if (value == Class<BigInt>() || value.getType() is BigInt) return result.adapt<String, BigInt>();
        if (value == Class<Runes>() || value.getType() is Runes) return result.adapt<String, Runes>();
        if (value == Class<Uri>() || value.getType() is Uri) return result.adapt<String, Uri>();
        if (value == Class<RegExp>() || value.getType() is RegExp) return result.adapt<String, RegExp>();
        if (value == Class<Pattern>() || value.getType() is Pattern) return result.adapt<String, Pattern>();
        if (value == Class<Enum>() || value.getType() is Enum) return result.adapt<String, Enum>();
        if (value == Class<BigInt>() || value.getType() is BigInt) return result.adapt<String, BigInt>();

        // String and Jetleaf dart types
        if (value == Class<Integer>() || value.getType() is Integer) return result.adapt<String, Integer>();
        if (value == Class<Long>() || value.getType() is Long) return result.adapt<String, Long>();
        if (value == Class<Float>() || value.getType() is Float) return result.adapt<String, Float>();
        if (value == Class<BigInteger>() || value.getType() is BigInteger) return result.adapt<String, BigInteger>();
        if (value == Class<BigDecimal>() || value.getType() is BigDecimal) return result.adapt<String, BigDecimal>();
        if (value == Class<Character>() || value.getType() is Character) return result.adapt<String, Character>();
        if (value == Class<Short>() || value.getType() is Short) return result.adapt<String, Short>();
        if (value == Class<Double>() || value.getType() is Double) return result.adapt<String, Double>();
        if (value == Class<Boolean>() || value.getType() is Boolean) return result.adapt<String, Boolean>();
        if (value == Class<Url>() || value.getType() is Url) return result.adapt<String, Url>();
        if (value == Class<Uuid>() || value.getType() is Uuid) return result.adapt<String, Uuid>();
        if (value == Class<Byte>() || value.getType() is Byte) return result.adapt<String, Byte>();
        if (value == Class<Locale>() || value.getType() is Locale) return result.adapt<String, Locale>();
        if (value == Class<Currency>() || value.getType() is Currency) return result.adapt<String, Currency>();

        // String and Time types
        if (value == Class<DateTime>() || value.getType() is DateTime) return result.adapt<String, DateTime>();
        if (value == Class<LocalDateTime>() || value.getType() is LocalDateTime) return result.adapt<String, LocalDateTime>();
        if (value == Class<LocalDate>() || value.getType() is LocalDate) return result.adapt<String, LocalDate>();
        if (value == Class<LocalTime>() || value.getType() is LocalTime) return result.adapt<String, LocalTime>();
        if (value == Class<ZoneId>() || value.getType() is ZoneId) return result.adapt<String, ZoneId>();
        if (value == Class<ZonedDateTime>() || value.getType() is ZonedDateTime) return result.adapt<String, ZonedDateTime>();
        if (value == Class<Duration>() || value.getType() is Duration) return result.adapt<String, Duration>();
      }

      // Int keys
      if (key == Class<int>() || key.getType() is int) {
        if (value == Class<int>() || value.getType() is int) return result.adapt<int, int>();

        if (value == Class<String>() || value.getType() is String) return result.adapt<int, String>();
        if (value == Class<double>() || value.getType() is double) return result.adapt<int, double>();
        if (value == Class<bool>() || value.getType() is bool) return result.adapt<int, bool>();
        if (value == Class<num>() || value.getType() is num) return result.adapt<int, num>();
        if (value == Class<BigInt>() || value.getType() is BigInt) return result.adapt<int, BigInt>();
        if (value == Class<Runes>() || value.getType() is Runes) return result.adapt<int, Runes>();
        if (value == Class<Uri>() || value.getType() is Uri) return result.adapt<int, Uri>();
        if (value == Class<RegExp>() || value.getType() is RegExp) return result.adapt<int, RegExp>();
        if (value == Class<Pattern>() || value.getType() is Pattern) return result.adapt<int, Pattern>();
        if (value == Class<Enum>() || value.getType() is Enum) return result.adapt<int, Enum>();
        
        if (value == Class<Integer>() || value.getType() is Integer) return result.adapt<int, Integer>();
        if (value == Class<Long>() || value.getType() is Long) return result.adapt<int, Long>();
        if (value == Class<Float>() || value.getType() is Float) return result.adapt<int, Float>();
        if (value == Class<Double>() || value.getType() is Double) return result.adapt<int, Double>();
        if (value == Class<BigInteger>() || value.getType() is BigInteger) return result.adapt<int, BigInteger>();
        if (value == Class<BigDecimal>() || value.getType() is BigDecimal) return result.adapt<int, BigDecimal>();
        if (value == Class<Character>() || value.getType() is Character) return result.adapt<int, Character>();
        if (value == Class<Short>() || value.getType() is Short) return result.adapt<int, Short>();
        if (value == Class<Boolean>() || value.getType() is Boolean) return result.adapt<int, Boolean>();
        if (value == Class<Url>() || value.getType() is Url) return result.adapt<int, Url>();
        if (value == Class<Uuid>() || value.getType() is Uuid) return result.adapt<int, Uuid>();
        if (value == Class<Byte>() || value.getType() is Byte) return result.adapt<int, Byte>();
        if (value == Class<Locale>() || value.getType() is Locale) return result.adapt<int, Locale>();
        if (value == Class<Currency>() || value.getType() is Currency) return result.adapt<int, Currency>();

        if (value == Class<DateTime>() || value.getType() is DateTime) return result.adapt<int, DateTime>();
        if (value == Class<LocalDateTime>() || value.getType() is LocalDateTime) return result.adapt<int, LocalDateTime>();
        if (value == Class<LocalDate>() || value.getType() is LocalDate) return result.adapt<int, LocalDate>();
        if (value == Class<LocalTime>() || value.getType() is LocalTime) return result.adapt<int, LocalTime>();
        if (value == Class<ZoneId>() || value.getType() is ZoneId) return result.adapt<int, ZoneId>();
        if (value == Class<ZonedDateTime>() || value.getType() is ZonedDateTime) return result.adapt<int, ZonedDateTime>();
        if (value == Class<Duration>() || value.getType() is Duration) return result.adapt<int, Duration>();
      }

      // ---------------- Double keys ----------------
      if (key == Class<double>() || key.getType() is double) {
        if (value == Class<double>() || value.getType() is double) return result.adapt<double, double>();

        if (value == Class<String>() || value.getType() is String) return result.adapt<double, String>();
        if (value == Class<int>() || value.getType() is int) return result.adapt<double, int>();
        if (value == Class<bool>() || value.getType() is bool) return result.adapt<double, bool>();
        if (value == Class<num>() || value.getType() is num) return result.adapt<double, num>();
        if (value == Class<BigInt>() || value.getType() is BigInt) return result.adapt<double, BigInt>();
        if (value == Class<Runes>() || value.getType() is Runes) return result.adapt<double, Runes>();
        if (value == Class<Uri>() || value.getType() is Uri) return result.adapt<double, Uri>();
        if (value == Class<RegExp>() || value.getType() is RegExp) return result.adapt<double, RegExp>();
        if (value == Class<Pattern>() || value.getType() is Pattern) return result.adapt<double, Pattern>();
        if (value == Class<Enum>() || value.getType() is Enum) return result.adapt<double, Enum>();

        if (value == Class<Integer>() || value.getType() is Integer) return result.adapt<double, Integer>();
        if (value == Class<Long>() || value.getType() is Long) return result.adapt<double, Long>();
        if (value == Class<Float>() || value.getType() is Float) return result.adapt<double, Float>();
        if (value == Class<Double>() || value.getType() is Double) return result.adapt<double, Double>();
        if (value == Class<BigInteger>() || value.getType() is BigInteger) return result.adapt<double, BigInteger>();
        if (value == Class<BigDecimal>() || value.getType() is BigDecimal) return result.adapt<double, BigDecimal>();
        if (value == Class<Character>() || value.getType() is Character) return result.adapt<double, Character>();
        if (value == Class<Short>() || value.getType() is Short) return result.adapt<double, Short>();
        if (value == Class<Boolean>() || value.getType() is Boolean) return result.adapt<double, Boolean>();
        if (value == Class<Url>() || value.getType() is Url) return result.adapt<double, Url>();
        if (value == Class<Uuid>() || value.getType() is Uuid) return result.adapt<double, Uuid>();
        if (value == Class<Byte>() || value.getType() is Byte) return result.adapt<double, Byte>();
        if (value == Class<Locale>() || value.getType() is Locale) return result.adapt<double, Locale>();
        if (value == Class<Currency>() || value.getType() is Currency) return result.adapt<double, Currency>();

        if (value == Class<DateTime>() || value.getType() is DateTime) return result.adapt<double, DateTime>();
        if (value == Class<LocalDateTime>() || value.getType() is LocalDateTime) return result.adapt<double, LocalDateTime>();
        if (value == Class<LocalDate>() || value.getType() is LocalDate) return result.adapt<double, LocalDate>();
        if (value == Class<LocalTime>() || value.getType() is LocalTime) return result.adapt<double, LocalTime>();
        if (value == Class<ZoneId>() || value.getType() is ZoneId) return result.adapt<double, ZoneId>();
        if (value == Class<ZonedDateTime>() || value.getType() is ZonedDateTime) return result.adapt<double, ZonedDateTime>();
        if (value == Class<Duration>() || value.getType() is Duration) return result.adapt<double, Duration>();
      }

      // ---------------- Bool keys ----------------
      if (key == Class<bool>() || key.getType() is bool) {
        if (value == Class<bool>() || value.getType() is bool) return result.adapt<bool, bool>();

        if (value == Class<String>() || value.getType() is String) return result.adapt<bool, String>();
        if (value == Class<int>() || value.getType() is int) return result.adapt<bool, int>();
        if (value == Class<double>() || value.getType() is double) return result.adapt<bool, double>();
        if (value == Class<num>() || value.getType() is num) return result.adapt<bool, num>();
        if (value == Class<BigInt>() || value.getType() is BigInt) return result.adapt<bool, BigInt>();
        if (value == Class<Runes>() || value.getType() is Runes) return result.adapt<bool, Runes>();
        if (value == Class<Uri>() || value.getType() is Uri) return result.adapt<bool, Uri>();
        if (value == Class<RegExp>() || value.getType() is RegExp) return result.adapt<bool, RegExp>();
        if (value == Class<Pattern>() || value.getType() is Pattern) return result.adapt<bool, Pattern>();
        if (value == Class<Enum>() || value.getType() is Enum) return result.adapt<bool, Enum>();

        if (value == Class<Integer>() || value.getType() is Integer) return result.adapt<bool, Integer>();
        if (value == Class<Long>() || value.getType() is Long) return result.adapt<bool, Long>();
        if (value == Class<Float>() || value.getType() is Float) return result.adapt<bool, Float>();
        if (value == Class<Double>() || value.getType() is Double) return result.adapt<bool, Double>();
        if (value == Class<BigInteger>() || value.getType() is BigInteger) return result.adapt<bool, BigInteger>();
        if (value == Class<BigDecimal>() || value.getType() is BigDecimal) return result.adapt<bool, BigDecimal>();
        if (value == Class<Character>() || value.getType() is Character) return result.adapt<bool, Character>();
        if (value == Class<Short>() || value.getType() is Short) return result.adapt<bool, Short>();
        if (value == Class<Boolean>() || value.getType() is Boolean) return result.adapt<bool, Boolean>();
        if (value == Class<Url>() || value.getType() is Url) return result.adapt<bool, Url>();
        if (value == Class<Uuid>() || value.getType() is Uuid) return result.adapt<bool, Uuid>();
        if (value == Class<Byte>() || value.getType() is Byte) return result.adapt<bool, Byte>();
        if (value == Class<Locale>() || value.getType() is Locale) return result.adapt<bool, Locale>();
        if (value == Class<Currency>() || value.getType() is Currency) return result.adapt<bool, Currency>();

        if (value == Class<DateTime>() || value.getType() is DateTime) return result.adapt<bool, DateTime>();
        if (value == Class<LocalDateTime>() || value.getType() is LocalDateTime) return result.adapt<bool, LocalDateTime>();
        if (value == Class<LocalDate>() || value.getType() is LocalDate) return result.adapt<bool, LocalDate>();
        if (value == Class<LocalTime>() || value.getType() is LocalTime) return result.adapt<bool, LocalTime>();
        if (value == Class<ZoneId>() || value.getType() is ZoneId) return result.adapt<bool, ZoneId>();
        if (value == Class<ZonedDateTime>() || value.getType() is ZonedDateTime) return result.adapt<bool, ZonedDateTime>();
        if (value == Class<Duration>() || value.getType() is Duration) return result.adapt<bool, Duration>();
      }

      // ---------------- Num keys ----------------
      if (key == Class<num>() || key.getType() is num) {
        if (value == Class<num>() || value.getType() is num) return result.adapt<num, num>();

        if (value == Class<String>() || value.getType() is String) return result.adapt<num, String>();
        if (value == Class<int>() || value.getType() is int) return result.adapt<num, int>();
        if (value == Class<double>() || value.getType() is double) return result.adapt<num, double>();
        if (value == Class<bool>() || value.getType() is bool) return result.adapt<num, bool>();
        if (value == Class<BigInt>() || value.getType() is BigInt) return result.adapt<num, BigInt>();
        if (value == Class<Runes>() || value.getType() is Runes) return result.adapt<num, Runes>();
        if (value == Class<Uri>() || value.getType() is Uri) return result.adapt<num, Uri>();
        if (value == Class<RegExp>() || value.getType() is RegExp) return result.adapt<num, RegExp>();
        if (value == Class<Pattern>() || value.getType() is Pattern) return result.adapt<num, Pattern>();
        if (value == Class<Enum>() || value.getType() is Enum) return result.adapt<num, Enum>();

        if (value == Class<Integer>() || value.getType() is Integer) return result.adapt<num, Integer>();
        if (value == Class<Long>() || value.getType() is Long) return result.adapt<num, Long>();
        if (value == Class<Float>() || value.getType() is Float) return result.adapt<num, Float>();
        if (value == Class<Double>() || value.getType() is Double) return result.adapt<num, Double>();
        if (value == Class<BigInteger>() || value.getType() is BigInteger) return result.adapt<num, BigInteger>();
        if (value == Class<BigDecimal>() || value.getType() is BigDecimal) return result.adapt<num, BigDecimal>();
        if (value == Class<Character>() || value.getType() is Character) return result.adapt<num, Character>();
        if (value == Class<Short>() || value.getType() is Short) return result.adapt<num, Short>();
        if (value == Class<Boolean>() || value.getType() is Boolean) return result.adapt<num, Boolean>();
        if (value == Class<Url>() || value.getType() is Url) return result.adapt<num, Url>();
        if (value == Class<Uuid>() || value.getType() is Uuid) return result.adapt<num, Uuid>();
        if (value == Class<Byte>() || value.getType() is Byte) return result.adapt<num, Byte>();
        if (value == Class<Locale>() || value.getType() is Locale) return result.adapt<num, Locale>();
        if (value == Class<Currency>() || value.getType() is Currency) return result.adapt<num, Currency>();

        if (value == Class<DateTime>() || value.getType() is DateTime) return result.adapt<num, DateTime>();
        if (value == Class<LocalDateTime>() || value.getType() is LocalDateTime) return result.adapt<num, LocalDateTime>();
        if (value == Class<LocalDate>() || value.getType() is LocalDate) return result.adapt<num, LocalDate>();
        if (value == Class<LocalTime>() || value.getType() is LocalTime) return result.adapt<num, LocalTime>();
        if (value == Class<ZoneId>() || value.getType() is ZoneId) return result.adapt<num, ZoneId>();
        if (value == Class<ZonedDateTime>() || value.getType() is ZonedDateTime) return result.adapt<num, ZonedDateTime>();
        if (value == Class<Duration>() || value.getType() is Duration) return result.adapt<num, Duration>();
      }

      // ---------------- DateTime keys ----------------
      if (key == Class<DateTime>() || key.getType() is DateTime) {
        if (value == Class<DateTime>() || value.getType() is DateTime) return result.adapt<DateTime, DateTime>();

        if (value == Class<String>() || value.getType() is String) return result.adapt<DateTime, String>();
        if (value == Class<int>() || value.getType() is int) return result.adapt<DateTime, int>();
        if (value == Class<double>() || value.getType() is double) return result.adapt<DateTime, double>();
        if (value == Class<bool>() || value.getType() is bool) return result.adapt<DateTime, bool>();
        if (value == Class<num>() || value.getType() is num) return result.adapt<DateTime, num>();
        if (value == Class<BigInt>() || value.getType() is BigInt) return result.adapt<DateTime, BigInt>();
        if (value == Class<Runes>() || value.getType() is Runes) return result.adapt<DateTime, Runes>();
        if (value == Class<Uri>() || value.getType() is Uri) return result.adapt<DateTime, Uri>();
        if (value == Class<RegExp>() || value.getType() is RegExp) return result.adapt<DateTime, RegExp>();
        if (value == Class<Pattern>() || value.getType() is Pattern) return result.adapt<DateTime, Pattern>();
        if (value == Class<Enum>() || value.getType() is Enum) return result.adapt<DateTime, Enum>();

        if (value == Class<Integer>() || value.getType() is Integer) return result.adapt<DateTime, Integer>();
        if (value == Class<Long>() || value.getType() is Long) return result.adapt<DateTime, Long>();
        if (value == Class<Float>() || value.getType() is Float) return result.adapt<DateTime, Float>();
        if (value == Class<Double>() || value.getType() is Double) return result.adapt<DateTime, Double>();
        if (value == Class<BigInteger>() || value.getType() is BigInteger) return result.adapt<DateTime, BigInteger>();
        if (value == Class<BigDecimal>() || value.getType() is BigDecimal) return result.adapt<DateTime, BigDecimal>();
        if (value == Class<Character>() || value.getType() is Character) return result.adapt<DateTime, Character>();
        if (value == Class<Short>() || value.getType() is Short) return result.adapt<DateTime, Short>();
        if (value == Class<Boolean>() || value.getType() is Boolean) return result.adapt<DateTime, Boolean>();
        if (value == Class<Url>() || value.getType() is Url) return result.adapt<DateTime, Url>();
        if (value == Class<Uuid>() || value.getType() is Uuid) return result.adapt<DateTime, Uuid>();
        if (value == Class<Byte>() || value.getType() is Byte) return result.adapt<DateTime, Byte>();
        if (value == Class<Locale>() || value.getType() is Locale) return result.adapt<DateTime, Locale>();
        if (value == Class<Currency>() || value.getType() is Currency) return result.adapt<DateTime, Currency>();

        if (value == Class<LocalDateTime>() || value.getType() is LocalDateTime) return result.adapt<DateTime, LocalDateTime>();
        if (value == Class<LocalDate>() || value.getType() is LocalDate) return result.adapt<DateTime, LocalDate>();
        if (value == Class<LocalTime>() || value.getType() is LocalTime) return result.adapt<DateTime, LocalTime>();
        if (value == Class<ZoneId>() || value.getType() is ZoneId) return result.adapt<DateTime, ZoneId>();
        if (value == Class<ZonedDateTime>() || value.getType() is ZonedDateTime) return result.adapt<DateTime, ZonedDateTime>();
        if (value == Class<Duration>() || value.getType() is Duration) return result.adapt<DateTime, Duration>();
      }
    }

    // Fallback: when key/value are Object/Dynamic (raw types), return the result as-is.
    // When the target is dart:collection's HashMap/LinkedHashMap, create one explicitly
    // since AdaptableMap (which extends Jetleaf's HashMap) is not a subtype of col.HashMap.
    if (targetType == Class<col.HashMap>() || targetType.getType() is col.HashMap) {
      return col.HashMap.from(targetMap);
    }
    if (targetType == Class<col.LinkedHashMap>() || targetType.getType() is col.LinkedHashMap) {
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
      if (value == Class<String>() || value.getType() is String) return result.adapt<String>();

      // Default dart types
      if (value == Class<int>() || value.getType() is int) return result.adapt<int>();
      if (value == Class<double>() || value.getType() is double) return result.adapt<double>();
      if (value == Class<bool>() || value.getType() is bool) return result.adapt<bool>();
      if (value == Class<num>() || value.getType() is num) return result.adapt<num>();
      if (value == Class<BigInt>() || value.getType() is BigInt) return result.adapt<BigInt>();
      if (value == Class<Runes>() || value.getType() is Runes) return result.adapt<Runes>();
      if (value == Class<Uri>() || value.getType() is Uri) return result.adapt<Uri>();
      if (value == Class<RegExp>() || value.getType() is RegExp) return result.adapt<RegExp>();
      if (value == Class<Pattern>() || value.getType() is Pattern) return result.adapt<Pattern>();
      if (value == Class<Enum>() || value.getType() is Enum) return result.adapt<Enum>();

      // Jetleaf dart types
      if (value == Class<Integer>() || value.getType() is Integer) return result.adapt<Integer>();
      if (value == Class<Long>() || value.getType() is Long) return result.adapt<Long>();
      if (value == Class<Float>() || value.getType() is Float) return result.adapt<Float>();
      if (value == Class<BigInteger>() || value.getType() is BigInteger) return result.adapt<BigInteger>();
      if (value == Class<BigDecimal>() || value.getType() is BigDecimal) return result.adapt<BigDecimal>();
      if (value == Class<Character>() || value.getType() is Character) return result.adapt<Character>();
      if (value == Class<Short>() || value.getType() is Short) return result.adapt<Short>();
      if (value == Class<Double>() || value.getType() is Double) return result.adapt<Double>();
      if (value == Class<Boolean>() || value.getType() is Boolean) return result.adapt<Boolean>();
      if (value == Class<Url>() || value.getType() is Url) return result.adapt<Url>();
      if (value == Class<Uuid>() || value.getType() is Uuid) return result.adapt<Uuid>();
      if (value == Class<Byte>() || value.getType() is Byte) return result.adapt<Byte>();
      if (value == Class<Locale>() || value.getType() is Locale) return result.adapt<Locale>();
      if (value == Class<Currency>() || value.getType() is Currency) return result.adapt<Currency>();

      // Time types
      if (value == Class<DateTime>() || value.getType() is DateTime) return result.adapt<DateTime>();
      if (value == Class<LocalDateTime>() || value.getType() is LocalDateTime) return result.adapt<LocalDateTime>();
      if (value == Class<LocalDate>() || value.getType() is LocalDate) return result.adapt<LocalDate>();
      if (value == Class<LocalTime>() || value.getType() is LocalTime) return result.adapt<LocalTime>();
      if (value == Class<ZoneId>() || value.getType() is ZoneId) return result.adapt<ZoneId>();
      if (value == Class<ZonedDateTime>() || value.getType() is ZonedDateTime) return result.adapt<ZonedDateTime>();
      if (value == Class<Duration>() || value.getType() is Duration) return result.adapt<Duration>();
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
      if (value == Class<String>() || value.getType() is String) return result.adapt<String>();

      // Default dart types
      if (value == Class<int>() || value.getType() is int) return result.adapt<int>();
      if (value == Class<double>() || value.getType() is double) return result.adapt<double>();
      if (value == Class<bool>() || value.getType() is bool) return result.adapt<bool>();
      if (value == Class<num>() || value.getType() is num) return result.adapt<num>();
      if (value == Class<BigInt>() || value.getType() is BigInt) return result.adapt<BigInt>();
      if (value == Class<Runes>() || value.getType() is Runes) return result.adapt<Runes>();
      if (value == Class<Uri>() || value.getType() is Uri) return result.adapt<Uri>();
      if (value == Class<RegExp>() || value.getType() is RegExp) return result.adapt<RegExp>();
      if (value == Class<Pattern>() || value.getType() is Pattern) return result.adapt<Pattern>();
      if (value == Class<Enum>() || value.getType() is Enum) return result.adapt<Enum>();

      // Jetleaf dart types
      if (value == Class<Integer>() || value.getType() is Integer) return result.adapt<Integer>();
      if (value == Class<Long>() || value.getType() is Long) return result.adapt<Long>();
      if (value == Class<Float>() || value.getType() is Float) return result.adapt<Float>();
      if (value == Class<BigInteger>() || value.getType() is BigInteger) return result.adapt<BigInteger>();
      if (value == Class<BigDecimal>() || value.getType() is BigDecimal) return result.adapt<BigDecimal>();
      if (value == Class<Character>() || value.getType() is Character) return result.adapt<Character>();
      if (value == Class<Short>() || value.getType() is Short) return result.adapt<Short>();
      if (value == Class<Double>() || value.getType() is Double) return result.adapt<Double>();
      if (value == Class<Boolean>() || value.getType() is Boolean) return result.adapt<Boolean>();
      if (value == Class<Url>() || value.getType() is Url) return result.adapt<Url>();
      if (value == Class<Uuid>() || value.getType() is Uuid) return result.adapt<Uuid>();
      if (value == Class<Byte>() || value.getType() is Byte) return result.adapt<Byte>();
      if (value == Class<Locale>() || value.getType() is Locale) return result.adapt<Locale>();
      if (value == Class<Currency>() || value.getType() is Currency) return result.adapt<Currency>();

      // Time types
      if (value == Class<DateTime>() || value.getType() is DateTime) return result.adapt<DateTime>();
      if (value == Class<LocalDateTime>() || value.getType() is LocalDateTime) return result.adapt<LocalDateTime>();
      if (value == Class<LocalDate>() || value.getType() is LocalDate) return result.adapt<LocalDate>();
      if (value == Class<LocalTime>() || value.getType() is LocalTime) return result.adapt<LocalTime>();
      if (value == Class<ZoneId>() || value.getType() is ZoneId) return result.adapt<ZoneId>();
      if (value == Class<ZonedDateTime>() || value.getType() is ZonedDateTime) return result.adapt<ZonedDateTime>();
      if (value == Class<Duration>() || value.getType() is Duration) return result.adapt<Duration>();
    }

    return result;
  }
}