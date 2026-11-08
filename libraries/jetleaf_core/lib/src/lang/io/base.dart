import 'dart:async';
import 'dart:convert';

/// {@template closeable}
/// An object that may hold resources until it is closed.
/// 
/// The [close] method is invoked to release resources that the object is
/// holding (such as open files). The close method is idempotent - calling
/// it multiple times should have no additional effect.
/// 
/// ## Example Usage
/// ```dart
/// class FileResource implements Closeable {
///   final File _file;
///   bool _closed = false;
///   
///   FileResource(String path) : _file = File(path);
///   
///   @override
///   Future<void> close() async {
///     if (_closed) return;
///     _closed = true;
///     // Perform cleanup
///   }
/// }
/// 
/// // Usage with try-finally
/// final resource = FileResource('data.txt');
/// try {
///   // Use resource
/// } finally {
///   await resource.close();
/// }
/// ```
/// 
/// {@endtemplate}
abstract class Closeable {
  /// {@macro closeable}
  Closeable();

  /// The default character encoding used for JSON serialization and deserialization.
  ///
  /// Jetson uses UTF-8 as the standard encoding for all JSON input and output
  /// operations to ensure full compatibility with the JSON specification
  /// (RFC 8259) and cross-platform interoperability.
  ///
  /// ### Details
  /// - All string data written by Jetson components is encoded using UTF-8.
  /// - Input streams are decoded using UTF-8 unless another encoding is
  ///   explicitly configured.
  /// - This constant provides a single reference point for encoding decisions
  ///   throughout the Jetson pipeline.
  ///
  /// ### Example
  /// ```dart
  /// final encoded = DEFAULT_ENCODING.encode('{"name":"Jetleaf"}');
  /// final decoded = DEFAULT_ENCODING.decode(encoded);
  /// print(decoded); // {"name":"Jetleaf"}
  /// ```
  static const Utf8Codec DEFAULT_ENCODING = utf8;
  
  /// Closes this resource, relinquishing any underlying resources.
  /// 
  /// This method is invoked automatically when using try-with-resources
  /// patterns or should be called explicitly in a finally block.
  /// 
  /// The close method is idempotent - calling it multiple times should
  /// have no additional effect beyond the first call.
  /// 
  /// ## Implementation Note
  /// Implementations should ensure that resources are properly released
  /// even if an exception occurs during the close operation. It's recommended
  /// to mark the resource as closed before attempting cleanup operations.
  /// 
  /// ## Example
  /// ```dart
  /// @override
  /// Future<void> close() async {
  ///   if (_closed) return; // Idempotent
  ///   
  ///   try {
  ///     await _performCleanup();
  ///   } finally {
  ///     _closed = true; // Always mark as closed
  ///   }
  /// }
  /// ```
  /// 
  /// Throws [IOException] if an I/O error occurs during closing.
  FutureOr<void> close();
}

// ---------------------------------------------------------------------------------------------------------------
// RUNNABLE
// ---------------------------------------------------------------------------------------------------------------

/// {@template runnable}
/// A simple contract for objects that can be executed.
///
/// The `Runnable` interface is inspired by Java's `Runnable`
/// and is commonly used to define a task or unit of work
/// that can be run, typically on a thread, executor, or lifecycle callback.
///
/// This interface is useful for generic task execution, background
/// processing, or deferred logic.
///
/// ### Example:
/// ```dart
/// class Task implements Runnable {
///   @override
///   FutureOr<void> run() {
///     print('Running a task...');
///   }
/// }
///
/// void execute(Runnable runnable) {
///   runnable.run();
/// }
///
/// void main() {
///   final task = Task();
///   execute(task); // Output: Running a task...
/// }
/// ```
/// {@endtemplate}
abstract interface class Runnable {
  /// {@template runnable_run}
  /// Executes the task encapsulated by this instance.
  ///
  /// Override this method with the logic that should be performed
  /// when the runnable is triggered.
  ///
  /// ### Example:
  /// ```dart
  /// class MyJob implements Runnable {
  ///   @override
  ///   FutureOr<void> run() {
  ///     print("Job started");
  ///   }
  /// }
  /// ```
  /// {@endtemplate}
  FutureOr<void> run();
}

// ---------------------------------------------------------------------------------------------------------------
// FLUSHABLE
// ---------------------------------------------------------------------------------------------------------------

/// {@template flushable}
/// An object that can be flushed.
/// 
/// The flush method is invoked to write any buffered output to the underlying
/// stream or device. This is particularly important for buffered streams where
/// data may be held in memory until the buffer is full or explicitly flushed.
/// 
/// ## Example Usage
/// ```dart
/// class BufferedOutput implements Flushable {
///   final List<int> _buffer = [];
///   final OutputStream _output;
///   
///   BufferedOutput(this._output);
///   
///   void write(int byte) {
///     _buffer.add(byte);
///     if (_buffer.length >= 1024) {
///       flush(); // Auto-flush when buffer is full
///     }
///   }
///   
///   @override
///   Future<void> flush() async {
///     if (_buffer.isNotEmpty) {
///       await _output.write(_buffer);
///       _buffer.clear();
///     }
///   }
/// }
/// ```
/// 
/// {@endtemplate}
abstract class Flushable {
  /// {@macro flushable}
  Flushable();

  /// Flushes this stream by writing any buffered output to the underlying stream.
  /// 
  /// If the intended destination of this stream is an abstraction provided by
  /// the underlying operating system, for example a file, then flushing the
  /// stream guarantees only that bytes previously written to the stream are
  /// passed to the operating system for writing; it does not guarantee that
  /// they are actually written to a physical device such as a disk drive.
  /// 
  /// ## Implementation Note
  /// Implementations should ensure that all buffered data is written to the
  /// underlying stream. If the underlying stream is also [Flushable], it
  /// should be flushed as well to ensure data reaches its final destination.
  /// 
  /// ## Example
  /// ```dart
  /// @override
  /// Future<void> flush() async {
  ///   // Write buffered data to underlying stream
  ///   if (_buffer.isNotEmpty) {
  ///     await _underlyingStream.write(_buffer);
  ///     _buffer.clear();
  ///   }
  ///   
  ///   // Flush underlying stream if it's also flushable
  ///   if (_underlyingStream is Flushable) {
  ///     await (_underlyingStream as Flushable).flush();
  ///   }
  /// }
  /// ```
  /// 
  /// Throws [IOException] if an I/O error occurs during flushing.
  Future<void> flush();
}