import 'dart:convert';
import 'dart:typed_data';

import 'package:meta/meta.dart';

import '../base.dart';
import '../../exceptions.dart';

/// {@template output_stream}
/// This abstract class is the superclass of all classes representing an output
/// stream of bytes.
/// 
/// An output stream accepts output bytes and sends them to some sink.
/// Applications that need to define a subclass of [OutputStream] must always
/// provide at least a method that writes one byte of output.
/// 
/// ## Design Philosophy
/// The [OutputStream] class provides a uniform interface for writing data to
/// various destinations such as files, network connections, or memory buffers.
/// It follows the decorator pattern, allowing streams to be wrapped with
/// additional functionality like buffering or compression.
/// 
/// ## Example Usage
/// ```dart
/// // Writing to a file
/// final output = FileOutputStream('output.bin');
/// try {
///   await output.write([72, 101, 108, 108, 111]); // "Hello"
///   await output.writeByte(33); // "!"
///   await output.flush();
/// } finally {
///   await output.close();
/// }
/// 
/// // Writing with buffering for better performance
/// final bufferedOutput = BufferedOutputStream(FileOutputStream('large_file.bin'));
/// try {
///   for (int i = 0; i < 1000000; i++) {
///     await bufferedOutput.writeByte(i % 256);
///   }
///   await bufferedOutput.flush(); // Ensure all data is written
/// } finally {
///   await bufferedOutput.close();
/// }
/// ```
/// 
/// {@endtemplate}
abstract class OutputStream implements Closeable, Flushable {
  /// {@macro output_stream}
  OutputStream();

  bool _closed = false;
  
  /// Returns `true` if this stream has been closed.
  bool get isClosed => _closed;
  
  /// Writes the specified byte to this output stream.
  /// 
  /// The general contract for [writeByte] is that one byte is written to the
  /// output stream. The byte to be written is the eight low-order bits of
  /// the argument [b]. The 24 high-order bits of [b] are ignored.
  /// 
  /// ## Parameters
  /// - [b]: The byte to write (only the low-order 8 bits are used)
  /// 
  /// ## Example
  /// ```dart
  /// final output = FileOutputStream('output.txt');
  /// try {
  ///   await output.writeByte(65); // Write 'A'
  ///   await output.writeByte(66); // Write 'B'
  ///   await output.writeByte(67); // Write 'C'
  ///   await output.flush();
  /// } finally {
  ///   await output.close();
  /// }
  /// ```
  /// 
  /// Throws [IOException] if an I/O error occurs.
  /// Throws [StreamClosedException] if the stream has been closed.
  Future<void> writeByte(int b);
  
  /// Writes [b.length] bytes from the specified byte array to this output stream.
  /// 
  /// The general contract for [write] is that it should have exactly the same
  /// effect as the call `write(b, 0, b.length)`.
  /// 
  /// ## Parameters
  /// - [b]: The data to write
  /// - [offset]: The start offset in the data (default: 0)
  /// - [length]: The number of bytes to write (default: remaining bytes from offset)
  /// 
  /// ## Example
  /// ```dart
  /// final output = FileOutputStream('output.txt');
  /// try {
  ///   // Write entire array
  ///   await output.write([72, 101, 108, 108, 111]); // "Hello"
  ///   
  ///   // Write part of array
  ///   final data = [32, 87, 111, 114, 108, 100, 33]; // " World!"
  ///   await output.write(data, 1, 5); // Write "World"
  ///   
  ///   await output.flush();
  /// } finally {
  ///   await output.close();
  /// }
  /// ```
  /// 
  /// Throws [InvalidArgumentException] if [offset] or [length] is negative, or if
  /// [offset] + [length] is greater than the length of [b].
  /// Throws [IOException] if an I/O error occurs.
  /// Throws [StreamClosedException] if the stream has been closed.
  Future<void> write(List<int> b, [int offset = 0, int? length]) async {
    checkClosed();
    
    length ??= b.length - offset;
    
    if (offset < 0 || length < 0 || offset + length > b.length) {
      throw InvalidArgumentException('Invalid offset or length');
    }
    
    for (int i = 0; i < length; i++) {
      await writeByte(b[offset + i]);
    }
  }
  
