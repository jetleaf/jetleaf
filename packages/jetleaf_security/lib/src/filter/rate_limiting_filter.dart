import 'package:jetleaf_core/lang.dart' show EqualsAndHashCode;

import 'typedefs.dart';
import 'dart:convert';

import 'package:jetleaf_web/jetleaf_web.dart';

import 'filter_orders.dart';
import 'security_filter.dart';

/// {@template rate_limit_config}
/// Configuration for [RateLimitingFilter] controlling token bucket capacity
/// and refill rate per client key.
///
/// Each client identified by a key owns one bucket. A request consumes one
/// token; tokens accrue continuously at [refillTokens] per [refillPeriod] up to
/// [capacity].
///
/// ### Contract and invariants
/// - [capacity] is the maximum burst size and the bucket's upper bound.
/// - [refillTokens] must be greater than zero for clients to recover quota.
/// - [keyExtractor] overrides the built-in client-key resolution when supplied.
/// - [trustedProxies] is empty by default so a client-supplied
///   `X-Forwarded-For` header can never choose its own bucket.
/// - [maxBuckets] bounds memory use by evicting the least recently refilled
///   bucket.
///
/// ### Example
/// ```dart
/// const config = RateLimitConfig(
///   capacity: 100,
///   refillTokens: 100,
///   refillPeriod: Duration(minutes: 1),
/// );
/// ```
/// {@endtemplate}
class RateLimitConfig with EqualsAndHashCode {
  /// Maximum burst capacity of tokens per bucket.
  final int capacity;

  /// Number of tokens refilled per [refillPeriod].
  final int refillTokens;

  /// Interval at which [refillTokens] are added back to the bucket.
  final Duration refillPeriod;

  /// Optional custom key extractor. When omitted, the trusted-proxy-aware
  /// default is used.
  final ClientKeyExtractor? keyExtractor;

  /// Client addresses allowed to set `X-Forwarded-For`. Empty by default, so
  /// a client-supplied header can never choose its own rate-limit bucket.
  final Set<String> trustedProxies;

  /// Maximum number of tracked buckets before idle ones are evicted.
  final int maxBuckets;

  /// {@macro rate_limit_config}
  const RateLimitConfig({
    this.capacity = 60,
    this.refillTokens = 60,
    this.refillPeriod = const Duration(minutes: 1),
    this.keyExtractor,
    this.trustedProxies = const {},
    this.maxBuckets = 10000,
  });

  /// Contributes the runtime type and every config field to equality and
  /// hashing.
  ///
  /// ### Returns
  /// The ordered list of properties used by [EqualsAndHashCode].
  @override
  List<Object?> equalizedProperties() => [
    runtimeType,
    capacity,
    refillTokens,
    refillPeriod,
    keyExtractor,
    trustedProxies,
    maxBuckets,
  ];
}

/// {@template rate_limiting_filter.token_bucket}
/// Mutable in-memory state for one client's token bucket.
///
/// [tokens] is fractional between refills so quota accrues smoothly, and
/// [lastRefill] anchors the next refill calculation.
/// {@endtemplate}
class _TokenBucket {
  /// {@template rate_limiting_filter.token_bucket.tokens}
  /// Currently available tokens; may be fractional between refills.
  /// {@endtemplate}
  double tokens;

  /// {@template rate_limiting_filter.token_bucket.last_refill}
  /// Time at which this bucket was last refilled.
  /// {@endtemplate}
  DateTime lastRefill;

  /// {@macro rate_limiting_filter.token_bucket}
  _TokenBucket(this.tokens, this.lastRefill);
}

/// {@template rate_limiting_filter}
/// In-memory token-bucket rate-limiting [SecurityFilter] that emits standard
/// `X-RateLimit-Remaining` and `Retry-After` headers and returns HTTP 429 when a
/// client exceeds its quota.
///
/// The filter derives a client key, refills that client's bucket, consumes one
/// token and either advances the chain or writes a JSON 429 response. State is
/// process-local and is not shared across instances.
///
/// ### Contract and invariants
/// - Buckets are keyed per client and capped by `RateLimitConfig.maxBuckets`.
/// - Only peers listed in `trustedProxies` may influence the key through
///   `X-Forwarded-For`; unknown peers fall back to a stable sentinel.
/// - An accepted request always carries `X-RateLimit-Remaining`.
/// - A rejected request sets 429, `Retry-After`, `X-RateLimit-Remaining: 0` and
///   a JSON error body, and does not advance the chain.
/// - It occupies the `SecurityFilterOrders.rateLimiting` slot, after CORS and
///   before any credentials work.
///
/// ### Example
/// ```dart
/// final filter = RateLimitingFilter(
///   config: const RateLimitConfig(capacity: 10, refillTokens: 10),
/// );
/// ```
/// {@endtemplate}
class RateLimitingFilter extends SecurityFilter {
  /// Rate limit configuration.
  final RateLimitConfig config;

  /// Clock provider (injectable for deterministic testing).
  final ClockSupplier clock;

  /// {@template rate_limiting_filter.buckets}
  /// Process-local map of client keys to their current token buckets.
  /// {@endtemplate}
  final Map<String, _TokenBucket> _buckets = {};

  /// Execution priority: after CORS but before authentication and other
  /// expensive security work.
  @override
  int get order => SecurityFilterOrders.rateLimiting;

