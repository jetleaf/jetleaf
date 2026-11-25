import 'package:jetleaf_core/lang.dart' show EqualsAndHashCode;
import 'package:jetleaf_web/jetleaf_web.dart';

import 'filter_orders.dart';
import 'header_writer.dart';
import 'security_filter.dart';

/// {@template security_headers_config}
/// Configuration for HTTP security response headers injected by
/// [SecurityHeadersFilter].
///
/// Each field maps to one header; a `null` value omits that header entirely.
/// Defaults follow a restrictive posture suitable for most applications.
///
/// ### Contract
/// - Non-null values become [StaticHeaderWriter] instances in the default
///   writer list.
/// - `strictTransportSecurity`, `contentSecurityPolicy` and `permissionsPolicy`
///   are omitted unless explicitly supplied.
///
/// ### Example
/// ```dart
/// const config = SecurityHeadersConfig(
///   frameOptions: 'SAMEORIGIN',
///   contentSecurityPolicy: "default-src 'self'",
/// );
/// ```
/// {@endtemplate}
class SecurityHeadersConfig with EqualsAndHashCode {
  /// `Strict-Transport-Security` header value (HSTS), or `null` to omit.
  final String? strictTransportSecurity;

  /// `X-Content-Type-Options` header value. Defaults to `'nosniff'`.
  final String? contentTypeOptions;

  /// `X-Frame-Options` header value. Defaults to `'DENY'`.
  final String? frameOptions;

  /// `Referrer-Policy` header value. Defaults to `'no-referrer'`.
  final String? referrerPolicy;

  /// `Content-Security-Policy` header value, or `null` to omit.
  final String? contentSecurityPolicy;

  /// `Permissions-Policy` header value, or `null` to omit.
  final String? permissionsPolicy;

  /// {@macro security_headers_config}
  const SecurityHeadersConfig({
    this.strictTransportSecurity = 'max-age=31536000; includeSubDomains',
    this.contentTypeOptions = 'nosniff',
    this.frameOptions = 'DENY',
    this.referrerPolicy = 'no-referrer',
    this.contentSecurityPolicy,
    this.permissionsPolicy,
  });

  /// Contributes the runtime type and every header value to equality and
  /// hashing.
  ///
  /// ### Returns
  /// The ordered list of properties used by [EqualsAndHashCode].
  @override
  List<Object?> equalizedProperties() => [
    runtimeType,
    strictTransportSecurity,
    contentTypeOptions,
    frameOptions,
    referrerPolicy,
    contentSecurityPolicy,
    permissionsPolicy,
  ];
}

/// {@template security_headers_filter}
/// Runs a composed list of [HeaderWriter]s over every response.
///
/// Each header is independently replaceable; pass [writers] to override the
/// defaults derived from [config]. Because writers run before the chain, their
/// headers are present even on error responses produced later.
///
/// ### Contract and invariants
/// - Writers are applied in list order, so later writers can override earlier
///   ones.
/// - The chain is always advanced after all writers have run.
/// - It occupies the `SecurityFilterOrders.headers` slot, ahead of the filters
///   whose failures might need these headers.
///
/// ### Example
/// ```dart
/// final filter = SecurityHeadersFilter(
///   const SecurityHeadersConfig(),
///   [StaticHeaderWriter('X-Custom', 'value')],
/// );
/// ```
/// {@endtemplate}
class SecurityHeadersFilter extends SecurityFilter {
  /// Configuration used to build the default writers.
  final SecurityHeadersConfig config;

  /// Writers applied in order.
  final List<HeaderWriter> writers;

  /// Execution priority: early, so headers decorate every downstream response.
  @override
  int get order => SecurityFilterOrders.headers;

  /// {@macro security_headers_filter}
  SecurityHeadersFilter([SecurityHeadersConfig? config, List<HeaderWriter>? writers])
      : config = config ?? const SecurityHeadersConfig(),
        writers = writers ?? _writersFor(config ?? const SecurityHeadersConfig());

  /// {@template security_headers_filter.writers_for}
  /// Builds the default writer list from a [SecurityHeadersConfig].
  ///
  /// A writer is included only when its corresponding configuration value is
  /// non-null, allowing individual headers to be disabled.
  ///
  /// ### Parameters
  /// - [config]: The configuration supplying header names and values.
  ///
  /// ### Returns
  /// An ordered list of [StaticHeaderWriter] instances.
  /// {@endtemplate}
  static List<HeaderWriter> _writersFor(SecurityHeadersConfig config) => [
    if (config.strictTransportSecurity case final value?) ...[
      StaticHeaderWriter('Strict-Transport-Security', value),
    ],
    if (config.contentTypeOptions case final value?) ...[
      StaticHeaderWriter('X-Content-Type-Options', value),
    ],
    if (config.frameOptions case final value?) ...[
      StaticHeaderWriter('X-Frame-Options', value),
    ],
    if (config.referrerPolicy case final value?) ...[
      StaticHeaderWriter('Referrer-Policy', value),
    ],
    if (config.contentSecurityPolicy case final value?) ...[
      StaticHeaderWriter('Content-Security-Policy', value),
    ],
    if (config.permissionsPolicy case final value?) ...[
      StaticHeaderWriter('Permissions-Policy', value),
    ],
  ];

  /// Writes every configured security header, then continues the chain.
  ///
  /// [request] is forwarded to each writer for request-aware decisions.
  /// [response] accumulates the emitted headers. [chain] is always invoked with
  /// `chain.next(request, response)` after the writers finish.
  ///
  /// ### Parameters
  /// - [request]: The incoming [ServerHttpRequest].
  /// - [response]: The outgoing [ServerHttpResponse].
  /// - [chain]: The remaining filter chain to delegate to.
  ///
  /// ### Returns
  /// A [Future] that completes after the downstream chain finishes.
  ///
  /// ### Throws
  /// Propagates errors from downstream filters.
  ///
  /// ### Example
  /// ```dart
  /// await filter.doFilter(request, response, chain);
  /// // response.headers now contains X-Frame-Options: DENY
  /// ```
  @override
  Future<void> doFilter(ServerHttpRequest request, ServerHttpResponse response, FilterChain chain) async {
    for (final writer in writers) {
      writer.writeHeaders(request, response);
    }
    await chain.next(request, response);
  }
}