  /// Writes all bytes from the specified [Uint8List] to this output stream.
  /// 
  /// This is a convenience method for writing binary data efficiently.
  /// 
  /// ## Parameters
  /// - [data]: The binary data to write
  /// 
  /// ## Example
  /// ```dart
  /// final output = FileOutputStream('binary_output.bin');
  /// try {
  ///   final binaryData = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47]); // PNG header
  ///   await output.writeBytes(binaryData);
  ///   await output.flush();
  /// } finally {
  ///   await output.close();
  /// }
  /// ```
  /// 
  /// Throws [IOException] if an I/O error occurs.
  /// Throws [StreamClosedException] if the stream has been closed.
  Future<void> writeBytes(Uint8List data) async {
    await write(data);
  }
  
  /// Writes a string to this output stream using UTF-8 encoding.
  /// 
  /// This is a convenience method for writing text data. The string is
  /// encoded as UTF-8 bytes and written to the stream.
  /// 
  /// ## Parameters
  /// - [str]: The string to write
  /// 
  /// ## Example
  /// ```dart
  /// final output = FileOutputStream('text_output.txt');
  /// try {
  ///   await output.writeString('Hello, World!');
  ///   await output.writeString('\n');
  ///   await output.writeString('This is a test.');
  ///   await output.flush();
  /// } finally {
  ///   await output.close();
  /// }
  /// ```
  /// 
  /// Throws [IOException] if an I/O error occurs.
  /// Throws [StreamClosedException] if the stream has been closed.
  Future<void> writeString(String str, [Encoding? encoding]) async {
    final bytes = Uint8List.fromList(str.codeUnits);
    await writeBytes(bytes);
  }

  /// Writes the given [obj] to the output stream.
  ///
  /// This method serializes or converts the object into a form that can be
  /// transmitted or stored by the underlying stream implementation.
  /// The exact behavior depends on the concrete [OutputStream] implementation
  /// (e.g., writing bytes, text, or structured data).
  ///
  /// Example:
  /// ```dart
  /// final out = OutputStream();
  ///
  /// // Write a string or number
  /// await out.writeObject('Hello, world!');
  /// await out.writeObject(42);
  ///
  /// // Write a custom object, depending on stream support
  /// await out.writeObject({'key': 'value'});
  /// ```
  ///
  /// [obj] – The object to write. Can be `null`.
  ///
  /// Throws an exception if writing fails or the stream is closed.
  Future<void> writeObject(Object? obj);
  
  /// Flushes this output stream and forces any buffered output bytes to be
  /// written out.
  /// 
  /// The general contract of [flush] is that calling it is an indication that,
  /// if any bytes previously written have been buffered by the implementation
  /// of the output stream, such bytes should immediately be written to their
  /// intended destination.
  /// 
  /// If the intended destination of this stream is an abstraction provided by
  /// the underlying operating system, for example a file, then flushing the
  /// stream guarantees only that bytes previously written to the stream are
  /// passed to the operating system for writing; it does not guarantee that
  /// they are actually written to a physical device such as a disk drive.
  /// 
  /// ## Example
  /// ```dart
  /// final output = BufferedOutputStream(FileOutputStream('output.txt'));
  /// try {
  ///   await output.writeString('Important data');
  ///   await output.flush(); // Ensure data is written immediately
  ///   
  ///   // Continue with more operations...
  ///   await output.writeString('More data');
  /// } finally {
  ///   await output.close(); // close() also flushes
  /// }
  /// ```
  /// 
  /// Throws [IOException] if an I/O error occurs.
  /// Throws [StreamClosedException] if the stream has been closed.
  @override
  Future<void> flush() async {
    checkClosed();
  }
  
  /// Closes this output stream and releases any system resources associated
  /// with this stream.
  /// 
  /// A closed stream cannot perform output operations and cannot be reopened.
  /// The [close] method of [OutputStream] calls [flush] before closing the stream.
  /// 
  /// ## Example
  /// ```dart
  /// final output = FileOutputStream('output.txt');
  /// try {
  ///   await output.writeString('Hello, World!');
  ///   // flush() is called automatically by close()
  /// } finally {
  ///   await output.close(); // Always close in finally block
  /// }
  /// ```
  /// 
  /// Throws [IOException] if an I/O error occurs.
  @override
  @mustCallSuper
  Future<void> close() async {
    if (!_closed) {
      _closed = true;
    }
  }
  
  /// Checks if the stream is closed and throws an exception if it is.
  @protected
  void checkClosed() {
    if (_closed) {
      throw StreamClosedException();
    }
  }
}