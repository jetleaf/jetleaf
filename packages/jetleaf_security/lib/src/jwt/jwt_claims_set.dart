import 'package:jetleaf_core/lang.dart' show EqualsAndHashCode;

/// {@template jwt_claims_set}
/// Immutable container for the standard and custom claims carried in a JWT
/// payload.
///
/// A claims set represents the decoded payload of a compact JWS token after
/// signature verification. It exposes typed accessors for the registered
/// claims defined by RFC 7519 — `sub`, `iss`, `aud`, `jti`, `iat`, `exp`, and
/// `nbf` — together with a generic lookup for application-specific values.
///
/// - **Immutable:** the supplied map is wrapped with [Map.unmodifiable], so no
///   caller can change a claim after the token has been verified.
/// - **Time claims:** `iat`, `exp`, and `nbf` values are interpreted as seconds
///   since the Unix epoch and converted to UTC [DateTime] instances.
/// - **Audience normalization:** a single `aud` string becomes a one-element
///   list; a list is copied so callers cannot mutate the source map through it.
/// - **Non-throwing absence:** missing or wrongly typed claims yield `null` or
///   an empty collection rather than throwing. Validation policy — including
///   expiry enforcement — belongs to the validator, not to this container.
///
/// ### Example
/// ```dart
/// final claims = JwtClaimsSet({
///   'sub': 'alice',
///   'iss': 'https://issuer.example.com',
///   'aud': ['orders-api'],
///   'exp': DateTime.now().toUtc().add(const Duration(minutes: 5))
///       .millisecondsSinceEpoch ~/ 1000,
/// });
///
/// print(claims.subject);                  // alice
/// print(claims.audience);                 // [orders-api]
/// print(claims.isExpired());              // false
/// print(claims.getClaim<String>('sub'));  // alice
/// ```
/// {@endtemplate}
class JwtClaimsSet with EqualsAndHashCode {
  /// The raw decoded payload, exposed as an unmodifiable map.
  final Map<String, Object?> claims;

  /// {@macro jwt_claims_set}
  ///
  /// ### Parameters
  /// - [claims] — decoded payload entries. The map is wrapped, not copied, so
  ///   callers should hand over a map they do not intend to mutate further.
  JwtClaimsSet(Map<String, Object?> claims)
      : claims = Map.unmodifiable(claims);

  /// The `sub` (subject) claim, or `null` when absent or not a string.
  String? get subject => claims['sub'] as String?;

  /// The `iss` (issuer) claim, or `null` when absent or not a string.
  String? get issuer => claims['iss'] as String?;

  /// The `aud` (audience) claim, normalized to a list of strings.
  ///
  /// A single string is returned as a one-element list, a list is converted to
  /// strings, and any other shape yields an empty list.
  List<String> get audience {
    final aud = claims['aud'];
    if (aud is String) return [aud];
    if (aud is List) return aud.map((e) => e.toString()).toList();
    return const [];
  }

  /// The `jti` (JWT ID) claim, or `null` when absent or not a string.
  String? get id => claims['jti'] as String?;

  /// The `iat` (issued-at) claim as a UTC instant, or `null` when unusable.
  DateTime? get issuedAt => _toDateTime(claims['iat']);

  /// The `exp` (expiration) claim as a UTC instant, or `null` when unusable.
  DateTime? get expiresAt => _toDateTime(claims['exp']);

  /// The `nbf` (not-before) claim as a UTC instant, or `null` when unusable.
  DateTime? get notBefore => _toDateTime(claims['nbf']);

  /// {@template jwt_claims_set.get_claim}
  /// Returns the claim named [name] when it is assignable to [T].
  ///
  /// ### Parameters
  /// - [name] — the claim key to look up.
  ///
  /// ### Returns
  /// The typed value, or `null` when the claim is missing or has a different
  /// runtime type. This is a strict `is T` check — no numeric widening or
  /// string coercion is performed.
  ///
  /// ### Example
  /// ```dart
  /// final plan = claims.getClaim<String>('plan');
  /// final level = claims.getClaim<int>('level');
  /// ```
  /// {@endtemplate}
  T? getClaim<T>(String name) {
    final val = claims[name];
    return val is T ? val : null;
  }

  /// {@template jwt_claims_set.is_expired}
  /// Reports whether the token is expired relative to a reference instant.
  ///
  /// This check is fail-open with respect to a missing `exp` claim: a token
  /// without `exp` is never reported as expired here. Rejecting tokens that
  /// omit `exp` is the validator's responsibility.
  ///
  /// [clockSkew] is subtracted from [now], widening the window in which the
  /// token is still considered valid. This tolerates small clock differences
  /// between issuer and verifier; keep it narrow (seconds, not minutes).
  ///
  /// ### Parameters
  /// - [now] — reference instant; defaults to the current UTC time.
  /// - [clockSkew] — tolerance applied to [now] when comparing `exp`.
  ///
  /// ### Returns
  /// `true` when `exp` exists and is strictly earlier than `now - clockSkew`;
  /// otherwise `false`.
  ///
  /// ### Example
  /// ```dart
  /// final expired = claims.isExpired(
  ///   now: DateTime.parse('2030-01-01T00:00:00Z'),
  ///   clockSkew: const Duration(seconds: 30),
  /// );
  /// ```
  /// {@endtemplate}
  bool isExpired({DateTime? now, Duration clockSkew = Duration.zero}) {
    final exp = expiresAt;
    if (exp == null) return false;
    final reference = (now ?? DateTime.now().toUtc()).subtract(clockSkew);
    return exp.isBefore(reference);
  }

  /// Converts an `int` or `double` epoch-seconds value to a UTC [DateTime].
  ///
  /// Returns `null` for any other representation, including numeric strings.
  static DateTime? _toDateTime(Object? raw) {
    if (raw is int) {
      return DateTime.fromMillisecondsSinceEpoch(raw * 1000, isUtc: true);
    }
    if (raw is double) {
      return DateTime.fromMillisecondsSinceEpoch((raw * 1000).toInt(), isUtc: true);
    }
    return null;
  }

  /// Returns a mutable copy of the claims as a JSON-ready map.
  ///
  /// Mutating the returned map does not affect this claims set.
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(claims);

  @override
  String toString() => 'JwtClaimsSet($claims)';

  /// Contributes the runtime type and [claims] to equality and hashing.
  ///
  /// ### Returns
  /// The ordered list of properties used by [EqualsAndHashCode].
  @override
  List<Object?> equalizedProperties() => [runtimeType, claims];
}