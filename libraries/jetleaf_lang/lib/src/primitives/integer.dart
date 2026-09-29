/// {@template integer}
/// A wrapper class for [int] that provides Java-like functionality and methods.
/// 
/// This class wraps Dart's primitive [int] type and provides additional utility methods
/// similar to Java's Integer class, making it easier for Java developers to work with
/// integers in Dart.
/// 
/// Example usage:
/// ```dart
/// Integer a = Integer(42);
/// Integer b = Integer.valueOf(10);
/// Integer c = Integer.parseInt("123");
/// 
/// print(a.toString()); // "42"
/// print(a.compareTo(b)); // 1 (since 42 > 10)
/// print(Integer.max(a.value, b.value)); // 42
/// ```
/// 
/// {@endtemplate}
class Integer implements Comparable<Integer> {
  /// The wrapped integer value
  final int _value;

  /// Maximum value for a 32-bit signed integer
  static const int MAX_VALUE = 2147483647;
  
  /// Minimum value for a 32-bit signed integer
  static const int MIN_VALUE = -2147483648;

  /// Creates an Integer with the specified value.
  /// 
  /// [value] the integer value to wrap
  /// 
  /// {@macro integer}
  const Integer(this._value);

  /// Returns the wrapped integer value.
  int get value => _value;

  /// Creates an Integer from a string representation.
  /// 
  /// [str] the string to parse
  /// [radix] the radix to use for parsing (default is 10)
  /// 
  /// Throws [InvalidFormatException] if the string cannot be parsed.
  /// 
  /// Example:
  /// ```dart
  /// Integer a = Integer.parseInt("42");
  /// Integer b = Integer.parseInt("1010", 2); // binary
  /// Integer c = Integer.parseInt("FF", 16); // hexadecimal
  /// ```
  /// 
  /// {@macro integer}
  static Integer parseInt(String str, [int radix = 10]) {
    return Integer(int.parse(str, radix: radix));
  }

  /// Returns an Integer instance representing the specified int value.
  /// 
  /// [value] the integer value
  /// 
  /// Example:
  /// ```dart
  /// Integer a = Integer.valueOf(42);
  /// ```
  /// 
  /// {@macro integer}
  static Integer valueOf(int value) {
    return Integer(value);
  }

  /// Returns an Integer instance from a string.
  /// 
  /// [str] the string representation
  /// [radix] the radix to use for parsing (default is 10)
  /// 
  /// {@macro integer}
  static Integer valueOfString(String str, [int radix = 10]) {
    return parseInt(str, radix);
  }

  /// Returns the larger of two int values.
  /// 
  /// [a] first value
  /// [b] second value
  static int max(int a, int b) => a > b ? a : b;

  /// Returns the smaller of two int values.
  /// 
  /// [a] first value
  /// [b] second value
  static int min(int a, int b) => a < b ? a : b;

  /// Returns the absolute value of this Integer.
  /// 
  /// Example:
  /// ```dart
  /// Integer a = Integer(-42);
  /// print(a.abs().value); // 42
  /// ```
  Integer abs() => Integer(_value.abs());

  /// Compares this Integer with another Integer.
  /// 
  /// Returns:
  /// - negative value if this < other
  /// - zero if this == other  
  /// - positive value if this > other
  @override
  int compareTo(Integer other) => _value.compareTo(other._value);

  /// Returns true if this Integer equals the specified object.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Integer && _value == other._value;
  }

  /// Returns the hash code for this Integer.
  @override
  int get hashCode => _value.hashCode;

  /// Returns a string representation of this Integer.
  @override
  String toString() => _value.toString();

  /// Returns a string representation in the specified radix.
  /// 
  /// [radix] the radix to use (2-36)
  /// 
  /// Example:
  /// ```dart
  /// Integer a = Integer(42);
  /// print(a.toString(2)); // "101010" (binary)
  /// print(a.toString(16)); // "2a" (hexadecimal)
  /// ```
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
  Integer operator +(Integer other) => Integer(_value + other._value);
  Integer operator -(Integer other) => Integer(_value - other._value);
  Integer operator *(Integer other) => Integer(_value * other._value);
  Integer operator ~/(Integer other) => Integer(_value ~/ other._value);
  Integer operator %(Integer other) => Integer(_value % other._value);
  Integer operator -() => Integer(-_value);

  /// Comparison operators
  bool operator <(Integer other) => _value < other._value;
  bool operator <=(Integer other) => _value <= other._value;
  bool operator >(Integer other) => _value > other._value;
  bool operator >=(Integer other) => _value >= other._value;

  /// Bitwise operators
  Integer operator &(Integer other) => Integer(_value & other._value);
  Integer operator |(Integer other) => Integer(_value | other._value);
  Integer operator ^(Integer other) => Integer(_value ^ other._value);
  Integer operator ~() => Integer(~_value);
  Integer operator <<(int shiftAmount) => Integer(_value << shiftAmount);
  Integer operator >>(int shiftAmount) => Integer(_value >> shiftAmount);
}