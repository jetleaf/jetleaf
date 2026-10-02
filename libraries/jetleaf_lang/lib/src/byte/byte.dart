import 'dart:typed_data';

import '../exceptions.dart';

/// {@template byte}
/// A comprehensive wrapper class for byte operations, supporting both single bytes and byte collections.
/// 
/// This class provides Java-like functionality for working with 8-bit signed integers (-128 to 127)
/// and collections of bytes. It can represent a single byte value or work with byte arrays,
/// similar to Java's Byte class and byte[] arrays.
/// 
/// ## Key Features:
/// 
/// * **Single byte operations**: Wrap and manipulate individual byte values
/// * **Byte array support**: Work with collections of bytes (`List<int>`)
/// * **Type conversions**: Convert between signed/unsigned, different radixes
/// * **Bitwise operations**: Full support for bit manipulation
/// * **Java compatibility**: Method signatures and behavior match Java's Byte class
/// 
/// ## Usage Examples:
/// 
/// ### Single Byte Operations:
/// ```dart
/// // Create single bytes
/// final b1 = Byte(127);                    // Maximum positive value
/// final b2 = Byte(-128);                   // Minimum negative value
/// final b3 = Byte.parseByte('42');         // Parse from string
/// final b4 = Byte.parseByte('FF', 16);     // Parse hex
/// 
/// // Basic operations
/// print(b1.value);                        // 127
/// print(b1.toUnsigned());                 // 127
/// print(b2.toUnsigned());                 // 128 (unsigned representation)
/// print(b1 + b2);                         // Byte(-1)
/// 
/// // Bitwise operations
/// final result = b1 & Byte(15);           // Bitwise AND
/// print(result.toBinaryString());         // Binary representation
/// ```
/// 
/// ### Byte Array Operations:
/// ```dart
/// // Create from byte arrays
/// final bytes = Byte.fromList([65, 66, 67]);        // From List<int>
/// final fromString = Byte.fromString('Hello');       // From string
/// final fromHex = Byte.fromHexString('48656C6C6F');  // From hex string
/// 
/// // Array operations
/// print(bytes.toList());                   // [65, 66, 67]
/// print(bytes.toString());                 // 'ABC'
/// print(bytes.toHexString());              // '414243'
/// 
/// // Manipulate arrays
/// bytes.append(68);                        // Add byte
/// bytes.appendAll([69, 70]);               // Add multiple bytes
/// final subBytes = bytes.subBytes(1, 3);   // Get substring
/// ```
/// 
/// ### Advanced Operations:
/// ```dart
/// // Validation and ranges
/// print(Byte.isValidByte(200));            // false (out of range)
/// print(Byte.isValidByte(-100));           // true
/// 
/// // Conversions
/// final unsigned = Byte.toUnsignedByte(200);  // Convert unsigned to signed
/// final signed = Byte.toSignedByte(200);      // Handle overflow
/// 
/// // Utility operations
/// final checksum = Byte.calculateChecksum([1, 2, 3, 4]);
/// final reversed = Byte.reverseBytes([1, 2, 3, 4]);
/// ```
/// 
/// {@endtemplate}
class Byte implements Comparable<Byte> {
  /// Internal storage for byte data - can be single byte or multiple bytes
  final List<int> _bytes;
  
  /// Maximum value for a signed byte (2^7 - 1)
  static const int MAX_VALUE = 127;
  
  /// Minimum value for a signed byte (-2^7)
  static const int MIN_VALUE = -128;
  
  /// Maximum value for an unsigned byte (2^8 - 1)
  static const int MAX_UNSIGNED_VALUE = 255;
  
  /// Minimum value for an unsigned byte
  static const int MIN_UNSIGNED_VALUE = 0;

  /// Creates a Byte representing a single byte value.
  /// 
  /// The [value] must be between -128 and 127 (signed byte range).
  /// 
  /// Example:
  /// ```dart
  /// final b1 = Byte(127);    // Maximum positive value
  /// final b2 = Byte(-128);   // Minimum negative value
  /// final b3 = Byte(0);      // Zero
  /// ```
  /// 
  /// Throws [InvalidArgumentException] if value is outside the valid byte range.
  /// 
  /// {@macro byte}
  Byte(int value) : _bytes = [_validateByteRange(value)];

