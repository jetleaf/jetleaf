import '../exceptions.dart';

/// {@template big_decimal}
/// A wrapper class for precise decimal arithmetic.
/// 
/// This class provides arbitrary precision decimal arithmetic similar to Java's BigDecimal.
/// It uses Dart's built-in support for arbitrary precision integers and implements
/// decimal arithmetic on top of it.
/// 
/// Example usage:
/// ```dart
/// BigDecimal a = BigDecimal("123.456");
/// BigDecimal b = BigDecimal("78.9");
/// BigDecimal sum = a + b;
/// 
/// print(sum.toString()); // "202.356"
/// print(sum.setScale(2)); // "202.36" (rounded)
/// ```
/// 
/// {@endtemplate}
class BigDecimal implements Comparable<BigDecimal> {
  /// The unscaled value (as BigInt)
  final BigInt _unscaledValue;
  
  /// The scale (number of digits after decimal point)
  final int _scale;

  /// Creates a BigDecimal with the specified unscaled value and scale.
  /// 
  /// [unscaledValue] the unscaled integer value
  /// [scale] the number of digits after the decimal point
  /// 
  /// {@macro big_decimal}
  const BigDecimal._(this._unscaledValue, this._scale);

  /// Creates a BigDecimal from a string representation.
  /// 
  /// [value] the string representation of the decimal number
  /// 
  /// {@macro big_decimal}
  factory BigDecimal(String value) {
    if (value.contains('.')) {
      List<String> parts = value.split('.');
      String integerPart = parts[0];
      String fractionalPart = parts[1];
      
      String unscaledStr = integerPart + fractionalPart;
      BigInt unscaled = BigInt.parse(unscaledStr);
      int scale = fractionalPart.length;
      
      return BigDecimal._(unscaled, scale);
    } else {
      return BigDecimal._(BigInt.parse(value), 0);
    }
  }

  /// Creates a BigDecimal from a double value.
  /// 
  /// [value] the double value
  /// 
  /// {@macro big_decimal}
  factory BigDecimal.fromDouble(double value) {
    return BigDecimal(value.toString());
  }

  /// Creates a BigDecimal from an integer value.
  /// 
  /// [value] the integer value
  /// 
  /// **Note:** This is equivalent to BigDecimal.fromDouble(value.toDouble()).
  /// ```dart
  /// BigDecimal a = BigDecimal.fromInt(42);
  /// print(a); // "42"
  /// ```
  /// 
  /// {@macro big_decimal}
  factory BigDecimal.fromInt(int value) {
    return BigDecimal._(BigInt.from(value), 0);
  }

  /// Returns the unscaled value as a BigInt.
  /// 
  /// [unscaledValue] the unscaled integer value
  BigInt get unscaledValue => _unscaledValue;

  /// Returns the scale (number of digits after decimal point).
  /// 
  /// [scale] the number of digits after the decimal point
  int get scale => _scale;

  /// Returns the precision (total number of digits).
  /// 
  /// [precision] the total number of digits
  int get precision => _unscaledValue.toString().replaceAll('-', '').length;

  /// Returns a BigDecimal with the specified scale.
  /// 
  /// [newScale] the desired scale
  /// 
  /// **Note:** This is equivalent to BigDecimal.fromDouble(this.toDouble().setScale(newScale)).
  /// ```dart
  /// BigDecimal a = BigDecimal.fromInt(42);
  /// BigDecimal b = a.setScale(2);
  /// print(b); // "42.00"
  /// ```
  BigDecimal setScale(int newScale) {
    if (newScale == _scale) return this;
    
    if (newScale > _scale) {
      // Increase scale by adding zeros
      int scaleDiff = newScale - _scale;
      BigInt newUnscaled = _unscaledValue * BigInt.from(10).pow(scaleDiff);
      return BigDecimal._(newUnscaled, newScale);
    } else {
      // Decrease scale by dividing and rounding
      int scaleDiff = _scale - newScale;
      BigInt divisor = BigInt.from(10).pow(scaleDiff);
      
      // Simple rounding (round half up)
      BigInt quotient = _unscaledValue ~/ divisor;
      BigInt remainder = _unscaledValue.remainder(divisor);
      BigInt halfDivisor = divisor ~/ BigInt.two;
      
      if (remainder.abs() >= halfDivisor) {
        quotient += _unscaledValue.isNegative ? BigInt.from(-1) : BigInt.one;
      }
      
      return BigDecimal._(quotient, newScale);
    }
  }

  /// Adds another BigDecimal to this one.
  BigDecimal operator +(BigDecimal other) {
    int maxScale = _scale > other._scale ? _scale : other._scale;
    BigDecimal a = setScale(maxScale);
    BigDecimal b = other.setScale(maxScale);
    
    BigInt result = a._unscaledValue + b._unscaledValue;
    return BigDecimal._(result, maxScale);
  }