  /// {@macro rate_limiting_filter}
  RateLimitingFilter({
    this.config = const RateLimitConfig(),
    ClockSupplier? clock,
  }) : clock = clock ?? DateTime.now;

  /// Applies quota enforcement to [request] before delegating to [chain].
  ///
  /// [request] supplies the client address or custom key. [response] receives
  /// rate-limit headers and, on rejection, a 429 status and JSON error body.
  /// [chain] is called with `chain.next(request, response)` only when a token
  /// is available.
  ///
  /// ### Parameters
  /// - [request]: The incoming [ServerHttpRequest].
  /// - [response]: The outgoing [ServerHttpResponse].
  /// - [chain]: The remaining filter chain to delegate to when allowed.
  ///
  /// ### Returns
  /// A [Future] that completes after the chain finishes or the 429 response is
  /// written.
  ///
  /// ### Throws
  /// Propagates errors raised by downstream filters; quota exhaustion is not an
  /// exception.
  ///
  /// ### Example
  /// ```dart
  /// await filter.doFilter(request, response, chain);
  /// // response.headers['X-RateLimit-Remaining'] reports the leftover quota.
  /// ```
  @override
  Future<void> doFilter(ServerHttpRequest request, ServerHttpResponse response, FilterChain chain) async {
    final key = _extractKey(request);
    final now = clock();
    _evictIfNeeded(now);
    final bucket = _buckets.putIfAbsent(
      key,
      () => _TokenBucket(config.capacity.toDouble(), now),
    );

    _refill(bucket, now);

    if (bucket.tokens >= 1.0) {
      bucket.tokens -= 1.0;
      response.getHeaders().set(
        'X-RateLimit-Remaining',
        bucket.tokens.floor().toString(),
      );
      await chain.next(request, response);
      return;
    }

    final retryAfterSeconds = (config.refillPeriod.inMilliseconds / 1000.0 / config.refillTokens)
        .ceil()
        .clamp(1, 3600);
    response.setStatus(HttpStatus.TOO_MANY_REQUESTS);
    response.getHeaders().set('Retry-After', retryAfterSeconds.toString());
    response.getHeaders().set('X-RateLimit-Remaining', '0');
    response.getHeaders().setContentType(MediaType.APPLICATION_JSON);
    final output = response.getBody();
    await output.writeString(
      jsonEncode({
        'error': 'too_many_requests',
        'message': 'Rate limit exceeded. Try again later.',
      }),
    );
    await output.close();
  }

  /// {@template rate_limiting_filter.extract_key}
  /// Resolves the bucket key for [request] using the configured extractor or
  /// the trusted-proxy-aware default.
  ///
  /// A `X-Forwarded-For` value is honored only when the direct peer is listed
  /// in `trustedProxies`. Otherwise the direct address is used, falling back to
  /// a stable sentinel when the transport exposes none.
  ///
  /// ### Parameters
  /// - [request]: The incoming request whose peer address is inspected.
  ///
  /// ### Returns
  /// A stable string key identifying the client's bucket.
  /// {@endtemplate}
  String _extractKey(ServerHttpRequest request) {
    if (config.keyExtractor != null) {
      return config.keyExtractor!(request);
    }
    final peer = request.getOrigin();
    if (peer.isNotEmpty && config.trustedProxies.contains(peer)) {
      final forwarded = request.getHeaders().getFirst('X-Forwarded-For');
      if (forwarded != null && forwarded.isNotEmpty) {
        return forwarded.split(',').first.trim();
      }
    }
    // Unknown peers always fall back to the direct connection address. If a
    // transport does not expose one, use a stable sentinel rather than a
    // client-controlled value.
    return peer.isEmpty ? 'direct-unknown' : peer;
  }

  /// {@template rate_limiting_filter.evict_if_needed}
  /// Removes the least recently refilled bucket when the map is at capacity.
  ///
  /// ### Parameters
  /// - [now]: The current time, used only for consistency with refill timing.
  /// {@endtemplate}
  void _evictIfNeeded(DateTime now) {
    if (_buckets.length < config.maxBuckets) return;
    String? oldestKey;
    DateTime? oldest;
    for (final entry in _buckets.entries) {
      if (oldest == null || entry.value.lastRefill.isBefore(oldest)) {
        oldest = entry.value.lastRefill;
        oldestKey = entry.key;
      }
    }
    if (oldestKey != null) _buckets.remove(oldestKey);
  }

  /// {@template rate_limiting_filter.refill}
  /// Adds proportionally to [bucket] for the time elapsed since its last
  /// refill, capped at the configured capacity.
  ///
  /// ### Parameters
  /// - [bucket]: The mutable bucket to refill.
  /// - [now]: The current time used to measure the elapsed interval.
  /// {@endtemplate}
  void _refill(_TokenBucket bucket, DateTime now) {
    final elapsedMs = now.difference(bucket.lastRefill).inMilliseconds;
    if (elapsedMs <= 0) return;

    final ratePerMs = config.refillTokens / config.refillPeriod.inMilliseconds;
    final added = elapsedMs * ratePerMs;
    if (added > 0) {
      bucket.tokens = (bucket.tokens + added).clamp(0.0, config.capacity.toDouble());
      bucket.lastRefill = now;
    }
  }
}
