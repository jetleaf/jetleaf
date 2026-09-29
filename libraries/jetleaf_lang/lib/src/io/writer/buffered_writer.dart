import 'writer.dart';

/// {@template buffered_writer}
/// Writes text to a character-output stream, buffering characters to provide
/// efficient writing of characters, arrays, and strings.
/// 
/// The buffer size may be specified, or the default size may be used. The
/// default is large enough for most purposes.
/// 
/// ## Example Usage
/// ```dart
/// // Basic buffered writing
/// final buffered = BufferedWriter(FileWriter('output.txt'));
/// try {
///   await buffered.write('Hello, World!');
///   await buffered.writeLine('This is a new line.');
///   await buffered.flush();
/// } finally {
///   await buffered.close();
/// }
/// 
/// // Writing large amounts of data efficiently
/// final buffered = BufferedWriter(FileWriter('large_output.txt'), bufferSize: 65536);
/// try {
///   for (int i = 0; i < 10000; i++) {
///     await buffered.writeLine('Record $i: ${generateLargeString()}');
///   }
///   await buffered.flush();
/// } finally {
///   await buffered.close();
/// }
/// ```
/// 
/// {@endtemplate}
class BufferedWriter extends Writer {
  static const int _defaultBufferSize = 8192;
  
  final Writer _writer;
  final List<int> _buffer;
  int _position = 0;   // Current position in buffer
  
  /// Creates a buffering character-output stream that uses a default-sized output buffer.
  /// 
  /// ## Parameters
  /// - [writer]: The underlying character writer
  /// - [bufferSize]: The buffer size (default: 8192 characters)
  /// 
  /// ## Example
  /// ```dart
  /// final buffered = BufferedWriter(FileWriter('output.txt'));
  /// final largeBuffered = BufferedWriter(
  ///   FileWriter('large_output.txt'), 
  ///   bufferSize: 65536
  /// );
  /// ```
  /// 
  /// {@macro buffered_writer}
  BufferedWriter(Writer writer, {int bufferSize = _defaultBufferSize})
      : _writer = writer,
        _buffer = List<int>.filled(bufferSize, 0);
  
  /// Flushes the buffer and ensures all data is written to the underlying writer.
  /// 
  /// This method is called automatically when the buffer is full or when
  /// [close] is called. It's also a good practice to call this method before
  /// reading from the stream to ensure all data is written.
  @override
  Future<void> flush() async {
    if (_position > 0) {
      await _writer.writeChars(_buffer, 0, _position);
      _position = 0;
    }
    await _writer.flush();
  }
  
  /// Writes a single character to the buffer.
  /// 
  /// The character to be written is contained in the 16 low-order bits of the
  /// given integer value; the 16 high-order bits are ignored.
  @override
  Future<void> writeChar(int c) async {
    if (_position >= _buffer.length) {
      await flush();
    }
    _buffer[_position++] = c & 0xFFFF;
  }
  
  /// Writes a string to the buffer.
  /// 
  /// This method writes the characters of the string to the buffer. If the
  /// buffer becomes full during writing, it will be automatically flushed.
  @override
  Future<void> write(String str, [int off = 0, int? len]) async {
    len ??= str.length - off;
    for (int i = 0; i < len; i++) {
      await writeChar(str.codeUnitAt(off + i));
    }
  }
  
  /// Writes a line of text to the buffer.
  /// 
  /// This method writes the specified string followed by a line separator.
  /// The line separator is platform-dependent and is obtained from the
  /// underlying writer.
  @override
  Future<void> writeLine([String? str]) async {
    if (str != null) {
      await write(str);
    }
    await write('\n');  // Using \n as the default line separator
  }
  
  /// Closes the writer and releases any system resources associated with it.
  /// 
  /// This method first flushes any remaining data in the buffer, then closes
  /// the underlying writer. After this method is called, any further attempts
  /// to use the writer will result in an [IOException].
  @override
  Future<void> close() async {
    if (isClosed) return;
    
    try {
      await flush();
    } finally {
      await _writer.close();
      await super.close();
    }
  }
  
  /// Writes a portion of a character array to the buffer.
  /// 
  /// This method writes `len` characters from the array `buf` starting at
  /// index `off`. If the buffer becomes full during writing, it will be
  /// automatically flushed.
  @override
  Future<void> writeChars(List<int> buf, [int off = 0, int? len]) async {
    len ??= buf.length - off;
    for (int i = 0; i < len; i++) {
      await writeChar(buf[off + i]);
    }
  }
}
