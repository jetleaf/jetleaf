import '../byte/byte.dart';
import '../exceptions.dart';
import '../extensions/primitives/iterable.dart';
import '../math/big_decimal.dart';
import '../math/big_integer.dart';
import '../meta/class/class.dart';
import '../primitives/double.dart';
import '../primitives/float.dart';
import '../primitives/integer.dart';
import '../primitives/long.dart';
import '../primitives/short.dart';

/// {@template number_utils}
/// An administrative utilities toolkit providing type-safe conversions, numerical downcasting safety, 
/// boundary overflow assertions, and contextual string radix decoding across standard platform primitives and custom object-wrapped types.
///
/// `NumberUtils` bridges the gap between primitive scalar values (`int`, `double`, `num`), standard platform structures (`BigInt`), 
/// and custom enterprise value objects designed to mimic precise memory footprints (`Byte`, `Short`, `Integer`, `Long`, `Float`, `Double`, `BigInteger`, `BigDecimal`).
///
/// ### Core Architectural Operations
/// 1. **Target-Class Scaling Protection:** Safely converts arbitrary numbers into a target class type ([convertNumberToTargetClass]). 
///    It tracks bit boundaries for narrowing transformations (e.g., converting a large `int` to a `Byte`), throwing descriptive exceptions 
///    on out-of-bounds data overflows instead of silently truncating data bits.
/// 2. **Contextual Text Radix Tokenization:** Scans, sanitizes, and parses complex textual notation variants ([parseNumber]). 
///    It automatically detects octal prefixes (`0`), standard hexadecimal identifiers (`0x`, `0X`, `#`), and directional sign markers (`-`).
/// 
/// ### Thread-Safety and Operational State
/// This utility class is marked as `abstract final` to prohibit initialization and inheritance patterns. 
/// All functions are pure, stateless algorithms operating entirely over passed parameter stacks, ensuring optimal safety across parallel stream pools.
/// {@endtemplate}
abstract final class NumberUtils {
  /// An immutable registry mapping containing all valid numeric classes participating within this configuration subsystem context.
  static final Set<Class> STANDARD_NUMBER_TYPES = {
    Class<Byte>(),
    Class<Short>(),
    Class<Integer>(),
    Class<Long>(),
    Class<BigInteger>(),
    Class<Float>(),
    Class<Double>(),
    Class<BigDecimal>(),
    Class<int>(),
    Class<num>(),
    Class<double>(),
    Class<BigInt>(),
  };

  /// Translates a runtime primitive [number] instance into the specified [targetClass] envelope, applying strict boundary validation guards.
  ///
  /// ### Narrowing and Overflow Verification Laws
  /// When downcasting values into fixed bit-width architectures (`Byte` [8-bit], `Short` [16-bit], `Integer` [32-bit]), 
  /// this method performs pre-allocation boundary checks against the signed limits of the targeted type. If the input exceeds these thresholds, 
  /// it throws an [IllegalArgumentException] to prevent silent wrap-around corruptions.
  ///
  /// ### Parameters
  /// - [number]: The active numeric primitive context instance carrying the runtime scalar value.
  /// - [targetClass]: The reflective type token mirror pinpointing the destination execution architecture.
  /// 
  /// ### Failures & Boundary Safety
  /// * Throws an [IllegalArgumentException] if [targetClass] is omitted from the [STANDARD_NUMBER_TYPES] compatibility matrix.
  /// * Throws an [IllegalArgumentException] if the numeric value exceeds the physical data limits of the target container class.
  ///
  /// ### Architecture Example
  /// ```dart
  /// // Precise narrowing transformation with validation guard active
  /// final int largeScalar = 42;
  /// final Byte smallByte = NumberUtils.convertNumberToTargetClass(largeScalar, Class<Byte>());
  /// print(smallByte.toInt()); // 42
  /// 
  /// // Triggers validation fallback exception safely instead of wrap-around bit corruption
  /// NumberUtils.convertNumberToTargetClass(300, Class<Byte>()); // Throws IllegalArgumentException: overflow
  /// ```
  static T convertNumberToTargetClass<T extends Comparable<T>>(num number, Class<T> targetClass) {
    if (STANDARD_NUMBER_TYPES.noneMatch((value) => value.getPackageUri() == targetClass.getPackageUri())) {
      throw IllegalArgumentException(
        'Could not convert number [$number] of type [${number.runtimeType}] '
        'to unsupported target class [$targetClass]',
      );
    }

    if (targetClass.isInstance(number)) {
      return number as T;
    }

    if (Class<Byte>() == targetClass) {
      final value = _checkedLongValue(number, targetClass);
      if (value < -128 || value > 127) {
        _raiseOverflowException(number, targetClass);
      }
      return Byte(value.toInt()) as T;
    }

    if (Class<Short>() == targetClass) {
      final value = _checkedLongValue(number, targetClass);
      if (value < Short.MIN_VALUE || value > Short.MAX_VALUE) {
        _raiseOverflowException(number, targetClass);
      }
      return Short(value.toInt()) as T;
    }

    if (Class<Integer>() == targetClass) {
      final value = _checkedLongValue(number, targetClass);
      if (value < Integer.MIN_VALUE || value > Integer.MAX_VALUE) {
        _raiseOverflowException(number, targetClass);
      }
      return Integer(value.toInt()) as T;
    }

    if (Class<Long>() == targetClass) {
      final value = _checkedLongValue(number, targetClass);
      return Long(value.toInt()) as T;
    }

    if (Class<BigInteger>() == targetClass) {
      return _toBigInteger(number) as T;
    }

    if (Class<Float>() == targetClass) {
      return Float(number.toDouble()) as T;
    }

    if (Class<Double>() == targetClass) {
      return Double(number.toDouble()) as T;
    }

    if (Class<BigDecimal>() == targetClass) {
      return BigDecimal(number.toString()) as T;
    }

    if (Class<int>() == targetClass) {
      return number.toInt() as T;
    }

    if (Class<double>() == targetClass) {
      return number.toDouble() as T;
    }

    if (Class<num>() == targetClass) {
      return number as T;
    }

    if (Class<BigInt>() == targetClass) {
      return _toBigInt(number) as T;
    }

    throw IllegalArgumentException(
      'Could not convert number [$number] of type [${number.runtimeType}] '
      'to unsupported target class [$targetClass]',
    );
  }

