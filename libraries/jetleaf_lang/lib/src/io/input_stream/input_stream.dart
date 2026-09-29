import 'dart:convert';
import 'dart:typed_data';

import 'package:meta/meta.dart';

import '../base.dart';
import '../../exceptions.dart';

/// {@template input_stream}
/// This abstract class is the superclass of all classes representing an input
/// stream of bytes.
/// 
/// Applications that need to define a subclass of [InputStream] must always
/// provide a method that returns the next byte of input.
/// 
/// ## Design Philosophy
/// The [InputStream] class provides a uniform interface for reading data from
/// various sources such as files, network connections, or memory buffers.
/// It follows the decorator pattern, allowing streams to be wrapped with
/// additional functionality like buffering or filtering.
/// 
/// ## Example Usage
/// ```dart
/// // Reading from a file
/// final input = FileInputStream('data.bin');
/// try {
///   final buffer = Uint8List(1024);
///   int bytesRead;
///   while ((bytesRead = await input.read(buffer)) != -1) {
///     // Process the data in buffer[0..bytesRead-1]
///     processData(buffer.sublist(0, bytesRead));
///   }
/// } finally {
///   await input.close();
/// }
/// 
/// // Reading with buffering for better performance
/// final bufferedInput = BufferedInputStream(FileInputStream('large_file.bin'));
/// try {
///   final data = await bufferedInput.readFully(1024);
///   processData(data);
/// } finally {
///   await bufferedInput.close();
/// }
/// ```
/// 
/// {@endtemplate}
abstract class InputStream implements Closeable {
  /// {@macro input_stream}
  InputStream();

  bool _closed = false;
  
  /// Returns `true` if this stream has been closed.
  bool get isClosed => _closed;
  
  /// Reads the next byte of data from the input stream.
  /// 
  /// The value byte is returned as an `int` in the range `0` to `255`.
  /// If no byte is available because the end of the stream has been reached,
  /// the value `-1` is returned.
  /// 
  /// This method blocks until input data is available, the end of the stream
  /// is detected, or an exception is thrown.
  /// 
  /// ## Returns
  /// The next byte of data, or `-1` if the end of the stream is reached.
  /// 
  /// ## Example
  /// ```dart
  /// final input = FileInputStream('data.txt');
  /// int byte;
  /// while ((byte = await input.readByte()) != -1) {
  ///   print('Read byte: $byte');
  /// }
  /// await input.close();
  /// ```
  /// 
  /// Throws [IOException] if an I/O error occurs.
  /// Throws [StreamClosedException] if the stream has been closed.
  Future<int> readByte();
  
  /// Reads some number of bytes from the input stream and stores them into
  /// the buffer array [b].
  /// 
  /// The number of bytes actually read is returned as an integer. This method
  /// blocks until input data is available, end of file is detected, or an
  /// exception is thrown.
  /// 
  /// If the length of [b] is zero, then no bytes are read and `0` is returned;
  /// otherwise, there is an attempt to read at least one byte. If no byte is
  /// available because the stream is at the end of the file, the value `-1`
  /// is returned; otherwise, at least one byte is read and stored into [b].
  /// 
  /// ## Parameters
  /// - [b]: The buffer into which the data is read
  /// - [offset]: The start offset in array [b] at which the data is written
  /// - [length]: The maximum number of bytes to read
  /// 
  /// ## Returns
  /// The total number of bytes read into the buffer, or `-1` if there is no
  /// more data because the end of the stream has been reached.
  /// 
  /// ## Example
  /// ```dart
  /// final input = FileInputStream('data.bin');
  /// final buffer = Uint8List(1024);
  /// 
  /// // Read up to 1024 bytes
  /// final bytesRead = await input.read(buffer);
  /// if (bytesRead != -1) {
  ///   print('Read $bytesRead bytes');
  ///   processData(buffer.sublist(0, bytesRead));
  /// }
  /// 
  /// // Read into a specific portion of the buffer
  /// final partialRead = await input.read(buffer, 100, 500);
  /// await input.close();
  /// ```
  /// 
  /// Throws [InvalidArgumentException] if [offset] or [length] is negative, or if
  /// [offset] + [length] is greater than the length of [b].
  /// Throws [IOException] if an I/O error occurs.
  /// Throws [StreamClosedException] if the stream has been closed.
  Future<int> read(List<int> b, [int offset = 0, int? length]) async {
    checkClosed();
    
    length ??= b.length - offset;
    
    if (offset < 0 || length < 0 || offset + length > b.length) {
      throw InvalidArgumentException('Invalid offset or length');
    }
    
    if (length == 0) {
      return 0;
    }
    
    final firstByte = await readByte();
    if (firstByte == -1) {
      return -1;
    }
    
    b[offset] = firstByte;
    int bytesRead = 1;
    
    try {
      for (int i = 1; i < length; i++) {
        final byte = await readByte();
        if (byte == -1) {
          break;
        }
        b[offset + i] = byte;
        bytesRead++;
      }
    } catch (e) {
      // Return what we've read so far
    }
    
    return bytesRead;
  }