  /// Creates a Byte from a list of byte values.
  /// 
  /// Each value in the [bytes] list must be between -128 and 127.
  /// 
  /// Example:
  /// ```dart
  /// final bytes = Byte.fromList([65, 66, 67]);        // 'ABC'
  /// final data = Byte.fromList([-1, 0, 1, 127]);      // Mixed values
  /// final empty = Byte.fromList([]);                   // Empty byte array
  /// ```
  /// 
  /// Throws [InvalidArgumentException] if any value is outside the valid byte range.
  /// 
  /// {@macro byte}
  Byte.fromList(List<int> bytes) : _bytes = bytes.map(_validateByteRange).toList();

  /// Creates a Byte from an unsigned byte list (0-255 range).
  /// 
  /// Values are automatically converted from unsigned (0-255) to signed (-128-127).
  /// 
  /// Example:
  /// ```dart
  /// final bytes = Byte.fromUnsignedList([255, 128, 0]);  // [-1, -128, 0]
  /// final data = Byte.fromUnsignedList([200, 100, 50]);  // [-56, 100, 50]
  /// ```
  /// 
  /// Throws [InvalidArgumentException] if any value is outside 0-255 range.
  /// 
  /// {@macro byte}
  Byte.fromUnsignedList(List<int> bytes) 
      : _bytes = bytes.map((b) => _validateUnsignedRange(b)).map(_unsignedToSigned).toList();

  /// Creates a Byte from a string, converting each character to its byte value.
  /// 
  /// Each character's code unit is used as the byte value. Characters with
  /// code units > 255 will cause an error.
  /// 
  /// Example:
  /// ```dart
  /// final hello = Byte.fromString('Hello');     // [72, 101, 108, 108, 111]
  /// final abc = Byte.fromString('ABC');         // [65, 66, 67]
  /// final empty = Byte.fromString('');          // []
  /// ```
  /// 
  /// Throws [InvalidArgumentException] if any character has a code unit > 255.
  /// 
  /// {@macro byte}
  Byte.fromString(String str) 
      : _bytes = str.codeUnits.map((c) => _validateUnsignedRange(c)).map(_unsignedToSigned).toList();

  /// Creates a Byte from a hexadecimal string.
  /// 
  /// The hex string should contain pairs of hexadecimal digits (0-9, A-F).
  /// Spaces and common separators are ignored.
  /// 
  /// Example:
  /// ```dart
  /// final data = Byte.fromHexString('48656C6C6F');     // 'Hello'
  /// final spaced = Byte.fromHexString('48 65 6C 6C 6F'); // Same as above
  /// final mixed = Byte.fromHexString('FF00AB');         // [-1, 0, -85]
  /// ```
  /// 
  /// Throws [InvalidFormatException] if the hex string is invalid.
  /// 
  /// {@macro byte}
  Byte.fromHexString(String hexString) : _bytes = _parseHexString(hexString);

  /// Creates a Byte from a Uint8List.
  /// 
  /// Values are converted from unsigned (0-255) to signed (-128-127).
  /// 
  /// Example:
  /// ```dart
  /// final uint8List = Uint8List.fromList([255, 128, 0]);
  /// final bytes = Byte.fromUint8List(uint8List);  // [-1, -128, 0]
  /// ```
  /// 
  /// {@macro byte}
  Byte.fromUint8List(Uint8List data) 
      : _bytes = data.map(_unsignedToSigned).toList();

  /// Creates an empty Byte array.
  /// 
  /// Example:
  /// ```dart
  /// final empty = Byte.empty();
  /// print(empty.length);  // 0
  /// print(empty.isEmpty); // true
  /// ```
  /// 
  /// {@macro byte}
  Byte.empty() : _bytes = <int>[];

  // Validation methods

  /// Validates that a value is within signed byte range (-128 to 127).
  static int _validateByteRange(int value) {
    if (value < MIN_VALUE || value > MAX_VALUE) {
      throw InvalidArgumentException('Byte value must be between $MIN_VALUE and $MAX_VALUE, got: $value');
    }
    return value;
  }

  /// Validates that a value is within unsigned byte range (0 to 255).
  static int _validateUnsignedRange(int value) {
    if (value < MIN_UNSIGNED_VALUE || value > MAX_UNSIGNED_VALUE) {
      throw InvalidArgumentException('Unsigned byte value must be between $MIN_UNSIGNED_VALUE and $MAX_UNSIGNED_VALUE, got: $value');
    }
    return value;
  }

