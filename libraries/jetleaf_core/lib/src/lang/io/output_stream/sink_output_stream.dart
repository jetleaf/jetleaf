import 'dart:convert';
import 'dart:io';
import 'dart:io' as io;
import 'dart:typed_data';

import '../../exceptions.dart';
import 'output_stream.dart';

/// {@template jetleaf_sink_output_stream}
/// A **concrete implementation** of [OutputStream] that wraps a Dart [IOSink],
/// allowing byte, list of bytes, and string data to be written to any underlying
/// sink, such as files, sockets, or stdout.
///
/// This stream ensures proper validation of offsets, lengths, and closed-state
/// before writing, and throws meaningful exceptions if misuse occurs.
///
/// ### Features
/// - Writes individual bytes via [writeByte].
/// - Writes lists of bytes via [write].
/// - Writes `Uint8List` directly via [writeBytes].
/// - Writes strings via [writeString], optionally supporting custom encodings.
/// - Supports flushing via [flush] and proper closure via [close].
///
/// ### Exceptions
/// - Throws [StreamClosedException] if writing or flushing after the stream is closed.
/// - Throws [InvalidArgumentException] if offset/length in [write] is invalid.
///
/// ### Example
/// ```dart
/// import 'dart:io';
///
/// final file = File('output.txt');
/// final sink = file.openWrite();
/// final stream = SinkOutputStream(sink);
///
/// await stream.writeString("Hello, Jetleaf!");
/// await stream.writeByte(10); // newline
/// await stream.flush();
/// await stream.close();
/// ```
///
/// {@endtemplate}
class SinkOutputStream extends OutputStream {
  /// The underlying [IOSink] that actually receives the written data.
  final IOSink _ioSink;

  /// {@macro jetleaf_sink_output_stream}
  SinkOutputStream(this._ioSink);
  
  @override
  Future<void> writeByte(int b) async {
    checkClosed();

    _ioSink.add([b & 0xFF]);
  }
  
  @override
  Future<void> write(List<int> b, [int offset = 0, int? length]) async {
    checkClosed();

    length ??= b.length - offset;
    if (offset < 0 || length < 0 || offset + length > b.length) {
      throw InvalidArgumentException('Invalid offset or length');
    }
    
    if (length == 0) {
      return;
    }

    try {
      final data = b.sublist(offset, offset + length);
      _ioSink.add(data);
    } on io.SocketException catch (e) {
      throw IOException('Network write error: ${e.message}', cause: e);
    } on io.HttpException catch (e) {
      throw IOException('HTTP write error: ${e.message}', cause: e);
    } catch (e) {
      throw IOException('Unknown error writing bytes to network: $e', cause: e);
    }
  }
  
  @override
  Future<void> writeBytes(Uint8List data) async {
    checkClosed();

    try {
      _ioSink.add(data);
    } on io.SocketException catch (e) {
      throw IOException('Network write error: ${e.message}', cause: e);
    } on io.HttpException catch (e) {
      throw IOException('HTTP write error: ${e.message}', cause: e);
    } catch (e) {
      throw IOException('Unknown error writing bytes to network: $e', cause: e);
    }
  }

  @override
  Future<void> writeObject(Object? obj) async {
    checkClosed();

    try {
      _ioSink.write(obj);
    } on io.SocketException catch (e) {
      throw IOException('Network write error: ${e.message}', cause: e);
    } on io.HttpException catch (e) {
      throw IOException('HTTP write error: ${e.message}', cause: e);
    } catch (e) {
      throw IOException('Unknown error writing bytes to network: $e', cause: e);
    }
  }
  
  @override
  Future<void> writeString(String str, [Encoding? encoding]) async {
    checkClosed();

    if (encoding != null) {
      // Use custom encoding if specified
      final bytes = Uint8List.fromList(str.codeUnits);
      await writeBytes(bytes);
    } else {
      // Use the response's built-in write method which handles encoding
      _ioSink.write(str);
    }
  }
  
  @override
  Future<void> flush() async {
    checkClosed();

    await _ioSink.flush();
  }
  
  @override
  Future<void> close() async {
    if (!isClosed) {
      await flush();
      await _ioSink.close();
      await super.close();
    }
  }
}