  /// Reads all remaining bytes from this input stream and decodes them into a [String].
  ///
  /// This method reads the entire stream from the current position until the end
  /// and then converts the bytes to a string using the specified [encoding].
  /// 
  /// The default encoding is [Closeable.DEFAULT_ENCODING].
  ///
  /// ## Parameters
  /// - [encoding]: The [Encoding] used to decode the byte data. Defaults to [Closeable.DEFAULT_ENCODING].
  ///
  /// ## Returns
  /// A [String] representing the decoded contents of the input stream.
  ///
  /// ## Example
  /// ```dart
  /// final input = FileInputStream('message.txt');
  /// try {
  ///   final text = await input.readAsString(encoding: Closeable.DEFAULT_ENCODING);
  ///   print('File contents: $text');
  /// } finally {
  ///   await input.close();
  /// }
  /// ```
  ///
  /// ## Throws
  /// - [StreamClosedException] if the stream has been closed.
  /// - [IOException] if an I/O or decoding error occurs.
  Future<String> readAsString([Encoding encoding = Closeable.DEFAULT_ENCODING]) async {
    checkClosed();

    try {
      final bytes = await readAll();
      return encoding.decode(bytes);
    } on FormatException catch (e) {
      throw IOException('Failed to decode stream: ${e.message}');
    }
  }
  
  /// Reads exactly [length] bytes from the input stream.
  /// 
  /// This method repeatedly calls [read] until exactly [length] bytes have
  /// been read or the end of stream is reached. If the end of stream is
  /// reached before [length] bytes are read, an [EndOfStreamException] is thrown.
  /// 
  /// ## Parameters
  /// - [length]: The exact number of bytes to read
  /// 
  /// ## Returns
  /// A [Uint8List] containing exactly [length] bytes.
  /// 
  /// ## Example
  /// ```dart
  /// final input = FileInputStream('data.bin');
  /// try {
  ///   // Read exactly 1024 bytes
  ///   final data = await input.readFully(1024);
  ///   print('Read exactly ${data.length} bytes');
  ///   processData(data);
  /// } catch (EndOfStreamException e) {
  ///   print('File was shorter than expected');
  /// } finally {
  ///   await input.close();
  /// }
  /// ```
  /// 
  /// Throws [EndOfStreamException] if the end of stream is reached before
  /// [length] bytes are read.
  /// Throws [IOException] if an I/O error occurs.
  /// Throws [StreamClosedException] if the stream has been closed.
  Future<Uint8List> readFully(int length) async {
    checkClosed();
    
    final buffer = Uint8List(length);
    int totalRead = 0;
    
    while (totalRead < length) {
      final bytesRead = await read(buffer, totalRead, length - totalRead);
      if (bytesRead == -1) {
        throw EndOfStreamException('Expected $length bytes but only $totalRead available');
      }
      totalRead += bytesRead;
    }
    
    return buffer;
  }
  
