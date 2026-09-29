import 'package:meta/meta.dart';

import '../base.dart';
import '../../exceptions.dart';

/// {@template writer}
/// Abstract class for writing to character streams.
/// 
/// The only methods that a subclass must implement are [writeChar], [flush],
/// and [close]. Most subclasses, however, will override some of the methods
/// defined here in order to provide higher efficiency, additional functionality,
/// or both.
/// 
/// ## Design Philosophy
/// The [Writer] class provides a uniform interface for writing character data
/// to various destinations. Unlike [OutputStream] which deals with raw bytes,
/// [Writer] handles character encoding and provides text-oriented operations.
/// 
/// ## Example Usage
/// ```dart
/// // Writing to a file
/// final writer = FileWriter('output.txt');
/// try {
///   await writer.write('Hello, World!');
///   await writer.writeLine('This is a new line.');
///   await writer.flush();
/// } finally {
///   await writer.close();
/// }
/// 
/// // Writing with buffering for better performance
/// final bufferedWriter = BufferedWriter(FileWriter('large_output.txt'));
/// try {
///   for (int i = 0; i < 1000; i++) {
///     await bufferedWriter.writeLine('Line $i: Some content here');
///   }
///   await bufferedWriter.flush(); // Ensure all data is written
/// } finally {
///   await bufferedWriter.close();
/// }
/// ```
/// 
/// {@endtemplate}
abstract class Writer implements Closeable, Flushable {
  /// {@macro writer}
  Writer();

  bool _closed = false;
  
  /// Returns `true` if this writer has been closed.
  bool get isClosed => _closed;
  
  /// Writes a single character.
  /// 
  /// The character to be written is contained in the 16 low-order bits of the
  /// given integer value; the 16 high-order bits are ignored.
  /// 
  /// ## Parameters
  /// - [c]: The character to write (only the low-order 16 bits are used)
  /// 
  /// ## Example
  /// ```dart
  /// final writer = FileWriter('output.txt');
  /// try {
  ///   await writer.writeChar(65); // Write 'A'
  ///   await writer.writeChar(66); // Write 'B'
  ///   await writer.writeChar(67); // Write 'C'
  ///   await writer.flush();
  /// } finally {
  ///   await writer.close();
  /// }
  /// ```
  /// 
  /// Throws [IOException] if an I/O error occurs.
  /// Throws [StreamClosedException] if the writer has been closed.
  Future<void> writeChar(int c);
  
  /// Writes an array of characters.
  /// 
  /// ## Parameters
  /// - [cbuf]: Array of characters to write
  /// - [offset]: Offset from which to start writing characters (default: 0)
  /// - [length]: Number of characters to write (default: remaining characters from offset)
  /// 
  /// ## Example
  /// ```dart
  /// final writer = FileWriter('output.txt');
  /// try {
  ///   final chars = 'Hello, World!'.codeUnits;
  ///   
  ///   // Write entire array
  ///   await writer.writeChars(chars);
  ///   
  ///   // Write part of array
  ///   await writer.writeChars(chars, 7, 5); // Write "World"
  ///   
  ///   await writer.flush();
  /// } finally {
  ///   await writer.close();
  /// }
  /// ```
  /// 
  /// Throws [InvalidArgumentException] if [offset] or [length] is negative, or if
  /// [offset] + [length] is greater than the length of [cbuf].
  /// Throws [IOException] if an I/O error occurs.
  /// Throws [StreamClosedException] if the writer has been closed.
  Future<void> writeChars(List<int> cbuf, [int offset = 0, int? length]) async {
    checkClosed();
    
    length ??= cbuf.length - offset;
    
    if (offset < 0 || length < 0 || offset + length > cbuf.length) {
      throw InvalidArgumentException('Invalid offset or length');
    }
    
    for (int i = 0; i < length; i++) {
      await writeChar(cbuf[offset + i]);
    }
  }
  
  /// Writes a string.
  /// 
  /// ## Parameters
  /// - [str]: String to write
  /// - [offset]: Offset from which to start writing characters (default: 0)
  /// - [length]: Number of characters to write (default: remaining characters from offset)
  /// 
  /// ## Example
  /// ```dart
  /// final writer = FileWriter('output.txt');
  /// try {
  ///   // Write entire string
  ///   await writer.write('Hello, World!');
  ///   
  ///   // Write part of string
  ///   await writer.write('Hello, World!', 7, 5); // Write "World"
  ///   
  ///   await writer.flush();
  /// } finally {
  ///   await writer.close();
  /// }
  /// ```
  /// 
  /// Throws [InvalidArgumentException] if [offset] or [length] is negative, or if
  /// [offset] + [length] is greater than the length of [str].
  /// Throws [IOException] if an I/O error occurs.
  /// Throws [StreamClosedException] if the writer has been closed.
  Future<void> write(String str, [int offset = 0, int? length]) async {
    checkClosed();
    
    length ??= str.length - offset;
    
    if (offset < 0 || length < 0 || offset + length > str.length) {
      throw InvalidArgumentException('Invalid offset or length');
    }
    
    final substring = str.substring(offset, offset + length);
    await writeChars(substring.codeUnits);
  }
  
  /// Writes a line separator.
  /// 
  /// The line separator string is defined by the system property line.separator,
  /// and is not necessarily a single newline character ('\n').
  /// 
  /// ## Example
  /// ```dart
  /// final writer = FileWriter('output.txt');
  /// try {
  ///   await writer.write('First line');
  ///   await writer.newLine();
  ///   await writer.write('Second line');
  ///   await writer.newLine();
  ///   await writer.flush();
  /// } finally {
  ///   await writer.close();
  /// }
  /// ```
  /// 
  /// Throws [IOException] if an I/O error occurs.
  /// Throws [StreamClosedException] if the writer has been closed.
  Future<void> newLine() async {
    await writeChar(10); // '\n' - simplified for cross-platform compatibility
  }
  
