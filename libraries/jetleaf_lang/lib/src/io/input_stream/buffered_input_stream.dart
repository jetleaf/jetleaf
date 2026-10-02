import 'dart:typed_data';

import 'input_stream.dart';
import '../../exceptions.dart';

/// {@template buffered_input_stream}
/// A [BufferedInputStream] adds functionality to another input stream-namely,
/// the ability to buffer the input and to support the [mark] and [reset] methods.
/// 
/// When the [BufferedInputStream] is created, an internal buffer array is created.
/// As bytes from the stream are read or skipped, the internal buffer is refilled
/// as necessary from the contained input stream, many bytes at a time.
/// 
/// ## Example Usage
/// ```dart
/// // Basic buffered reading
/// final buffered = BufferedInputStream(FileInputStream('large_file.bin'));
/// try {
///   final buffer = Uint8List(1024);
///   int bytesRead;
///   while ((bytesRead = await buffered.read(buffer)) != -1) {
///     processData(buffer.sublist(0, bytesRead));
///   }
/// } finally {
///   await buffered.close();
/// }
/// 
/// // Using mark and reset
/// final buffered = BufferedInputStream(FileInputStream('data.bin'));
/// try {
///   buffered.mark(1024); // Mark current position
///   
///   final header = await buffered.readFully(10);
///   if (!isValidHeader(header)) {
///     await buffered.reset(); // Go back to marked position
///     processAsRawData(buffered);
///   } else {
///     processStructuredData(buffered);
///   }
/// } finally {
///   await buffered.close();
/// }
/// ```
/// 
/// {@endtemplate}
class BufferedInputStream extends InputStream {
  static const int _defaultBufferSize = 8192;
  
  final InputStream _input;
  final Uint8List _buffer;
  int _count = 0;      // Number of valid bytes in buffer
  int _position = 0;   // Current position in buffer
  int _markPosition = -1; // Mark position in buffer
  int _markLimit = 0;  // Read limit for mark
  
  /// Creates a [BufferedInputStream] and saves its argument, the input stream
  /// [input], for later use.
  /// 
  /// ## Parameters
  /// - [input]: The underlying input stream
  /// - [bufferSize]: The buffer size (default: 8192 bytes)
  /// 
  /// ## Example
  /// ```dart
  /// final buffered = BufferedInputStream(FileInputStream('data.bin'));
  /// final largeBuffered = BufferedInputStream(
  ///   FileInputStream('huge_file.bin'), 
  ///   bufferSize: 65536
  /// );
  /// ```
  /// 
  /// {@macro buffered_input_stream}
  BufferedInputStream(InputStream input, {int bufferSize = _defaultBufferSize})
      : _input = input,
        _buffer = Uint8List(bufferSize);
  
  /// Fills the buffer with data from the underlying input stream.
  Future<void> _fillBuffer() async {
    if (_markPosition < 0) {
      // No mark set, can use entire buffer
      _position = 0;
      _count = await _input.read(_buffer);
      if (_count == -1) {
        _count = 0;
      }
    } else {
      // Mark is set, need to preserve marked data
      if (_position >= _markLimit) {
        // Mark is no longer valid
        _markPosition = -1;
        _position = 0;
        _count = await _input.read(_buffer);
        if (_count == -1) {
          _count = 0;
        }
      } else {
        // Shift buffer to preserve marked data
        final preserveCount = _count - _markPosition;
        _buffer.setRange(0, preserveCount, _buffer, _markPosition);
        _position -= _markPosition;
        _count = preserveCount;
        _markPosition = 0;
        
        // Fill rest of buffer
        final bytesRead = await _input.read(_buffer, _count, _buffer.length - _count);
        if (bytesRead > 0) {
          _count += bytesRead;
        }
      }
    }
  }
  
  @override
  Future<int> readByte() async {
    checkClosed();
    
    if (_position >= _count) {
      await _fillBuffer();
      if (_count == 0) {
        return -1; // End of stream
      }
    }
    
    return _buffer[_position++];
  }
  
