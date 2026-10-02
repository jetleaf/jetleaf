import 'dart:typed_data';

import '../exceptions.dart';

/// {@template byte_array}
/// A wrapper for byte arrays similar to Java's byte[] with utility methods.
/// 
/// This class provides a convenient interface for working with byte arrays,
/// wrapping Dart's `List<int>` with Java-like methods and additional utilities.
/// 
/// Example usage:
/// ```dart
/// ByteArray bytes = ByteArray.fromString("Hello");
/// ByteArray copy = bytes.copy();
/// bytes.set(0, 72); // Change 'H' to 'H' (same value)
/// 
/// print(bytes.toString()); // "Hello"
/// print(bytes.length); // 5
/// ```
/// 
/// {@endtemplate}
class ByteArray {
  /// The underlying byte data
  final List<int> _bytes;

  /// Creates a ByteArray from a list of bytes.
  /// 
  /// [bytes] the byte data
  /// 
  /// {@macro byte_array}
  ByteArray._(this._bytes);

  /// Creates a ByteArray with the specified size, filled with zeros.
  /// 
  /// [size] the size of the array
  /// 
  /// {@macro byte_array}
  factory ByteArray(int size) {
    return ByteArray._(List<int>.filled(size, 0));
  }

  /// Creates a ByteArray from an existing list of bytes.
  /// 
  /// [bytes] the byte data to copy
  /// 
  /// {@macro byte_array}
  factory ByteArray.fromList(List<int> bytes) {
    return ByteArray._(List<int>.from(bytes));
  }

  /// Creates a ByteArray from a Uint8List.
  /// 
  /// [data] the byte data
  /// 
  /// {@macro byte_array}
  factory ByteArray.fromUint8List(Uint8List data) {
    return ByteArray._(List<int>.from(data));
  }

  /// Creates a ByteArray from a string.
  /// 
  /// [str] the string to convert to bytes
  /// 
  /// {@macro byte_array}
  factory ByteArray.fromString(String str) {
    return ByteArray._(str.codeUnits);
  }

  /// Creates a ByteArray filled with the specified value.
  /// 
  /// [size] the size of the array
  /// [fillValue] the value to fill with (0-255)
  /// 
  /// {@macro byte_array}
  factory ByteArray.filled(int size, int fillValue) {
    if (fillValue < 0 || fillValue > 255) {
      throw InvalidArgumentException('Fill value must be between 0 and 255, got: $fillValue');
    }
    return ByteArray._(List<int>.filled(size, fillValue));
  }

  /// Returns the length of this byte array.
  int get length => _bytes.length;

  /// Returns true if this array is empty.
  bool get isEmpty => _bytes.isEmpty;

  /// Returns true if this array is not empty.
  bool get isNotEmpty => _bytes.isNotEmpty;

  /// Gets the byte at the specified index.
  /// 
  /// [index] the index
  int get(int index) {
    return _bytes[index];
  }

  /// Sets the byte at the specified index.
  /// 
  /// [index] the index
  /// [value] the byte value (0-255)
  void set(int index, int value) {
    if (value < 0 || value > 255) {
      throw InvalidArgumentException('Byte value must be between 0 and 255, got: $value');
    }
    _bytes[index] = value;
  }

  /// Copies a portion of this array to another array.
  /// 
  /// [srcPos] the starting position in this array
  /// [dest] the destination array
  /// [destPos] the starting position in the destination array
  /// [length] the number of bytes to copy
  void copyTo(int srcPos, ByteArray dest, int destPos, int length) {
    for (int i = 0; i < length; i++) {
      dest.set(destPos + i, get(srcPos + i));
    }
  }

  /// Creates a copy of this byte array.
  /// 
  /// [start] the starting index (optional)
  /// [end] the ending index (optional)
  ByteArray copy([int? start, int? end]) {
    return ByteArray.fromList(_bytes.sublist(start ?? 0, end));
  }

  /// Returns a subarray of this byte array.
  /// 
  /// [start] the starting index
  /// [end] the ending index (optional)
  ByteArray subArray(int start, [int? end]) {
    return ByteArray.fromList(_bytes.sublist(start, end));
  }

  /// Fills this array with the specified value.
  /// 
  /// [value] the value to fill with (0-255)
  /// [start] the starting index (optional)
  /// [end] the ending index (optional)
  void fill(int value, [int? start, int? end]) {
    if (value < 0 || value > 255) {
      throw InvalidArgumentException('Fill value must be between 0 and 255, got: $value');
    }
    
    int startIndex = start ?? 0;
    int endIndex = end ?? _bytes.length;
    
    for (int i = startIndex; i < endIndex; i++) {
      _bytes[i] = value;
    }
  }

