import 'package:jetleaf_core/lang.dart' show EqualsAndHashCode;

import 'jws_algorithms.dart';
import 'jwt_base64_url.dart';

/// {@template jwk}
/// A parsed JSON Web Key with strict algorithm, use, and key-type filtering.
///
/// A [Jwk] is an untrusted data structure until [canVerify] has been consulted.
/// The verifier only uses a key when its declared `use` permits signature
/// verification, its optional `alg` matches the token algorithm, its `kty` is
/// in the expected family, and every parameter that family requires is present
/// and decodable.
///
/// - **Immutable:** the source map is wrapped with [Map.unmodifiable].
/// - **Integer members:** `n`, `e`, `d`, `p`, `q`, `x`, and `y` are decoded from
///   their unsigned big-endian base64url representation on access.
/// - **Fail-closed:** missing, empty, or wrongly typed members yield `null`,
///   which makes [canVerify] return `false` rather than throwing.
///
/// ### See also
/// - [JwkSetSource] — supplies keys by `kid` from a JWKS document.
/// - [JwsAlgorithms] — the algorithm families used for filtering.
///
/// ### Example
/// ```dart
/// final jwk = Jwk.fromJson({
///   'kty': 'RSA',
///   'kid': 'key-1',
///   'use': 'sig',
///   'alg': 'RS256',
///   'n': modulusBase64Url,
///   'e': 'AQAB',
/// });
/// print(jwk.canVerify(JwsAlgorithms.rs256)); // true
/// ```
/// {@endtemplate}
final class Jwk with EqualsAndHashCode {
  /// The raw JWK members, exposed as an unmodifiable map.
  final Map<String, Object?> values;

  /// {@macro jwk}
  Jwk(Map<String, Object?> values)
      : values = Map.unmodifiable(values);

  /// {@template jwk.from_json}
  /// Parses a JWK from a decoded JSON object.
  ///
  /// ### Parameters
  /// - [json] — the decoded member map from a JWKS `keys` array.
  ///
  /// ### Returns
  /// A [Jwk] view over [json]. No validation happens here; call [canVerify]
  /// before using the key.
  /// {@endtemplate}
  factory Jwk.fromJson(Map<String, Object?> json) => Jwk(json);

  /// Key type (`oct`, `RSA`, or `EC`), or `null` when absent.
  String? get kty => values['kty'] as String?;

  /// Intended use. Only `sig` (or an absent `use`) may verify signatures.
  String? get use => values['use'] as String?;

  /// Algorithm restriction declared by the key, if any.
  String? get alg => values['alg'] as String?;

  /// Key identifier used to match a token's `kid` header.
  String? get kid => values['kid'] as String?;

  /// EC curve name (`P-256`, `P-384`, or `P-521`), if present.
  String? get crv => values['crv'] as String?;

  /// Decodes the unsigned big-endian integer member named [name].
  ///
  /// Returns `null` for a missing, empty, or non-string value so key filtering
  /// fails closed instead of throwing on malformed JWKS input.
  BigInt? _integer(String name) {
    final value = values[name];
    if (value is! String || value.isEmpty) return null;
    return JwtBase64Url.decodeInteger(value);
  }

  /// RSA modulus `n`.
  BigInt? get n => _integer('n');

  /// RSA public exponent `e`.
  BigInt? get e => _integer('e');

  /// RSA private exponent `d`.
  BigInt? get d => _integer('d');

  /// RSA first prime `p`.
  BigInt? get p => _integer('p');

  /// RSA second prime `q`.
  BigInt? get q => _integer('q');

  /// EC public x coordinate.
  BigInt? get x => _integer('x');

  /// EC public y coordinate.
  BigInt? get y => _integer('y');

  /// Raw symmetric secret for an `oct` key.
  List<int>? get kBytes {
    final value = values['k'];
    if (value is! String || value.isEmpty) return null;
    return JwtBase64Url.decode(value);
  }

  /// {@template jwk.can_verify}
  /// Reports whether this key may be used to verify [algorithm].
  ///
  /// This is a security-critical gate and is fail-closed. A key is accepted
  /// only when all of the following hold:
  ///
  /// - `use` is absent or exactly `sig` — an encryption key is never reused
  ///   for signature verification.
  /// - `alg` is absent or exactly [algorithm] — a key cannot be repurposed for
  ///   an algorithm its issuer did not intend.
  /// - the family derived from [algorithm] matches `kty` and all required
  ///   parameters decode successfully: `k` for `oct`, `n` and `e` for `RSA`,
  ///   and `x`, `y` plus a curve matching [JwsAlgorithms.ecCurve] for `EC`.
  /// - [algorithm] is itself one of the supported JWA identifiers.
  ///
  /// ### Parameters
  /// - [algorithm] — the JWA identifier already checked against the decoder's
  ///   algorithm allowlist.
  ///
  /// ### Returns
  /// `true` only for a fully usable verification key; `false` otherwise.
  ///
  /// ### Example
  /// ```dart
  /// if (!jwk.canVerify('RS256')) {
  ///   throw BadCredentialsException('No suitable JWK found');
  /// }
  /// ```
  /// {@endtemplate}
  bool canVerify(String algorithm) {
    if (use != null && use != 'sig') return false;
    if (alg != null && alg != algorithm) return false;

    if (JwsAlgorithms.hmac.contains(algorithm)) {
      return kty == 'oct' && kBytes != null;
    }
    if (JwsAlgorithms.rsa.contains(algorithm)) {
      return kty == 'RSA' && n != null && e != null;
    }
    if (JwsAlgorithms.ec.contains(algorithm)) {
      return kty == 'EC' &&
          crv == JwsAlgorithms.ecCurve(algorithm) &&
          x != null &&
          y != null;
    }
    return false;
  }

  @override
  String toString() => 'Jwk(kty: $kty, kid: $kid, alg: $alg, use: $use)';

  /// Contributes the runtime type and [values] to equality and hashing.
  ///
  /// ### Returns
  /// The ordered list of properties used by [EqualsAndHashCode].
  @override
  List<Object?> equalizedProperties() => [runtimeType, values];
}