  /// Writes a string followed by a line separator.
  /// 
  /// This is a convenience method that combines [write] and [newLine].
  /// 
  /// ## Parameters
  /// - [str]: String to write (if null, writes "null")
  /// 
  /// ## Example
  /// ```dart
  /// final writer = FileWriter('output.txt');
  /// try {
  ///   await writer.writeLine('First line');
  ///   await writer.writeLine('Second line');
  ///   await writer.writeLine('Third line');
  ///   await writer.flush();
  /// } finally {
  ///   await writer.close();
  /// }
  /// ```
  /// 
  /// Throws [IOException] if an I/O error occurs.
  /// Throws [StreamClosedException] if the writer has been closed.
  Future<void> writeLine([String? str]) async {
    if (str != null) {
      await write(str);
    }
    await newLine();
  }
  
  /// Writes the string representation of an object.
  /// 
  /// The string representation is obtained by calling the object's [toString]
  /// method. If the object is null, the string "null" is written.
  /// 
  /// ## Parameters
  /// - [obj]: The object to write
  /// 
  /// ## Example
  /// ```dart
  /// final writer = FileWriter('output.txt');
  /// try {
  ///   await writer.writeObject(42);
  ///   await writer.writeObject(' ');
  ///   await writer.writeObject(3.14);
  ///   await writer.writeObject(' ');
  ///   await writer.writeObject(true);
  ///   await writer.flush();
  /// } finally {
  ///   await writer.close();
  /// }
  /// ```
  /// 
  /// Throws [IOException] if an I/O error occurs.
  /// Throws [StreamClosedException] if the writer has been closed.
  Future<void> writeObject(Object? obj) async {
    await write(obj?.toString() ?? 'null');
  }
  
  /// Appends the specified character to this writer.
  /// 
  /// An invocation of this method of the form `writer.append(c)` behaves in
  /// exactly the same way as the invocation `writer.writeChar(c)`.
  /// 
  /// ## Parameters
  /// - [c]: The character to append
  /// 
  /// ## Returns
  /// This writer
  /// 
  /// ## Example
  /// ```dart
  /// final writer = FileWriter('output.txt');
  /// try {
  ///   await writer.append(72)  // 'H'
  ///              .append(101) // 'e'
  ///              .append(108) // 'l'
  ///              .append(108) // 'l'
  ///              .append(111); // 'o'
  ///   await writer.flush();
  /// } finally {
  ///   await writer.close();
  /// }
  /// ```
  /// 
  /// Throws [IOException] if an I/O error occurs.
  /// Throws [StreamClosedException] if the writer has been closed.
  Future<Writer> append(int c) async {
    await writeChar(c);
    return this;
  }
  
  /// Appends the specified character sequence to this writer.
  /// 
  /// ## Parameters
  /// - [csq]: The character sequence to append (if null, writes "null")
  /// 
  /// ## Returns
  /// This writer
  /// 
  /// ## Example
  /// ```dart
  /// final writer = FileWriter('output.txt');
  /// try {
  ///   await writer.appendString('Hello')
  ///              .appendString(', ')
  ///              .appendString('World!');
  ///   await writer.flush();
  /// } finally {
  ///   await writer.close();
  /// }
  /// ```
  /// 
  /// Throws [IOException] if an I/O error occurs.
  /// Throws [StreamClosedException] if the writer has been closed.
  Future<Writer> appendString(String? csq) async {
    await write(csq ?? 'null');
    return this;
  }
  
  /// Flushes the stream.
  /// 
  /// If the stream has saved any characters from the various write() methods
  /// in a buffer, write them immediately to their intended destination. Then,
  /// if that destination is another character or byte stream, flush it. Thus
  /// one flush() invocation will flush all the buffers in a chain of Writers
  /// and OutputStreams.
  /// 
  /// ## Example
  /// ```dart
  /// final writer = BufferedWriter(FileWriter('output.txt'));
  /// try {
  ///   await writer.write('Important data');
  ///   await writer.flush(); // Ensure data is written immediately
  ///   
  ///   // Continue with more operations...
  ///   await writer.write('More data');
  /// } finally {
  ///   await writer.close(); // close() also flushes
  /// }
  /// ```
  /// 
  /// Throws [IOException] if an I/O error occurs.
  /// Throws [StreamClosedException] if the writer has been closed.
  @override
  Future<void> flush() async {
    checkClosed();
    // Default implementation does nothing
  }
  
  /// Closes the stream, flushing it first.
  /// 
  /// Once the stream has been closed, further write() or flush() invocations
  /// will cause an IOException to be thrown. Closing a previously closed
  /// stream has no effect.
  /// 
  /// ## Example
  /// ```dart
  /// final writer = FileWriter('output.txt');
  /// try {
  ///   await writer.write('Hello, World!');
  ///   // flush() is called automatically by close()
  /// } finally {
  ///   await writer.close(); // Always close in finally block
  /// }
  /// ```
  /// 
  /// Throws [IOException] if an I/O error occurs.
  @override
  @mustCallSuper
  Future<void> close() async {
    _closed = true;
  }
  
  /// Checks if the writer is closed and throws an exception if it is.
  @protected
  void checkClosed() {
    if (_closed) {
      throw StreamClosedException();
    }
  }
}