import 'package:jetleaf_lang/lang.dart';

import '../core/converters.dart';
import '../helpers/_commons.dart';
import '../helpers/convertible_pair.dart';
import '../exceptions.dart';

// ======================================== PRIMITIVE CONVERTERS ==========================================

/// {@template number_generic_converter}
/// A converter that transforms a [num] to a specific numeric subtype.
///
/// Supported conversions:
/// - `num` → `int`
/// - `num` → `double`
/// - `num` → `num` (identity)
/// - `num` → `String`
/// - `num` → `Integer`
/// - `num` → `Long`
/// - `num` → `Float`
/// - `num` → `BigInteger`
/// - `num` → `BigDecimal`
/// - `num` → `Character`
/// - `num` → `Short`
/// - `num` → `Double`
/// - `num` → `Boolean`
/// - `num` → `BigInt`
/// - `num` → `bool`
///
/// Example:
/// ```dart
/// final converter = NumberGenericConverter();
/// print(converter.convert(3.7)); // prints: 3
/// ```
/// {@endtemplate}
class NumberGenericConverter extends CommonPairedConditionalConverter {
  /// {@macro number_generic_converter}
  NumberGenericConverter();

  @override
  Set<ConvertiblePair>? getConvertibleTypes() => {
    ConvertiblePair(NUM, NUM),
    ConvertiblePair(NUM, INT),
    ConvertiblePair(NUM, DOUBLE),
    ConvertiblePair(NUM, STRING),
    ConvertiblePair(NUM, BIG_INT),
    ConvertiblePair(NUM, INTEGER),
    ConvertiblePair(NUM, LONG),
    ConvertiblePair(NUM, FLOAT),
    ConvertiblePair(NUM, BIG_INTEGER),
    ConvertiblePair(NUM, BIG_DECIMAL),
    ConvertiblePair(NUM, Class<Short>(null, PackageNames.LANG)),
    ConvertiblePair(NUM, Class<Double>(null, PackageNames.LANG)),
    ConvertiblePair(NUM, BOOLEAN),
    ConvertiblePair(NUM, CHARACTER),
    ConvertiblePair(NUM, BOOL),
  };

  @override
  Object? convert<T>(Object? source, Class sourceType, Class targetType) {
    if (source == null) return null;

    final sourceNum = source as num;

    try {
      return switch(targetType.getType()) {
        const (int) => sourceNum.round(),
        const (double) => sourceNum.toDouble(),
        const (String) => sourceNum.toString(),
        const (Integer) => Integer.valueOf(sourceNum.toInt()),
        const (Long) => Long.valueOf(sourceNum.toInt()),
        const (Float) => Float.valueOf(sourceNum.toDouble()),
        const (BigInteger) => BigInteger.fromInt(sourceNum.toInt()),
        const (BigDecimal) => BigDecimal.fromInt(sourceNum.toInt()),
        const (Character) => Character.valueOf(sourceNum.toString()),
        const (Short) => Short.valueOf(sourceNum.toInt()),
        const (Double) => Double.valueOf(sourceNum.toDouble()),
        const (Boolean) => Boolean.valueOf(sourceNum.toInt() != 0),
        const (BigInt) => BigInt.from(sourceNum.toInt()),
        const (bool) => sourceNum.toInt() != 0,
        _ => sourceNum,
      };
    } catch (e) {
      throw ConversionFailedException(sourceType: sourceType, targetType: targetType, value: source, point: e);
    }
  }
}

// =========================================== INT GENERIC CONVERTER =========================================

/// {@template int_generic_converter}
/// A converter that transforms an [int] to a specific numeric subtype.
///
/// Supported conversions:
/// - `int` → `int` (identity)
/// - `int` → `double`
/// - `int` → `num`
/// - `int` → `String`
/// - `int` → `Integer`
/// - `int` → `Long`
/// - `int` → `Float`
/// - `int` → `BigInteger`
/// - `int` → `BigDecimal`
/// - `int` → `Character`
/// - `int` → `Short`
/// - `int` → `Double`
/// - `int` → `Boolean`
/// - `int` → `BigInt`
/// - `int` → `bool`
///
/// Example:
/// ```dart
/// final converter = IntGenericConverter();
/// print(converter.convert(3)); // prints: 3
/// ```
/// {@endtemplate}
class IntGenericConverter extends CommonPairedConditionalConverter {
  /// {@macro int_generic_converter}
  IntGenericConverter();

  @override
  Set<ConvertiblePair>? getConvertibleTypes() => {
    ConvertiblePair(INT, INT),
    ConvertiblePair(INT, DOUBLE),
    ConvertiblePair(INT, NUM),
    ConvertiblePair(INT, STRING),
    ConvertiblePair(INT, INTEGER),
    ConvertiblePair(INT, LONG),
    ConvertiblePair(INT, FLOAT),
    ConvertiblePair(INT, BIG_INTEGER),
    ConvertiblePair(INT, BIG_DECIMAL),
    ConvertiblePair(INT, CHARACTER),
    ConvertiblePair(INT, Class<Short>(null, PackageNames.LANG)),
    ConvertiblePair(INT, Class<Double>(null, PackageNames.LANG)),
    ConvertiblePair(INT, BOOLEAN),
    ConvertiblePair(INT, BIG_INT),
    ConvertiblePair(INT, BOOL),
  };

  @override
  Object? convert<T>(Object? source, Class sourceType, Class targetType) {
    if (source == null) return null;

    final sourceNum = source as int;

    try {
      return switch(targetType.getType()) {
        const (num) => sourceNum,
        const (double) => sourceNum.toDouble(),
        const (String) => sourceNum.toString(),
        const (Integer) => Integer.valueOf(sourceNum),
        const (Long) => Long.valueOf(sourceNum),
        const (Float) => Float.valueOf(sourceNum.toDouble()),
        const (BigInteger) => BigInteger.fromInt(sourceNum),
        const (BigDecimal) => BigDecimal.fromInt(sourceNum),
        const (Character) => Character.valueOf(sourceNum.toString()),
        const (Short) => Short.valueOf(sourceNum),
        const (Double) => Double.valueOf(sourceNum.toDouble()),
        const (Boolean) => Boolean.valueOf(sourceNum != 0),
        const (BigInt) => BigInt.from(sourceNum),
        const (bool) => sourceNum != 0,
        _ => sourceNum,
      };
    } catch (e) {
      throw ConversionFailedException(sourceType: sourceType, targetType: targetType, value: source, point: e);
    }
  }
}

// ======================================= DOUBLE GENERIC CONVERTER =========================================

/// {@template double_generic_converter}
/// A converter that transforms a [double] to a specific numeric subtype.
///
/// Supported conversions:
/// - `double` → `double` (identity)
/// - `double` → `int`
/// - `double` → `num`
/// - `double` → `String`
/// - `double` → `Integer`
/// - `double` → `Long`
/// - `double` → `Float`
/// - `double` → `BigInteger`
/// - `double` → `BigDecimal`
/// - `double` → `Character`
/// - `double` → `Short`
/// - `double` → `Double`
/// - `double` → `Boolean`
/// - `double` → `BigInt`
/// - `double` → `bool`
///
/// Example:
/// ```dart
/// final converter = DoubleGenericConverter();
/// print(converter.convert(3.7)); // prints: 3.7
/// ```
/// {@endtemplate}
class DoubleGenericConverter extends CommonPairedConditionalConverter {
  /// {@macro double_generic_converter}
  DoubleGenericConverter();