  /// Reads all remaining bytes from the input stream.
  /// 
  /// This method reads from the current position until the end of the stream
  /// is reached. The returned list contains all the bytes that were read.
  /// 
  /// ## Returns
  /// A [Uint8List] containing all remaining bytes in the stream.
  /// 
  /// ## Example
  /// ```dart
  /// final input = FileInputStream('small_file.txt');
  /// try {
  ///   final allData = await input.readAll();
  ///   print('Read ${allData.length} bytes total');
  ///   final text = String.fromCharCodes(allData);
  ///   print('Content: $text');
  /// } finally {
  ///   await input.close();
  /// }
  /// ```
  /// 
  /// Throws [IOException] if an I/O error occurs.
  /// Throws [StreamClosedException] if the stream has been closed.
  Future<Uint8List> readAll() async {
    checkClosed();
    
    final chunks = <List<int>>[];
    final buffer = Uint8List(8192); // 8KB buffer
    int totalLength = 0;
    
    int bytesRead;
    while ((bytesRead = await read(buffer)) != -1) {
      chunks.add(Uint8List.fromList(buffer.sublist(0, bytesRead)));
      totalLength += bytesRead;
    }
    
    // Combine all chunks into a single array
    final result = Uint8List(totalLength);
    int offset = 0;
    for (final chunk in chunks) {
      result.setRange(offset, offset + chunk.length, chunk);
      offset += chunk.length;
    }
    
    return result;
  }
  
  /// Skips over and discards [n] bytes of data from this input stream.
  /// 
  /// The [skip] method may, for a variety of reasons, end up skipping over
  /// some smaller number of bytes, possibly `0`. This may result from any of
  /// a number of conditions; reaching end of file before [n] bytes have been
  /// skipped is only one possibility.
  /// 
  /// ## Parameters
  /// - [n]: The number of bytes to be skipped
  /// 
  /// ## Returns
  /// The actual number of bytes skipped.
  /// 
  /// ## Example
  /// ```dart
  /// final input = FileInputStream('data.bin');
  /// try {
  ///   // Skip the first 100 bytes (e.g., header)
  ///   final skipped = await input.skip(100);
  ///   print('Skipped $skipped bytes');
  ///   
  ///   // Now read the actual data
  ///   final data = await input.readAll();
  ///   processData(data);
  /// } finally {
  ///   await input.close();
  /// }
  /// ```
  /// 
  /// Throws [IOException] if an I/O error occurs.
  /// Throws [StreamClosedException] if the stream has been closed.
  Future<int> skip(int n) async {
    checkClosed();
    
    if (n <= 0) {
      return 0;
    }
    
    int skipped = 0;
    final buffer = Uint8List(8192.clamp(1, n)); // Use reasonable buffer size
    
    while (skipped < n) {
      final toRead = (n - skipped).clamp(1, buffer.length);
      final bytesRead = await read(buffer, 0, toRead);
      if (bytesRead == -1) {
        break;
      }
      skipped += bytesRead;
    }
    
    return skipped;
  }
  
  /// Returns an estimate of the number of bytes that can be read (or skipped over)
  /// from this input stream without blocking by the next invocation of a method
  /// for this input stream.
  /// 
  /// Note that while some implementations of [InputStream] will return the total
  /// number of bytes in the stream, many will not. It is never correct to use
  /// the return value of this method to allocate a buffer intended to hold all
  /// data in this stream.
  /// 
  /// ## Returns
  /// An estimate of the number of bytes that can be read (or skipped over)
  /// from this input stream without blocking, or `0` when it reaches the end
  /// of the input stream.
  /// 
  /// ## Example
  /// ```dart
  /// final input = FileInputStream('data.bin');
  /// try {
  ///   final available = await input.available();
  ///   print('Approximately $available bytes available');
  ///   
  ///   if (available > 0) {
  ///     final buffer = Uint8List(available.clamp(1, 8192));
  ///     final bytesRead = await input.read(buffer);
  ///     processData(buffer.sublist(0, bytesRead));
  ///   }
  /// } finally {
  ///   await input.close();
  /// }
  /// ```
  /// 
  /// Throws [IOException] if an I/O error occurs.
  /// Throws [StreamClosedException] if the stream has been closed.
  Future<int> available() async {
    checkClosed();
    return 0; // Default implementation
  }
  
