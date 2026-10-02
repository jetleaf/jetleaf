import 'url.dart';

/// {@template uri_extension}
/// Extension on Dart's [Uri] class to convert it into a [Url] instance.
/// 
/// This allows seamless transition between [Uri] and [Url] for interoperability.
/// 
/// Example:
/// ```dart
/// final uri = Uri.parse('https://example.com');
/// final url = uri.toUrl();
/// ```
/// {@endtemplate}
extension UriExtension on Uri {
  /// {@macro uri_extension}
  Url toUrl() => Url(toString());
}