  @override
  Set<ConvertiblePair>? getConvertibleTypes() => {
    ConvertiblePair(DOUBLE, DOUBLE),
    ConvertiblePair(DOUBLE, INT),
    ConvertiblePair(DOUBLE, NUM),
    ConvertiblePair(DOUBLE, STRING),
    ConvertiblePair(DOUBLE, INTEGER),
    ConvertiblePair(DOUBLE, LONG),
    ConvertiblePair(DOUBLE, FLOAT),
    ConvertiblePair(DOUBLE, BIG_INTEGER),
    ConvertiblePair(DOUBLE, BIG_DECIMAL),
    ConvertiblePair(DOUBLE, CHARACTER),
    ConvertiblePair(DOUBLE, Class<Short>(null, PackageNames.LANG)),
    ConvertiblePair(DOUBLE, Class<Double>(null, PackageNames.LANG)),
    ConvertiblePair(DOUBLE, BOOLEAN),
    ConvertiblePair(DOUBLE, BIG_INT),
    ConvertiblePair(DOUBLE, BOOL),
  };

  @override
  Object? convert<T>(Object? source, Class sourceType, Class targetType) {
    if (source == null) return null;

    final sourceNum = source as double;

    try {
      return switch(targetType.getType()) {
        const (num) => sourceNum.toInt(),
        const (int) => sourceNum.toInt(),
        const (String) => sourceNum.toString(),
        const (Integer) => Integer.valueOf(sourceNum.toInt()),
        const (Long) => Long.valueOf(sourceNum.toInt()),
        const (Float) => Float.valueOf(sourceNum),
        const (BigInteger) => BigInteger.fromInt(sourceNum.toInt()),
        const (BigDecimal) => BigDecimal.fromInt(sourceNum.toInt()),
        const (Character) => Character.valueOf(sourceNum.toString()),
        const (Short) => Short.valueOf(sourceNum.toInt()),
        const (Double) => Double.valueOf(sourceNum),
        const (Boolean) => Boolean.valueOf(sourceNum.toInt() != 0),
        const (BigInt) => BigInt.from(sourceNum.toInt()),
        const (bool) => sourceNum.toInt() != 0,
        _ => sourceNum,
      };
    } catch (e) {
      throw ConversionFailedException(sourceType: sourceType, targetType: targetType, value: source, point: e);
    }
  }
}

/// {@template string_generic_converter}
/// A converter that transforms a [String] to a specific numeric subtype.
///
/// Supported conversions:
/// - `String` → `String` (identity)
/// - `String` → `int`
/// - `String` → `double`
/// - `String` → `num`
/// - `String` → `Integer`
/// - `String` → `Long`
/// - `String` → `Float`
/// - `String` → `BigInteger`
/// - `String` → `BigDecimal`
/// - `String` → `Character`
/// - `String` → `Short`
/// - `String` → `Double`
/// - `String` → `Boolean`
/// - `String` → `BigInt`
/// - `String` → `bool`
///
/// Example:
/// ```dart
/// final converter = StringGenericConverter();
/// print(converter.convert('3.7')); // prints: 3.7
/// ```
/// {@endtemplate}
class StringGenericConverter extends CommonPairedConditionalConverter {
  /// {@macro string_generic_converter}
  StringGenericConverter();

  @override
  Set<ConvertiblePair>? getConvertibleTypes() => {
    ConvertiblePair(STRING, STRING),
    ConvertiblePair(STRING, INT),
    ConvertiblePair(STRING, DOUBLE),
    ConvertiblePair(STRING, NUM),
    ConvertiblePair(STRING, INTEGER),
    ConvertiblePair(STRING, LONG),
    ConvertiblePair(STRING, FLOAT),
    ConvertiblePair(STRING, BIG_INTEGER),
    ConvertiblePair(STRING, BIG_DECIMAL),
    ConvertiblePair(STRING, Class<Short>(null, PackageNames.LANG)),
    ConvertiblePair(STRING, Class<Double>(null, PackageNames.LANG)),
    ConvertiblePair(STRING, BOOLEAN),
    ConvertiblePair(STRING, CHARACTER),
    ConvertiblePair(STRING, BIG_INT),
    ConvertiblePair(STRING, BOOL),
  };

  @override
  Object? convert<T>(Object? source, Class sourceType, Class targetType) {
    if (source == null) return null;

    final sourceString = source as String;

    Map<String, bool> booleanMapping = {
      "TRUE": true,
      "FALSE": false,
      "1": true,
      "0": false
    };

    bool toBool() {
      final result = booleanMapping[sourceString.toUpperCase()];
      if(result != null) {
        return result;
      } else {
        throw ConversionFailedException(sourceType: sourceType, targetType: targetType, value: source);
      }
    }

    try {
      return switch(targetType.getType()) {
        const (int) => int.parse(sourceString),
        const (double) => double.parse(sourceString),
        const (num) => num.parse(sourceString),
        const (Integer) => Integer.valueOfString(sourceString),
        const (Long) => Long.valueOfString(sourceString),
        const (Float) => Float.valueOfString(sourceString),
        const (BigInteger) => BigInteger.fromInt(int.parse(sourceString)),
        const (BigDecimal) => BigDecimal.fromInt(int.parse(sourceString)),
        const (Character) => Character.valueOf(sourceString.toString()),
        const (Short) => Short.parseShort(sourceString),
        const (Double) => Double.valueOf(sourceString.toDouble()),
        const (Boolean) => Boolean.valueOf(toBool()),
        const (BigInt) => BigInt.from(int.parse(sourceString)),
        const (bool) => toBool(),
        _ => sourceString,
      };
    } on ConversionFailedException catch (_) {
      rethrow;
    } catch (e) {
      throw ConversionFailedException(sourceType: sourceType, targetType: targetType, value: source, point: e);
    }
  }
}

// ======================================= BOOL GENERIC CONVERTER =========================================

/// {@template bool_generic_converter}
/// A converter that transforms a [bool] to a specific numeric subtype.
///
/// Supported conversions:
/// - `bool` → `bool` (identity)
/// - `bool` → `double`
/// - `bool` → `num`
/// - `bool` → `String`
/// - `bool` → `Integer`
/// - `bool` → `Long`
/// - `bool` → `Float`
/// - `bool` → `BigInteger`
/// - `bool` → `BigDecimal`
/// - `bool` → `Character`
/// - `bool` → `Short`
/// - `bool` → `Double`
/// - `bool` → `Boolean`
/// - `bool` → `BigInt`
/// - `bool` → `int`
///
/// Example:
/// ```dart
/// final converter = BoolGenericConverter();
/// print(converter.convert(true)); // prints: true
/// ```
/// {@endtemplate}
class BoolGenericConverter extends CommonPairedConditionalConverter {
  /// {@macro bool_generic_converter}
  BoolGenericConverter();

  @override
  Set<ConvertiblePair>? getConvertibleTypes() => {
    ConvertiblePair(BOOL, BOOL),
    ConvertiblePair(BOOL, DOUBLE),
    ConvertiblePair(BOOL, NUM),
    ConvertiblePair(BOOL, STRING),
    ConvertiblePair(BOOL, INT),
    ConvertiblePair(BOOL, INTEGER),
    ConvertiblePair(BOOL, LONG),
    ConvertiblePair(BOOL, FLOAT),
    ConvertiblePair(BOOL, BIG_INTEGER),
    ConvertiblePair(BOOL, BIG_DECIMAL),
    ConvertiblePair(BOOL, CHARACTER),
    ConvertiblePair(BOOL, Class<Short>(null, PackageNames.LANG)),
    ConvertiblePair(BOOL, Class<Double>(null, PackageNames.LANG)),
    ConvertiblePair(BOOL, BOOLEAN),
    ConvertiblePair(BOOL, BIG_INT),
  };

