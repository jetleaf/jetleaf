import 'dart:convert';
import 'dart:typed_data';

import '../base.dart';
import 'byte_array_input_stream.dart';

/// {@template string_input_stream}
/// A character-based input stream backed by an encoded [String].
///
/// `StringInputStream` adapts textual data into a byte-oriented
/// [ByteArrayInputStream] using a configurable [Encoding].
///
/// This class is useful for:
/// - Feeding text into APIs that operate on [InputStream]
/// - Testing parsers without filesystem or network I/O
/// - Streaming configuration files or source code from memory
///
/// By default, UTF-8 encoding is used.
///
/// ---
///
/// ### 🔧 Example:
/// ```dart
/// final input = StringInputStream('Hello Jetleaf 🌱');
///
/// final b1 = await input.readByte(); // UTF-8 byte
/// final b2 = await input.readByte();
/// ```
///
/// ---
///
/// ### ⚠️ Note:
/// This class operates at the **byte level**, not character level.
/// Multi-byte characters may produce multiple reads.
/// {@endtemplate}
final class StringInputStream extends ByteArrayInputStream {
  /// The original string backing this stream.
  final String value;

  /// The encoding used to convert the string to bytes.
  final Encoding encoding;

  /// {@macro string_input_stream}
  ///
  /// Creates a [StringInputStream] using UTF-8 encoding by default.
  StringInputStream(this.value, {this.encoding = Closeable.DEFAULT_ENCODING}) : super(
    Uint8List.fromList(encoding.encode(value)),
  );
}