import '../exceptions.dart';

/// {@template short}
/// A wrapper class for [int] representing a 16-bit signed integer.
/// 
/// This class wraps a short integer value and provides Java-like functionality
/// similar to Java's Short class.
/// 
/// Example usage:
/// ```dart
/// Short s1 = Short(32767);
/// Short s2 = Short.parseShort("1000");
/// Short s3 = Short.valueOf(-32768);
/// 
/// print(s1.toString()); // "32767"
/// print(s1.toUnsigned()); // 32767
/// ```
/// 
/// {@endtemplate}
class Short implements Comparable<Short> {
  /// The wrapped short value
  final int _value;

  /// Maximum value for a signed short
  static const int MAX_VALUE = 32767;
  
  /// Minimum value for a signed short
  static const int MIN_VALUE = -32768;

  /// Creates a Short with the specified value.
  /// 
  /// [value] the short value to wrap (must be between -32768 and 32767)
  /// 
  /// Throws [InvalidArgumentException] if value is outside short range.
  /// 
  /// {@macro short}
  Short(int value) : _value = _validateShortRange(value);

  /// Validates that the value is within short range
  static int _validateShortRange(int value) {
    if (value < MIN_VALUE || value > MAX_VALUE) {
      throw InvalidArgumentException('Short value must be between $MIN_VALUE and $MAX_VALUE, got: $value');
    }
    return value;
  }

  /// Returns the wrapped short value.
  int get value => _value;

  /// Parses a string to a Short.
  /// 
  /// [str] the string to parse
  /// [radix] the radix to use for parsing (default is 10)
  /// 
  /// {@macro short}
  static Short parseShort(String str, [int radix = 10]) {
    int parsed = int.parse(str, radix: radix);
    return Short(parsed);
  }

  /// Returns a Short instance representing the specified int value.
  /// 
  /// {@macro short}
  static Short valueOf(int value) {
    return Short(value);
  }

  /// Returns the unsigned representation of this short (0-65535).
  int toUnsigned() => _value < 0 ? _value + 65536 : _value;

  /// Returns the absolute value of this Short.
  Short abs() => Short(_value.abs());

  /// Compares this Short with another Short.
  @override
  int compareTo(Short other) => _value.compareTo(other._value);

  /// Returns true if this Short equals the specified object.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Short && _value == other._value;
  }

  /// Returns the hash code for this Short.
  @override
  int get hashCode => _value.hashCode;

  /// Returns a string representation of this Short.
  @override
  String toString() => _value.toString();

  /// Arithmetic and comparison operators
  Short operator +(Short other) => Short(_value + other._value);
  Short operator -(Short other) => Short(_value - other._value);
  Short operator *(Short other) => Short(_value * other._value);
  Short operator ~/(Short other) => Short(_value ~/ other._value);
  Short operator %(Short other) => Short(_value % other._value);
  Short operator -() => Short(-_value);

  bool operator <(Short other) => _value < other._value;
  bool operator <=(Short other) => _value <= other._value;
  bool operator >(Short other) => _value > other._value;
  bool operator >=(Short other) => _value >= other._value;
}