  @override
  Object? convert<T>(Object? source, Class sourceType, Class targetType) {
    if (source == null) return null;

    final boolValue = (source as bool);

    try {
      return switch (targetType.getType()) {
        const (int) => boolValue ? 1 : 0,
        const (double) => boolValue ? 1.0 : 0.0,
        const (num) => boolValue ? 1 : 0,
        const (String) => boolValue.toString(),
        const (Integer) => Integer.valueOf(boolValue ? 1 : 0),
        const (Long) => Long.valueOf(boolValue ? 1 : 0),
        const (Float) => Float.valueOf(boolValue ? 1.0 : 0.0),
        const (BigInteger) => BigInteger.fromInt(boolValue ? 1 : 0),
        const (BigDecimal) => BigDecimal.fromInt(boolValue ? 1 : 0),
        const (Character) => Character.valueOf(boolValue ? '1' : '0'),
        const (Short) => Short.valueOf(boolValue ? 1 : 0),
        const (Double) => Double.valueOf(boolValue ? 1.0 : 0.0),
        const (Boolean) => Boolean.valueOf(boolValue),
        const (BigInt) => BigInt.from(boolValue ? 1 : 0),
        const (bool) => boolValue,
        _ => boolValue,
      };
    } catch (e) {
      throw ConversionFailedException(sourceType: sourceType, targetType: targetType, value: source, point: e);
    }
  }
}

// ======================================= BIGINT GENERIC CONVERTER =========================================

/// {@template bigint_generic_converter}
/// A converter that transforms a [BigInt] to a specific numeric subtype.
///
/// Supported conversions:
/// - `BigInt` → `BigInt` (identity)
/// - `BigInt` → `int`
/// - `BigInt` → `double`
/// - `BigInt` → `num`
/// - `BigInt` → `String`
/// - `BigInt` → `Integer`
/// - `BigInt` → `Long`
/// - `BigInt` → `Float`
/// - `BigInt` → `BigInteger`
/// - `BigInt` → `BigDecimal`
/// - `BigInt` → `Character`
/// - `BigInt` → `Short`
/// - `BigInt` → `Double`
/// - `BigInt` → `Boolean`
/// - `BigInt` → `bool`
///
/// Example:
/// ```dart
/// final converter = BigIntGenericConverter();
/// print(converter.convert(BigInt.from(3)))); // prints: 3
/// ```
/// {@endtemplate}
class BigIntGenericConverter extends CommonPairedConditionalConverter {
  /// {@macro bigint_generic_converter}
  BigIntGenericConverter();

  @override
  Set<ConvertiblePair>? getConvertibleTypes() => {
    ConvertiblePair(BIG_INT, INT),
    ConvertiblePair(BIG_INT, DOUBLE),
    ConvertiblePair(BIG_INT, NUM),
    ConvertiblePair(BIG_INT, STRING),
    ConvertiblePair(BIG_INT, INTEGER),
    ConvertiblePair(BIG_INT, LONG),
    ConvertiblePair(BIG_INT, FLOAT),
    ConvertiblePair(BIG_INT, BIG_INTEGER),
    ConvertiblePair(BIG_INT, BIG_DECIMAL),
    ConvertiblePair(BIG_INT, CHARACTER),
    ConvertiblePair(BIG_INT, Class<Short>(null, PackageNames.LANG)),
    ConvertiblePair(BIG_INT, Class<Double>(null, PackageNames.LANG)),
    ConvertiblePair(BIG_INT, BOOLEAN),
    ConvertiblePair(BIG_INT, BIG_INT),
    ConvertiblePair(BIG_INT, BOOL),
  };

  @override
  bool matches(Class sourceType, Class targetType) {
    if(sourceType.isAssignableTo(BIG_INT)) {
      return true;
    }

    return super.matches(sourceType, targetType);
  }

  @override
  Object? convert<T>(Object? source, Class sourceType, Class targetType) {
    if (source == null) return null;

    final bigIntValue = source as BigInt;

    try {
      return switch (targetType.getType()) {
        const (int) => bigIntValue.toInt(),
        const (double) => bigIntValue.toDouble(),
        const (num) => bigIntValue.toInt(),
        const (String) => bigIntValue.toString(),
        const (Integer) => Integer.valueOf(bigIntValue.toInt()),
        const (Long) => Long.valueOf(bigIntValue.toInt()),
        const (Float) => Float.valueOf(bigIntValue.toDouble()),
        const (BigInteger) => BigInteger.fromInt(bigIntValue.toInt()),
        const (BigDecimal) => BigDecimal.fromInt(bigIntValue.toInt()),
        const (Character) => Character.valueOf(bigIntValue.toString()),
        const (Short) => Short.valueOf(bigIntValue.toInt()),
        const (Double) => Double.valueOf(bigIntValue.toDouble()),
        const (Boolean) => Boolean.valueOf(bigIntValue.toInt() != 0),
        const (BigInt) => bigIntValue,
        const (bool) => bigIntValue.toInt() != 0,
        _ => bigIntValue,
      };
    } catch (e) {
      throw ConversionFailedException(sourceType: sourceType, targetType: targetType, value: source, point: e);
    }
  }
}

// ======================================= INTEGER GENERIC CONVERTER =========================================

/// {@template integer_generic_converter}
/// A converter that transforms a [Integer] to a specific numeric subtype.
///
/// Supported conversions:
/// - `Integer` → `Integer` (identity)
/// - `Integer` → `int`
/// - `Integer` → `double`
/// - `Integer` → `num`
/// - `Integer` → `String`
/// - `Integer` → `Integer`
/// - `Integer` → `Long`
/// - `Integer` → `Float`
/// - `Integer` → `BigInteger`
/// - `Integer` → `BigDecimal`
/// - `Integer` → `Character`
/// - `Integer` → `Short`
/// - `Integer` → `Double`
/// - `Integer` → `Boolean`
/// - `Integer` → `BigInt`
/// - `Integer` → `bool`
///
/// Example:
/// ```dart
/// final converter = IntegerGenericConverter();
/// print(converter.convert(Integer.valueOf(3)))); // prints: 3
/// ```
/// {@endtemplate}
class IntegerGenericConverter extends CommonPairedConditionalConverter {
  /// {@macro integer_generic_converter}
  IntegerGenericConverter();

  @override
  Set<ConvertiblePair>? getConvertibleTypes() => {
    ConvertiblePair(INTEGER, INT),
    ConvertiblePair(INTEGER, DOUBLE),
    ConvertiblePair(INTEGER, NUM),
    ConvertiblePair(INTEGER, STRING),
    ConvertiblePair(INTEGER, INTEGER),
    ConvertiblePair(INTEGER, LONG),
    ConvertiblePair(INTEGER, FLOAT),
    ConvertiblePair(INTEGER, BIG_INTEGER),
    ConvertiblePair(INTEGER, BIG_DECIMAL),
    ConvertiblePair(INTEGER, CHARACTER),
    ConvertiblePair(INTEGER, Class<Short>(null, PackageNames.LANG)),
    ConvertiblePair(INTEGER, Class<Double>(null, PackageNames.LANG)),
    ConvertiblePair(INTEGER, BOOLEAN),
    ConvertiblePair(INTEGER, BIG_INT),
    ConvertiblePair(INTEGER, BOOL),
  };

  @override
  Object? convert<T>(Object? source, Class sourceType, Class targetType) {
    if (source == null) return null;

    final intValue = source as Integer;

    try {
      return switch (targetType.getType()) {
        const (int) => intValue.value,
        const (double) => intValue.toDouble(),
        const (num) => intValue.value,
        const (String) => intValue.toString(),
        const (Long) => Long.valueOf(intValue.value),
        const (Float) => Float.valueOf(intValue.toDouble()),
        const (BigInteger) => BigInteger.fromInt(intValue.value),
        const (BigDecimal) => BigDecimal.fromInt(intValue.value),
        const (Character) => Character.valueOf(intValue.toString()),
        const (Short) => Short.valueOf(intValue.value),
        const (Double) => Double.valueOf(intValue.toDouble()),
        const (Boolean) => Boolean.valueOf(intValue.value != 0),
        const (BigInt) => BigInt.from(intValue.value),
        const (bool) => intValue.value != 0,
        _ => intValue,
      };
    } catch (e) {
      throw ConversionFailedException(sourceType: sourceType, targetType: targetType, value: source, point: e);
    }
  }
}

// ======================================= LONG GENERIC CONVERTER =========================================

