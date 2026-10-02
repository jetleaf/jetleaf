import '../exceptions.dart';
import 'helpers.dart';

/// {@template uri_template}
/// A utility class for defining and working with URI templates that include
/// path variables (e.g., `/users/{id}/orders/{orderId}`).
///
/// This class supports matching incoming paths against templates,
/// extracting variable values, and expanding templates into full URIs
/// given a variable map.
///
/// ---
///
/// ### 🧰 Usage:
/// ```dart
/// final template = UriTemplate('/users/{id}/orders/{orderId}');
///
/// final match = template.match('/users/42/orders/99');
/// print(match); // {id: 42, orderId: 99}
///
/// final expanded = template.expand({'id': '42', 'orderId': '99'});
/// print(expanded); // /users/42/orders/99
/// ```
///
/// ---
///
/// Use this class when you need structured path parsing in routers,
/// dynamic endpoint generation, or URL normalization logic.
///
/// {@endtemplate}
class UriTemplate {
  /// The raw URI template string.
  final String template;

  final List<String> _variableNames;
  final RegExp _pathRegex;

  /// {@macro uri_template}
  UriTemplate(this.template) : _variableNames = extractVariableNames(template), _pathRegex = buildRegex(template);

  /// {@template uri_template_match}
  /// Matches a path string against the URI template and extracts values
  /// for declared path variables.
  ///
  /// If the path matches the template format, this returns a `Map<String, String>`
  /// where keys are variable names and values are matched path segments.
  ///
  /// Returns `null` if the path does not conform to the template.
  ///
  /// ---
  ///
  /// ### Example:
  /// ```dart
  /// final template = UriTemplate('/blog/{year}/{slug}');
  /// final result = template.match('/blog/2025/my-first-post');
  /// print(result); // {year: 2025, slug: my-first-post}
  /// ```
  /// {@endtemplate}
  Map<String, String>? match(String path) {
    final match = _pathRegex.firstMatch(path);
    if (match == null) {
      return null;
    }
    final result = <String, String>{};
    for (int i = 0; i < _variableNames.length; i++) {
      final value = match.group(i + 1); // Group 0 is the full match
      if (value != null) {
        result[_variableNames[i]] = value;
      } else {
        // This should not happen if the regex is built correctly for all variables
        return null;
      }
    }
    return result;
  }

  /// {@template uri_template_expand}
  /// Replaces all variable placeholders in the template with actual values
  /// provided in the [variables] map.
  ///
  /// Throws a [UriPathMatchingException] if any required variable is missing.
  ///
  /// ---
  ///
  /// ### Example:
  /// ```dart
  /// final template = UriTemplate('/docs/{section}/{page}');
  /// final url = template.expand({'section': 'guide', 'page': 'intro'});
  /// print(url); // /docs/guide/intro
  /// ```
  /// {@endtemplate}
  String expand(Map<String, String> variables, [bool throwIfNotFound = true]) {
    String expandedPath = template;
    for (final varName in _variableNames) {
      if (!variables.containsKey(varName) && throwIfNotFound) {
        throw UriPathMatchingException('Missing required URI template variable: $varName');
      }
      expandedPath = expandedPath.replaceAll('{$varName}', variables[varName]!);
    }

    return expandedPath;
  }

  /// {@template uri_template_normalize_path}
  /// Normalizes a raw path by:
  /// - Reducing multiple slashes (`//`) to one (`/`)
  /// - Ensuring a leading slash
  /// - Removing trailing slash if path is not the root
  ///
  /// Useful for consistent internal comparisons or storage.
  ///
  /// ---
  ///
  /// ### Example:
  /// ```dart
  /// final normalized = UriTemplate.normalizePath('///api//v1/users/');
  /// print(normalized); // /api/v1/users
  /// ```
  /// {@endtemplate}
  static String normalizePath(String path) {
    String normalized = path.replaceAll(RegExp(r'/{2,}'), '/'); // Replace multiple slashes with single
    if (!normalized.startsWith('/')) {
      normalized = '/$normalized';
    }
    if (normalized.length > 1 && normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }

    return normalized;
  }

