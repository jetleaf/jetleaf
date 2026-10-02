import 'dart:async';
import 'dart:convert' show ByteConversionSink, Encoding;
import 'dart:typed_data';

import '../exceptions.dart';
import '../io/base.dart';

/// {@template byte_stream}
/// A stream of bytes similar to Java's InputStream/OutputStream.
/// 
/// This class provides a stream-based interface for reading and writing bytes,
/// wrapping Dart's `Stream<List<int>>` with Java-like methods.
/// 
/// Example usage:
/// ```dart
/// ByteStream stream = ByteStream.fromList([72, 101, 108, 108, 111]);
/// List<int> data = await stream.readAll();
/// print(String.fromCharCodes(data)); // "Hello"
/// ```
/// 
/// {@endtemplate}
class ByteStream {
  /// The underlying stream
  final Stream<List<int>> _stream;
  
  /// Stream controller for writing
  StreamController<List<int>>? _controller;

  /// Creates a ByteStream from an existing stream.
  /// 
  /// [stream] the underlying stream
  /// 
  /// {@macro byte_stream}
  ByteStream._(this._stream);

  /// Creates a ByteStream from a list of bytes.
  /// 
  /// [bytes] the byte data
  /// 
  /// {@macro byte_stream}
  factory ByteStream.fromList(List<int> bytes) {
    return ByteStream._(Stream.value(bytes));
  }

  /// Creates a ByteStream from a list of bytes that can be broadcasted.
  /// 
  /// [bytes] the byte data
  /// 
  /// {@macro byte_stream}
  factory ByteStream.fromBroadcast(List<int> bytes) {
    return ByteStream._(Stream.value(bytes).asBroadcastStream());
  }

  /// Creates a ByteStream from a stream of bytes.
  /// 
  /// [stream] the stream of byte data
  /// 
  /// {@macro byte_stream}
  factory ByteStream.fromStream(Stream<List<int>> stream) {
    return ByteStream._(stream);
  }

  /// Creates a ByteStream from a string.
  /// 
  /// [str] the string to convert to bytes
  /// 
  /// {@macro byte_stream}
  factory ByteStream.fromString(String str) {
    return ByteStream.fromList(str.codeUnits);
  }

  /// Creates an empty ByteStream that can be written to.
  /// 
  /// {@macro byte_stream}
  factory ByteStream.empty() {
    StreamController<List<int>> controller = StreamController<List<int>>();
    ByteStream stream = ByteStream._(controller.stream);
    stream._controller = controller;
    return stream;
  }

  /// Creates a ByteStream from a Uint8List.
  /// 
  /// [data] the byte data
  /// 
  /// {@macro byte_stream}
  factory ByteStream.fromUint8List(Uint8List data) {
    return ByteStream._(Stream.value(data));
  }

  /// Creates a ByteStream from a Stream of Uint8List.
  /// 
  /// [stream] the stream of byte data
  /// 
  /// {@macro byte_stream}
  factory ByteStream.fromUint8ListStream(Stream<Uint8List> stream) {
    return ByteStream._(stream);
  }

  /// Reads all bytes from the stream.
  /// 
  /// Returns a Future that completes with all the bytes
  Future<List<int>> readAll() async {
    List<int> result = [];
    await for (List<int> chunk in _stream) {
      result.addAll(chunk);
    }
    return result;
  }

  /// Reads all bytes and returns them as a Uint8List.
  Future<Uint8List> readAllAsUint8List() async {
    List<int> bytes = await readAll();
    return Uint8List.fromList(bytes);
  }

  /// Reads all bytes and converts them to a string.
  /// 
  /// [encoding] the encoding to use (defaults to UTF-8 via codeUnits)
  Future<String> readAllAsString() async {
    List<int> bytes = await readAll();
    return String.fromCharCodes(bytes);
  }

  /// Reads a specific number of bytes from the stream.
  /// 
  /// [count] the number of bytes to read
  /// 
  /// Returns a Future that completes with the requested bytes, or fewer if stream ends
  Future<List<int>> read(int count) async {
    List<int> result = [];
    int remaining = count;
    
    await for (List<int> chunk in _stream) {
      if (remaining <= 0) break;
      
      if (chunk.length <= remaining) {
        result.addAll(chunk);
        remaining -= chunk.length;
      } else {
        result.addAll(chunk.take(remaining));
        remaining = 0;
      }
    }
    
    return result;
  }

