/// # Architecture Ecosystem: Low-Level I/O Topologies & Functional Stream Processing
///
/// A production-grade, highly optimized Input/Output and functional pipeline ecosystem providing deterministic,
/// byte-level and character-level streaming abstractions.
///
/// This library decouples the application from native operational system file descriptors, network sockets, 
/// and memory buffers. It implements an explicit dual-layered taxonomy:
///
/// 1. **Binary-Stream Layer (I/O):** Raw sequential 8-bit byte mutations managed via [InputStream] and [OutputStream] branches.
/// 2. **Character-Reader Layer (I/O):** Localized UTF-16/UTF-8 textual scanning and encoding layers handled via [Reader] and [Writer] abstractions.
/// 3. **Functional-Pipeline Layer (BaseStream):** High-velocity, lazy-evaluation stream structures ([IntStream], [DoubleStream], [GenericStream]) 
///    designed to perform filter-map-reduce processing loops over infinite data arrays with minimal memory footprints.
///
/// ---
///
/// ## 1. Stream Hierarchy & Memory Topologies
///
/// ```text
///                     [BaseStream] 
///                          |
///         +----------------+----------------+
///         |                                 |
///  [InputStream] (Raw Bytes 8-bit)   [Reader] (Encoded Characters)
///         |                                 |
///  +------+------+                   +------+------+
///  |             |                   |             |
/// [FileInputStream] [Buffered...]  [FileReader]  [BufferedReader]
/// ```
///
/// ---
///
/// ## 2. Core Operational Layouts
///
/// ### Defensive Buffering Mechanics
/// Direct hardware interaction (Disk reads, network socket packet processing) carries major latency overheads. 
/// Classes like [BufferedInputStream], [BufferedOutputStream], [BufferedReader], and [BufferedWriter] wrap raw streams 
/// within an internal contiguous segment array buffer. This layout aggregates reads/writes into balanced operational chunks, 
/// optimizing CPU cache line alignment and minimizing system-call traps.
///
/// ### Primitive-Specialized Streaming Performance
/// To prevent boxing and unboxing memory allocations during arithmetic data processing, the streaming API separates execution paths 
/// into specialized primitive streams ([IntStream], [DoubleStream]) alongside a type-safe [GenericStream] engine.
///
/// ### Pipeline Architecture Example
/// ```dart
/// // Processing a text file lazily via a functional streaming filter loop
/// final FileInputStream rawFile = FileInputStream('server_logs.txt');
/// final BufferedReader reader = BufferedReader(FileReader(rawFile));
/// 
/// // Read, filter, and count targets without inflating high-water mark memory limits
/// final int errorCount = StreamSupport.stream(reader.lines())
///     .filter((line) => line.contains('[ERROR]'))
///     .mapToInt((line) => 1)
///     .sum();
/// 
/// logger.info('Total processed anomalies in current cycle: $errorCount');
/// ```
library;

// ============================================================================
// BINARY INPUT OPERATIONS (RAW 8-BIT SEQUENCES)
// ============================================================================

export 'src/io/input_stream/input_stream.dart';
export 'src/io/input_stream/buffered_input_stream.dart';
export 'src/io/input_stream/file_input_stream.dart';
export 'src/io/input_stream/network_input_stream.dart';
export 'src/io/input_stream/byte_array_input_stream.dart';
export 'src/io/input_stream/string_input_stream.dart';
export 'src/io/input_stream/input_stream_source.dart';

// ============================================================================
// BINARY OUTPUT OPERATIONS (RAW 8-BIT DESTINATIONS)
// ============================================================================

export 'src/io/output_stream/output_stream.dart';
export 'src/io/output_stream/buffered_output_stream.dart';
export 'src/io/output_stream/byte_array_output_stream.dart';
export 'src/io/output_stream/file_output_stream.dart';
export 'src/io/output_stream/network_output_stream.dart';
export 'src/io/output_stream/sink_output_stream.dart';

// ============================================================================
// TEXT READERS (CHARACTER DECODING PIPELINES)
// ============================================================================

export 'src/io/reader/reader.dart';
export 'src/io/reader/file_reader.dart';
export 'src/io/reader/string_reader.dart';
export 'src/io/reader/buffered_reader.dart';

// ============================================================================
// TEXT WRITERS (CHARACTER ENCODING PERIMETERS)
// ============================================================================

export 'src/io/writer/writer.dart';
export 'src/io/writer/file_writer.dart';
export 'src/io/writer/buffered_writer.dart';

// ============================================================================
// LAZY RE-ACCUMULATION STREAMING FRAMEWORKS (BASESTREAM)
// ============================================================================

export 'src/io/base_stream/base_stream.dart';
export 'src/io/base_stream/int/int_stream.dart';
export 'src/io/base_stream/int/_int_stream.dart';
export 'src/io/base_stream/double/double_stream.dart';
export 'src/io/base_stream/double/_double_stream.dart';
export 'src/io/base_stream/generic/generic_stream.dart';
export 'src/io/base_stream/generic/_generic_stream.dart';

// ============================================================================
// LOGICAL STRING PRINTER TRACES
// ============================================================================

export 'src/io/print_stream/print_stream.dart';
export 'src/io/print_stream/console_print_stream.dart';

// ============================================================================
// STREAM CONSTRUCTION SUPPORTING GLUE
// ============================================================================

export 'src/io/stream_support.dart';
export 'src/io/stream_builder.dart';
export 'src/io/base.dart';