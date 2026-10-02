part of 'url_connection.dart';

/// {@template http_url_connection}
/// A concrete implementation of [UrlConnection] for HTTP and HTTPS protocols.
///
/// This class uses Dart's `HttpClient` to establish a connection to the
/// specified [Url], sends the HTTP request, and retrieves the response.
///
/// ### Example:
/// ```dart
/// final connection = HttpUrlConnection(Url.parse('https://example.com'));
/// await connection.connect();
///
/// final stream = connection.getInputStream();
/// int byte;
/// while ((byte = await stream.readByte()) != -1) {
///   print(String.fromCharCode(byte));
/// }
/// await stream.close();
/// ```
///
/// Errors during the connection process are wrapped in [NetworkException]
/// for consistent handling.
/// {@endtemplate}
class HttpUrlConnection extends UrlConnection {
  /// {@macro http_url_connection}
  HttpUrlConnection(super.url);

  @override
  Future<void> connect() async {
    if (_connected) return;

    final client = HttpClient();
    try {
      final request = await client.getUrl(url.toUri());
      _setRequest(request);
      final response = await request.close();
      _setResponse(response);
    } on SocketException catch (e) {
      throw NetworkException(
        'Failed to connect to ${url.toString()}: ${e.message}',
        cause: e
      );
    } on HandshakeException catch (e) {
      throw NetworkException(
        'SSL/TLS handshake failed for ${url.toString()}: ${e.message}',
        cause: e
      );
    } on HttpException catch (e) {
      throw NetworkException(
        'HTTP error for ${url.toString()}: ${e.message}',
        cause: e
      );
    } catch (e) {
      throw NetworkException(
        'An unknown network error occurred for ${url.toString()}: $e',
        cause: e
      );
    } finally {
      client.close(); // Ensure the client is closed
    }
  }
}