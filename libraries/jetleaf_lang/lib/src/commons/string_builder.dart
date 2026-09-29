import '../exceptions.dart';

/// {@template string_builder}
/// A mutable sequence of characters similar to Java's StringBuilder.
/// 
/// This class provides an efficient way to build strings by appending
/// characters, strings, and other data types.
/// 
/// Example usage:
/// ```dart
/// StringBuilder sb = StringBuilder();
/// sb.append("Hello");
/// sb.append(" ");
/// sb.append("World");
/// sb.append("!");
/// 
/// print(sb.toString()); // "Hello World!"
/// print(sb.length()); // 12
/// ```
/// 
/// {@endtemplate}
final class StringBuilder {
  /// Internal string buffer
  final StringBuffer _buffer;

  /// Creates an empty StringBuilder.
  /// 
  /// {@macro string_builder}
  StringBuilder() : _buffer = StringBuffer();

  /// Creates a StringBuilder with initial content.
  /// 
  /// [initialContent] the initial string content
  /// 
  /// {@macro string_builder}
  StringBuilder.withContent(String initialContent) : _buffer = StringBuffer(initialContent);

  /// Creates a StringBuilder with initial capacity (ignored in Dart).
  /// 
  /// {@macro string_builder}
  StringBuilder.withCapacity(int capacity) : _buffer = StringBuffer();

  /// Appends a string to this StringBuilder.
  /// 
  /// [str] the string to append
  /// Returns this StringBuilder for method chaining
  StringBuilder append(dynamic str) {
    _buffer.write(str.toString());
    return this;
  }

  /// Appends an object's string representation to this StringBuilder.
  /// 
  /// [obj] the object to append
  /// Returns this StringBuilder for method chaining
  StringBuilder appendObject(Object? obj) {
    _buffer.write(obj?.toString() ?? 'null');
    return this;
  }

  /// Appends a character to this StringBuilder.
  /// 
  /// [char] the character to append
  /// Returns this StringBuilder for method chaining
  StringBuilder appendChar(String char) {
    if (char.length != 1) {
      throw InvalidArgumentException('Must be a single character');
    }
    _buffer.write(char);
    return this;
  }

  /// Appends a character code.
  StringBuilder appendCharCode(int charCode) {
    _buffer.writeCharCode(charCode);
    return this;
  }

  /// Appends an integer to this StringBuilder.
  /// 
  /// [value] the integer to append
  /// Returns this StringBuilder for method chaining
  StringBuilder appendInt(int value) {
    _buffer.write(value);
    return this;
  }

  /// Appends a double to this StringBuilder.
  /// 
  /// [value] the double to append
  /// Returns this StringBuilder for method chaining
  StringBuilder appendDouble(double value) {
    _buffer.write(value);
    return this;
  }

  /// Appends a boolean to this StringBuilder.
  /// 
  /// [value] the boolean to append
  /// Returns this StringBuilder for method chaining
  StringBuilder appendBool(bool value) {
    _buffer.write(value);
    return this;
  }

  /// Appends a line separator to this StringBuilder.
  /// 
  /// Returns this StringBuilder for method chaining
  StringBuilder appendLine([String? str]) {
    if (str != null) {
      _buffer.write(str);
    }
    _buffer.writeln();
    return this;
  }

  /// Inserts a string at the specified index.
  /// 
  /// [index] the index at which to insert
  /// [str] the string to insert
  /// Returns this StringBuilder for method chaining
  StringBuilder insert(int index, String str) {
    String current = _buffer.toString();
    if (index < 0 || index > current.length) {
      throw RangeError('Index out of range: $index');
    }
    
    String before = current.substring(0, index);
    String after = current.substring(index);
    
    _buffer.clear();
    _buffer.write(before);
    _buffer.write(str);
    _buffer.write(after);
    
    return this;
  }

  /// Deletes characters from the specified range.
  /// 
  /// [start] the starting index (inclusive)
  /// [end] the ending index (exclusive)
  /// Returns this StringBuilder for method chaining
  StringBuilder delete(int start, int end) {
    String current = _buffer.toString();
    if (start < 0 || end > current.length || start > end) {
      throw RangeError('Invalid range: $start to $end');
    }
    
    String before = current.substring(0, start);
    String after = current.substring(end);
    
    _buffer.clear();
    _buffer.write(before);
    _buffer.write(after);
    
    return this;
  }

  /// Deletes the character at the specified index.
  /// 
  /// [index] the index of the character to delete
  /// Returns this StringBuilder for method chaining
  StringBuilder deleteCharAt(int index) {
    return delete(index, index + 1);
  }

  /// Replaces characters in the specified range with the given string.
  /// 
  /// [start] the starting index (inclusive)
  /// [end] the ending index (exclusive)
  /// [str] the replacement string
  /// Returns this StringBuilder for method chaining
  StringBuilder replace(int start, int end, String str) {
    delete(start, end);
    insert(start, str);
    return this;
  }