  /// Converts unsigned byte (0-255) to signed byte (-128-127).
  static int _unsignedToSigned(int unsigned) {
    return unsigned > 127 ? unsigned - 256 : unsigned;
  }

  /// Converts signed byte (-128-127) to unsigned byte (0-255).
  static int _signedToUnsigned(int signed) {
    return signed < 0 ? signed + 256 : signed;
  }

  /// Parses a hexadecimal string into a list of signed bytes.
  static List<int> _parseHexString(String hexString) {
    // Remove common separators and whitespace
    final cleaned = hexString.replaceAll(RegExp(r'[\s\-:_]'), '').toUpperCase();
    
    if (cleaned.length % 2 != 0) {
      throw InvalidFormatException('Hex string must have even length: $hexString');
    }
    
    final bytes = <int>[];
    for (int i = 0; i < cleaned.length; i += 2) {
      final hexByte = cleaned.substring(i, i + 2);
      try {
        final unsigned = int.parse(hexByte, radix: 16);
        bytes.add(_unsignedToSigned(unsigned));
      } catch (e) {
        throw InvalidFormatException('Invalid hex string: $hexString');
      }
    }
    
    return bytes;
  }

  // Properties

  /// Returns the byte value if this represents a single byte.
  /// 
  /// Example:
  /// ```dart
  /// final b = Byte(42);
  /// print(b.value);  // 42
  /// ```
  /// 
  /// Throws [NoGuaranteeException] if this represents multiple bytes.
  int get value {
    if (_bytes.length != 1) {
      throw NoGuaranteeException('Cannot get single value from byte array of length ${_bytes.length}');
    }
    return _bytes[0];
  }

  /// Returns the number of bytes in this Byte object.
  /// 
  /// Example:
  /// ```dart
  /// final single = Byte(42);
  /// final multiple = Byte.fromList([1, 2, 3]);
  /// 
  /// print(single.length);    // 1
  /// print(multiple.length);  // 3
  /// ```
  int get length => _bytes.length;

  /// Returns true if this Byte object contains no bytes.
  /// 
  /// Example:
  /// ```dart
  /// final empty = Byte.empty();
  /// final notEmpty = Byte(0);
  /// 
  /// print(empty.isEmpty);     // true
  /// print(notEmpty.isEmpty);  // false
  /// ```
  bool get isEmpty => _bytes.isEmpty;

  /// Returns true if this Byte object contains at least one byte.
  bool get isNotEmpty => _bytes.isNotEmpty;

  /// Returns true if this represents a single byte value.
  /// 
  /// Example:
  /// ```dart
  /// final single = Byte(42);
  /// final multiple = Byte.fromList([1, 2, 3]);
  /// 
  /// print(single.isSingleByte);    // true
  /// print(multiple.isSingleByte);  // false
  /// ```
  bool get isSingleByte => _bytes.length == 1;

  // Static utility methods

  /// Parses a string to a Byte representing a single byte value.
  /// 
  /// The [str] parameter is parsed as an integer in the specified [radix].
  /// 
  /// Example:
  /// ```dart
  /// final decimal = Byte.parseByte('42');        // 42
  /// final hex = Byte.parseByte('FF', 16);        // -1 (255 as signed)
  /// final binary = Byte.parseByte('1010', 2);    // 10
  /// final negative = Byte.parseByte('-128');     // -128
  /// ```
  /// 
  /// Throws [InvalidFormatException] if the string cannot be parsed.
  /// Throws [InvalidArgumentException] if the parsed value is outside byte range.
  static Byte parseByte(String str, [int radix = 10]) {
    final parsed = int.parse(str, radix: radix);

    // Convert to signed 8-bit if needed
    final signed = parsed > MAX_VALUE ? parsed - 256 : parsed;
    return Byte(signed);
  }

  /// Returns a Byte instance representing the specified int value.
  /// 
  /// This is equivalent to calling `Byte(value)` but follows Java naming conventions.
  /// 
  /// Example:
  /// ```dart
  /// final b1 = Byte.valueOf(42);
  /// final b2 = Byte.valueOf(-100);
  /// ```
  static Byte valueOf(int value) => Byte(value);

  /// Checks if a value is within the valid signed byte range (-128 to 127).
  /// 
  /// Example:
  /// ```dart
  /// print(Byte.isValidByte(127));   // true
  /// print(Byte.isValidByte(128));   // false
  /// print(Byte.isValidByte(-128));  // true
  /// print(Byte.isValidByte(-129));  // false
  /// ```
  static bool isValidByte(int value) {
    return value >= MIN_VALUE && value <= MAX_VALUE;
  }

