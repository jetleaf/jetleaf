import '../exceptions.dart';

/// {@template double}
/// A wrapper class for [double] that provides Java-like functionality and methods.
/// 
/// This class wraps Dart's primitive [double] type and provides additional utility methods
/// similar to Java's Double class.
/// 
/// Example usage:
/// ```dart
/// Double a = Double(3.14);
/// Double b = Double.valueOf(2.71);
/// Double c = Double.parseDouble("1.618");
/// 
/// print(a.toString()); // "3.14"
/// print(a.compareTo(b)); // 1 (since 3.14 > 2.71)
/// ```
/// 
/// {@endtemplate}
class Double implements Comparable<Double> {
  /// The wrapped double value
  final double _value;

  /// Maximum finite value for a double
  static const double MAX_VALUE = double.maxFinite;
  
  /// Minimum positive normal value for a double
  static const double MIN_VALUE = double.minPositive;
  
  /// Positive infinity
  static const double POSITIVE_INFINITY = double.infinity;
  
  /// Negative infinity
  static const double NEGATIVE_INFINITY = double.negativeInfinity;
  
  /// Not-a-Number value
  static const double NaN = double.nan;

  /// Creates a Double with the specified value.
  /// 
  /// [value] the double value to wrap
  /// 
  /// {@macro double}
  const Double(this._value);

  /// Returns the wrapped double value.
  double get value => _value;

  /// Parses a string to a Double.
  /// 
  /// [str] the string to parse
  /// 
  /// Throws [InvalidFormatException] if the string cannot be parsed.
  /// 
  /// Example:
  /// ```dart
  /// Double a = Double.parseDouble("3.14");
  /// Double b = Double.parseDouble("1.23e-4");
  /// ```
  /// 
  /// {@macro double}
  static Double parseDouble(String str) {
    try {
      return Double(double.parse(str));
    } catch (e) {
      throw InvalidFormatException('Invalid double value: $str');
    }
  }

  /// Returns a Double instance representing the specified double value.
  /// 
  /// [value] the double value
  /// 
  /// {@macro double}
  static Double valueOf(double value) {
    return Double(value);
  }

  /// Returns a Double instance from a string.
  /// 
  /// [str] the string representation
  /// 
  /// {@macro double}
  static Double valueOfString(String str) {
    return parseDouble(str);
  }

  /// Returns the larger of two double values.
  /// 
  /// [a] first value
  /// [b] second value
  static double max(double a, double b) => a > b ? a : b;

  /// Returns the smaller of two double values.
  /// 
  /// [a] first value
  /// [b] second value
  static double min(double a, double b) => a < b ? a : b;

  /// Returns true if the value is NaN.
  bool get isNaN => _value.isNaN;

  /// Returns true if the value is infinite.
  bool get isInfinite => _value.isInfinite;

  /// Returns true if the value is finite.
  bool get isFinite => _value.isFinite;

  /// Returns true if the value is negative.
  bool get isNegative => _value.isNegative;

  /// Returns the absolute value of this Double.
  Double abs() => Double(_value.abs());

  /// Returns the ceiling of this Double.
  Double ceil() => Double(_value.ceilToDouble());

  /// Returns the floor of this Double.
  Double floor() => Double(_value.floorToDouble());

  /// Rounds this Double to the nearest integer.
  Double round() => Double(_value.roundToDouble());

  /// Truncates this Double to an integer.
  Double truncate() => Double(_value.truncateToDouble());

  /// Compares this Double with another Double.
  /// 
  /// Returns:
  /// - negative value if this < other
  /// - zero if this == other
  /// - positive value if this > other
  @override
  int compareTo(Double other) => _value.compareTo(other._value);

  /// Returns true if this Double equals the specified object.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Double && _value == other._value;
  }

  /// Returns the hash code for this Double.
  @override
  int get hashCode => _value.hashCode;

  /// Returns a string representation of this Double.
  @override
  String toString() => _value.toString();

  /// Returns the value as an int (truncated).
  int toInt() => _value.toInt();

  /// Arithmetic operators
  Double operator +(Double other) => Double(_value + other._value);
  Double operator -(Double other) => Double(_value - other._value);
  Double operator *(Double other) => Double(_value * other._value);
  Double operator /(Double other) => Double(_value / other._value);
  Double operator %(Double other) => Double(_value % other._value);
  Double operator -() => Double(-_value);

  /// Comparison operators
  bool operator <(Double other) => _value < other._value;
  bool operator <=(Double other) => _value <= other._value;
  bool operator >(Double other) => _value > other._value;
  bool operator >=(Double other) => _value >= other._value;
}