  /// Reverses the contents of this StringBuilder.
  /// 
  /// Returns this StringBuilder for method chaining
  StringBuilder reverse() {
    String current = _buffer.toString();
    _buffer.clear();
    _buffer.write(current.split('').reversed.join(''));
    return this;
  }

  /// Returns the character at the specified index.
  /// 
  /// [index] the index
  String charAt(int index) {
    String current = _buffer.toString();
    if (index < 0 || index >= current.length) {
      throw RangeError('Index out of range: $index');
    }
    return current[index];
  }

  /// Sets the character at the specified index.
  /// 
  /// [index] the index
  /// [char] the new character
  void setCharAt(int index, String char) {
    if (char.length != 1) {
      throw InvalidArgumentException('Must be a single character');
    }
    
    String current = _buffer.toString();
    if (index < 0 || index >= current.length) {
      throw RangeError('Index out of range: $index');
    }
    
    String before = current.substring(0, index);
    String after = current.substring(index + 1);
    
    _buffer.clear();
    _buffer.write(before);
    _buffer.write(char);
    _buffer.write(after);
  }

  /// Returns a substring of this StringBuilder.
  /// 
  /// [start] the starting index
  /// [end] the ending index (optional)
  String substring(int start, [int? end]) {
    return _buffer.toString().substring(start, end);
  }

  /// Returns the index of the first occurrence of the specified string.
  /// 
  /// [str] the string to search for
  /// [start] the starting index (optional)
  /// Returns -1 if not found
  int indexOf(String str, [int start = 0]) {
    return _buffer.toString().indexOf(str, start);
  }

  /// Returns the index of the last occurrence of the specified string.
  /// 
  /// [str] the string to search for
  /// [start] the starting index from the end (optional)
  /// Returns -1 if not found
  int lastIndexOf(String str, [int? start]) {
    return _buffer.toString().lastIndexOf(str, start);
  }

  /// Returns the length of this StringBuilder.
  int length() => _buffer.toString().length;

  /// Returns true if this StringBuilder is empty.
  bool isEmpty() => length() == 0;

  /// Returns true if this StringBuilder is not empty.
  bool isNotEmpty() => length() > 0;

  /// Clears the contents of this StringBuilder.
  /// 
  /// Returns this StringBuilder for method chaining
  StringBuilder clear() {
    _buffer.clear();
    return this;
  }

  /// Sets the length of this StringBuilder.
  /// 
  /// If the new length is less than the current length, the StringBuilder is truncated.
  /// If the new length is greater, null characters are appended.
  /// 
  /// [newLength] the new length
  void setLength(int newLength) {
    String current = _buffer.toString();
    
    if (newLength < 0) {
      throw InvalidArgumentException('Length cannot be negative');
    }
    
    if (newLength < current.length) {
      _buffer.clear();
      _buffer.write(current.substring(0, newLength));
    } else if (newLength > current.length) {
      int padding = newLength - current.length;
      _buffer.write('\x00' * padding);
    }
  }

  /// Ensures that the capacity is at least the specified minimum.
  /// 
  /// [minimumCapacity] the minimum capacity
  /// Note: In Dart, this is mostly a no-op since StringBuffer handles capacity automatically
  void ensureCapacity(int minimumCapacity) {
    // StringBuffer in Dart handles capacity automatically
    // This method is provided for Java compatibility
  }

  /// Trims whitespace from the beginning and end.
  /// 
  /// Returns this StringBuilder for method chaining
  StringBuilder trim() {
    String trimmed = _buffer.toString().trim();
    _buffer.clear();
    _buffer.write(trimmed);
    return this;
  }

  /// Appends all elements from an iterable.
  StringBuilder appendAll(Iterable<Object?> objects, [String separator = '']) {
    _buffer.writeAll(objects, separator);
    return this;
  }

  /// Trims the capacity to the current length.
  StringBuilder trimToSize() {
    // No-op in Dart since StringBuffer doesn't have excess capacity
    return this;
  }

  /// Returns the current capacity (same as length in Dart).
  int get capacity => length();

  /// Returns the string representation of this StringBuilder.
  @override
  String toString() => _buffer.toString();

  /// Returns true if this StringBuilder equals the specified object.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is StringBuilder) {
      return _buffer.toString() == other._buffer.toString();
    }
    if (other is String) {
      return _buffer.toString() == other;
    }
    return false;
  }

  /// Returns the hash code for this StringBuilder.
  @override
  int get hashCode => _buffer.toString().hashCode;

  /// Operator overloads
  String operator [](int index) => charAt(index);
  void operator []=(int index, String char) => setCharAt(index, char);

  /// Addition operator for appending
  StringBuilder operator +(Object other) {
    return StringBuilder.withContent(_buffer.toString())..appendObject(other);
  }
}