  /// Checks if a value is within the valid unsigned byte range (0 to 255).
  /// 
  /// Example:
  /// ```dart
  /// print(Byte.isValidUnsignedByte(255));  // true
  /// print(Byte.isValidUnsignedByte(256));  // false
  /// print(Byte.isValidUnsignedByte(-1));   // false
  /// ```
  static bool isValidUnsignedByte(int value) {
    return value >= MIN_UNSIGNED_VALUE && value <= MAX_UNSIGNED_VALUE;
  }

  /// Converts an unsigned byte value (0-255) to signed byte (-128-127).
  /// 
  /// Values 0-127 remain unchanged, values 128-255 become -128 to -1.
  /// 
  /// Example:
  /// ```dart
  /// print(Byte.toSignedByte(100));   // 100
  /// print(Byte.toSignedByte(200));   // -56
  /// print(Byte.toSignedByte(255));   // -1
  /// ```
  /// 
  /// Throws [InvalidArgumentException] if value is outside 0-255 range.
  static int toSignedByte(int unsignedValue) {
    _validateUnsignedRange(unsignedValue);
    return _unsignedToSigned(unsignedValue);
  }

  /// Converts a signed byte value (-128-127) to unsigned byte (0-255).
  /// 
  /// Values 0-127 remain unchanged, values -128 to -1 become 128-255.
  /// 
  /// Example:
  /// ```dart
  /// print(Byte.toUnsignedByte(100));   // 100
  /// print(Byte.toUnsignedByte(-56));   // 200
  /// print(Byte.toUnsignedByte(-1));    // 255
  /// ```
  /// 
  /// Throws [InvalidArgumentException] if value is outside -128-127 range.
  static int toUnsignedByte(int signedValue) {
    _validateByteRange(signedValue);
    return _signedToUnsigned(signedValue);
  }

  /// Calculates a simple checksum of a byte array.
  /// 
  /// Returns the sum of all bytes modulo 256, converted to signed byte.
  /// 
  /// Example:
  /// ```dart
  /// final checksum = Byte.calculateChecksum([1, 2, 3, 4]);  // 10
  /// final overflow = Byte.calculateChecksum([255, 255]);    // -2
  /// ```
  static int calculateChecksum(List<int> bytes) {
    final sum = bytes.fold<int>(0, (sum, byte) => sum + _signedToUnsigned(byte));
    return _unsignedToSigned(sum % 256);
  }

  /// Reverses the order of bytes in a list.
  /// 
  /// Example:
  /// ```dart
  /// final original = [1, 2, 3, 4];
  /// final reversed = Byte.reverseBytes(original);  // [4, 3, 2, 1]
  /// ```
  static List<int> reverseBytes(List<int> bytes) {
    return bytes.reversed.toList();
  }

  // Instance methods

  /// Returns the unsigned representation of this byte (0-255).
  /// 
  /// For single bytes only.
  /// 
  /// Example:
  /// ```dart
  /// final b1 = Byte(100);
  /// final b2 = Byte(-56);
  /// 
  /// print(b1.toUnsigned());  // 100
  /// print(b2.toUnsigned());  // 200
  /// ```
  /// 
  /// Throws [NoGuaranteeException] if this represents multiple bytes.
  int toUnsigned() {
    if (!isSingleByte) {
      throw NoGuaranteeException('Cannot convert byte array to single unsigned value');
    }
    return _signedToUnsigned(_bytes[0]);
  }

  /// Returns the absolute value of this Byte.
  /// 
  /// For single bytes only.
  /// 
  /// Example:
  /// ```dart
  /// final b1 = Byte(-42);
  /// final b2 = Byte(42);
  /// 
  /// print(b1.abs().value);  // 42
  /// print(b2.abs().value);  // 42
  /// ```
  /// 
  /// Throws [NoGuaranteeException] if this represents multiple bytes.
  Byte abs() {
    if (!isSingleByte) {
      throw NoGuaranteeException('Cannot get absolute value of byte array');
    }
    return Byte(_bytes[0].abs());
  }

  /// Returns the bytes as a `List<int>` with signed values (-128 to 127).
  /// 
  /// Example:
  /// ```dart
  /// final bytes = Byte.fromList([100, -56, 0]);
  /// print(bytes.toList());  // [100, -56, 0]
  /// ```
  List<int> toList() => List<int>.from(_bytes);

