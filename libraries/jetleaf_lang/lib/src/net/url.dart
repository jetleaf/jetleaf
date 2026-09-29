library;

import '../exceptions.dart';
import '../io/input_stream/input_stream.dart';
import 'url_connection.dart';

/// {@template url}
/// Represents a Uniform Resource Locator (URL) and provides methods to parse,
/// construct, and open connections to the referenced resource.
///
/// This class acts as a convenient wrapper around Dart's built-in [Uri] class,
/// and integrates with Jetleaf's networking system to provide typed access
/// and connection management.
///
/// Use [Url] when you need structured access to URL components or want to
/// establish a connection via [UrlConnection].
///
/// ### Example: Parse and connect
/// ```dart
/// final url = Url('https://example.com/api/data?user=42');
/// print(url.host);     // example.com
/// print(url.query);    // user=42
///
/// final stream = await url.openStream();
/// int byte;
/// while ((byte = await stream.readByte()) != -1) {
///   print(String.fromCharCode(byte));
/// }
/// await stream.close();
/// ```
/// {@endtemplate}
final class Url {
  final Uri _uri;

  /// {@macro url}
  ///
  /// Parses the given [spec] string into a [Url] instance.
  ///
  /// Throws a [MalformedUrlException] if the URL is not valid.
  Url(String spec) : _uri = _parseUri(spec);

  /// Creates a new [Url] instance from its individual components.
  ///
  /// All parts are assembled into a valid URI using Dart's [Uri] class.
  ///
  /// - [protocol]: Scheme (e.g. `"http"`, `"https"`)
  /// - [host]: Hostname or IP address
  /// - [port]: Port number or `-1` for default
  /// - [path]: Path portion of the URL
  /// - [query]: Optional query (no `?` prefix)
  /// - [fragment]: Optional fragment (no `#` prefix)
  ///
  /// Throws a [MalformedUrlException] if the components do not form a valid URL.
  Url.fromComponents({
    required String protocol,
    required String host,
    int port = -1,
    String path = '',
    String query = '',
    String fragment = '',
  }) : _uri = _buildUri(protocol, host, port, path, query, fragment);

  /// Internal helper that parses a string into a [Uri].
  ///
  /// Wraps any [FormatException] into a [MalformedUrlException].
  static Uri _parseUri(String spec) {
    try {
      return Uri.parse(spec);
    } on FormatException catch (e) {
      throw MalformedUrlException('Invalid URL format: ${e.message}', uri: Uri.tryParse(spec));
    }
  }

  /// Internal helper to construct a [Uri] from components.
  ///
  /// Converts `-1` port to `null`, and skips empty query/fragment parts.
  static Uri _buildUri(String protocol, String host, int port, String path, String query, String fragment) {
    try {
      return Uri(
        scheme: protocol,
        host: host,
        port: port == -1 ? null : port,
        path: path,
        query: query.isEmpty ? null : query,
        fragment: fragment.isEmpty ? null : fragment,
      );
    } on FormatException catch (e) {
      throw MalformedUrlException('Invalid URL components: ${e.message}');
    }
  }

  /// The scheme of the URL, such as `"http"` or `"https"`.
  String get protocol => _uri.scheme;

  /// The host portion of the URL (e.g., `"example.com"`).
  String get host => _uri.host;

  /// The port number, or `-1` if not explicitly set.
  int get port => _uri.port == 0 ? -1 : _uri.port;

  /// The path component of the URL (e.g., `"/api/data"`).
  String get path => _uri.path;

  /// The query string (e.g., `"name=foo&age=30"`) without leading `'?'`.
  String get query => _uri.query;

  /// The fragment (e.g., `"section1"`) without leading `'#'`.
  String get fragment => _uri.fragment;

  /// Returns this [Url] as a [Uri].
  ///
  /// This allows usage of core Dart URI APIs when needed.
  Uri toUri() => _uri;

  /// Opens a connection to this [Url] and returns an [InputStream] to read from it.
  ///
  /// This is a convenience method that:
  /// 1. Creates a [UrlConnection]
  /// 2. Connects to the URL
  /// 3. Returns the input stream for the response body
  ///
  /// Throws a [NetworkException] on failure.
  ///
  /// ### Example
  /// ```dart
  /// final stream = await Url('https://example.com').openStream();
  /// ```
  Future<InputStream> openStream() async {
    final connection = openConnection();
    await connection.connect();
    return connection.getInputStream();
  }

  /// Opens a new [UrlConnection] to the resource represented by this [Url].
  ///
  /// The actual implementation depends on the scheme:
  /// - `"http"` and `"https"` → [HttpUrlConnection]
  ///
  /// Throws a [NetworkException] if the protocol is unsupported.
  UrlConnection openConnection() {
    switch (protocol) {
      case 'http':
      case 'https':
        return HttpUrlConnection(this);
      default:
        throw NetworkException('Unsupported protocol: $protocol');
    }
  }

  @override
  String toString() => _uri.toString();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Url && _uri == other._uri;
  }

  @override
  int get hashCode => _uri.hashCode;
}