  @override
  Future<int> read(List<int> b, [int offset = 0, int? length]) async {
    checkClosed();
    
    length ??= b.length - offset;
    
    if (offset < 0 || length < 0 || offset + length > b.length) {
      throw InvalidArgumentException('Invalid offset or length');
    }
    
    if (length == 0) {
      return 0;
    }
    
    int totalRead = 0;
    
    // First, read from buffer if available
    if (_position < _count) {
      final availableInBuffer = _count - _position;
      final toReadFromBuffer = length.clamp(0, availableInBuffer);
      
      b.setRange(offset, offset + toReadFromBuffer, _buffer, _position);
      _position += toReadFromBuffer;
      totalRead += toReadFromBuffer;
      offset += toReadFromBuffer;
      length -= toReadFromBuffer;
    }
    
    // If we need more data and the request is large, read directly
    if (length > 0 && length >= _buffer.length) {
      final directRead = await _input.read(b, offset, length);
      if (directRead > 0) {
        totalRead += directRead;
      } else if (totalRead == 0) {
        return -1; // End of stream
      }
    } else if (length > 0) {
      // Fill buffer and read from it
      await _fillBuffer();
      if (_count > 0) {
        final toRead = length.clamp(0, _count);
        b.setRange(offset, offset + toRead, _buffer, 0);
        _position = toRead;
        totalRead += toRead;
      } else if (totalRead == 0) {
        return -1; // End of stream
      }
    }
    
    return totalRead;
  }
  
  @override
  Future<int> skip(int n) async {
    checkClosed();
    
    if (n <= 0) {
      return 0;
    }
    
    int totalSkipped = 0;
    
    // First, skip from buffer if available
    if (_position < _count) {
      final availableInBuffer = _count - _position;
      final toSkipFromBuffer = n.clamp(0, availableInBuffer);
      _position += toSkipFromBuffer;
      totalSkipped += toSkipFromBuffer;
      n -= toSkipFromBuffer;
    }
    
    // If we need to skip more, delegate to underlying stream
    if (n > 0) {
      final skippedFromStream = await _input.skip(n);
      totalSkipped += skippedFromStream;
    }
    
    return totalSkipped;
  }
  
  @override
  Future<int> available() async {
    checkClosed();
    
    final bufferedAvailable = _count - _position;
    final streamAvailable = await _input.available();
    return bufferedAvailable + streamAvailable;
  }
  
  @override
  bool markSupported() => true;
  
  @override
  void mark(int readLimit) {
    if (isClosed) {
      return;
    }
    
    _markLimit = readLimit;
    _markPosition = _position;
  }
  
  @override
  Future<void> reset() async {
    checkClosed();
    
    if (_markPosition < 0) {
      throw IOException('Mark not set or invalidated');
    }
    
    _position = _markPosition;
  }
  
  @override
  Future<void> close() async {
    if (!isClosed) {
      try {
        await _input.close();
      } finally {
        await super.close();
      }
    }
  }
  
  /// Returns the underlying input stream.
  /// 
  /// ## Returns
  /// The [InputStream] that this buffered stream wraps.
  /// 
  /// ## Example
  /// ```dart
  /// final fileInput = FileInputStream('data.bin');
  /// final buffered = BufferedInputStream(fileInput);
  /// 
  /// assert(identical(buffered.underlyingStream, fileInput));
  /// ```
  InputStream get underlyingStream => _input;
  
  /// Returns the size of the internal buffer.
  /// 
  /// ## Returns
  /// The buffer size in bytes.
  /// 
  /// ## Example
  /// ```dart
  /// final buffered = BufferedInputStream(
  ///   FileInputStream('data.bin'), 
  ///   bufferSize: 16384
  /// );
  /// print('Buffer size: ${buffered.bufferSize}'); // 16384
  /// ```
  int get bufferSize => _buffer.length;
  
  /// Returns the number of bytes currently available in the buffer.
  /// 
  /// ## Returns
  /// The number of bytes that can be read without accessing the underlying stream.
  /// 
  /// ## Example
  /// ```dart
  /// final buffered = BufferedInputStream(FileInputStream('data.bin'));
  /// await buffered.readByte(); // This may fill the buffer
  /// print('Bytes in buffer: ${buffered.bufferedCount}');
  /// ```
  int get bufferedCount => _count - _position;
}