/// {@template long_generic_converter}
/// A converter that transforms a [Long] to a specific numeric subtype.
///
/// Supported conversions:
/// - `Long` → `Long` (identity)
/// - `Long` → `int`
/// - `Long` → `double`
/// - `Long` → `num`
/// - `Long` → `String`
/// - `Long` → `Integer`
/// - `Long` → `Long`
/// - `Long` → `Float`
/// - `Long` → `BigInteger`
/// - `Long` → `BigDecimal`
/// - `Long` → `Character`
/// - `Long` → `Short`
/// - `Long` → `Double`
/// - `Long` → `Boolean`
/// - `Long` → `BigInt`
/// - `Long` → `bool`
///
/// Example:
/// ```dart
/// final converter = LongGenericConverter();
/// print(converter.convert(Long.valueOf(3)))); // prints: 3
/// ```
/// {@endtemplate}
class LongGenericConverter extends CommonPairedConditionalConverter {
  /// {@macro long_generic_converter}
  LongGenericConverter();

  @override
  Set<ConvertiblePair>? getConvertibleTypes() => {
    ConvertiblePair(LONG, INT),
    ConvertiblePair(LONG, DOUBLE),
    ConvertiblePair(LONG, NUM),
    ConvertiblePair(LONG, STRING),
    ConvertiblePair(LONG, INTEGER),
    ConvertiblePair(LONG, LONG),
    ConvertiblePair(LONG, FLOAT),
    ConvertiblePair(LONG, BIG_INTEGER),
    ConvertiblePair(LONG, BIG_DECIMAL),
    ConvertiblePair(LONG, CHARACTER),
    ConvertiblePair(LONG, Class<Short>(null, PackageNames.LANG)),
    ConvertiblePair(LONG, Class<Double>(null, PackageNames.LANG)),
    ConvertiblePair(LONG, BOOLEAN),
    ConvertiblePair(LONG, BIG_INT),
    ConvertiblePair(LONG, BOOL),
  };

  @override
  Object? convert<T>(Object? source, Class sourceType, Class targetType) {
    if (source == null) return null;

    final longValue = source as Long;

    try {
      return switch (targetType.getType()) {
        const (int) => longValue.value,
        const (double) => longValue.toDouble(),
        const (num) => longValue.value,
        const (String) => longValue.toString(),
        const (Integer) => Integer.valueOf(longValue.value),
        const (Float) => Float.valueOf(longValue.toDouble()),
        const (BigInteger) => BigInteger.fromInt(longValue.value),
        const (BigDecimal) => BigDecimal.fromInt(longValue.value),
        const (Character) => Character.valueOf(longValue.toString()),
        const (Short) => Short.valueOf(longValue.value),
        const (Double) => Double.valueOf(longValue.toDouble()),
        const (Boolean) => Boolean.valueOf(longValue.value != 0),
        const (BigInt) => BigInt.from(longValue.value),
        const (bool) => longValue.value != 0,
        _ => longValue,
      };
    } catch (e) {
      throw ConversionFailedException(sourceType: sourceType, targetType: targetType, value: source, point: e);
    }
  }
}

// ======================================= FLOAT GENERIC CONVERTER =========================================

/// {@template float_generic_converter}
/// A converter that transforms a [Float] to a specific numeric subtype.
///
/// Supported conversions:
/// - `Float` → `Float` (identity)
/// - `Float` → `int`
/// - `Float` → `double`
/// - `Float` → `num`
/// - `Float` → `String`
/// - `Float` → `Integer`
/// - `Float` → `Long`
/// - `Float` → `Float`
/// - `Float` → `BigInteger`
/// - `Float` → `BigDecimal`
/// - `Float` → `Character`
/// - `Float` → `Short`
/// - `Float` → `Double`
/// - `Float` → `Boolean`
/// - `Float` → `BigInt`
/// - `Float` → `bool`
///
/// Example:
/// ```dart
/// final converter = FloatGenericConverter();
/// print(converter.convert(Float.valueOf(3)))); // prints: 3
/// ```
/// {@endtemplate}
class FloatGenericConverter extends CommonPairedConditionalConverter {
  /// {@macro float_generic_converter}
  FloatGenericConverter();

  @override
  Set<ConvertiblePair>? getConvertibleTypes() => {
    ConvertiblePair(FLOAT, INT),
    ConvertiblePair(FLOAT, DOUBLE),
    ConvertiblePair(FLOAT, NUM),
    ConvertiblePair(FLOAT, STRING),
    ConvertiblePair(FLOAT, INTEGER),
    ConvertiblePair(FLOAT, LONG),
    ConvertiblePair(FLOAT, FLOAT),
    ConvertiblePair(FLOAT, BIG_INTEGER),
    ConvertiblePair(FLOAT, BIG_DECIMAL),
    ConvertiblePair(FLOAT, CHARACTER),
    ConvertiblePair(FLOAT, Class<Short>(null, PackageNames.LANG)),
    ConvertiblePair(FLOAT, Class<Double>(null, PackageNames.LANG)),
    ConvertiblePair(FLOAT, BOOLEAN),
    ConvertiblePair(FLOAT, BIG_INT),
    ConvertiblePair(FLOAT, BOOL),
  };

  @override
  Object? convert<T>(Object? source, Class sourceType, Class targetType) {
    if (source == null) return null;

    final floatValue = source as Float;

    try {
      return switch (targetType.getType()) {
        const (int) => floatValue.toInt(),
        const (double) => double.parse(floatValue.toString()),
        const (num) => num.parse(floatValue.toString()),
        const (String) => floatValue.toString(),
        const (Integer) => Integer.valueOf(floatValue.toInt()),
        const (Long) => Long.valueOf(floatValue.toInt()),
        const (Float) => Float.valueOf(floatValue.toInt().toDouble()),
        const (BigInteger) => BigInteger.fromInt(floatValue.toInt()),
        const (BigDecimal) => BigDecimal.fromInt(floatValue.toInt()),
        const (Character) => Character.valueOf(floatValue.toString()),
        const (Short) => Short.valueOf(floatValue.toInt()),
        const (Double) => Double.valueOf(double.parse(floatValue.toString())),
        const (Boolean) => Boolean.valueOf(floatValue.toInt() != 0),
        const (BigInt) => BigInt.from(floatValue.toInt()),
        const (bool) => floatValue.toInt() != 0,
        _ => floatValue,
      };
    } catch (e) {
      throw ConversionFailedException(sourceType: sourceType, targetType: targetType, value: source, point: e);
    }
  }
}

// ======================================= BIGINTEGER GENERIC CONVERTER =========================================

/// {@template biginteger_generic_converter}
/// A converter that transforms a [BigInteger] to a specific numeric subtype.
///
/// Supported conversions:
/// - `BigInteger` → `BigInteger` (identity)
/// - `BigInteger` → `int`
/// - `BigInteger` → `double`
/// - `BigInteger` → `num`
/// - `BigInteger` → `String`
/// - `BigInteger` → `Integer`
/// - `BigInteger` → `Long`
/// - `BigInteger` → `Float`
/// - `BigInteger` → `BigInteger`
/// - `BigInteger` → `BigDecimal`
/// - `BigInteger` → `Character`
/// - `BigInteger` → `Short`
/// - `BigInteger` → `Double`
/// - `BigInteger` → `Boolean`
/// - `BigInteger` → `BigInt`
/// - `BigInteger` → `bool`
///
/// Example:
/// ```dart
/// final converter = BigIntegerGenericConverter();
/// print(converter.convert(BigInteger.valueOf(3)))); // prints: 3
/// ```
/// {@endtemplate}
class BigIntegerGenericConverter extends CommonPairedConditionalConverter {
  /// {@macro biginteger_generic_converter}
  BigIntegerGenericConverter();