  /// Reverses the order of bytes in this array.
  void reverse() {
    int i = 0;
    int j = _bytes.length - 1;
    while (i < j) {
      final tmp = _bytes[i];
      _bytes[i] = _bytes[j];
      _bytes[j] = tmp;
      i++;
      j--;
    }
  }

  /// Sorts the bytes in this array.
  void sort() {
    _bytes.sort();
  }

  /// Returns the index of the first occurrence of the specified byte.
  /// 
  /// [value] the byte to search for
  /// [start] the starting index (optional)
  /// Returns -1 if not found
  int indexOf(int value, [int start = 0]) {
    for (int i = start; i < _bytes.length; i++) {
      if (_bytes[i] == value) return i;
    }
    return -1;
  }

  /// Returns the index of the last occurrence of the specified byte.
  /// 
  /// [value] the byte to search for
  /// [start] the starting index from the end (optional)
  /// Returns -1 if not found
  int lastIndexOf(int value, [int? start]) {
    int startIndex = start ?? _bytes.length - 1;
    for (int i = startIndex; i >= 0; i--) {
      if (_bytes[i] == value) return i;
    }
    return -1;
  }

  /// Returns true if this array contains the specified byte.
  /// 
  /// [value] the byte to search for
  bool contains(int value) {
    return _bytes.contains(value);
  }

  /// Converts this byte array to a `List<int>`.
  List<int> toList() => List<int>.from(_bytes);

  /// Converts this byte array to a Uint8List.
  Uint8List toUint8List() => Uint8List.fromList(_bytes);

  /// Converts this byte array to a string.
  /// 
  /// Interprets bytes as character codes.
  String toStringAsChars() => String.fromCharCodes(_bytes);

  /// Returns a hexadecimal string representation of this byte array.
  /// 
  /// [separator] optional separator between hex values
  String toHexString([String separator = '']) {
    return _bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(separator);
  }

  /// Creates a ByteArray from a hexadecimal string.
  /// 
  /// [hexString] the hex string (e.g., "48656C6C6F" for "Hello")
  static ByteArray fromHexString(String hexString) {
    // Remove any whitespace or separators
    String cleaned = hexString.replaceAll(RegExp(r'[^0-9A-Fa-f]'), '');
    
    if (cleaned.length % 2 != 0) {
      throw InvalidArgumentException('Hex string must have even length');
    }
    
    List<int> bytes = [];
    for (int i = 0; i < cleaned.length; i += 2) {
      String hexByte = cleaned.substring(i, i + 2);
      bytes.add(int.parse(hexByte, radix: 16));
    }
    
    return ByteArray.fromList(bytes);
  }

  /// Concatenates this byte array with another.
  /// 
  /// [other] the other byte array
  ByteArray concat(ByteArray other) {
    List<int> combined = List<int>.from(_bytes);
    combined.addAll(other._bytes);
    return ByteArray.fromList(combined);
  }

  /// Operator overloads
  int operator [](int index) => get(index);
  void operator []=(int index, int value) => set(index, value);

  /// Concatenation operator
  ByteArray operator +(ByteArray other) => concat(other);

  /// Returns true if this byte array equals the specified object.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ByteArray) return false;
    if (_bytes.length != other._bytes.length) return false;
    
    for (int i = 0; i < _bytes.length; i++) {
      if (_bytes[i] != other._bytes[i]) return false;
    }
    return true;
  }

  /// Returns the hash code for this byte array.
  @override
  int get hashCode => Object.hashAll(_bytes);

  /// Returns a string representation of this byte array.
  @override
  String toString() {
    if (_bytes.every((b) => b >= 32 && b <= 126)) {
      // If all bytes are printable ASCII, show as string
      return 'ByteArray("${toStringAsChars()}")';
    } else {
      // Otherwise show as hex
      return 'ByteArray([${toHexString(' ')}])';
    }
  }

  /// Static utility methods
  
  /// Compares two byte arrays lexicographically.
  /// 
  /// [a] the first array
  /// [b] the second array
  /// Returns negative, zero, or positive value
  static int compare(ByteArray a, ByteArray b) {
    int minLength = a.length < b.length ? a.length : b.length;
    
    for (int i = 0; i < minLength; i++) {
      int diff = a.get(i) - b.get(i);
      if (diff != 0) return diff;
    }
    
    return a.length - b.length;
  }

  /// Returns true if two byte arrays are equal.
  /// 
  /// [a] the first array
  /// [b] the second array
  static bool equals(ByteArray a, ByteArray b) {
    return a == b;
  }
}