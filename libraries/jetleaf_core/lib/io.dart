/// 💾 **Jetleaf I/O Subsystem: Streams, Buffers & Functional Topologies**
///
/// This library provides a unified, cross-platform input/output (I/O) architecture
/// and functional streaming pipeline for the Jetleaf framework.
///
/// Key capabilities:
/// - **Byte Streams:** [InputStream] and [OutputStream] hierarchies supporting files, networks, memory buffers, and strings.
/// - **Buffered Pipelines:** High-throughput [BufferedInputStream] and [BufferedOutputStream] to minimize syscalls.
/// - **Character Decoders:** [Reader] and [Writer] abstractions for UTF-8 character manipulation.
/// - **Functional Primitive Streams:** [IntStream], [DoubleStream], and [GenericStream] supporting map, filter, flatMap, and reduce.
///
/// ---
///
/// ## 🌊 I/O Stream Hierarchy
///
/// ```text
/// ┌─────────────────────────────────────────────────────────────┐
/// │                     Input & Output Streams                  │
/// ├──────────────────────────────┬──────────────────────────────┤
/// │ Byte Streams (Input/Output)  │ Character Streams (Read/Write)│
/// ├──────────────────────────────┼──────────────────────────────┤
/// │ • FileInputStream            │ • FileReader / FileWriter    │
/// │ • ByteArrayInputStream       │ • StringReader               │
/// │ • BufferedInputStream        │ • BufferedReader             │
/// │ • NetworkInputStream         │ • BufferedWriter             │
/// └──────────────────────────────┴──────────────────────────────┘
/// ```
///
/// ---
///
/// ## 📦 Exports Categorization
///
/// ### 📥 Byte Input Streams
/// - [InputStream] — abstract base class representing an input stream of bytes.
/// - [BufferedInputStream] — adds buffering and mark/reset capabilities to an input stream.
/// - [ByteArrayInputStream] — input stream backed by an in-memory byte buffer.
/// - [StringInputStream] — wraps a String into an encoded byte stream.
///
/// ### 📤 Byte Output Streams
/// - [OutputStream] — abstract base class representing an output stream of bytes.
/// - [BufferedOutputStream] — buffers byte writes for high-volume I/O efficiency.
/// - [ByteArrayOutputStream] — captures written bytes in a growable in-memory buffer.
///
/// ### 📖 Readers & Writers
/// - [Reader], [Writer] — abstract character stream abstractions.
/// - [BufferedReader] — reads text from a character-input stream, buffering characters for efficient reading of lines.
/// - [BufferedWriter] — writes text to a character-output stream with internal buffering.
///
/// ### ⚡ Functional Streams
/// - [BaseStream] — base interface for functional streams.
/// - [GenericStream] — typed stream supporting transformation pipelines.
/// - [StreamBuilder] — builder for constructing streaming pipelines.
///
/// ---
///
/// ## 🎯 Usage Example: Functional Stream Processing
///
/// ```dart
/// import 'package:jetleaf_core/io.dart';
///
/// void main() {
///   // Build a functional stream from memory
///   final stream = StreamBuilder.of<String>(['dart', 'jetleaf', 'backend', 'aot'])
///       .filter((s) => s.length > 3)
///       .map((s) => s.toUpperCase());
///
///   final results = stream.toList();
///   print('Filtered results: $results');
///   // Output: ['DART', 'JETLEAF', 'BACKEND']
/// }
/// ```
library;

export 'src/lang/io/input_stream/input_stream.dart';
export 'src/lang/io/input_stream/buffered_input_stream.dart';
export 'src/lang/io/input_stream/file_input_stream.dart';
export 'src/lang/io/input_stream/network_input_stream.dart';
export 'src/lang/io/input_stream/byte_array_input_stream.dart';
export 'src/lang/io/input_stream/string_input_stream.dart';
export 'src/lang/io/input_stream/input_stream_source.dart';

export 'src/lang/io/output_stream/output_stream.dart';
export 'src/lang/io/output_stream/buffered_output_stream.dart';
export 'src/lang/io/output_stream/byte_array_output_stream.dart';
export 'src/lang/io/output_stream/file_output_stream.dart';
export 'src/lang/io/output_stream/network_output_stream.dart';
export 'src/lang/io/output_stream/sink_output_stream.dart';

export 'src/lang/io/reader/reader.dart';
export 'src/lang/io/reader/file_reader.dart';
export 'src/lang/io/reader/string_reader.dart';
export 'src/lang/io/reader/buffered_reader.dart';

export 'src/lang/io/writer/writer.dart';
export 'src/lang/io/writer/file_writer.dart';
export 'src/lang/io/writer/buffered_writer.dart';

export 'src/lang/io/base_stream/base_stream.dart';
export 'src/lang/io/base_stream/int/int_stream.dart';
export 'src/lang/io/base_stream/int/_int_stream.dart';
export 'src/lang/io/base_stream/double/double_stream.dart';
export 'src/lang/io/base_stream/double/_double_stream.dart';
export 'src/lang/io/base_stream/generic/generic_stream.dart';
export 'src/lang/io/base_stream/generic/_generic_stream.dart';

export 'src/lang/io/print_stream/print_stream.dart';
export 'src/lang/io/print_stream/console_print_stream.dart';

export 'src/lang/io/stream_support.dart';
export 'src/lang/io/stream_builder.dart';
export 'src/lang/io/base.dart';