  @override
  Set<ConvertiblePair>? getConvertibleTypes() => {
    ConvertiblePair(BIG_INTEGER, INT),
    ConvertiblePair(BIG_INTEGER, DOUBLE),
    ConvertiblePair(BIG_INTEGER, NUM),
    ConvertiblePair(BIG_INTEGER, STRING),
    ConvertiblePair(BIG_INTEGER, INTEGER),
    ConvertiblePair(BIG_INTEGER, LONG),
    ConvertiblePair(BIG_INTEGER, FLOAT),
    ConvertiblePair(BIG_INTEGER, BIG_INTEGER),
    ConvertiblePair(BIG_INTEGER, BIG_DECIMAL),
    ConvertiblePair(BIG_INTEGER, CHARACTER),
    ConvertiblePair(BIG_INTEGER, Class<Short>(null, PackageNames.LANG)),
    ConvertiblePair(BIG_INTEGER, Class<Double>(null, PackageNames.LANG)),
    ConvertiblePair(BIG_INTEGER, BOOLEAN),
    ConvertiblePair(BIG_INTEGER, BIG_INT),
    ConvertiblePair(BIG_INTEGER, BOOL),
  };

  @override
  Object? convert<T>(Object? source, Class sourceType, Class targetType) {
    if (source == null) return null;

    final bigIntValue = source as BigInteger;

    try {
      return switch (targetType.getType()) {
        const (int) => bigIntValue.toInt(),
        const (double) => bigIntValue.toDouble(),
        const (num) => bigIntValue.toInt(),
        const (String) => bigIntValue.toString(),
        const (Integer) => Integer.valueOf(bigIntValue.toInt()),
        const (Long) => Long.valueOf(bigIntValue.toInt()),
        const (Float) => Float.valueOf(bigIntValue.toDouble()),
        const (BigDecimal) => BigDecimal.fromInt(bigIntValue.toInt()),
        const (Character) => Character.valueOf(bigIntValue.toString()),
        const (Short) => Short.valueOf(bigIntValue.toInt()),
        const (Double) => Double.valueOf(bigIntValue.toDouble()),
        const (Boolean) => Boolean.valueOf(bigIntValue.toInt() != 0),
        const (BigInt) => BigInt.from(bigIntValue.toInt()),
        const (bool) => bigIntValue.toInt() != 0,
        _ => bigIntValue,
      };
    } catch (e) {
      throw ConversionFailedException(sourceType: sourceType, targetType: targetType, value: source, point: e);
    }
  }
}

// ======================================= BIGDECIMAL GENERIC CONVERTER =========================================

/// {@template bigdecimal_generic_converter}
/// A converter that transforms a [BigDecimal] to a specific numeric subtype.
///
/// Supported conversions:
/// - `BigDecimal` → `BigDecimal` (identity)
/// - `BigDecimal` → `int`
/// - `BigDecimal` → `double`
/// - `BigDecimal` → `num`
/// - `BigDecimal` → `String`
/// - `BigDecimal` → `Integer`
/// - `BigDecimal` → `Long`
/// - `BigDecimal` → `Float`
/// - `BigDecimal` → `BigInteger`
/// - `BigDecimal` → `BigDecimal`
/// - `BigDecimal` → `Character`
/// - `BigDecimal` → `Short`
/// - `BigDecimal` → `Double`
/// - `BigDecimal` → `Boolean`
/// - `BigDecimal` → `BigInt`
/// - `BigDecimal` → `bool`
///
/// Example:
/// ```dart
/// final converter = BigDecimalGenericConverter();
/// print(converter.convert(BigDecimal.valueOf(3)))); // prints: 3
/// ```
/// {@endtemplate}
class BigDecimalGenericConverter extends CommonPairedConditionalConverter {
  /// {@macro bigdecimal_generic_converter}
  BigDecimalGenericConverter();

  @override
  Set<ConvertiblePair>? getConvertibleTypes() => {
    ConvertiblePair(BIG_DECIMAL, INT),
    ConvertiblePair(BIG_DECIMAL, DOUBLE),
    ConvertiblePair(BIG_DECIMAL, NUM),
    ConvertiblePair(BIG_DECIMAL, STRING),
    ConvertiblePair(BIG_DECIMAL, INTEGER),
    ConvertiblePair(BIG_DECIMAL, LONG),
    ConvertiblePair(BIG_DECIMAL, FLOAT),
    ConvertiblePair(BIG_DECIMAL, BIG_INTEGER),
    ConvertiblePair(BIG_DECIMAL, BIG_DECIMAL),
    ConvertiblePair(BIG_DECIMAL, CHARACTER),
    ConvertiblePair(BIG_DECIMAL, Class<Short>(null, PackageNames.LANG)),
    ConvertiblePair(BIG_DECIMAL, Class<Double>(null, PackageNames.LANG)),
    ConvertiblePair(BIG_DECIMAL, BOOLEAN),
    ConvertiblePair(BIG_DECIMAL, BIG_INT),
    ConvertiblePair(BIG_DECIMAL, BOOL),
  };

  @override
  Object? convert<T>(Object? source, Class sourceType, Class targetType) {
    if (source == null) return null;

    final decimalValue = source as BigDecimal;

    try {
      return switch (targetType.getType()) {
        const (int) => decimalValue.toDouble().round(),
        const (double) => decimalValue.toDouble(),
        const (num) => decimalValue.toDouble(),
        const (String) => decimalValue.toString(),
        const (Integer) => Integer.valueOf(decimalValue.toDouble().round()),
        const (Long) => Long.valueOf(decimalValue.toDouble().round()),
        const (Float) => Float.valueOf(decimalValue.toDouble()),
        const (BigInteger) => BigInteger.fromInt(decimalValue.toDouble().round()),
        const (Character) => Character.valueOf(decimalValue.toString()),
        const (Short) => Short.valueOf(decimalValue.toDouble().round()),
        const (Double) => Double.valueOf(decimalValue.toDouble()),
        const (Boolean) => Boolean.valueOf(decimalValue.toDouble().round() != 0),
        const (BigInt) => BigInt.from(decimalValue.toDouble().round()),
        const (bool) => decimalValue.toDouble().round() != 0,
        _ => decimalValue,
      };
    } catch (e) {
      throw ConversionFailedException(sourceType: sourceType, targetType: targetType, value: source, point: e);
    }
  }
}

// ======================================= SHORT GENERIC CONVERTER =========================================

/// {@template short_generic_converter}
/// A converter that transforms a [Short] to a specific numeric subtype.
///
/// Supported conversions:
/// - `Short` → `Short` (identity)
/// - `Short` → `int`
/// - `Short` → `double`
/// - `Short` → `num`
/// - `Short` → `String`
/// - `Short` → `Integer`
/// - `Short` → `Long`
/// - `Short` → `Float`
/// - `Short` → `BigInteger`
/// - `Short` → `BigDecimal`
/// - `Short` → `Character`
/// - `Short` → `Short`
/// - `Short` → `Double`
/// - `Short` → `Boolean`
/// - `Short` → `BigInt`
/// - `Short` → `bool`
///
/// Example:
/// ```dart
/// final converter = ShortGenericConverter();
/// print(converter.convert(Short.valueOf(3)))); // prints: 3
/// ```
/// {@endtemplate}
class ShortGenericConverter extends CommonPairedConditionalConverter {
  /// {@macro short_generic_converter}
  ShortGenericConverter();

  @override
  Set<ConvertiblePair>? getConvertibleTypes() => {
    ConvertiblePair(Class<Short>(null, PackageNames.LANG), INT),
    ConvertiblePair(Class<Short>(null, PackageNames.LANG), DOUBLE),
    ConvertiblePair(Class<Short>(null, PackageNames.LANG), NUM),
    ConvertiblePair(Class<Short>(null, PackageNames.LANG), STRING),
    ConvertiblePair(Class<Short>(null, PackageNames.LANG), INTEGER),
    ConvertiblePair(Class<Short>(null, PackageNames.LANG), LONG),
    ConvertiblePair(Class<Short>(null, PackageNames.LANG), FLOAT),
    ConvertiblePair(Class<Short>(null, PackageNames.LANG), BIG_INTEGER),
    ConvertiblePair(Class<Short>(null, PackageNames.LANG), BIG_DECIMAL),
    ConvertiblePair(Class<Short>(null, PackageNames.LANG), CHARACTER),
    ConvertiblePair(Class<Short>(null, PackageNames.LANG), Class<Short>(null, PackageNames.LANG)),
    ConvertiblePair(Class<Short>(null, PackageNames.LANG), Class<Double>(null, PackageNames.LANG)),
    ConvertiblePair(Class<Short>(null, PackageNames.LANG), BOOLEAN),
    ConvertiblePair(Class<Short>(null, PackageNames.LANG), BIG_INT),
    ConvertiblePair(Class<Short>(null, PackageNames.LANG), BOOL),
  };