  /// Returns the bytes as a `List<int>` with unsigned values (0 to 255).
  /// 
  /// Example:
  /// ```dart
  /// final bytes = Byte.fromList([100, -56, 0]);
  /// print(bytes.toUnsignedList());  // [100, 200, 0]
  /// ```
  List<int> toUnsignedList() => _bytes.map(_signedToUnsigned).toList();

  /// Returns the bytes as a Uint8List.
  /// 
  /// Example:
  /// ```dart
  /// final bytes = Byte.fromList([100, -56, 0]);
  /// final uint8List = bytes.toUint8List();  // Uint8List with [100, 200, 0]
  /// ```
  Uint8List toUint8List() => Uint8List.fromList(toUnsignedList());

  /// Converts bytes to a string by interpreting each byte as a character code.
  /// 
  /// Negative bytes are converted to their unsigned equivalents first.
  /// 
  /// Example:
  /// ```dart
  /// final hello = Byte.fromString('Hello');
  /// print(hello.toString());  // 'Hello'
  /// 
  /// final bytes = Byte.fromList([65, 66, 67]);
  /// print(bytes.toString());  // 'ABC'
  /// ```
  @override
  String toString() {
    if (isEmpty) return '';
    return String.fromCharCodes(toUnsignedList());
  }

  /// Returns a hexadecimal string representation of the bytes.
  /// 
  /// Each byte is represented as a two-digit uppercase hex value.
  /// 
  /// Example:
  /// ```dart
  /// final bytes = Byte.fromList([255, 0, 171]);
  /// print(bytes.toHexString());  // 'FF00AB'
  /// 
  /// final hello = Byte.fromString('Hi');
  /// print(hello.toHexString());  // '4869'
  /// ```
  String toHexString() {
    return toUnsignedList()
        .map((b) => b.toRadixString(16).toUpperCase().padLeft(2, '0'))
        .join();
  }

  /// Returns a binary string representation of the bytes.
  /// 
  /// Each byte is represented as an 8-bit binary value.
  /// 
  /// Example:
  /// ```dart
  /// final b = Byte(42);
  /// print(b.toBinaryString());  // '00101010'
  /// 
  /// final bytes = Byte.fromList([1, 2]);
  /// print(bytes.toBinaryString());  // '0000000100000010'
  /// ```
  String toBinaryString() {
    return toUnsignedList()
        .map((b) => b.toRadixString(2).padLeft(8, '0'))
        .join();
  }

  /// Returns a string representation in the specified radix.
  /// 
  /// For single bytes only.
  /// 
  /// Example:
  /// ```dart
  /// final b = Byte(42);
  /// print(b.toRadixString(16));  // '2a'
  /// print(b.toRadixString(2));   // '101010'
  /// print(b.toRadixString(8));   // '52'
  /// ```
  /// 
  /// Throws [NoGuaranteeException] if this represents multiple bytes.
  String toRadixString(int radix) {
    if (!isSingleByte) {
      throw NoGuaranteeException('Cannot convert byte array to single radix string');
    }
    return toUnsigned().toRadixString(radix);
  }

  // Array manipulation methods

  /// Appends a single byte to this byte array.
  /// 
  /// Example:
  /// ```dart
  /// final bytes = Byte.fromList([1, 2, 3]);
  /// bytes.append(4);
  /// print(bytes.toList());  // [1, 2, 3, 4]
  /// ```
  /// 
  /// Throws [InvalidArgumentException] if value is outside byte range.
  void append(int byte) {
    _bytes.add(_validateByteRange(byte));
  }

  /// Appends multiple bytes to this byte array.
  /// 
  /// Example:
  /// ```dart
  /// final bytes = Byte.fromList([1, 2]);
  /// bytes.appendAll([3, 4, 5]);
  /// print(bytes.toList());  // [1, 2, 3, 4, 5]
  /// ```
  /// 
  /// Throws [InvalidArgumentException] if any value is outside byte range.
  void appendAll(List<int> bytes) {
    _bytes.addAll(bytes.map(_validateByteRange));
  }

  /// Inserts a byte at the specified index.
  /// 
  /// Example:
  /// ```dart
  /// final bytes = Byte.fromList([1, 3, 4]);
  /// bytes.insert(1, 2);
  /// print(bytes.toList());  // [1, 2, 3, 4]
  /// ```
  /// 
  /// Throws [InvalidArgumentException] if value is outside byte range.
  /// Throws [RangeError] if index is invalid.
  void insert(int index, int byte) {
    _bytes.insert(index, _validateByteRange(byte));
  }