  /// Tokenizes, sanitizes, and decodes an unstructured [text] payload directly into a validated instance of [targetClass].
  ///
  /// This method strips layout characters and handles octal, decimal, and hexadecimal representations dynamically.
  ///
  /// ### Text Processing Stages
  /// 1. **Whitespace Elimination:** All interior layout tokens, tabs, spaces, and newline sequences are stripped via [_trimAllWhitespace].
  /// 2. **Radix Identification:** The sanitized string is examined for base prefixes via [_isHexNumber] or octal tokens.
  /// 3. **Prefix Slicing & Extraction:** Standard markers (`0x`, `0X`, `#`) are stripped before parsing to resolve core values.
  ///
  /// ### Parameters
  /// - [text]: The raw incoming alphanumeric input block to decode.
  /// - [targetClass]: The reflective type token mirror specifying the destination numerical standard.
  ///
  /// ### Failures & State Handling
  /// Throws an [IllegalArgumentException] if the [text] string is malformed or violates the formatting constraints of the destination type.
  ///
  /// ### Architecture Example
  /// ```dart
  /// final Integer parsedHex = NumberUtils.parseNumber(" 0x7F ", Class<Integer>());
  /// print(parsedHex.toInt()); // 127
  /// 
  /// final BigInt parsedHash = NumberUtils.parseNumber("-#FF", Class<BigInt>());
  /// print(parsedHash); // -255
  /// ```
  static T parseNumber<T extends Comparable<T>>(String text, Class<T> targetClass) {
    if (STANDARD_NUMBER_TYPES.noneMatch((value) => value.getPackageUri() == targetClass.getPackageUri())) {
      throw IllegalArgumentException('Cannot convert String [$text] to target class [$targetClass]');
    }

    final trimmed = _trimAllWhitespace(text);

    if (Class<Byte>() == targetClass) {
      return Byte.parseByte(_stripPrefix(trimmed, 16), _isHexNumber(trimmed) ? 16 : 10) as T;
    }

    if (Class<Short>() == targetClass) {
      return Short.parseShort(_stripPrefix(trimmed, 16), _isHexNumber(trimmed) ? 16 : 10) as T;
    }

    if (Class<Integer>() == targetClass) {
      return Integer.parseInt(_stripPrefix(trimmed, 16), _isHexNumber(trimmed) ? 16 : 10) as T;
    }

    if (Class<Long>() == targetClass) {
      return Long.parseLong(_stripPrefix(trimmed, 16), _isHexNumber(trimmed) ? 16 : 10) as T;
    }

    if (Class<BigInteger>() == targetClass) {
      return _decodeBigInteger(trimmed) as T;
    }

    if (Class<Float>() == targetClass) {
      return Float(double.parse(trimmed)) as T;
    }

    if (Class<Double>() == targetClass) {
      return Double(double.parse(trimmed)) as T;
    }

    if (Class<BigDecimal>() == targetClass) {
      return BigDecimal(trimmed) as T;
    }

    if (Class<int>() == targetClass) {
      return int.parse(trimmed) as T;
    }

    if (Class<double>() == targetClass) {
      return double.parse(trimmed) as T;
    }

    if (Class<num>() == targetClass) {
      return num.parse(trimmed) as T;
    }

    if (Class<BigInt>() == targetClass) {
      return _isHexNumber(trimmed) ? _decodeBigIntHex(trimmed) as T : BigInt.parse(trimmed) as T;
    }

    throw IllegalArgumentException('Cannot convert String [$text] to target class [$targetClass]');
  }