  @override
  Object? convert<T>(Object? source, Class sourceType, Class targetType) {
    if (source == null) return null;

    final shortValue = source as Short;

    try {
      return switch (targetType.getType()) {
        const (int) => shortValue.value,
        const (double) => shortValue.value.toDouble(),
        const (num) => shortValue.value,
        const (String) => shortValue.toString(),
        const (Integer) => Integer.valueOf(shortValue.value),
        const (Long) => Long.valueOf(shortValue.value),
        const (Float) => Float.valueOf(shortValue.value.toDouble()),
        const (BigInteger) => BigInteger.fromInt(shortValue.value),
        const (BigDecimal) => BigDecimal.fromInt(shortValue.value),
        const (Character) => Character.valueOf(shortValue.toString()),
        const (Double) => Double.valueOf(shortValue.value.toDouble()),
        const (Boolean) => Boolean.valueOf(shortValue.value != 0),
        const (BigInt) => BigInt.from(shortValue.value),
        const (bool) => shortValue.value != 0,
        _ => shortValue,
      };
    } catch (e) {
      throw ConversionFailedException(sourceType: sourceType, targetType: targetType, value: source, point: e);
    }
  }
}

// ======================================= DOUBLED GENERIC CONVERTER =========================================

/// {@template doubled_generic_converter}
/// A converter that transforms a [Double] to a specific numeric subtype.
///
/// Supported conversions:
/// - `Double` → `Double` (identity)
/// - `Double` → `int`
/// - `Double` → `double`
/// - `Double` → `num`
/// - `Double` → `String`
/// - `Double` → `Integer`
/// - `Double` → `Long`
/// - `Double` → `Float`
/// - `Double` → `BigInteger`
/// - `Double` → `BigDecimal`
/// - `Double` → `Character`
/// - `Double` → `Short`
/// - `Double` → `Double`
/// - `Double` → `Boolean`
/// - `Double` → `BigInt`
/// - `Double` → `bool`
///
/// Example:
/// ```dart
/// final converter = DoubleGenericConverter();
/// print(converter.convert(Double.valueOf(3)))); // prints: 3
/// ```
/// {@endtemplate}
class DoubledGenericConverter extends CommonPairedConditionalConverter {
  /// {@macro doubled_generic_converter}
  DoubledGenericConverter();

  @override
  Set<ConvertiblePair>? getConvertibleTypes() => {
    ConvertiblePair(Class<Double>(null, PackageNames.LANG), INT),
    ConvertiblePair(Class<Double>(null, PackageNames.LANG), DOUBLE),
    ConvertiblePair(Class<Double>(null, PackageNames.LANG), NUM),
    ConvertiblePair(Class<Double>(null, PackageNames.LANG), STRING),
    ConvertiblePair(Class<Double>(null, PackageNames.LANG), INTEGER),
    ConvertiblePair(Class<Double>(null, PackageNames.LANG), LONG),
    ConvertiblePair(Class<Double>(null, PackageNames.LANG), FLOAT),
    ConvertiblePair(Class<Double>(null, PackageNames.LANG), BIG_INTEGER),
    ConvertiblePair(Class<Double>(null, PackageNames.LANG), BIG_DECIMAL),
    ConvertiblePair(Class<Double>(null, PackageNames.LANG), CHARACTER),
    ConvertiblePair(Class<Double>(null, PackageNames.LANG), Class<Short>(null, PackageNames.LANG)),
    ConvertiblePair(Class<Double>(null, PackageNames.LANG), Class<Double>(null, PackageNames.LANG)),
    ConvertiblePair(Class<Double>(null, PackageNames.LANG), BOOLEAN),
    ConvertiblePair(Class<Double>(null, PackageNames.LANG), BIG_INT),
    ConvertiblePair(Class<Double>(null, PackageNames.LANG), BOOL),
  };

  @override
  Object? convert<T>(Object? source, Class sourceType, Class targetType) {
    if (source == null) return null;

    final doubleValue = source as Double;

    try {
      return switch (targetType.getType()) {
        const (int) => doubleValue.toInt(),
        const (double) => doubleValue,
        const (num) => doubleValue,
        const (String) => doubleValue.toString(),
        const (Integer) => Integer.valueOf(doubleValue.toInt()),
        const (Long) => Long.valueOf(doubleValue.toInt()),
        const (Float) => Float.valueOf(doubleValue.value),
        const (BigInteger) => BigInteger.fromInt(doubleValue.toInt()),
        const (BigDecimal) => BigDecimal.fromInt(doubleValue.toInt()),
        const (Character) => Character.valueOf(doubleValue.toString()),
        const (Short) => Short.valueOf(doubleValue.toInt()),
        const (Boolean) => Boolean.valueOf(doubleValue.toInt() != 0),
        const (BigInt) => BigInt.from(doubleValue.toInt()),
        const (bool) => doubleValue.toInt() != 0,
        _ => doubleValue,
      };
    } catch (e) {
      throw ConversionFailedException(sourceType: sourceType, targetType: targetType, value: source, point: e);
    }
  }
}

// ======================================= BOOLEAN GENERIC CONVERTER =========================================

/// {@template boolean_generic_converter}
/// A converter that transforms a [Boolean] to a specific numeric subtype.
///
/// Supported conversions:
/// - `Boolean` → `Boolean` (identity)
/// - `Boolean` → `int`
/// - `Boolean` → `double`
/// - `Boolean` → `num`
/// - `Boolean` → `String`
/// - `Boolean` → `Integer`
/// - `Boolean` → `Long`
/// - `Boolean` → `Float`
/// - `Boolean` → `BigInteger`
/// - `Boolean` → `BigDecimal`
/// - `Boolean` → `Character`
/// - `Boolean` → `Short`
/// - `Boolean` → `Double`
/// - `Boolean` → `Boolean`
/// - `Boolean` → `BigInt`
/// - `Boolean` → `bool`
///
/// Example:
/// ```dart
/// final converter = BooleanGenericConverter();
/// print(converter.convert(Boolean.valueOf(true)))); // prints: true
/// ```
/// {@endtemplate}
class BooleanGenericConverter extends CommonPairedConditionalConverter {
  /// {@macro boolean_generic_converter}
  BooleanGenericConverter();

  @override
  Set<ConvertiblePair>? getConvertibleTypes() => {
    ConvertiblePair(BOOLEAN, INT),
    ConvertiblePair(BOOLEAN, DOUBLE),
    ConvertiblePair(BOOLEAN, NUM),
    ConvertiblePair(BOOLEAN, STRING),
    ConvertiblePair(BOOLEAN, INTEGER),
    ConvertiblePair(BOOLEAN, LONG),
    ConvertiblePair(BOOLEAN, FLOAT),
    ConvertiblePair(BOOLEAN, BIG_INTEGER),
    ConvertiblePair(BOOLEAN, BIG_DECIMAL),
    ConvertiblePair(BOOLEAN, CHARACTER),
    ConvertiblePair(BOOLEAN, Class<Short>(null, PackageNames.LANG)),
    ConvertiblePair(BOOLEAN, Class<Double>(null, PackageNames.LANG)),
    ConvertiblePair(BOOLEAN, BOOLEAN),
    ConvertiblePair(BOOLEAN, BIG_INT),
    ConvertiblePair(BOOLEAN, BOOL),
  };

