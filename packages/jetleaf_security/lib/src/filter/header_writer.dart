import 'package:jetleaf_core/lang.dart' show EqualsAndHashCode;
import 'package:jetleaf_web/jetleaf_web.dart';

/// {@template header_writer}
/// Writes one security header, or a related group of headers, onto a response.
///
/// Writers are small, composable units invoked by `SecurityHeadersFilter` for
/// every request. Keeping each header in its own writer lets applications
/// replace, add or remove individual headers without changing the filter.
///
/// ### Contract
/// - [writeHeaders] is synchronous and must not advance any filter chain.
/// - Implementations receive both sides of the exchange so they can make
///   request-dependent decisions (for example whether to emit a header).
/// - Writers are applied in list order; a later writer may overwrite an
///   earlier value.
///
/// ### See also
/// - [StaticHeaderWriter]
/// - `SecurityHeadersFilter`
/// {@endtemplate}
abstract interface class HeaderWriter {
  /// Writes headers for [request] to [response].
  ///
  /// ### Parameters
  /// - [request]: The incoming [ServerHttpRequest], available for conditional
  ///   decisions.
  /// - [response]: The outgoing [ServerHttpResponse] whose headers are modified.
  ///
  /// ### Returns
  /// Nothing; the response is mutated in place.
  ///
  /// ### Example
  /// ```dart
  /// writer.writeHeaders(request, response);
  /// ```
  void writeHeaders(ServerHttpRequest request, ServerHttpResponse response);
}

/// {@template static_header_writer}
/// Writes a fixed header value, optionally without overwriting an existing one.
///
/// This is the default writer used for configuration-driven headers such as
/// `Strict-Transport-Security`, `X-Frame-Options` and `Referrer-Policy`.
///
/// ### Contract
/// - With [overwrite] set, any value already present on the response is
///   replaced.
/// - Otherwise the value is written only when the header is absent, preserving
///   a value set earlier by application code.
///
/// ### Example
/// ```dart
/// const writer = StaticHeaderWriter('X-Frame-Options', 'DENY');
/// writer.writeHeaders(request, response);
/// ```
/// {@endtemplate}
final class StaticHeaderWriter with EqualsAndHashCode implements HeaderWriter {
  /// Header name.
  final String name;

  /// Header value.
  final String value;

  /// Whether to replace a value already set by the application.
  final bool overwrite;

  /// {@macro static_header_writer}
  const StaticHeaderWriter(this.name, this.value, {this.overwrite = true});

  /// Writes [value] under [name] to [response] according to [overwrite].
  ///
  /// ### Parameters
  /// - [request]: The incoming [ServerHttpRequest]; unused by this writer.
  /// - [response]: The outgoing [ServerHttpResponse] whose headers are modified.
  ///
  /// ### Returns
  /// Nothing; the response headers are mutated in place.
  @override
  void writeHeaders(ServerHttpRequest request, ServerHttpResponse response) {
    if (overwrite || response.getHeaders().getFirst(name) == null) {
      response.getHeaders().set(name, value);
    }
  }

  /// Contributes the runtime type, [name], [value] and [overwrite] to equality
  /// and hashing.
  ///
  /// ### Returns
  /// The ordered list of properties used by [EqualsAndHashCode].
  @override
  List<Object?> equalizedProperties() => [runtimeType, name, value, overwrite];
}
