import '../exceptions.dart';

/// {@template long}
/// A wrapper class for large integers that provides Java-like functionality.
/// 
/// This class wraps Dart's [int] type but is designed for large integer values,
/// similar to Java's Long class.
/// 
/// Example usage:
/// ```dart
/// Long a = Long(9223372036854775807);
/// Long b = Long.valueOf(1000000000000);
/// Long c = Long.parseLong("123456789012345");
/// 
/// print(a.toString()); // "9223372036854775807"
/// print(a.compareTo(b)); // 1
/// ```
/// 
/// {@endtemplate}
class Long implements Comparable<Long> {
  /// The wrapped long value
  final int _value;

  /// Maximum value for a 64-bit signed integer
  static const int MAX_VALUE = 9223372036854775807;
  
  /// Minimum value for a 64-bit signed integer
  static const int MIN_VALUE = -9223372036854775808;

  /// Creates a Long with the specified value.
  /// 
  /// [value] the long value to wrap
  /// 
  /// {@macro long}
  const Long(this._value);

  /// Returns the wrapped long value.
  int get value => _value;

  /// Parses a string to a Long.
  /// 
  /// [str] the string to parse
  /// [radix] the radix to use for parsing (default is 10)
  /// 
  /// Throws [InvalidFormatException] if the string cannot be parsed.
  /// 
  /// {@macro long}
  static Long parseLong(String str, [int radix = 10]) {
    try {
      return Long(int.parse(str, radix: radix));
    } catch (e) {
      throw InvalidFormatException('Invalid long value: $str');
    }
  }

  /// Returns a Long instance representing the specified int value.
  /// 
  /// [value] the long value
  /// 
  /// {@macro long}
  static Long valueOf(int value) {
    return Long(value);
  }

  /// Returns a Long instance from a string.
  /// 
  /// [str] the string representation
  /// [radix] the radix to use for parsing (default is 10)
  /// 
  /// {@macro long}
  static Long valueOfString(String str, [int radix = 10]) {
    return parseLong(str, radix);
  }

  /// Returns the larger of two int values.
  static int max(int a, int b) => a > b ? a : b;

  /// Returns the smaller of two int values.
  static int min(int a, int b) => a < b ? a : b;

  /// Returns the absolute value of this Long.
  Long abs() => Long(_value.abs());

  /// Compares this Long with another Long.
  @override
  int compareTo(Long other) => _value.compareTo(other._value);

  /// Returns true if this Long equals the specified object.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Long && _value == other._value;
  }

  /// Returns the hash code for this Long.
  @override
  int get hashCode => _value.hashCode;

  /// Returns a string representation of this Long.
  @override
  String toString() => _value.toString();

  /// Returns a string representation in the specified radix.
  String toRadixString([int? radix]) {
    if (radix == null) return _value.toString();
    return _value.toRadixString(radix);
  }

  /// Returns the value as a double.
  double toDouble() => _value.toDouble();

  /// Returns true if the value is even.
  bool get isEven => _value.isEven;

  /// Returns true if the value is odd.
  bool get isOdd => _value.isOdd;

  /// Returns true if the value is negative.
  bool get isNegative => _value.isNegative;

  /// Arithmetic operators
  Long operator +(Long other) => Long(_value + other._value);
  Long operator -(Long other) => Long(_value - other._value);
  Long operator *(Long other) => Long(_value * other._value);
  Long operator ~/(Long other) => Long(_value ~/ other._value);
  Long operator %(Long other) => Long(_value % other._value);
  Long operator -() => Long(-_value);

  /// Comparison operators
  bool operator <(Long other) => _value < other._value;
  bool operator <=(Long other) => _value <= other._value;
  bool operator >(Long other) => _value > other._value;
  bool operator >=(Long other) => _value >= other._value;

  /// Bitwise operators
  Long operator &(Long other) => Long(_value & other._value);
  Long operator |(Long other) => Long(_value | other._value);
  Long operator ^(Long other) => Long(_value ^ other._value);
  Long operator ~() => Long(~_value);
  Long operator <<(int shiftAmount) => Long(_value << shiftAmount);
  Long operator >>(int shiftAmount) => Long(_value >> shiftAmount);
}