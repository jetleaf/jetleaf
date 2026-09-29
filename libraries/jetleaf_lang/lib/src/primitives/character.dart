import '../exceptions.dart';

/// {@template character}
/// A wrapper class for single characters that provides Java-like functionality.
/// 
/// This class wraps a single character (represented as a String in Dart) and provides
/// utility methods similar to Java's Character class.
/// 
/// Example usage:
/// ```dart
/// Character a = Character('A');
/// Character b = Character.valueOf('z');
/// 
/// print(a.isUpperCase()); // true
/// print(a.toLowerCase()); // Character('a')
/// print(Character.isDigit('5')); // true
/// ```
/// 
/// {@endtemplate}
class Character implements Comparable<Character> {
  /// The wrapped character value
  final String _value;

  /// Creates a Character with the specified character.
  /// 
  /// [value] the character to wrap (must be a single character)
  /// 
  /// Throws [InvalidArgumentException] if the string is not exactly one character.
  /// 
  /// {@macro character}
  Character(String value) : _value = _validateSingleChar(value);

  /// Validates that the input is a single character
  static String _validateSingleChar(String value) {
    if (value.length != 1) {
      throw InvalidArgumentException('Character must be exactly one character, got: $value');
    }
    return value;
  }

  /// Returns the wrapped character value.
  String get value => _value;

  /// Returns a Character instance representing the specified character.
  /// 
  /// [char] the character value
  /// 
  /// {@macro character}
  static Character valueOf(String char) {
    return Character(char);
  }

  /// Returns the Unicode code point of this character.
  int get codePoint => _value.codeUnitAt(0);

  /// Returns true if this character is a digit (0-9).
  bool isDigit() => _isDigit(_value);

  /// Returns true if this character is a letter.
  bool isLetter() => _isLetter(_value);

  /// Returns true if this character is a letter or digit.
  bool isLetterOrDigit() => isLetter() || isDigit();

  /// Returns true if this character is uppercase.
  bool isUpperCase() => _value == _value.toUpperCase() && _value != _value.toLowerCase();

  /// Returns true if this character is lowercase.
  bool isLowerCase() => _value == _value.toLowerCase() && _value != _value.toUpperCase();

  /// Returns true if this character is whitespace.
  bool isWhitespace() => _isWhitespace(_value);

  /// Converts this character to uppercase.
  Character toUpperCase() => Character(_value.toUpperCase());

  /// Converts this character to lowercase.
  Character toLowerCase() => Character(_value.toLowerCase());

  /// Static methods for character testing
  
  /// Returns true if the specified character is a digit.
  static bool _isDigit(String char) {
    if (char.length != 1) return false;
    int code = char.codeUnitAt(0);
    return code >= 48 && code <= 57; // '0' to '9'
  }

  /// Returns true if the specified character is a letter.
  static bool _isLetter(String char) {
    if (char.length != 1) return false;
    int code = char.codeUnitAt(0);
    return (code >= 65 && code <= 90) || (code >= 97 && code <= 122); // A-Z or a-z
  }

  /// Returns true if the specified character is whitespace.
  static bool _isWhitespace(String char) {
    if (char.length != 1) return false;
    return char == ' ' || char == '\t' || char == '\n' || char == '\r';
  }

  /// Compares this Character with another Character.
  @override
  int compareTo(Character other) => _value.compareTo(other._value);

  /// Returns true if this Character equals the specified object.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Character && _value == other._value;
  }

  /// Returns the hash code for this Character.
  @override
  int get hashCode => _value.hashCode;

  /// Returns a string representation of this Character.
  @override
  String toString() => _value;
}