  @override
  Object? convert<T>(Object? source, Class sourceType, Class targetType) {
    if (source == null) return null;

    final boolValue = (source as Boolean).value;

    try {
      return switch (targetType.getType()) {
        const (int) => boolValue ? 1 : 0,
        const (double) => boolValue ? 1.0 : 0.0,
        const (num) => boolValue ? 1 : 0,
        const (String) => boolValue.toString(),
        const (Integer) => Integer.valueOf(boolValue ? 1 : 0),
        const (Long) => Long.valueOf(boolValue ? 1 : 0),
        const (Float) => Float.valueOf(boolValue ? 1.0 : 0.0),
        const (BigInteger) => BigInteger.fromInt(boolValue ? 1 : 0),
        const (BigDecimal) => BigDecimal.fromInt(boolValue ? 1 : 0),
        const (Character) => Character.valueOf(boolValue ? '1' : '0'),
        const (Short) => Short.valueOf(boolValue ? 1 : 0),
        const (Double) => Double.valueOf(boolValue ? 1.0 : 0.0),
        const (Boolean) => Boolean.valueOf(boolValue),
        const (BigInt) => BigInt.from(boolValue ? 1 : 0),
        const (bool) => boolValue,
        _ => boolValue,
      };
    } catch (e) {
      throw ConversionFailedException(sourceType: sourceType, targetType: targetType, value: source, point: e);
    }
  }
}

// ======================================= CHARACTER GENERIC CONVERTER =========================================

/// {@template character_generic_converter}
/// A converter that transforms a [Character] to a specific numeric subtype.
///
/// Supported conversions:
/// - `Character` → `Character` (identity)
/// - `Character` → `int`
/// - `Character` → `double`
/// - `Character` → `num`
/// - `Character` → `String`
/// - `Character` → `Integer`
/// - `Character` → `Long`
/// - `Character` → `Float`
/// - `Character` → `BigInteger`
/// - `Character` → `BigDecimal`
/// - `Character` → `Character`
/// - `Character` → `Short`
/// - `Character` → `Double`
/// - `Character` → `Boolean`
/// - `Character` → `BigInt`
/// - `Character` → `bool`
///
/// Example:
/// ```dart
/// final converter = CharacterGenericConverter();
/// print(converter.convert(Character.valueOf('A')))); // prints: A
/// ```
/// {@endtemplate}
class CharacterGenericConverter extends CommonPairedConditionalConverter {
  /// {@macro character_generic_converter}
  CharacterGenericConverter();

  @override
  Set<ConvertiblePair>? getConvertibleTypes() => {
    ConvertiblePair(CHARACTER, INT),
    ConvertiblePair(CHARACTER, DOUBLE),
    ConvertiblePair(CHARACTER, NUM),
    ConvertiblePair(CHARACTER, STRING),
    ConvertiblePair(CHARACTER, INTEGER),
    ConvertiblePair(CHARACTER, LONG),
    ConvertiblePair(CHARACTER, FLOAT),
    ConvertiblePair(CHARACTER, BIG_INTEGER),
    ConvertiblePair(CHARACTER, BIG_DECIMAL),
    ConvertiblePair(CHARACTER, CHARACTER),
    ConvertiblePair(CHARACTER, Class<Short>(null, PackageNames.LANG)),
    ConvertiblePair(CHARACTER, Class<Double>(null, PackageNames.LANG)),
    ConvertiblePair(CHARACTER, BOOLEAN),
    ConvertiblePair(CHARACTER, BIG_INT),
    ConvertiblePair(CHARACTER, BOOL),
  };

  @override
  Object? convert<T>(Object? source, Class sourceType, Class targetType) {
    if (source == null) return null;

    final charValue = (source as Character).toString();
    final intValue = int.tryParse(charValue) ?? (charValue.isNotEmpty ? charValue.codeUnitAt(0) : 0);

    try {
      return switch (targetType.getType()) {
        const (int) => intValue,
        const (double) => intValue.toDouble(),
        const (num) => intValue,
        const (String) => charValue,
        const (Integer) => Integer.valueOf(intValue),
        const (Long) => Long.valueOf(intValue),
        const (Float) => Float.valueOf(intValue.toDouble()),
        const (BigInteger) => BigInteger.fromInt(intValue),
        const (BigDecimal) => BigDecimal.fromInt(intValue),
        const (Character) => Character.valueOf(charValue),
        const (Short) => Short.valueOf(intValue),
        const (Double) => Double.valueOf(intValue.toDouble()),
        const (Boolean) => Boolean.valueOf(intValue != 0),
        const (BigInt) => BigInt.from(intValue),
        const (bool) => intValue != 0,
        _ => charValue,
      };
    } catch (e) {
      throw ConversionFailedException(sourceType: sourceType, targetType: targetType, value: source, point: e);
    }
  }
}

// ========================================= RUNES CONVERTER ==============================================

/// {@template string_to_runes_converter}
/// A [Converter] that converts a [String] to a [Runes].
///
/// Example:
/// ```dart
/// final converter = StringToRunesConverter();
/// print(converter.convert('hello')); // prints: Runes(104, 101, 108, 108, 111)
/// ```
/// {@endtemplate}
class StringToRunesConverter extends CommonConverter<String, Runes> {
  /// {@macro string_to_runes_converter}
  @override
  Runes convert(String source) {
    return source.runes;
  }
}

/// {@template runes_to_string_converter}
/// A [Converter] that converts a [Runes] to a [String].
///
/// Example:
/// ```dart
/// final converter = RunesToStringConverter();
/// print(converter.convert(Runes(104, 101, 108, 108, 111))); // prints: "hello"
/// ```
/// {@endtemplate}
class RunesToStringConverter extends CommonConverter<Runes, String> {
  /// {@macro runes_to_string_converter}
  @override
  String convert(Runes source) {
    return String.fromCharCodes(source);
  }
}

/// {@template iterable_int_to_string_converter}
/// Workaround converter for [Iterable<int>] to [String].
///
/// jetleaf_lang's [Runes.getClass()] returns [Class<Iterable<int>>] due to
/// type erasure, so the [RunesToStringConverter] registered for `(Runes, String)`
/// is never found. This converter handles the erasured type by delegating to
/// [String.fromCharCodes].
/// {@endtemplate}
class IterableIntToStringConverter extends CommonConverter<Iterable<int>, String> {
  /// {@macro iterable_int_to_string_converter}
  @override
  String convert(Iterable<int> source) {
    return String.fromCharCodes(source);
  }
}

// ========================================= SYMBOL CONVERTER ==============================================

/// {@template string_to_symbol_converter}
/// A [Converter] that converts a [String] to a [Symbol].
///
/// Example:
/// ```dart
/// final converter = StringToSymbolConverter();
/// print(converter.convert('hello')); // prints: Symbol("hello")
/// ```
/// {@endtemplate}
class StringToSymbolConverter extends CommonConverter<String, Symbol> {
  /// {@macro string_to_symbol_converter}
  @override
  Symbol convert(String source) {
    return Symbol(source);
  }
}

/// {@template symbol_to_string_converter}
/// A [Converter] that converts a [Symbol] to a [String].
///
/// Example:
/// ```dart
/// final converter = SymbolToStringConverter();
/// print(converter.convert(Symbol("hello"))); // prints: "hello"
/// ```
/// {@endtemplate}
class SymbolToStringConverter extends CommonConverter<Symbol, String> {
  /// {@macro symbol_to_string_converter}
  @override
  String convert(Symbol source) {
    return source.toString().replaceAll('Symbol("', '').replaceAll('")', '');
  }
}

// ========================================= URI Converters =========================================

/// {@template string_to_uri_converter}
/// A [Converter] that converts a [String] to a [Uri].
///
/// Example:
/// ```dart
/// final converter = StringToUriConverter();
/// print(converter.convert('https://example.com')); // prints: Uri.parse('https://example.com')
/// ```
/// {@endtemplate}
class StringToUriConverter extends CommonConverter<String, Uri> {
  /// List of validators for this converter
  final List<UriValidator> validators;