  /// Removes the byte at the specified index.
  /// 
  /// Returns the removed byte.
  /// 
  /// Example:
  /// ```dart
  /// final bytes = Byte.fromList([1, 2, 3, 4]);
  /// final removed = bytes.removeAt(1);
  /// print(removed);         // 2
  /// print(bytes.toList());  // [1, 3, 4]
  /// ```
  /// 
  /// Throws [RangeError] if index is invalid.
  int removeAt(int index) {
    return _bytes.removeAt(index);
  }

  /// Removes all bytes from this byte array.
  /// 
  /// Example:
  /// ```dart
  /// final bytes = Byte.fromList([1, 2, 3]);
  /// bytes.clear();
  /// print(bytes.isEmpty);  // true
  /// ```
  void clear() {
    _bytes.clear();
  }

  /// Returns a sub-array of bytes from [start] to [end] (exclusive).
  /// 
  /// Example:
  /// ```dart
  /// final bytes = Byte.fromList([1, 2, 3, 4, 5]);
  /// final sub = bytes.subBytes(1, 4);
  /// print(sub.toList());  // [2, 3, 4]
  /// ```
  /// 
  /// Throws [RangeError] if indices are invalid.
  Byte subBytes(int start, [int? end]) {
    end ??= _bytes.length;
    return Byte.fromList(_bytes.sublist(start, end));
  }

  /// Returns the byte at the specified index.
  /// 
  /// Example:
  /// ```dart
  /// final bytes = Byte.fromList([10, 20, 30]);
  /// print(bytes[1]);  // 20
  /// ```
  /// 
  /// Throws [RangeError] if index is invalid.
  int operator [](int index) => _bytes[index];

  /// Sets the byte at the specified index.
  /// 
  /// Example:
  /// ```dart
  /// final bytes = Byte.fromList([10, 20, 30]);
  /// bytes[1] = 25;
  /// print(bytes.toList());  // [10, 25, 30]
  /// ```
  /// 
  /// Throws [InvalidArgumentException] if value is outside byte range.
  /// Throws [RangeError] if index is invalid.
  void operator []=(int index, int value) {
    _bytes[index] = _validateByteRange(value);
  }

  // Arithmetic operators (for single bytes)

  /// Adds two Byte values.
  /// 
  /// Both operands must represent single bytes.
  /// 
  /// Example:
  /// ```dart
  /// final a = Byte(10);
  /// final b = Byte(20);
  /// final sum = a + b;
  /// print(sum.value);  // 30
  /// ```
  /// 
  /// Throws [NoGuaranteeException] if either operand represents multiple bytes.
  /// Throws [InvalidArgumentException] if result is outside byte range.
  Byte operator +(Byte other) {
    if (!isSingleByte || !other.isSingleByte) {
      throw NoGuaranteeException('Arithmetic operations only supported for single bytes');
    }
    return Byte(_bytes[0] + other._bytes[0]);
  }

  /// Subtracts two Byte values.
  Byte operator -(Byte other) {
    if (!isSingleByte || !other.isSingleByte) {
      throw NoGuaranteeException('Arithmetic operations only supported for single bytes');
    }
    return Byte(_bytes[0] - other._bytes[0]);
  }

  /// Multiplies two Byte values.
  Byte operator *(Byte other) {
    if (!isSingleByte || !other.isSingleByte) {
      throw NoGuaranteeException('Arithmetic operations only supported for single bytes');
    }
    return Byte(_bytes[0] * other._bytes[0]);
  }

  /// Integer division of two Byte values.
  Byte operator ~/(Byte other) {
    if (!isSingleByte || !other.isSingleByte) {
      throw NoGuaranteeException('Arithmetic operations only supported for single bytes');
    }
    return Byte(_bytes[0] ~/ other._bytes[0]);
  }

  /// Modulo operation of two Byte values.
  Byte operator %(Byte other) {
    if (!isSingleByte || !other.isSingleByte) {
      throw NoGuaranteeException('Arithmetic operations only supported for single bytes');
    }
    return Byte(_bytes[0] % other._bytes[0]);
  }

