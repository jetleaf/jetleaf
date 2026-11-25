import 'package:jetleaf_core/lang.dart' show IllegalArgumentException;
import 'dart:convert';
import 'dart:typed_data';


import 'jws_algorithms.dart';
import 'jwt_base64_url.dart';
import 'jwt_claims_set.dart';
import 'jwt_crypto.dart';
import 'jwt_key.dart';

/// {@template jwt_encoder}
/// Encodes and signs [JwtClaimsSet] instances into compact JWS strings.
///
/// ### Contract
/// - [encode] produces three base64url segments: header, payload, and
///   signature. Every segment is unpadded.
/// - The signing algorithm is chosen by configuration, never by the caller's
///   claims, and must belong to the family of the configured key.
/// - The returned string is a credential. Treat it as sensitive and erase it
///   from request state once verification has completed.
///
/// ### Implementer guidance
/// - Validate the algorithm against [JwsAlgorithms] before signing so an
///   unsupported identifier cannot reach the cryptographic layer.
/// - Inject `iat` and, when requested, `exp` using UTC time in epoch seconds.
/// - Guard against a mismatched key family: a symmetric secret must not be
///   paired with an RSA or EC algorithm.
///
/// ### See also
/// - [DartJwtEncoder] — the built-in implementation.
/// - [JwtDecoder] — verifies the strings produced here.
///
/// ### Example
/// ```dart
/// final token = encoder.encode(claims, expiresIn: const Duration(minutes: 15));
/// ```
/// {@endtemplate}
abstract interface class JwtEncoder {
  /// {@template jwt_encoder.encode}
  /// Signs [claims] and returns a serialized compact JWT string.
  ///
  /// ### Parameters
  /// - [claims] — the payload to sign; its entries are copied before standard
  ///   claims are injected.
  /// - [expiresIn] — when supplied, sets `exp` to this duration from the
  ///   current UTC time; existing `exp` values are overwritten.
  /// - [keyId] — optional `kid` written into the protected header to help the
  ///   verifier locate the key.
  ///
  /// ### Returns
  /// The unpadded `header.payload.signature` string.
  /// {@endtemplate}
  String encode(JwtClaimsSet claims, {
    Duration? expiresIn,
    String? keyId,
  });
}

/// {@template dart_jwt_encoder}
/// Built-in [JwtEncoder] backed by the in-house JWS signing engine.
///
/// The configured [algorithm] is checked against [JwsAlgorithms.all] on every
/// call, and the signing key must belong to the matching family: [JwtSecretKey]
/// for HMAC, [JwtRsaKey] for RSA, and [JwtEcKey] for EC. A mismatch throws
/// instead of producing a token that cannot be verified.
///
/// Standard claims are injected before signing: `iat` is added when absent,
/// `exp` is set from [encode]'s `expiresIn`, and `iss` is added from [issuer]
/// only when the caller has not supplied one.
///
/// ### Example
/// ```dart
/// final encoder = DartJwtEncoder(
///   signingKey: JwtSecretKey.fromString('a-long-random-secret'),
///   algorithm: JwsAlgorithms.hs256,
///   issuer: 'https://issuer.example.com',
/// );
/// ```
/// {@endtemplate}
final class DartJwtEncoder implements JwtEncoder {
  /// The private or shared key used to sign tokens.
  final JwtKey signingKey;

  /// JWA identifier for the signature. Must be in the matching key family.
  final String algorithm;

  /// Default `iss` claim injected when not already present.
  final String? issuer;

  /// {@macro dart_jwt_encoder}
  const DartJwtEncoder({
    required this.signingKey,
    this.algorithm = JwsAlgorithms.hs256,
    this.issuer,
  });

  /// {@macro jwt_encoder.encode}
  ///
  /// Builds the protected header with `typ: JWT`, the configured `alg`, and an
  /// optional `kid`, injects the standard claims, then signs the UTF-8 bytes of
  /// `base64url(header).base64url(payload)`.
  ///
  /// ### Throws
  /// [ArgumentError] when [algorithm] is unsupported or incompatible with
  /// [signingKey].
  @override
  String encode(JwtClaimsSet claims, {
    Duration? expiresIn,
    String? keyId,
  }) {
    if (!JwsAlgorithms.all.contains(algorithm)) {
      throw IllegalArgumentException('algorithm: Unsupported JWS algorithm (got $algorithm)');
    }
    final payload = Map<String, dynamic>.from(claims.toJson());
    if (issuer != null && !payload.containsKey('iss')) {
      payload['iss'] = issuer;
    }
    if (expiresIn != null) {
      payload['exp'] = DateTime.now().toUtc().add(expiresIn).millisecondsSinceEpoch ~/ 1000;
    }
    payload.putIfAbsent(
      'iat',
      () => DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000,
    );

    final header = <String, dynamic>{
      'typ': 'JWT',
      'alg': algorithm,
      'kid': ?keyId,
    };

    final encodedHeader = JwtBase64Url.encode(utf8.encode(jsonEncode(header)));
    final encodedPayload = JwtBase64Url.encode(utf8.encode(jsonEncode(payload)));
    final signingInput = utf8.encode('$encodedHeader.$encodedPayload');

    final signature = _sign(signingInput);
    return '$encodedHeader.$encodedPayload.${JwtBase64Url.encode(signature)}';
  }

  /// Produces the signature for [signingInput] using [signingKey].
  ///
  /// Each branch rejects a key whose family does not match [algorithm] or that
  /// lacks the required private parameters, throwing [ArgumentError] instead
  /// of emitting an unverifiable token.
  Uint8List _sign(List<int> signingInput) {
    if (signingKey case JwtSecretKey(:final bytes)) {
      if (!JwsAlgorithms.hmac.contains(algorithm)) {
        throw IllegalArgumentException('HMAC key cannot be used with $algorithm');
      }
      return JwtCrypto.signHmac(algorithm, bytes, signingInput);
    }
    if (signingKey case JwtRsaKey(:final n, :final d, :final p, :final q)) {
      if (!JwsAlgorithms.rsa.contains(algorithm) ||
          n == null || d == null || p == null || q == null) {
        throw IllegalArgumentException('RSA key is not usable for $algorithm');
      }
      return JwtCrypto.signRsa(
        algorithm,
        n: n, d: d, p: p, q: q,
        data: signingInput,
      );
    }
    if (signingKey case JwtEcKey(:final d)) {
      if (!JwsAlgorithms.ec.contains(algorithm) || d == null) {
        throw IllegalArgumentException('EC key is not usable for $algorithm');
      }
      return JwtCrypto.signEc(algorithm, d: d, data: signingInput);
    }
    throw IllegalArgumentException('Unsupported signing key');
  }
}