import 'dart:typed_data';

import 'output_stream.dart';
import '../../exceptions.dart';

/// {@template buffered_output_stream}
/// The class implements a buffered output stream.
/// 
/// By setting up such an output stream, an application can write bytes to the
/// underlying output stream without necessarily causing a call to the underlying
/// system for each byte written.
/// 
/// ## Example Usage
/// ```dart
/// // Basic buffered writing
/// final buffered = BufferedOutputStream(FileOutputStream('output.bin'));
/// try {
///   for (int i = 0; i < 10000; i++) {
///     await buffered.writeByte(i % 256);
///   }
///   await buffered.flush(); // Ensure all data is written
/// } finally {
///   await buffered.close();
/// }
/// 
/// // Writing large amounts of data efficiently
/// final buffered = BufferedOutputStream(
///   FileOutputStream('large_output.bin'),
///   bufferSize: 65536 // 64KB buffer
/// );
/// try {
///   final data = generateLargeDataSet();
///   await buffered.write(data);
///   await buffered.flush();
/// } finally {
///   await buffered.close();
/// }
/// ```
/// 
/// {@endtemplate}
class BufferedOutputStream extends OutputStream {
  static const int _defaultBufferSize = 8192;
  
  final OutputStream _output;
  final Uint8List _buffer;
  int _count = 0; // Number of bytes in buffer
  
  /// Creates a new buffered output stream to write data to the specified
  /// underlying output stream.
  /// 
  /// ## Parameters
  /// - [output]: The underlying output stream
  /// - [bufferSize]: The buffer size (default: 8192 bytes)
  /// 
  /// ## Example
  /// ```dart
  /// final buffered = BufferedOutputStream(FileOutputStream('output.bin'));
  /// final largeBuffered = BufferedOutputStream(
  ///   FileOutputStream('huge_output.bin'), 
  ///   bufferSize: 65536
  /// );
  /// ```
  /// 
  /// {@macro buffered_output_stream}
  BufferedOutputStream(OutputStream output, {int bufferSize = _defaultBufferSize})
    : _output = output, _buffer = Uint8List(bufferSize);
  
  /// Flushes the internal buffer to the underlying output stream.
  Future<void> _flushBuffer() async {
    if (_count > 0) {
      await _output.write(_buffer, 0, _count);
      _count = 0;
    }
  }
  
  @override
  Future<void> writeByte(int b) async {
    checkClosed();
    
    if (_count >= _buffer.length) {
      await _flushBuffer();
    }
    
    _buffer[_count++] = b & 0xFF;
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
    
    // If the data is larger than our buffer, flush current buffer and write directly
    if (length >= _buffer.length) {
      await _flushBuffer();
      await _output.write(b, offset, length);
      return;
    }
    
    // If the data won't fit in the current buffer, flush it first
    if (_count + length > _buffer.length) {
      await _flushBuffer();
    }
    
    // Copy data to buffer
    _buffer.setRange(_count, _count + length, b, offset);
    _count += length;
  }

  @override
  Future<void> writeObject(Object? obj) async {
    checkClosed();
    writeString(obj.toString());
  }
  
  @override
  Future<void> flush() async {
    checkClosed();
    
    await _flushBuffer();
    await _output.flush();
  }
  
  @override
  Future<void> close() async {
    if (isClosed) return;

    try {
      await flush();
      await _output.close();
    } finally {
      await super.close();
    }
  }
  
  /// Returns the underlying output stream.
  /// 
  /// ## Returns
  /// The [OutputStream] that this buffered stream wraps.
  /// 
  /// ## Example
  /// ```dart
  /// final fileOutput = FileOutputStream('output.bin');
  /// final buffered = BufferedOutputStream(fileOutput);
  /// 
  /// assert(identical(buffered.underlyingStream, fileOutput));
  /// ```
  OutputStream get underlyingStream => _output;
  
  /// Returns the size of the internal buffer.
  /// 
  /// ## Returns
  /// The buffer size in bytes.
  /// 
  /// ## Example
  /// ```dart
  /// final buffered = BufferedOutputStream(
  ///   FileOutputStream('output.bin'), 
  ///   bufferSize: 16384
  /// );
  /// print('Buffer size: ${buffered.bufferSize}'); // 16384
  /// ```
  int get bufferSize => _buffer.length;
  
  /// Returns the number of bytes currently in the buffer.
  /// 
  /// ## Returns
  /// The number of bytes waiting to be flushed.
  /// 
  /// ## Example
  /// ```dart
  /// final buffered = BufferedOutputStream(FileOutputStream('output.bin'));
  /// await buffered.writeByte(65);
  /// print('Bytes in buffer: ${buffered.bufferedCount}'); // 1
  /// 
  /// await buffered.flush();
  /// print('Bytes in buffer: ${buffered.bufferedCount}'); // 0
  /// ```
  int get bufferedCount => _count;
  
  /// Returns the remaining space in the buffer.
  /// 
  /// ## Returns
  /// The number of bytes that can be written to the buffer before it needs to be flushed.
  /// 
  /// ## Example
  /// ```dart
  /// final buffered = BufferedOutputStream(FileOutputStream('output.bin'));
  /// print('Buffer space: ${buffered.remainingBufferSpace}'); // 8192
  /// 
  /// await buffered.writeByte(65);
  /// print('Buffer space: ${buffered.remainingBufferSpace}'); // 8191
  /// ```
  int get remainingBufferSpace => _buffer.length - _count;
}