  /// Tests if this input stream supports the [mark] and [reset] methods.
  /// 
  /// Whether or not [mark] and [reset] are supported is an invariant property
  /// of a particular input stream instance. The [markSupported] method returns
  /// `true` if and only if this stream supports the mark/reset functionality.
  /// 
  /// ## Returns
  /// `true` if this stream instance supports the mark and reset methods;
  /// `false` otherwise.
  /// 
  /// ## Example
  /// ```dart
  /// final input = FileInputStream('data.txt');
  /// if (input.markSupported()) {
  ///   input.mark(1024); // Mark current position
  ///   
  ///   // Read some data
  ///   final preview = await input.readFully(100);
  ///   
  ///   // Reset to marked position
  ///   await input.reset();
  ///   
  ///   // Read again from the marked position
  ///   final actualData = await input.readAll();
  /// }
  /// ```
  bool markSupported() => false;
  
  /// Marks the current position in this input stream.
  /// 
  /// A subsequent call to the [reset] method repositions this stream at the
  /// last marked position so that subsequent reads re-read the same bytes.
  /// 
  /// The [readLimit] argument tells this input stream to allow that many bytes
  /// to be read before the mark position gets invalidated.
  /// 
  /// ## Parameters
  /// - [readLimit]: The maximum limit of bytes that can be read before the
  ///   mark position becomes invalid
  /// 
  /// ## Example
  /// ```dart
  /// final input = BufferedInputStream(FileInputStream('data.txt'));
  /// if (input.markSupported()) {
  ///   input.mark(1024); // Allow up to 1024 bytes to be read
  ///   
  ///   // Peek at the data
  ///   final header = await input.readFully(10);
  ///   
  ///   if (isValidHeader(header)) {
  ///     // Reset and process the entire stream
  ///     await input.reset();
  ///     processStream(input);
  ///   }
  /// }
  /// ```
  /// 
  /// Throws [IOException] if the stream does not support mark, or if some
  /// other I/O error occurs.
  void mark(int readLimit) {
    // Default implementation does nothing
  }
  
  /// Repositions this stream to the position at the time the [mark] method
  /// was last called on this input stream.
  /// 
  /// If the method [markSupported] returns `true`, then:
  /// - If [mark] has not been called since the stream was created, or the
  ///   number of bytes read from the stream since [mark] was last called is
  ///   larger than the argument to [mark] at that last call, then an
  ///   [IOException] might be thrown.
  /// - If such an [IOException] is not thrown, then the stream is reset to
  ///   a state such that all the bytes read since the most recent call to
  ///   [mark] will be resupplied to subsequent callers of the [read] method,
  ///   followed by any bytes that otherwise would have been the next input
  ///   data as of the time of the call to [reset].
  /// 
  /// ## Example
  /// ```dart
  /// final input = BufferedInputStream(FileInputStream('config.txt'));
  /// if (input.markSupported()) {
  ///   input.mark(1024);
  ///   
  ///   // Try to parse as JSON
  ///   try {
  ///     final jsonData = await input.readAll();
  ///     final config = jsonDecode(String.fromCharCodes(jsonData));
  ///     return config;
  ///   } catch (e) {
  ///     // Reset and try parsing as XML
  ///     await input.reset();
  ///     final xmlData = await input.readAll();
  ///     return parseXml(String.fromCharCodes(xmlData));
  ///   }
  /// }
  /// ```
  /// 
  /// Throws [IOException] if the stream has not been marked or if the mark
  /// has been invalidated, or if the stream does not support reset, or if
  /// some other I/O error occurs.
  Future<void> reset() async {
    throw IOException('Mark/reset not supported');
  }
  
  /// Closes this input stream and releases any system resources associated
  /// with the stream.
  /// 
  /// The [close] method of [InputStream] does nothing. Subclasses should
  /// override this method to release resources.
  /// 
  /// ## Example
  /// ```dart
  /// final input = FileInputStream('data.txt');
  /// try {
  ///   // Use the input stream
  ///   final data = await input.readAll();
  ///   processData(data);
  /// } finally {
  ///   await input.close(); // Always close in finally block
  /// }
  /// ```
  /// 
  /// Throws [IOException] if an I/O error occurs.
  @override
  @mustCallSuper
  Future<void> close() async {
    _closed = true;
  }
  
  /// Checks if the stream is closed and throws an exception if it is.
  @protected
  void checkClosed() {
    if (_closed) {
      throw StreamClosedException();
    }
  }
}