import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/exceptions.dart';
import 'jwk.dart';

/// {@template jwk_set_source}
/// Supplies verification [Jwk] keys to a JWT decoder, identified by `kid`.
///
/// ### Contract
/// - [resolveKey] returns the key registered for the requested identifier, or
///   a default signing key when [keyId] is `null`.
/// - A `null` return means "no suitable key is available"; the caller must
///   treat it as a failed verification rather than a reason to skip signature
///   checking. Implementations are expected to fail closed on fetch or parse
///   errors by throwing an authentication exception.
/// - Returned keys are untrusted until the decoder applies [Jwk.canVerify] for
///   the token's algorithm. A source does not relax algorithm or key-type
///   filtering on the decoder's behalf.
///
/// ### Implementer guidance
/// - Keep lookups bounded and cache remote documents to avoid an HTTP request
///   per token.
/// - Never fall back to a key from an unverified or unrelated document when a
///   specific `kid` cannot be found.
/// - Use [BadCredentialsException] (or another [AuthenticationException]) for
///   transport and document errors so callers can handle them uniformly.
///
/// ### Example
/// ```dart
/// final source = StaticJwkSetSource({'key-1': pinnedJwk});
/// final key = await source.resolveKey('key-1');
/// ```
///
/// ### See also
/// - [RemoteJwkSetSource] — cached HTTP-backed implementation.
/// - [StaticJwkSetSource] — fixed in-memory implementation for tests and
///   pinned keys.
/// {@endtemplate}
abstract interface class JwkSetSource {
  /// {@template jwk_set_source.resolve_key}
  /// Resolves the key matching [keyId], or a default signing key when `null`.
  ///
  /// ### Parameters
  /// - [keyId] — the token header's `kid`, or `null` when the token omits it.
  ///
  /// ### Returns
  /// The matching [Jwk], or `null` when no key is available. The decoder must
  /// reject the token when `null` is returned; a missing key is never a
  /// license to accept a signature.
  /// {@endtemplate}
  Future<Jwk?> resolveKey(String? keyId);
}

/// {@template remote_jwk_set_source}
/// Fetches and caches a remote JWKS document.
///
/// The source keeps a single in-flight refresh so concurrent token
/// verifications share one HTTP request, applies a cooldown to refreshes
/// triggered by unknown `kid` values so an attacker cannot force a request
/// flood, and fails closed when the endpoint is unreachable or the document is
/// malformed.
///
/// - **Caching:** a successful fetch is reused for [cacheTtl]; keys are stored
///   as an unmodifiable map and the first signing key becomes the default.
/// - **Key filtering:** entries are ignored unless they have a `kid`, an
///   accepted `use` (`sig` or absent), and a supported `kty` (`RSA`, `EC`, or
///   `oct`). A document with no usable keys is rejected.
/// - **Fail-closed:** transport errors, non-200 responses, and malformed
///   documents throw [BadCredentialsException]; previously cached keys are not
///   silently substituted for a failed refresh.
///
/// ### Example
/// ```dart
/// final source = RemoteJwkSetSource(
///   Uri.parse('https://issuer.example.com/.well-known/jwks.json'),
///   cacheTtl: const Duration(minutes: 15),
/// );
/// final jwk = await source.resolveKey('key-2026-01');
/// ```
/// {@endtemplate}
final class RemoteJwkSetSource implements JwkSetSource {
  /// The JWKS endpoint consulted on refresh.
  final Uri jwksUri;

  /// How long a fetched document is considered fresh.
  final Duration cacheTtl;

  /// Minimum interval between refreshes triggered by unknown key ids.
  final Duration unknownKidCooldown;

  final http.Client _httpClient;
  Map<String, Jwk> _cachedKeys = const {};
  Jwk? _defaultKey;
  DateTime? _lastFetched;
  DateTime? _lastUnknownKidRefresh;
  Future<void>? _inFlight;

