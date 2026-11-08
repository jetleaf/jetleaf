import '../exceptions.dart';

/// {@template float}
/// A wrapper class for single-precision floating point numbers.
/// 
/// This class wraps Dart's [double] type but represents it as a single-precision float,
/// similar to Java's Float class.
/// 
/// Example usage:
/// ```dart
/// Float a = Float(3.14);
/// Float b = Float.valueOf(2.71);
/// Float c = Float.parseFloat("1.618");
/// 
/// print(a.toString()); // "3.14"
/// print(a.compareTo(b)); // 1
/// ```
/// 
/// {@endtemplate}
class Float implements Comparable<Float> {
  /// The wrapped float value (stored as double in Dart)
  final double _value;

  /// Maximum finite value for a float
  static const double MAX_VALUE = 3.4028235e+38;
  
  /// Minimum positive normal value for a float
  static const double MIN_VALUE = 1.4e-45;
  
  /// Positive infinity
  static const double POSITIVE_INFINITY = double.infinity;
  
  /// Negative infinity
  static const double NEGATIVE_INFINITY = double.negativeInfinity;
  
  /// Not-a-Number value
  static const double NaN = double.nan;

  /// Creates a Float with the specified value.
  /// 
  /// [value] the float value to wrap
  /// 
  /// {@macro float}
  const Float(this._value);

  /// Returns the wrapped float value.
  double get value => _value;

  /// Parses a string to a Float.
  /// 
  /// [str] the string to parse
  /// 
  /// Throws [InvalidFormatException] if the string cannot be parsed.
  /// 
  /// {@macro float}
  static Float parseFloat(String str) {
    try {
      return Float(double.parse(str));
    } catch (e) {
      throw InvalidFormatException('Invalid float value: $str');
    }
  }

  /// Returns a Float instance representing the specified double value.
  /// 
  /// [value] the float value
  /// 
  /// {@macro float}
  static Float valueOf(double value) {
    return Float(value);
  }

  /// Returns a Float instance from a string.
  /// 
  /// [str] the string representation
  /// 
  /// {@macro float}
  static Float valueOfString(String str) {
    return parseFloat(str);
  }

  /// Returns the larger of two double values.
  static double max(double a, double b) => a > b ? a : b;

  /// Returns the smaller of two double values.
  static double min(double a, double b) => a < b ? a : b;

  /// Returns true if the value is NaN.
  bool get isNaN => _value.isNaN;

  /// Returns true if the value is infinite.
  bool get isInfinite => _value.isInfinite;

  /// Returns true if the value is finite.
  bool get isFinite => _value.isFinite;

  /// Returns true if the value is negative.
  bool get isNegative => _value.isNegative;

  /// Returns the absolute value of this Float.
  Float abs() => Float(_value.abs());

  /// Returns the ceiling of this Float.
  Float ceil() => Float(_value.ceilToDouble());

  /// Returns the floor of this Float.
  Float floor() => Float(_value.floorToDouble());

  /// Rounds this Float to the nearest integer.
  Float round() => Float(_value.roundToDouble());

  /// Truncates this Float to an integer.
  Float truncate() => Float(_value.truncateToDouble());

  /// Compares this Float with another Float.
  @override
  int compareTo(Float other) => _value.compareTo(other._value);

  /// Returns true if this Float equals the specified object.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Float && _value == other._value;
  }

  /// Returns the hash code for this Float.
  @override
  int get hashCode => _value.hashCode;

  /// Returns a string representation of this Float.
  @override
  String toString() => _value.toString();

  /// Returns the value as an int (truncated).
  int toInt() => _value.toInt();

  /// Arithmetic operators
  Float operator +(Float other) => Float(_value + other._value);
  Float operator -(Float other) => Float(_value - other._value);
  Float operator *(Float other) => Float(_value * other._value);
  Float operator /(Float other) => Float(_value / other._value);
  Float operator %(Float other) => Float(_value % other._value);
  Float operator -() => Float(-_value);

  /// Comparison operators
  bool operator <(Float other) => _value < other._value;
  bool operator <=(Float other) => _value <= other._value;
  bool operator >(Float other) => _value > other._value;
  bool operator >=(Float other) => _value >= other._value;
}