import 'dart:io' as io;

import '../../exceptions.dart';
import 'output_stream.dart';

/// {@template network_output_stream}
/// An [OutputStream] implementation that writes bytes to a Dart `HttpClientRequest`.
///
/// This stream is used to send body content to a server over HTTP.
///
/// ### Use case:
/// This is typically used by a higher-level [UrlConnection] abstraction
/// to manage writing request bodies before connecting the request.
///
/// ### Example:
/// ```dart
/// final request = await HttpClient().postUrl(Uri.parse('https://example.com'));
/// final stream = NetworkOutputStream(request);
/// 
/// await stream.write([72, 101, 108, 108, 111]); // writes "Hello"
/// await stream.flush(); // ensures data is sent to the request buffer
/// await stream.close(); // closes the stream (but not the request itself)
/// 
/// // The actual HTTP request is sent by calling:
/// final response = await request.close();
/// ```
///
/// > ⚠️ Do **not** call `_request.close()` in this stream. That should be done externally.
/// {@endtemplate}
class NetworkOutputStream extends OutputStream {
  final io.HttpClientRequest _request;

  /// {@macro network_output_stream}
  ///
  /// Creates a new instance that wraps the provided [HttpClientRequest].
  NetworkOutputStream(this._request);

  @override
  Future<void> writeByte(int b) async {
    checkClosed();
    try {
      _request.add([b]);
    } on io.SocketException catch (e) {
      throw IOException('Network write error: ${e.message}', cause: e);
    } on io.HttpException catch (e) {
      throw IOException('HTTP write error: ${e.message}', cause: e);
    } catch (e) {
      throw IOException('Unknown error writing byte to network: $e', cause: e);
    }
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
      _request.add(b.sublist(offset, offset + length));
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
      _request.write(obj);
    } on io.SocketException catch (e) {
      throw IOException('Network write error: ${e.message}', cause: e);
    } on io.HttpException catch (e) {
      throw IOException('HTTP write error: ${e.message}', cause: e);
    } catch (e) {
      throw IOException('Unknown error writing bytes to network: $e', cause: e);
    }
  }

  @override
  Future<void> flush() async {
    checkClosed();
    try {
      await _request.flush();
    } on io.SocketException catch (e) {
      throw IOException('Network flush error: ${e.message}', cause: e);
    } on io.HttpException catch (e) {
      throw IOException('HTTP flush error: ${e.message}', cause: e);
    } catch (e) {
      throw IOException('Unknown error flushing network stream: $e', cause: e);
    }
  }

  @override
  Future<void> close() async {
    if (!isClosed) {
      // Important: Do NOT call _request.close() here.
      // The HttpClientRequest is closed by UrlConnection.connect()
      // to ensure the request is sent after all data is written.
      await super.close();
    }
  }
}