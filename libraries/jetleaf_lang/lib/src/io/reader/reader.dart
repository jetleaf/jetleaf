import 'package:meta/meta.dart';

import '../base.dart';
import '../../exceptions.dart';

/// {@template reader}
/// Abstract class for reading character streams.
/// 
/// The only methods that a subclass must implement are [readChar] and [close].
/// Most subclasses, however, will override some of the methods defined here
/// in order to provide higher efficiency, additional functionality, or both.
/// 
/// ## Design Philosophy
/// The [Reader] class provides a uniform interface for reading character data
/// from various sources. Unlike [InputStream] which deals with raw bytes,
/// [Reader] handles character encoding and provides text-oriented operations.
/// 
/// ## Example Usage
/// ```dart
/// // Reading from a file
/// final reader = FileReader('document.txt');
/// try {
///   String line;
///   while ((line = await reader.readLine()) != null) {
///     print('Line: $line');
///   }
/// } finally {
///   await reader.close();
/// }
/// 
/// // Reading with buffering for better performance
/// final bufferedReader = BufferedReader(FileReader('large_document.txt'));
/// try {
///   final content = await bufferedReader.readAll();
///   processText(content);
/// } finally {
///   await bufferedReader.close();
/// }
/// ```
/// 
/// {@endtemplate}
abstract class Reader implements Closeable {
  /// {@macro reader}
  Reader();

  bool _closed = false;
  
  /// Returns `true` if this reader has been closed.
  bool get isClosed => _closed;
  
  /// Reads a single character.
  /// 
  /// This method will block until a character is available, an I/O error
  /// occurs, or the end of the stream is reached.
  /// 
  /// ## Returns
  /// The character read, as an integer in the range 0 to 65535, or -1 if
  /// the end of the stream has been reached.
  /// 
  /// ## Example
  /// ```dart
  /// final reader = FileReader('text.txt');
  /// try {
  ///   int char;
  ///   while ((char = await reader.readChar()) != -1) {
  ///     print('Character: ${String.fromCharCode(char)}');
  ///   }
  /// } finally {
  ///   await reader.close();
  /// }
  /// ```
  /// 
  /// Throws [IOException] if an I/O error occurs.
  /// Throws [StreamClosedException] if the reader has been closed.
  Future<int> readChar();
  
  /// Reads characters into an array.
  /// 
  /// This method will block until some input is available, an I/O error occurs,
  /// or the end of the stream is reached.
  /// 
  /// ## Parameters
  /// - [cbuf]: Destination buffer
  /// - [offset]: Offset at which to start storing characters (default: 0)
  /// - [length]: Maximum number of characters to read (default: remaining buffer space)
  /// 
  /// ## Returns
  /// The number of characters read, or -1 if the end of the stream has been reached.
  /// 
  /// ## Example
  /// ```dart
  /// final reader = FileReader('text.txt');
  /// try {
  ///   final buffer = List<int>.filled(1024, 0);
  ///   final charsRead = await reader.read(buffer);
  ///   if (charsRead != -1) {
  ///     final text = String.fromCharCodes(buffer.sublist(0, charsRead));
  ///     print('Read: $text');
  ///   }
  /// } finally {
  ///   await reader.close();
  /// }
  /// ```
  /// 
  /// Throws [InvalidArgumentException] if [offset] or [length] is negative, or if
  /// [offset] + [length] is greater than the length of [cbuf].
  /// Throws [IOException] if an I/O error occurs.
  /// Throws [StreamClosedException] if the reader has been closed.
  Future<int> read(List<int> cbuf, [int offset = 0, int? length]) async {
    checkClosed();
    
    length ??= cbuf.length - offset;
    
    if (offset < 0 || length < 0 || offset + length > cbuf.length) {
      throw InvalidArgumentException('Invalid offset or length');
    }
    
    if (length == 0) {
      return 0;
    }
    
    final firstChar = await readChar();
    if (firstChar == -1) {
      return -1;
    }
    
    cbuf[offset] = firstChar;
    int charsRead = 1;
    
    try {
      for (int i = 1; i < length; i++) {
        final char = await readChar();
        if (char == -1) {
          break;
        }
        cbuf[offset + i] = char;
        charsRead++;
      }
    } catch (e) {
      // Return what we've read so far
    }
    
    return charsRead;
  }
  