  /// {@macro string_to_uri_converter}
  StringToUriConverter(this.validators);

  @override
  Uri convert(String source) {
    final uri = Uri.tryParse(source);
    if (uri == null) {
      throw ConversionFailedException(
        sourceType: Class.forType(String),
        targetType: Class.forType(Uri),
        value: source,
        point: ConversionException("Invalid URI")
      );
    } else if (validators.any((validator) => !validator.isValid(uri))) {
      throw ConversionFailedException(
        sourceType: Class.forType(String),
        targetType: Class.forType(Uri),
        value: source,
        point: ConversionException(validators.where((validator) => !validator.isValid(uri)).map((validator) => validator.errorMessage).join(', '))
      );
    }

    return uri;
  }
}

/// {@template uri_to_string_converter}
/// A [Converter] that converts a [Uri] to a [String].
///
/// Example:
/// ```dart
/// final converter = UriToStringConverter();
/// print(converter.convert(Uri.parse('https://example.com'))); // prints: 'https://example.com'
/// ```
/// {@endtemplate}
class UriToStringConverter extends CommonConverter<Uri, String> {
  /// {@macro uri_to_string_converter}
  @override
  String convert(Uri source) {
    return source.toString();
  }
}

// ============================================ RegExp Converters ==========================================

/// {@template string_to_reg_exp_converter}
/// A [Converter] that converts a [String] to a [RegExp].
///
/// Example:
/// ```dart
/// final converter = StringToRegExpConverter();
/// print(converter.convert('hello')); // prints: RegExp('hello')
/// ```
/// {@endtemplate}
class StringToRegExpConverter extends CommonConverter<String, RegExp> {
  /// {@macro string_to_reg_exp_converter}
  @override
  RegExp convert(String source) {
    try {
      return RegExp(source);
    } catch (e) {
      throw ConversionFailedException(sourceType: Class.forType(String), targetType: Class.forType(RegExp), value: source, point: e);
    }
  }
}

/// {@template reg_exp_to_string_converter}
/// A [Converter] that converts a [RegExp] to a [String].
///
/// Example:
/// ```dart
/// final converter = RegExpToStringConverter();
/// print(converter.convert(RegExp('hello'))); // prints: 'hello'
/// ```
/// {@endtemplate}
class RegExpToStringConverter extends CommonConverter<RegExp, String> {
  /// {@macro reg_exp_to_string_converter}
  @override
  String convert(RegExp source) {
    return source.pattern;
  }
}

/// {@template string_to_pattern_converter}
/// A [Converter] that converts a [String] to a [Pattern].
///
/// Creates a RegExp pattern from the string.
///
/// Example:
/// ```dart
/// final converter = StringToPatternConverter();
/// print(converter.convert(r'\d+')); // prints: RegExp(r'\d+')
/// ```
/// {@endtemplate}
class StringToPatternConverter extends CommonConverter<String, Pattern> {
  /// {@macro string_to_pattern_converter}
  @override
  Pattern convert(String source) {
    return RegExp(source);
  }
}

/// {@template pattern_to_string_converter}
/// A [Converter] that converts a [Pattern] to a [String].
///
/// Example:
/// ```dart
/// final converter = PatternToStringConverter();
/// print(converter.convert(RegExp('hello'))); // prints: 'hello'
/// ```
/// {@endtemplate}
class PatternToStringConverter extends CommonConverter<Pattern, String> {
  @override
  String convert(Pattern source) {
    return source.toString();
  }
}

// ============================================ ENUM CONVERTER ==============================================

/// {@template string_to_enum_converter_factory}
/// A [ConverterFactory] that provides converters to convert strings to enums.
///
/// This factory dynamically returns a converter that transforms
/// a [String] value to a specific enum type at runtime.
///
/// Example:
/// ```dart
/// final factory = StringToEnumConverterFactory();
/// final converter = factory.getConverter<Enum>(Class.forType(Enum));
///
/// print(converter?.convert('value')); // prints: Enum.value
/// ```
/// {@endtemplate}
class StringToEnumConverterFactory extends CommonConverterFactory<String, Enum> {
  /// {@macro string_to_enum_converter_factory}
  @override
  Converter<String, T>? getConverter<T>(Class<T> targetType) {
    return _StringToEnumConverter<T>(targetType);
  }
}

/// {@template string_to_enum_converter}
/// A [Converter] that converts a [String] to an [Enum].
///
/// Example:
/// ```dart
/// final converter = StringToEnumConverter();
/// print(converter.convert('value')); // prints: Enum.value
/// ```
/// {@endtemplate}
@Generic(_StringToEnumConverter)
class _StringToEnumConverter<T> extends CommonConverter<String, T> {
  /// The target enum type to convert into.
  final Class<T> _targetType;

  /// {@macro string_to_enum_converter}
  _StringToEnumConverter(this._targetType);

  @override
  T convert(String source) {
    final result = _targetType.getEnumValues().find((e) => e.getName() == source);
    if (result != null) {
      return result.getValue() as T;
    }
    
    throw ConversionFailedException(sourceType: Class.forType(String), targetType: _targetType, value: source);
  }
}

/// {@template enum_to_string_converter}
/// A [Converter] that converts an [Enum] to a [String].
///
/// Example:
/// ```dart
/// final converter = EnumToStringConverter();
/// print(converter.convert(Enum.value)); // prints: "value"
/// ```
/// {@endtemplate}
class EnumToStringConverter extends CommonConverter<Enum, String> {
  /// {@macro enum_to_string_converter}
  @override
  String convert(Enum source) {
    return source.name;
  }
}

/// {@template int_to_enum_converter_factory}
/// A [ConverterFactory] that provides converters to convert integers to enums.
///
/// This factory dynamically returns a converter that transforms
/// an [int] value to a specific enum type at runtime.
///
/// Example:
/// ```dart
/// final factory = IntToEnumConverterFactory();
/// final converter = factory.getConverter<Enum>(Class.forType(Enum));
///
/// print(converter?.convert(0)); // prints: Enum.value
/// ```
/// {@endtemplate}
class IntToEnumConverterFactory extends CommonConverterFactory<int, Enum> {
  /// {@macro int_to_enum_converter_factory}
  @override
  Converter<int, T>? getConverter<T>(Class<T> targetType) {
    return _IntToEnumConverter<T>(targetType);
  }
}

/// {@template int_to_enum_converter}
/// A [Converter] that converts an [int] to an [Enum].
///
/// Example:
/// ```dart
/// final converter = IntToEnumConverter();
/// print(converter.convert(0)); // prints: Enum.value
/// ```
/// {@endtemplate}
@Generic(_IntToEnumConverter)
class _IntToEnumConverter<T> extends CommonConverter<int, T> {
  /// The target enum type to convert into.
  final Class<T> _targetType;

  /// {@macro int_to_enum_converter}
  _IntToEnumConverter(this._targetType);

  @override
  T convert(int source) {
    if(_targetType.isEnum()) {
      final result = _targetType.getEnumValues().find((e) => e.getPosition() == source);
      if(result != null) {
        return result.getValue() as T;
      }
    }
    throw ConversionFailedException(
      sourceType: Class.forType(int),
      targetType: _targetType,
      value: source,
      point: UnsupportedError('Direct enum conversion from int by index failed.')
    );
  }
}

/// {@template enum_to_int_converter}
/// A [Converter] that converts an [Enum] to an [int].
///
/// Example:
/// ```dart
/// final converter = EnumToIntConverter();
/// print(converter.convert(Enum.value)); // prints: 0
/// ```
/// {@endtemplate}
class EnumToIntConverter extends CommonConverter<Enum, int> {
  /// {@macro enum_to_int_converter}
  @override
  int convert(Enum source) {
    return source.index;
  }
}