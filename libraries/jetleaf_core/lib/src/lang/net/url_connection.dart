import 'dart:io' show HttpClient, HandshakeException, HttpException, SocketException, HttpClientRequest, HttpClientResponse;

import '../exceptions.dart';
import '../io/input_stream/input_stream.dart';
import '../io/input_stream/network_input_stream.dart';
import 'url.dart';

part '_url_connection.dart';

/// {@template url_connection}
/// Represents a communication link between the application and a [Url].
///
/// This class serves as the base abstraction for different types of
/// connections (e.g., HTTP, FTP). Concrete subclasses are expected to implement
/// protocol-specific connection logic in the [connect] method.
///
/// Once connected, the [UrlConnection] provides access to the request and
/// response objects, and allows obtaining an input stream for reading the response body.
///
/// ### Example
/// ```dart
/// class HttpUrlConnection extends UrlConnection {
///   HttpUrlConnection(Url url) : super(url);
///
///   @override
///   Future<void> connect() async {
///     final client = HttpClient();
///     final req = await client.getUrl(Uri.parse(url.toString()));
///     _setRequest(req);
///     _setResponse(await req.close());
///   }
/// }
///
/// final connection = HttpUrlConnection(Url.parse('https://example.com'));
/// await connection.connect();
/// final stream = connection.getInputStream();
/// int byte;
/// while ((byte = await stream.readByte()) != -1) {
///   print(byte);
/// }
/// ```
/// {@endtemplate}
abstract class UrlConnection {
  /// The [Url] this connection was created for.
  final Url url;

  HttpClientRequest? _request;
  HttpClientResponse? _response;
  bool _connected = false;

  /// {@macro url_connection}
  UrlConnection(this.url);

  /// Establishes a connection to the resource referenced by this [UrlConnection].
  ///
  /// Must be implemented by subclasses to perform protocol-specific logic
  /// (e.g., building a `HttpClientRequest`, sending the request, and receiving the response).
  ///
  /// Throws a [NetworkException] if any error occurs during the connection process.
  Future<void> connect();

  /// Returns the underlying [HttpClientRequest] object.
  ///
  /// Can be used by subclasses during [connect] to write request headers or body.
  HttpClientRequest? get request => _request;

  /// Returns the underlying [HttpClientResponse] object.
  ///
  /// Available only after [connect] completes successfully.
  HttpClientResponse? get response => _response;

  /// Returns an [InputStream] that reads the response body of this connection.
  ///
  /// Throws a [NetworkException] if [connect] has not yet been called or the response
  /// has not been received.
  ///
  /// ### Example
  /// ```dart
  /// final stream = connection.getInputStream();
  /// int byte;
  /// while ((byte = await stream.readByte()) != -1) {
  ///   // Process each byte
  /// }
  /// ```
  InputStream getInputStream() {
    if (!_connected || _response == null) {
      throw NetworkException('Connection not established or response not received.');
    }
    return NetworkInputStream(_response!);
  }

  /// Sets the internal [HttpClientRequest] reference.
  ///
  /// Intended to be used by subclasses after building the request.
  void _setRequest(HttpClientRequest request) {
    _request = request;
  }

  /// Sets the internal [HttpClientResponse] and marks the connection as open.
  ///
  /// Intended to be used by subclasses after calling `request.close()`.
  void _setResponse(HttpClientResponse response) {
    _response = response;
    _connected = true;
  }
}