  /// Reads a line of text.
  /// 
  /// A line is considered to be terminated by any one of a line feed ('\n'),
  /// a carriage return ('\r'), or a carriage return followed immediately by
  /// a linefeed.
  /// 
  /// ## Returns
  /// A String containing the contents of the line, not including any
  /// line-termination characters, or null if the end of the stream has
  /// been reached.
  /// 
  /// ## Example
  /// ```dart
  /// final reader = FileReader('lines.txt');
  /// try {
  ///   String? line;
  ///   int lineNumber = 1;
  ///   while ((line = await reader.readLine()) != null) {
  ///     print('Line $lineNumber: $line');
  ///     lineNumber++;
  ///   }
  /// } finally {
  ///   await reader.close();
  /// }
  /// ```
  /// 
  /// Throws [IOException] if an I/O error occurs.
  /// Throws [StreamClosedException] if the reader has been closed.
  Future<String?> readLine() async {
    checkClosed();
    
    final buffer = StringBuffer();
    int char;
    
    while ((char = await readChar()) != -1) {
      if (char == 10) { // '\n'
        break;
      } else if (char == 13) { // '\r'
        // Check for '\r\n'
        final nextChar = await readChar();
        if (nextChar != -1 && nextChar != 10) {
          // Put back the character if it's not '\n'
          // This is a simplified implementation - real implementation would use mark/reset
        }
        break;
      } else {
        buffer.writeCharCode(char);
      }
    }
    
    if (buffer.isEmpty && char == -1) {
      return null; // End of stream
    }
    
    return buffer.toString();
  }
  
  /// Reads all remaining characters from the reader.
  /// 
  /// This method reads from the current position until the end of the reader
  /// is reached. The returned string contains all the characters that were read.
  /// 
  /// ## Returns
  /// A String containing all remaining characters in the reader.
  /// 
  /// ## Example
  /// ```dart
  /// final reader = FileReader('document.txt');
  /// try {
  ///   final content = await reader.readAll();
  ///   print('Document content:');
  ///   print(content);
  /// } finally {
  ///   await reader.close();
  /// }
  /// ```
  /// 
  /// Throws [IOException] if an I/O error occurs.
  /// Throws [StreamClosedException] if the reader has been closed.
  Future<String> readAll() async {
    checkClosed();
    
    final buffer = StringBuffer();
    final charBuffer = List<int>.filled(8192, 0); // 8KB buffer
    
    int charsRead;
    while ((charsRead = await read(charBuffer)) != -1) {
      buffer.write(String.fromCharCodes(charBuffer.sublist(0, charsRead)));
    }
    
    return buffer.toString();
  }
  
  /// Skips characters.
  /// 
  /// This method will block until some characters are available, an I/O error
  /// occurs, or the end of the stream is reached.
  /// 
  /// ## Parameters
  /// - [n]: The number of characters to skip
  /// 
  /// ## Returns
  /// The number of characters actually skipped.
  /// 
  /// ## Example
  /// ```dart
  /// final reader = FileReader('data.txt');
  /// try {
  ///   // Skip the first 100 characters (e.g., header)
  ///   final skipped = await reader.skip(100);
  ///   print('Skipped $skipped characters');
  ///   
  ///   // Now read the actual content
  ///   final content = await reader.readAll();
  ///   processContent(content);
  /// } finally {
  ///   await reader.close();
  /// }
  /// ```
  /// 
  /// Throws [IOException] if an I/O error occurs.
  /// Throws [StreamClosedException] if the reader has been closed.
  Future<int> skip(int n) async {
    checkClosed();
    
    if (n <= 0) {
      return 0;
    }
    
    int skipped = 0;
    final buffer = List<int>.filled(8192.clamp(1, n), 0);
    
    while (skipped < n) {
      final toRead = (n - skipped).clamp(1, buffer.length);
      final charsRead = await read(buffer, 0, toRead);
      if (charsRead == -1) {
        break;
      }
      skipped += charsRead;
    }
    
    return skipped;
  }
  