  /// Unary minus operator.
  Byte operator -() {
    if (!isSingleByte) {
      throw NoGuaranteeException('Unary operations only supported for single bytes');
    }
    return Byte(-_bytes[0]);
  }

  // Comparison operators

  /// Compares this Byte with another Byte.
  /// 
  /// For single bytes, compares the byte values.
  /// For byte arrays, compares lexicographically.
  /// 
  /// Example:
  /// ```dart
  /// final a = Byte(10);
  /// final b = Byte(20);
  /// print(a.compareTo(b));  // -1 (a < b)
  /// 
  /// final arr1 = Byte.fromList([1, 2, 3]);
  /// final arr2 = Byte.fromList([1, 2, 4]);
  /// print(arr1.compareTo(arr2));  // -1 (arr1 < arr2)
  /// ```
  @override
  int compareTo(Byte other) {
    // Compare lengths first for arrays
    if (_bytes.length != other._bytes.length) {
      return _bytes.length.compareTo(other._bytes.length);
    }
    
    // Compare element by element
    for (int i = 0; i < _bytes.length; i++) {
      final comparison = _bytes[i].compareTo(other._bytes[i]);
      if (comparison != 0) return comparison;
    }
    
    return 0; // Equal
  }

  /// Less than operator.
  bool operator <(Byte other) => compareTo(other) < 0;

  /// Less than or equal operator.
  bool operator <=(Byte other) => compareTo(other) <= 0;

  /// Greater than operator.
  bool operator >(Byte other) => compareTo(other) > 0;

  /// Greater than or equal operator.
  bool operator >=(Byte other) => compareTo(other) >= 0;

  // Bitwise operators (for single bytes)

  /// Bitwise AND operation.
  /// 
  /// Example:
  /// ```dart
  /// final a = Byte(0x0F);  // 00001111
  /// final b = Byte(0x33);  // 00110011
  /// final result = a & b;  // 00000011 = 3
  /// print(result.value);   // 3
  /// ```
  Byte operator &(Byte other) {
    if (!isSingleByte || !other.isSingleByte) {
      throw NoGuaranteeException('Bitwise operations only supported for single bytes');
    }
    return Byte(_bytes[0] & other._bytes[0]);
  }

  /// Bitwise OR operation.
  Byte operator |(Byte other) {
    if (!isSingleByte || !other.isSingleByte) {
      throw NoGuaranteeException('Bitwise operations only supported for single bytes');
    }
    return Byte(_bytes[0] | other._bytes[0]);
  }

  /// Bitwise XOR operation.
  Byte operator ^(Byte other) {
    if (!isSingleByte || !other.isSingleByte) {
      throw NoGuaranteeException('Bitwise operations only supported for single bytes');
    }
    return Byte(_bytes[0] ^ other._bytes[0]);
  }

  /// Bitwise NOT operation.
  Byte operator ~() {
    if (!isSingleByte) {
      throw NoGuaranteeException('Bitwise operations only supported for single bytes');
    }
    return Byte(~_bytes[0]);
  }

  /// Left shift operation.
  Byte operator <<(int shiftAmount) {
    if (!isSingleByte) {
      throw NoGuaranteeException('Shift operations only supported for single bytes');
    }
    return Byte(_bytes[0] << shiftAmount);
  }

  /// Right shift operation.
  Byte operator >>(int shiftAmount) {
    if (!isSingleByte) {
      throw NoGuaranteeException('Shift operations only supported for single bytes');
    }
    return Byte(_bytes[0] >> shiftAmount);
  }

  // Equality and hash code

  /// Returns true if this Byte equals the specified object.
  /// 
  /// Two Byte objects are equal if they contain the same sequence of bytes.
  /// 
  /// Example:
  /// ```dart
  /// final a = Byte(42);
  /// final b = Byte(42);
  /// final c = Byte.fromList([1, 2, 3]);
  /// final d = Byte.fromList([1, 2, 3]);
  /// 
  /// print(a == b);  // true
  /// print(c == d);  // true
  /// print(a == c);  // false
  /// ```
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Byte) return false;
    
    if (_bytes.length != other._bytes.length) return false;
    
    for (int i = 0; i < _bytes.length; i++) {
      if (_bytes[i] != other._bytes[i]) return false;
    }
    
    return true;
  }

  /// Returns the hash code for this Byte.
  @override
  int get hashCode {
    int hash = 0;
    for (final byte in _bytes) {
      hash = hash * 31 + byte.hashCode;
    }
    return hash;
  }
}