  /// Subtracts another BigDecimal from this one.
  BigDecimal operator -(BigDecimal other) {
    int maxScale = _scale > other._scale ? _scale : other._scale;
    BigDecimal a = setScale(maxScale);
    BigDecimal b = other.setScale(maxScale);
    
    BigInt result = a._unscaledValue - b._unscaledValue;
    return BigDecimal._(result, maxScale);
  }

  /// Multiplies this BigDecimal by another.
  BigDecimal operator *(BigDecimal other) {
    BigInt result = _unscaledValue * other._unscaledValue;
    int newScale = _scale + other._scale;
    return BigDecimal._(result, newScale);
  }

  /// Divides this BigDecimal by another.
  /// 
  /// [other] the divisor
  /// [scale] the scale of the result (default is max of operand scales + 10)
  BigDecimal divide(BigDecimal other, [int? resultScale]) {
    if (other._unscaledValue == BigInt.zero) {
      throw InvalidArgumentException('Division by zero');
    }
    
    resultScale ??= (_scale > other._scale ? _scale : other._scale) + 10;
    
    // Scale up the dividend to achieve desired precision
    int scaleDiff = resultScale + other._scale - _scale;
    BigInt scaledDividend = _unscaledValue * BigInt.from(10).pow(scaleDiff);
    
    BigInt quotient = scaledDividend ~/ other._unscaledValue;
    return BigDecimal._(quotient, resultScale);
  }

  /// Returns the absolute value of this BigDecimal.
  BigDecimal abs() {
    return _unscaledValue.isNegative 
        ? BigDecimal._(-_unscaledValue, _scale)
        : this;
  }

  /// Returns the negation of this BigDecimal.
  BigDecimal operator -() {
    return BigDecimal._(-_unscaledValue, _scale);
  }

  /// Compares this BigDecimal with another.
  @override
  int compareTo(BigDecimal other) {
    int maxScale = _scale > other._scale ? _scale : other._scale;
    BigDecimal a = setScale(maxScale);
    BigDecimal b = other.setScale(maxScale);
    
    return a._unscaledValue.compareTo(b._unscaledValue);
  }

  /// Comparison operators
  bool operator <(BigDecimal other) => compareTo(other) < 0;
  bool operator <=(BigDecimal other) => compareTo(other) <= 0;
  bool operator >(BigDecimal other) => compareTo(other) > 0;
  bool operator >=(BigDecimal other) => compareTo(other) >= 0;

  /// Returns true if this BigDecimal equals the specified object.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BigDecimal && compareTo(other) == 0;
  }

  /// Returns the hash code for this BigDecimal.
  @override
  int get hashCode => Object.hash(_unscaledValue, _scale);

  /// Returns a string representation of this BigDecimal.
  @override
  String toString() {
    if (_scale == 0) {
      return _unscaledValue.toString();
    }
    
    String unscaledStr = _unscaledValue.abs().toString();
    bool isNegative = _unscaledValue.isNegative;
    
    if (unscaledStr.length <= _scale) {
      // Add leading zeros
      String zeros = '0' * (_scale - unscaledStr.length + 1);
      unscaledStr = zeros + unscaledStr;
    }
    
    int insertPos = unscaledStr.length - _scale;
    String result = '${unscaledStr.substring(0, insertPos)}.${unscaledStr.substring(insertPos)}';
    
    return isNegative ? '-$result' : result;
  }

  /// Converts to double (may lose precision).
  /// 
  /// Usage:
  /// ```dart
  /// final doubleValue = bigDecimal.toDouble();
  /// ```
  double toDouble() {
    return double.parse(toString());
  }

  /// This creates a BigDecimal with value 0.
  /// 
  /// Usage:
  /// ```dart
  /// final zero = BigDecimal.ZERO;
  /// ```
  /// 
  /// {@macro big_decimal}
  static final BigDecimal ZERO = BigDecimal._(BigInt.zero, 0);
  
  /// This creates a BigDecimal with value 1.
  /// 
  /// Usage:
  /// ```dart
  /// final one = BigDecimal.ONE;
  /// ```
  /// 
  /// {@macro big_decimal}
  static final BigDecimal ONE = BigDecimal._(BigInt.one, 0);
  
  /// This creates a BigDecimal with value 10.
  /// 
  /// Usage:
  /// ```dart
  /// final ten = BigDecimal.TEN;
  /// ```
  /// 
  /// {@macro big_decimal}
  static final BigDecimal TEN = BigDecimal._(BigInt.from(10), 0);
}