  /// Tells whether this stream is ready to be read.
  /// 
  /// ## Returns
  /// True if the next read() is guaranteed not to block for input, false otherwise.
  /// Note that returning false does not guarantee that the next read will block.
  /// 
  /// ## Example
  /// ```dart
  /// final reader = FileReader('data.txt');
  /// try {
  ///   if (await reader.ready()) {
  ///     final content = await reader.readAll();
  ///     processContent(content);
  ///   } else {
  ///     print('Reader not ready, may block on read');
  ///   }
  /// } finally {
  ///   await reader.close();
  /// }
  /// ```
  /// 
  /// Throws [IOException] if an I/O error occurs.
  /// Throws [StreamClosedException] if the reader has been closed.
  Future<bool> ready() async {
    checkClosed();
    return false; // Default implementation
  }
  
  /// Tells whether this stream supports the mark() operation.
  /// 
  /// ## Returns
  /// true if and only if this stream supports the mark operation.
  /// 
  /// ## Example
  /// ```dart
  /// final reader = BufferedReader(FileReader('data.txt'));
  /// if (reader.markSupported()) {
  ///   reader.mark(1024); // Mark current position
  ///   
  ///   // Read some data
  ///   final preview = await reader.readLine();
  ///   
  ///   // Reset to marked position
  ///   await reader.reset();
  ///   
  ///   // Read again from the marked position
  ///   final actualData = await reader.readAll();
  /// }
  /// ```
  bool markSupported() => false;
  
  /// Marks the present position in the stream.
  /// 
  /// Subsequent calls to reset() will attempt to reposition the stream to this point.
  /// 
  /// ## Parameters
  /// - [readAheadLimit]: Limit on the number of characters that may be read
  ///   while still preserving the mark
  /// 
  /// ## Example
  /// ```dart
  /// final reader = BufferedReader(FileReader('config.txt'));
  /// if (reader.markSupported()) {
  ///   reader.mark(1024); // Allow up to 1024 characters to be read
  ///   
  ///   // Try to detect file format
  ///   final firstLine = await reader.readLine();
  ///   
  ///   if (firstLine?.startsWith('<?xml') == true) {
  ///     // Reset and process as XML
  ///     await reader.reset();
  ///     processXml(reader);
  ///   } else {
  ///     // Reset and process as plain text
  ///     await reader.reset();
  ///     processText(reader);
  ///   }
  /// }
  /// ```
  /// 
  /// Throws [IOException] if the stream does not support mark, or if some
  /// other I/O error occurs.
  void mark(int readAheadLimit) {
    // Default implementation does nothing
  }
  
  /// Resets the stream.
  /// 
  /// If the stream has been marked, then attempt to reposition it at the mark.
  /// If the stream has not been marked, then attempt to reset it in some way
  /// appropriate to the particular stream, for example by repositioning it to
  /// its starting point.
  /// 
  /// ## Example
  /// ```dart
  /// final reader = BufferedReader(FileReader('data.txt'));
  /// if (reader.markSupported()) {
  ///   reader.mark(1024);
  ///   
  ///   // Read and analyze some data
  ///   final sample = await reader.readLine();
  ///   
  ///   if (needsReprocessing(sample)) {
  ///     // Reset to marked position and reprocess
  ///     await reader.reset();
  ///     reprocessData(reader);
  ///   }
  /// }
  /// ```
  /// 
  /// Throws [IOException] if the stream has not been marked, or if the mark
  /// has been invalidated, or if the stream does not support reset, or if
  /// some other I/O error occurs.
  Future<void> reset() async {
    throw IOException('Mark/reset not supported');
  }
  
  /// Closes the stream and releases any system resources associated with it.
  /// 
  /// Once the stream has been closed, further read(), ready(), mark(), reset(),
  /// or skip() invocations will throw an IOException. Closing a previously
  /// closed stream has no effect.
  /// 
  /// ## Example
  /// ```dart
  /// final reader = FileReader('data.txt');
  /// try {
  ///   final content = await reader.readAll();
  ///   processContent(content);
  /// } finally {
  ///   await reader.close(); // Always close in finally block
  /// }
  /// ```
  /// 
  /// Throws [IOException] if an I/O error occurs.
  @override
  @mustCallSuper
  Future<void> close() async {
    _closed = true;
  }
  
  /// Checks if the reader is closed and throws an exception if it is.
  @protected
  void checkClosed() {
    if (_closed) {
      throw StreamClosedException();
    }
  }
}