  /// {@macro remote_jwk_set_source}
  RemoteJwkSetSource(
    this.jwksUri, {
    this.cacheTtl = const Duration(minutes: 15),
    this.unknownKidCooldown = const Duration(seconds: 30),
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  /// {@macro jwk_set_source.resolve_key}
  ///
  /// Refreshes first when the cache is expired or when [keyId] is unknown and
  /// the unknown-`kid` cooldown has elapsed. Concurrent callers share the same
  /// refresh future.
  @override
  Future<Jwk?> resolveKey(String? keyId) async {
    final now = DateTime.now();
    final expired = _lastFetched == null || now.difference(_lastFetched!) >= cacheTtl;
    final unknown = keyId != null && !_cachedKeys.containsKey(keyId);

    if (expired || (unknown && _canRefreshForUnknownKid(now))) {
      await _refreshOnce();
    }

    if (keyId != null) return _cachedKeys[keyId];
    return _defaultKey;
  }

  /// Returns `true` (and records [now]) when an unknown-`kid` refresh is due.
  ///
  /// The cooldown bounds how often an unseen identifier may trigger network
  /// traffic, limiting an attacker's ability to amplify requests.
  bool _canRefreshForUnknownKid(DateTime now) {
    final last = _lastUnknownKidRefresh;
    if (last == null || now.difference(last) >= unknownKidCooldown) {
      _lastUnknownKidRefresh = now;
      return true;
    }
    return false;
  }

  /// Coalesces concurrent refreshes into a single in-flight HTTP fetch.
  Future<void> _refreshOnce() {
    final existing = _inFlight;
    if (existing != null) return existing;
    final future = _refresh();
    _inFlight = future;
    return future.whenComplete(() => _inFlight = null);
  }

  /// Fetches, validates, and installs a new JWKS snapshot.
  ///
  /// Throws [BadCredentialsException] on transport failure, non-200 status,
  /// malformed structure, or a document containing no signing keys. The
  /// existing cache is left untouched on failure, and callers fail closed.
  Future<void> _refresh() async {
    final http.Response response;
    try {
      response = await _httpClient.get(jwksUri);
    } catch (e) {
      throw BadCredentialsException('Failed to fetch JWKS document', e);
    }
    if (response.statusCode != 200) {
      throw BadCredentialsException('JWKS endpoint returned ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> || decoded['keys'] is! List) {
      throw BadCredentialsException('Malformed JWKS document');
    }

    final parsed = <String, Jwk>{};
    Jwk? first;
    for (final entry in decoded['keys'] as List) {
      if (entry is! Map<String, dynamic>) continue;
      final use = entry['use'];
      if (use != null && use != 'sig') continue;
      final kty = entry['kty'];
      if (kty != 'RSA' && kty != 'EC' && kty != 'oct') continue;
      final kid = entry['kid'] as String?;
      if (kid == null) continue;
      final jwk = Jwk.fromJson(entry);
      parsed[kid] = jwk;
      first ??= jwk;
    }

    if (parsed.isEmpty) {
      throw BadCredentialsException('JWKS document has no signing keys');
    }
    _cachedKeys = Map.unmodifiable(parsed);
    _defaultKey = first;
    _lastFetched = DateTime.now();
  }
}

/// {@template static_jwk_set_source}
/// In-memory [JwkSetSource] backed by a fixed map of `kid` to [Jwk].
///
/// Useful for pinned keys, local development, and deterministic tests. There
/// is no refresh path: a missing `kid` returns `null`, which the decoder treats
/// as a failed verification.
///
/// ### Example
/// ```dart
/// final source = StaticJwkSetSource({
///   'key-1': Jwk.fromJson(rsaJwkJson),
/// });
/// ```
/// {@endtemplate}
final class StaticJwkSetSource implements JwkSetSource {
  final Map<String, Jwk> _keys;

  /// {@macro static_jwk_set_source}
  StaticJwkSetSource(Map<String, Jwk> keys)
      : _keys = Map.unmodifiable(keys);

  /// {@macro jwk_set_source.resolve_key}
  ///
  /// Returns the key registered for [keyId], or the first entry when [keyId]
  /// is `null`. Returns `null` when the map is empty or the identifier is
  /// unknown; the caller must reject the token in that case.
  @override
  Future<Jwk?> resolveKey(String? keyId) async {
    if (keyId != null) return _keys[keyId];
    return _keys.values.isEmpty ? null : _keys.values.first;
  }
}