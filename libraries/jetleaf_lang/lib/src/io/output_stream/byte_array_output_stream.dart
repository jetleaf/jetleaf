import 'dart:typed_data';

import '../../exceptions.dart';
import 'output_stream.dart';

/// {@template byte_array_output_stream}
/// An [OutputStream] that writes to a growable internal byte buffer.
///
/// `ByteArrayOutputStream` provides an in-memory output sink similar to Java's
/// `ByteArrayOutputStream`. It allows binary data to be written sequentially
/// and later retrieved as a single [Uint8List] for processing, storage, or transmission.
///
/// This stream grows automatically as more bytes are written, making it suitable
/// for dynamic or unknown-length binary outputs.
///
/// ---
///
/// ### 🔧 Example:
/// ```dart
/// final stream = ByteArrayOutputStream();
/// stream.writeByte(104); // h
/// stream.writeByte(105); // i
///
/// final result = stream.toBytes();
/// print(String.fromCharCodes(result)); // hi
/// ```
///
/// ---
///
/// ### ✅ Use Cases:
/// - Buffering binary content before sending to a file or network.
/// - Serializing data in memory.
/// - Mocking writable streams during testing.
/// {@endtemplate}
class ByteArrayOutputStream extends OutputStream {
  static const int _defaultInitialCapacity = 32;

  Uint8List _buffer;
  int _count = 0;

  /// {@macro byte_array_output_stream}
  ///
  /// Creates a new [ByteArrayOutputStream] with an optional [initialCapacity].
  /// If not provided, defaults to `32` bytes.
  ///
  /// The internal buffer will automatically grow when needed.
  ByteArrayOutputStream([int initialCapacity = _defaultInitialCapacity]) : _buffer = Uint8List(initialCapacity);
  
  @override
  Future<void> writeByte(int b) async {
    checkClosed();

    _ensureCapacity(_count + 1);
    _buffer[_count++] = b & 0xFF;
  }

  @override
  Future<void> writeObject(Object? obj) async {
    checkClosed();
    writeString(obj.toString());
  }
  
  @override
  Future<void> write(List<int> b, [int offset = 0, int? length]) async {
    checkClosed();

    length ??= b.length - offset;    
    if (offset < 0 || length < 0 || offset + length > b.length) {
      throw InvalidArgumentException('Invalid offset or length');
    }
    
    if (length == 0) {
      return;
    }
    
    _ensureCapacity(_count + length);
    
    for (int i = 0; i < length; i++) {
      _buffer[_count + i] = b[offset + i] & 0xFF;
    }
    
    _count += length;
  }
  
  /// Writes the contents of another ByteArrayOutputStream to this stream.
  /// 
  /// [other] - The ByteArrayOutputStream to write from
  Future<void> writeTo(ByteArrayOutputStream other) async {
    checkClosed();

    await write(other._buffer, 0, other._count);
  }
  
  /// Returns a copy of the current contents as a byte array.
  /// 
  /// Returns a new Uint8List containing the written data.
  Uint8List toByteArray() => Uint8List.fromList(_buffer.take(_count).toList());
  
  /// Returns the current size of the buffer (number of bytes written).
  int size() => _count;
  
  /// Returns the current contents as a string using UTF-8 encoding.
  /// 
  /// [encoding] - The character encoding to use (defaults to UTF-8)
  /// 
  /// Returns the contents as a string.
  @override
  String toString([String encoding = 'utf-8']) => String.fromCharCodes(_buffer.take(_count));
  
  /// Resets the buffer to empty, discarding all written data.
  void reset() {
    checkClosed();

    _count = 0;
  }
  
  /// Ensures the buffer has at least the specified capacity.
  void _ensureCapacity(int minCapacity) {
    if (minCapacity > _buffer.length) {
      _grow(minCapacity);
    }
  }
  
  /// Grows the buffer to accommodate the specified minimum capacity.
  void _grow(int minCapacity) {
    final oldCapacity = _buffer.length;
    var newCapacity = oldCapacity * 2;
    
    if (newCapacity < minCapacity) {
      newCapacity = minCapacity;
    }
    
    final newBuffer = Uint8List(newCapacity);
    newBuffer.setRange(0, _count, _buffer);
    _buffer = newBuffer;
  }
}