  /// {@template uri_template_normalize}
  /// Produces a normalized version of a full URL string by applying
  /// various standardizations:
  ///
  /// - Converts scheme and host to lowercase
  /// - Removes default ports (80 for HTTP, 443 for HTTPS)
  /// - Resolves path segments (`.` and `..`)
  /// - Reduces multiple slashes
  /// - Removes trailing slashes for non-root paths
  /// - Sorts and re-encodes query parameters
  /// - Re-encodes fragment
  /// - Preserves user info
  ///
  /// ---
  ///
  /// ### Example:
  /// ```dart
  /// final url = 'HTTP://Example.com:80/users?id=2&name=John';
  /// final normalized = UriTemplate.normalize(url);
  /// print(normalized); // http://example.com/users?id=2&name=John
  /// ```
  /// {@endtemplate}
  static String normalize(String url) {
    Uri uri = Uri.parse(url);

    // Scheme normalization: lowercase
    String normalizedScheme = uri.scheme.toLowerCase();

    // Host normalization: lowercase and remove trailing dot
    String normalizedHost = uri.host.toLowerCase();
    if (normalizedHost.isNotEmpty && normalizedHost.endsWith('.')) {
      normalizedHost = normalizedHost.substring(0, normalizedHost.length - 1);
    }

    // Port normalization: remove default ports
    int? normalizedPort = uri.port;
    if ((normalizedScheme == 'http' && normalizedPort == 80) ||
        (normalizedScheme == 'https' && normalizedPort == 443)) {
      normalizedPort = null; // Indicate default port, so it's not included in the URI string
    }

    // Path normalization: resolve . and .., reduce multiple slashes, remove trailing slash for non-root
    String normalizedPath = uri.path;
    if (normalizedPath.isEmpty) {
      normalizedPath = '/'; // Empty path becomes root path
    } else {
      // Use Uri.parse().normalizePath() to resolve . and .. and handle multiple slashes.
      // This also handles percent-encoding for path segments.
      normalizedPath = normalizePath(normalizedPath);

      // Remove trailing slash if it's not the root path
      if (normalizedPath.length > 1 && normalizedPath.endsWith('/')) {
        normalizedPath = normalizedPath.substring(0, normalizedPath.length - 1);
      }
    }

    // Query normalization: sort parameters by key, then by value, and re-encode
    Map<String, List<String>> queryParams = uri.queryParametersAll;
    List<String> sortedKeys = queryParams.keys.toList()..sort();
    List<String> normalizedQuerySegments = [];

    for (String key in sortedKeys) {
      List<String> values = List.from(queryParams[key]!)..sort(); // Sort values for each key
      String encodedKey = Uri.encodeQueryComponent(key);
      for (String value in values) {
        String encodedValue = Uri.encodeQueryComponent(value);
        normalizedQuerySegments.add('$encodedKey=$encodedValue');
      }
    }
    String? normalizedQuery = normalizedQuerySegments.isEmpty ? null : normalizedQuerySegments.join('&');

    // Fragment normalization: re-encode
    String? normalizedFragment = uri.fragment.isEmpty ? null : Uri.encodeComponent(uri.fragment);

    // Reconstruct the URI
    Uri resultUri = Uri(
      scheme: normalizedScheme,
      userInfo: uri.userInfo.isEmpty ? null : uri.userInfo, // Preserve user info if present
      host: normalizedHost,
      port: normalizedPort,
      path: normalizedPath,
      query: normalizedQuery,
      fragment: normalizedFragment,
    );

    return resultUri.toString();
  }

  /// Matches two urls to each other
  static bool matches(String first, String second) {
    return normalize(first) == normalize(second);
  }
}