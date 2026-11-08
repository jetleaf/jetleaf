/// {@template boolean}
/// A wrapper class for [bool] that provides Java-like functionality and methods.
/// 
/// This class wraps Dart's primitive [bool] type and provides additional utility methods
/// similar to Java's Boolean class.
/// 
/// Example usage:
/// ```dart
/// Boolean a = Boolean(true);
/// Boolean b = Boolean.valueOf(false);
/// Boolean c = Boolean.parseBoolean("true");
/// 
/// print(a.toString()); // "true"
/// print(a.compareTo(b)); // 1 (true > false)
/// ```
/// 
/// {@endtemplate}
class Boolean implements Comparable<Boolean> {
  /// The wrapped boolean value
  final bool _value;

  /// Boolean constant representing true
  /// 
  /// {@macro boolean}
  static const Boolean TRUE = Boolean(true);
  
  /// Boolean constant representing false
  /// 
  /// {@macro boolean}
  static const Boolean FALSE = Boolean(false);

  /// Creates a Boolean with the specified value.
  /// 
  /// [value] the boolean value to wrap
  /// 
  /// {@macro boolean}
  const Boolean(this._value);

  /// Returns the wrapped boolean value.
  bool get value => _value;

  /// Parses a string to a Boolean.
  /// 
  /// Returns true if the string equals "true" (case-insensitive), false otherwise.
  /// 
  /// [str] the string to parse
  /// 
  /// Example:
  /// ```dart
  /// Boolean a = Boolean.parseBoolean("true");   // true
  /// Boolean b = Boolean.parseBoolean("TRUE");   // true
  /// Boolean c = Boolean.parseBoolean("false");  // false
  /// Boolean d = Boolean.parseBoolean("xyz");    // false
  /// ```
  /// 
  /// {@macro boolean}
  static Boolean parseBoolean(String str) {
    return Boolean(str.toLowerCase() == 'true');
  }

  /// Returns a Boolean instance representing the specified bool value.
  /// 
  /// [value] the boolean value
  /// 
  /// {@macro boolean}
  static Boolean valueOf(bool value) {
    return value ? TRUE : FALSE;
  }

  /// Returns a Boolean instance from a string.
  /// 
  /// [str] the string representation
  /// 
  /// {@macro boolean}
  static Boolean valueOfString(String str) {
    return parseBoolean(str);
  }

  /// Performs a logical AND operation.
  /// 
  /// [other] the other Boolean
  Boolean and(Boolean other) => Boolean(_value && other._value);

  /// Performs a logical OR operation.
  /// 
  /// [other] the other Boolean
  Boolean or(Boolean other) => Boolean(_value || other._value);

  /// Performs a logical XOR operation.
  /// 
  /// [other] the other Boolean
  Boolean xor(Boolean other) => Boolean(_value != other._value);

  /// Returns the logical negation of this Boolean.
  Boolean not() => Boolean(!_value);

  /// Compares this Boolean with another Boolean.
  /// 
  /// false is considered less than true.
  /// 
  /// Returns:
  /// - negative value if this < other
  /// - zero if this == other
  /// - positive value if this > other
  @override
  int compareTo(Boolean other) {
    if (_value == other._value) return 0;
    return _value ? 1 : -1;
  }

  /// Returns true if this Boolean equals the specified object.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Boolean && _value == other._value;
  }

  /// Returns the hash code for this Boolean.
  @override
  int get hashCode => _value.hashCode;

  /// Returns a string representation of this Boolean.
  @override
  String toString() => _value.toString();

  /// Logical operators
  Boolean operator &(Boolean other) => and(other);
  Boolean operator |(Boolean other) => or(other);
  Boolean operator ^(Boolean other) => xor(other);
  Boolean operator ~() => not();
}