  /// Writes bytes to the stream (only if created with empty constructor).
  /// 
  /// [bytes] the bytes to write
  void write(List<int> bytes) {
    if (_controller == null) {
      throw NoGuaranteeException('Cannot write to a read-only ByteStream');
    }
    _controller!.add(bytes);
  }

  /// Writes a string to the stream as bytes.
  /// 
  /// [str] the string to write
  void writeString(String str) {
    write(str.codeUnits);
  }

  /// Writes a single byte to the stream.
  /// 
  /// [byte] the byte to write (0-255)
  void writeByte(int byte) {
    if (byte < 0 || byte > 255) {
      throw InvalidArgumentException('Byte value must be between 0 and 255, got: $byte');
    }
    write([byte]);
  }

  /// Closes the stream for writing.
  void close() {
    _controller?.close();
  }

  /// Returns the underlying stream.
  Stream<List<int>> get stream => _stream;

  /// Transforms this ByteStream using the provided transformer.
  /// 
  /// [transformer] the stream transformer to apply
  ByteStream transform<T>(StreamTransformer<List<int>, T> transformer) {
    return ByteStream._(stream.transform(transformer).cast<List<int>>());
  }

  /// Maps each chunk of bytes using the provided function.
  /// 
  /// [mapper] the function to apply to each chunk
  ByteStream map(List<int> Function(List<int>) mapper) {
    return ByteStream._(_stream.map(mapper));
  }

  /// Filters chunks of bytes using the provided predicate.
  /// 
  /// [predicate] the predicate function
  ByteStream where(bool Function(List<int>) predicate) {
    return ByteStream._(_stream.where(predicate));
  }

  /// Skips the first [count] chunks.
  /// 
  /// [count] the number of chunks to skip
  ByteStream skip(int count) {
    return ByteStream._(_stream.skip(count));
  }

  /// Takes only the first [count] chunks.
  /// 
  /// [count] the number of chunks to take
  ByteStream take(int count) {
    return ByteStream._(_stream.take(count));
  }

  /// Collects all emitted chunks into a single byte array.
  /// 
  /// Returns a Future that completes with the collected bytes.
  Future<Uint8List> toBytes() {
    var completer = Completer<Uint8List>();
    var sink = ByteConversionSink.withCallback((bytes) => completer.complete(Uint8List.fromList(bytes)));
    listen(sink.add, onError: completer.completeError, onDone: sink.close, cancelOnError: true);
    return completer.future;
  }

  /// Listens to the stream with the provided callback.
  /// 
  /// [onData] callback for data chunks
  /// [onError] callback for errors
  /// [onDone] callback when stream is done
  /// [cancelOnError] whether to cancel on error
  StreamSubscription<List<int>> listen(void Function(List<int>)? onData, {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    return _stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  /// Converts the byte stream to a string using UTF-8 or the given [encoding].
  /// 
  /// [encoding] the encoding to use (defaults to UTF-8)
  Future<String> bytesToString([Encoding encoding = Closeable.DEFAULT_ENCODING]) => encoding.decodeStream(_stream);

  /// Returns the length of the stream (consumes the stream).
  /// 
  /// Note: This will consume the entire stream to count bytes.
  Future<int> get length async {
    int count = 0;
    await for (List<int> chunk in _stream) {
      count += chunk.length;
    }
    return count;
  }

  /// Converts the stream to a single `Future<List<int>>`.
  Future<List<int>> toList() => readAll();

  /// Returns a string representation of this ByteStream.
  @override
  String toString() => 'ByteStream';

  /// Static utility methods
  
  /// Concatenates multiple ByteStreams into one.
  /// 
  /// [streams] the streams to concatenate
  static ByteStream concat(List<ByteStream> streams) {
    Stream<List<int>> concatenated = Stream.fromIterable(streams)
        .asyncExpand((stream) => stream._stream);
    return ByteStream._(concatenated);
  }

  /// Creates a ByteStream that repeats the given bytes.
  /// 
  /// [bytes] the bytes to repeat
  /// [count] the number of times to repeat (null for infinite)
  static ByteStream repeat(List<int> bytes, [int? count]) {
    if (count == null) {
      return ByteStream._(Stream.periodic(Duration.zero, (_) => bytes));
    } else {
      return ByteStream._(Stream.fromIterable(List.filled(count, bytes)));
    }
  }

  /// Creates a ByteStream from multiple byte arrays.
  /// 
  /// [byteArrays] the arrays of bytes
  static ByteStream fromArrays(List<List<int>> byteArrays) {
    return ByteStream._(Stream.fromIterable(byteArrays));
  }
}