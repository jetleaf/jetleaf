import 'dart:async';
import 'dart:typed_data';

import '../../exceptions.dart';
import 'input_stream.dart';

/// {@template network_input_stream}
/// An [InputStream] implementation that reads bytes from a Dart [Stream<List<int>>].
///
/// This is typically used to wrap network response streams such as
/// `HttpClientResponse` in Dart.
///
/// The class buffers incoming chunks and provides methods to read the stream
/// byte-by-byte in a non-blocking manner.
///
/// ### Example usage:
/// ```dart
/// final response = await HttpClient().getUrl(Uri.parse('https://example.com'));
/// final inputStream = NetworkInputStream(response);
///
/// int byte;
/// while ((byte = await inputStream.readByte()) != -1) {
///   print(byte);
/// }
/// await inputStream.close();
/// ```
/// {@endtemplate}
class NetworkInputStream extends InputStream {
  final Stream<List<int>> _sourceStream;
  StreamSubscription<List<int>>? _subscription;
  Uint8List _buffer = Uint8List(0);
  int _bufferOffset = 0;
  Completer<void>? _readCompleter;
  bool _isDone = false;

  /// {@macro network_input_stream}
  ///
  /// The provided [_sourceStream] must emit `List<int>` values (byte chunks).
  NetworkInputStream(this._sourceStream) {
    _subscription = _sourceStream.listen(
      (data) {
        _buffer = Uint8List.fromList([..._buffer.sublist(_bufferOffset), ...data]);
        _bufferOffset = 0;
        _readCompleter?.complete();
        _readCompleter = null;
      },
      onError: (error) {
        _readCompleter?.completeError(IOException('Error reading from network stream: $error', cause: error));
        _readCompleter = null;
        _isDone = true;
        close(); // Close on error
      },
      onDone: () {
        _isDone = true;
        _readCompleter?.complete();
        _readCompleter = null;
      },
      cancelOnError: true,
    );
  }

  @override
  Future<int> readByte() async {
    checkClosed();

    if (_bufferOffset < _buffer.length) {
      return _buffer[_bufferOffset++];
    }

    if (_isDone) {
      return -1; // End of stream
    }

    // Buffer is empty, wait for more data
    _readCompleter = Completer<void>();
    await _readCompleter!.future;

    if (_bufferOffset < _buffer.length) {
      return _buffer[_bufferOffset++];
    }

    if (_isDone) {
      return -1; // End of stream after waiting
    }

    // This case should ideally not be reached if _isDone is handled correctly
    // and data is always provided or stream is done.
    throw IOException('Failed to read byte: no data available after waiting.');
  }

  @override
  Future<int> available() async {
    checkClosed();
    // For a network stream, we can only reliably report what's already buffered.
    // We cannot predict how much more data is coming without blocking.
    return _buffer.length - _bufferOffset;
  }

  @override
  bool markSupported() => false; // Network streams typically don't support mark/reset

  @override
  void mark(int readLimit) {
    throw IOException('Mark/reset not supported on NetworkInputStream');
  }

  @override
  Future<void> reset() async {
    throw IOException('Mark/reset not supported on NetworkInputStream');
  }

  @override
  Future<void> close() async {
    if (!isClosed) {
      await _subscription?.cancel();
      _subscription = null;
      _buffer = Uint8List(0);
      _bufferOffset = 0;
      _readCompleter?.completeError(StreamClosedException()); // Complete any pending reads with error
      _readCompleter = null;
      await super.close();
    }
  }
}