  /// Internal algorithmic scanner tracking standard hexadecimal structural notation frameworks.
  /// 
  /// Checks for prefixes like `0x`, `0X`, or `#`, accounting for leading negative sign markers.
  static bool _isHexNumber(String value) {
    final index = value.startsWith('-') ? 1 : 0;
    return value.startsWith('0x', index) ||
        value.startsWith('0X', index) ||
        value.startsWith('#', index);
  }

  /// Strips formatting tokens out of alphanumeric text records during processing loops.
  static String _stripPrefix(String value, int radix) {
    if (radix != 16) return value;
    final index = value.startsWith('-') ? 1 : 0;
    if (value.startsWith('0x', index) || value.startsWith('0X', index)) {
      return '${value.substring(0, index)}${value.substring(index + 2)}';
    }
    if (value.startsWith('#', index)) {
      return '${value.substring(0, index)}${value.substring(index + 1)}';
    }
    return value;
  }

  /// Parses non-standard data types to extract and build structural [BigInteger] frames.
  /// 
  /// Manages signs, tracks leading markers, and supports base-8 (octal), base-10 (decimal), and base-16 (hexadecimal) strings.
  static BigInteger _decodeBigInteger(String value) {
    int radix = 10;
    int index = 0;
    bool negative = false;

    if (value.startsWith('-')) {
      negative = true;
      index++;
    }

    if (value.startsWith('0x', index) || value.startsWith('0X', index)) {
      index += 2;
      radix = 16;
    } else if (value.startsWith('#', index)) {
      index++;
      radix = 16;
    } else if (value.startsWith('0', index) && value.length > 1 + index) {
      index++;
      radix = 8;
    }

    final result = BigInteger(value.substring(index), radix);
    return negative ? -result : result;
  }

  /// Specialized internal hex utility mapping raw string characters directly into [BigInt] targets.
  static BigInt _decodeBigIntHex(String value) {
    int index = 0;
    bool negative = false;

    if (value.startsWith('-')) {
      negative = true;
      index++;
    }

    if (value.startsWith('0x', index) || value.startsWith('0X', index)) {
      index += 2;
    } else if (value.startsWith('#', index)) {
      index++;
    }

    final result = BigInt.parse(value.substring(index), radix: 16);
    return negative ? -result : result;
  }

  /// Safe conversion pipeline isolating and generating [BigInteger] representations out of polymorphic input variants.
  static BigInteger _toBigInteger(dynamic number) {
    if (number is BigInteger) return number;
    if (number is BigDecimal) {
      final scaled = number.setScale(0);
      return BigInteger.fromBigInt(scaled.unscaledValue);
    }
    return BigInteger.fromInt((number as num).toInt());
  }

  /// Safe conversion pipeline isolating and generating standard platform [BigInt] allocations out of polymorphic inputs.
  static BigInt _toBigInt(dynamic number) {
    if (number is BigDecimal) {
      final scaled = number.setScale(0);
      return scaled.unscaledValue;
    }
    return BigInt.from((number as num).toInt());
  }

  /// Pass-through hook reserved for runtime scaling verification routines.
  static num _checkedLongValue(num number, dynamic targetClass) {
    return number;
  }

  /// Shuts down execution pipelines when discovering data narrowing overflows.
  static Never _raiseOverflowException(num number, dynamic targetClass) {
    throw IllegalArgumentException(
      'Could not convert number [$number] of type [${number.runtimeType}] '
      'to target class [$targetClass]: overflow',
    );
  }

  /// Strips layout whitespaces, spaces, tabs, and carriage returns via low-level character code screening loops.
  static String _trimAllWhitespace(String text) {
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      final ch = text.codeUnitAt(i);
      // Validate character points match space (0x20), horizontal tab (0x09), line feed (0x0A), or carriage return (0x0D)
      if (ch != 0x20 && ch != 0x09 && ch != 0x0A && ch != 0x0D) {
        buffer.writeCharCode(ch);
      }
    }
    return buffer.toString();
  }
}