import 'input_stream.dart';

/// {@template input_stream_source}
/// A simple interface for objects that provide an [InputStream].
///
/// This abstraction is useful for generic access to stream-based content
/// (e.g., files, network streams, in-memory data) without tying the implementation
/// to a specific resource type.
///
/// It is typically used in configuration loaders, template resolvers, or
/// file/resource access APIs.
///
/// ---
///
/// ### Example Usage
/// ```dart
/// class FileInputStreamSource implements InputStreamSource {
///   final File file;
///
///   FileInputStreamSource(this.file);
///
///   @override
///   InputStream getInputStream() {
///     return FileInputStream(file);
///   }
/// }
/// ```
///
/// In Jetleaf, this is a core abstraction used to generalize resource access.
/// {@endtemplate}
abstract interface class InputStreamSource {
  /// {@macro input_stream_source}
  InputStreamSource();

  /// Returns a new [InputStream] to read the underlying content.
  ///
  /// A new stream should be returned each time this method is called.
  /// The caller is responsible for closing the stream.
  InputStream getInputStream();
}