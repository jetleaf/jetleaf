import 'dart:convert';

import 'package:jetleaf_core/lang.dart' show EqualsAndHashCode;

import 'jws_algorithms.dart';

/// {@template jwt_key}
/// Sealed base type for keys used by the in-house JWS signing and verification
/// engine.
///
/// The three subtypes map one-to-one to the algorithm families in
/// [JwsAlgorithms]: [JwtSecretKey] for HMAC, [JwtRsaKey] for RSA PKCS#1 v1.5,
/// and [JwtEcKey] for ECDSA. Because the hierarchy is sealed, a switch over
/// these types is exhaustive and the verifier can reject any key whose family
/// does not match the token's `alg` before performing cryptography.
///
/// ### Example
/// ```dart
/// const JwtKey hmacKey = JwtSecretKey([1, 2, 3]);
/// const JwtKey rsaKey = JwtRsaKey(n: modulus, e: exponent);
/// ```
///
/// ### See also
/// - [JwsAlgorithms] — the closed algorithm allowlist and family sets.
/// - `JwtEncoder` and `JwtDecoder` — the consumers of these keys.
/// {@endtemplate}
sealed class JwtKey {
  /// {@macro jwt_key}
  const JwtKey();
}

/// {@template jwt_secret_key}
/// A symmetric HMAC secret used with the `HS256`, `HS384`, and `HS512`
/// algorithms.
///
/// The same bytes are required for signing and verification. Treat the secret
/// as highly sensitive: it must not be logged, and [JwtSecretKey] instances
/// should not be serialized into tokens.
///
/// ### Example
/// ```dart
/// const key = JwtSecretKey([1, 2, 3, 4]);
/// final fromText = JwtSecretKey.fromString('a-long-random-secret');
/// ```
/// {@endtemplate}
final class JwtSecretKey extends JwtKey with EqualsAndHashCode {
  /// The secret bytes.
  final List<int> bytes;

  /// {@macro jwt_secret_key}
  const JwtSecretKey(this.bytes);

  /// {@template jwt_secret_key.from_string}
  /// Creates a secret key from the UTF-8 encoding of [secret].
  ///
  /// ### Parameters
  /// - [secret] — the shared secret text. Use a cryptographically random value
  ///   of adequate length; short human-chosen strings are not sufficient.
  ///
  /// ### Returns
  /// A [JwtSecretKey] holding the UTF-8 bytes of [secret].
  /// {@endtemplate}
  factory JwtSecretKey.fromString(String secret) => JwtSecretKey(utf8.encode(secret));

  /// Contributes the runtime type and [bytes] to equality and hashing.
  ///
  /// ### Returns
  /// The ordered list of properties used by [EqualsAndHashCode].
  @override
  List<Object?> equalizedProperties() => [runtimeType, bytes];
}

/// {@template jwt_rsa_key}
/// RSA key parameters for the `RS256`, `RS384`, and `RS512` algorithms.
///
/// Verification needs the public pair (`n`, `e`); signing additionally needs
/// the private exponent and both primes (`d`, `p`, `q`). A key missing any
/// required component is rejected rather than used with partial parameters.
///
/// ### Example
/// ```dart
/// const publicKey = JwtRsaKey(n: modulus, e: exponent);
/// print(publicKey.canVerify); // true
/// print(publicKey.canSign);   // false
/// ```
/// {@endtemplate}
final class JwtRsaKey extends JwtKey with EqualsAndHashCode {
  /// The modulus.
  final BigInt? n;

  /// The public exponent.
  final BigInt? e;

  /// The private exponent.
  final BigInt? d;

  /// The first prime factor.
  final BigInt? p;

  /// The second prime factor.
  final BigInt? q;

  /// {@macro jwt_rsa_key}
  const JwtRsaKey({this.n, this.e, this.d, this.p, this.q});

  /// Whether all private components needed to sign are present.
  bool get canSign => n != null && d != null && p != null && q != null;

  /// Whether the public components needed to verify are present.
  bool get canVerify => n != null && e != null;

  /// Contributes the runtime type and all key components to equality and
  /// hashing.
  ///
  /// ### Returns
  /// The ordered list of properties used by [EqualsAndHashCode].
  @override
  List<Object?> equalizedProperties() => [runtimeType, n, e, d, p, q];
}

/// {@template jwt_ec_key}
/// Elliptic-curve key parameters for the `ES256`, `ES384`, and `ES512`
/// algorithms.
///
/// Verification needs the public point (`x`, `y`) on the curve named by [crv];
/// signing needs the private scalar [d]. The curve identifier is part of key
/// filtering: a key whose curve does not match the algorithm is rejected, so
/// a token cannot be verified against a key from a different curve.
///
/// ### Example
/// ```dart
/// const key = JwtEcKey(crv: 'P-256', x: x, y: y);
/// print(key.canVerify(JwsAlgorithms.es256)); // true when x and y are set
/// ```
/// {@endtemplate}
final class JwtEcKey extends JwtKey with EqualsAndHashCode {
  /// The JWK curve name: `P-256`, `P-384`, or `P-521`.
  final String crv;

  /// The public x coordinate.
  final BigInt? x;

  /// The public y coordinate.
  final BigInt? y;

  /// The private scalar used for signing.
  final BigInt? d;

  /// {@macro jwt_ec_key}
  const JwtEcKey({required this.crv, this.x, this.y, this.d});

  /// {@template jwt_ec_key.can_verify}
  /// Whether this key can verify a signature made with [algorithm].
  ///
  /// Both the curve identifier and the public coordinates must be present.
  /// A missing coordinate fails closed by returning `false`.
  ///
  /// ### Parameters
  /// - [algorithm] — a JWA EC identifier such as [JwsAlgorithms.es256].
  ///
  /// ### Returns
  /// `true` only when [crv] matches the algorithm's required curve and both
  /// [x] and [y] are available.
  /// {@endtemplate}
  bool canVerify(String algorithm) => crv == JwsAlgorithms.ecCurve(algorithm) && x != null && y != null;

  /// Contributes the runtime type and all curve parameters to equality and
  /// hashing.
  ///
  /// ### Returns
  /// The ordered list of properties used by [EqualsAndHashCode].
  @override
  List<Object?> equalizedProperties() => [runtimeType, crv, x, y, d];
}