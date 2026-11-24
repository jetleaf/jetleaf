import 'package:jetleaf_core/lang.dart' show IllegalArgumentException;
/// {@template jws_algorithms}
/// The closed set of JWS algorithms this engine can sign and verify.
///
/// Algorithms are named with their JWA (RFC 7518) identifiers. The accepted
/// set is always configured explicitly by the caller — it is never derived
/// from an untrusted token header. A decoder checks the header's `alg` against
/// its own allowlist before any key is resolved, and a key must additionally
/// pass family and parameter filtering for that algorithm.
///
/// | Family | Constants | Signature mechanism | Digest / curve |
/// |--------|-----------|---------------------|----------------|
/// | HMAC | [hs256], [hs384], [hs512] | symmetric shared secret | SHA-256 / SHA-384 / SHA-512 |
/// | RSA | [rs256], [rs384], [rs512] | RSASSA-PKCS1-v1_5 | SHA-256 / SHA-384 / SHA-512 |
/// | EC | [es256], [es384], [es512] | ECDSA with raw R‖S encoding | P-256 / P-384 / P-521 |
///
/// ### Example
/// ```dart
/// // Only accept asymmetric signatures from known issuers.
/// const allowed = JwsAlgorithms.rsa;
/// JwsAlgorithms.checkAllowed('RS256', allowed); // ok
/// // JwsAlgorithms.checkAllowed('HS256', allowed); // throws ArgumentError
/// ```
/// {@endtemplate}
abstract final class JwsAlgorithms {
  /// HMAC with SHA-256 (`HS256`). Symmetric; requires an `oct` key.
  static const String hs256 = 'HS256';

  /// HMAC with SHA-384 (`HS384`). Symmetric; requires an `oct` key.
  static const String hs384 = 'HS384';

  /// HMAC with SHA-512 (`HS512`). Symmetric; requires an `oct` key.
  static const String hs512 = 'HS512';

  /// RSASSA-PKCS1-v1_5 with SHA-256 (`RS256`). Requires an `RSA` key.
  static const String rs256 = 'RS256';

  /// RSASSA-PKCS1-v1_5 with SHA-384 (`RS384`). Requires an `RSA` key.
  static const String rs384 = 'RS384';

  /// RSASSA-PKCS1-v1_5 with SHA-512 (`RS512`). Requires an `RSA` key.
  static const String rs512 = 'RS512';

  /// ECDSA with SHA-256 on the P-256 curve (`ES256`). Requires an `EC` key.
  static const String es256 = 'ES256';

  /// ECDSA with SHA-384 on the P-384 curve (`ES384`). Requires an `EC` key.
  static const String es384 = 'ES384';

  /// ECDSA with SHA-512 on the P-521 curve (`ES512`). Requires an `EC` key.
  static const String es512 = 'ES512';

  /// Every algorithm supported by the engine.
  ///
  /// Prefer a narrower family set when the issuer is known.
  static const Set<String> all = {
    hs256, hs384, hs512,
    rs256, rs384, rs512,
    es256, es384, es512,
  };

  /// The symmetric HMAC family: [hs256], [hs384], and [hs512].
  static const Set<String> hmac = {hs256, hs384, hs512};

  /// The RSA PKCS#1 v1.5 family: [rs256], [rs384], and [rs512].
  static const Set<String> rsa = {rs256, rs384, rs512};

  /// The elliptic-curve family: [es256], [es384], and [es512].
  static const Set<String> ec = {es256, es384, es512};

  /// {@macro jws_algorithms}
  const JwsAlgorithms._();

  /// {@template jws_algorithms.check_allowed}
  /// Enforces that [algorithm] appears in the caller-supplied [allowed] set.
  ///
  /// This is the first gate in signature verification. Never pass a set built
  /// from the token header: the untrusted `alg` value may only be checked
  /// against an allowlist the application controls.
  ///
  /// ### Parameters
  /// - [algorithm] — the JWA identifier taken from the token header.
  /// - [allowed] — the explicit allowlist of identifiers this verifier accepts.
  ///
  /// ### Throws
  /// [ArgumentError] when [algorithm] is not in [allowed].
  ///
  /// ### Example
  /// ```dart
  /// JwsAlgorithms.checkAllowed(algorithmFromHeader, JwsAlgorithms.rsa);
  /// ```
  /// {@endtemplate}
  static void checkAllowed(String algorithm, Set<String> allowed) {
    if (!allowed.contains(algorithm)) {
      throw IllegalArgumentException('algorithm: Algorithm is not in the decoder allowlist (got $algorithm)');
    }
  }

  /// {@template jws_algorithms.rsa_digest_identifier}
  /// Returns the PKCS#1 v1.5 digest-info prefix required by [algorithm].
  ///
  /// The returned hexadecimal string is the DER `DigestInfo` identifier that
  /// prefixes the hash inside an RSASSA-PKCS1-v1_5 signature. It is part of the
  /// verification input, so a mismatch rejects the signature.
  ///
  /// ### Parameters
  /// - [algorithm] — one of [rs256], [rs384], or [rs512].
  ///
  /// ### Returns
  /// The lowercase hex digest identifier for SHA-256, SHA-384, or SHA-512.
  ///
  /// ### Throws
  /// [ArgumentError] when [algorithm] is not an RSA algorithm.
  /// {@endtemplate}
  static String rsaDigestIdentifier(String algorithm) => switch (algorithm) {
    rs256 => '0609608648016503040201',
    rs384 => '0609608648016503040202',
    rs512 => '0609608648016503040203',
    _ => throw IllegalArgumentException('algorithm: Not an RSA algorithm (got $algorithm)'),
  };

  /// {@template jws_algorithms.ec_curve}
  /// Returns the JWK curve name required by [algorithm].
  ///
  /// Key filtering uses this value to reject an EC key whose `crv` does not
  /// match the signature algorithm, preventing cross-curve key confusion.
  ///
  /// ### Parameters
  /// - [algorithm] — one of [es256], [es384], or [es512].
  ///
  /// ### Returns
  /// `P-256`, `P-384`, or `P-521` respectively.
  ///
  /// ### Throws
  /// [ArgumentError] when [algorithm] is not an EC algorithm.
  ///
  /// ### Example
  /// ```dart
  /// JwsAlgorithms.ecCurve(JwsAlgorithms.es256); // P-256
  /// ```
  /// {@endtemplate}
  static String ecCurve(String algorithm) => switch (algorithm) {
    es256 => 'P-256',
    es384 => 'P-384',
    es512 => 'P-521',
    _ => throw IllegalArgumentException('algorithm: Not an EC algorithm (got $algorithm)'),
  };
}
