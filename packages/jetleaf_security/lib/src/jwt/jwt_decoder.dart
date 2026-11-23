import 'dart:convert';

import '../core/exceptions.dart';
import 'jwk.dart';
import 'jwk_set_source.dart';
import 'jws_algorithms.dart';
import 'jwt_base64_url.dart';
import 'jwt_claims_set.dart';
import 'jwt_crypto.dart';
import 'jwt_key.dart';
import 'jwt_validator.dart';

/// {@template jwt_decoder}
/// Decodes and verifies compact JWS token strings into a [JwtClaimsSet].
///
/// ### Contract
/// - [decode] returns claims only after the signature has been verified and
///   the configured validator has accepted the claims. There is no mode that
///   returns unverified claims; a token that fails any check is rejected.
/// - The token's `alg` header is untrusted and may only narrow an application
///   controlled allowlist. It never selects the verification key family by
///   itself, and it never widens the accepted algorithms.
/// - Implementations must fail closed: malformed input, an unknown `kid`, a
///   key whose `use`/`alg`/`kty` does not permit verification, a bad signature,
///   or a failed claim check all surface as an [AuthenticationException].
///
/// ### Implementer guidance
/// - Keep the algorithm allowlist explicit and as narrow as the issuer set
///   permits; prefer a family set from [JwsAlgorithms] over the full set.
/// - Resolve keys from a trusted source and apply [Jwk.canVerify] before using
///   them, including curve checks for EC keys.
/// - Run a [JwtValidator] after signature verification so clock skew, issuer,
///   audience, and expiry policy are applied consistently.
///
/// ### See also
/// - [DartJwtDecoder] — the built-in implementation.
/// - [JwtEncoder] — produces the compact strings consumed here.
///
/// ### Example
/// ```dart
/// JwtClaimsSet claims = await decoder.decode(compactJwt);
/// ```
/// {@endtemplate}
abstract interface class JwtDecoder {
  /// {@template jwt_decoder.decode}
  /// Decodes, verifies, and validates [token], returning its claims.
  ///
  /// ### Parameters
  /// - [token] — a compact JWS string with three non-empty dot-separated
  ///   segments.
  ///
  /// ### Returns
  /// The verified [JwtClaimsSet]. This method never returns claims for a token
  /// whose signature or policy checks failed.
  ///
  /// ### Throws
  /// [AuthenticationException] (typically [BadCredentialsException] or
  /// [JwtValidationException]) on any verification failure.
  /// {@endtemplate}
  Future<JwtClaimsSet> decode(String token);
}

/// {@template dart_jwt_decoder}
/// Built-in [JwtDecoder] using either one static verification key or a
/// [JwkSetSource] looked up by the token's `kid`.
///
/// Verification is fail-closed at every stage: the compact structure must be
/// well formed, `alg` must appear in [allowedAlgorithms], the resolved key must
/// pass family and parameter checks for that algorithm, the signature must
/// verify, and [validator] must accept the decoded claims.
///
/// - **Static key mode:** [DartJwtDecoder.withKey] avoids key lookup and is
///   suited to a single issuer with a pinned key.
/// - **JWKS mode:** [DartJwtDecoder.withJwkSet] resolves keys by `kid` and
///   rejects the token when no usable key is found.
/// - **Clock skew:** applied by [validator] after verification, never during
///   signature checking.
///
/// ### Example
/// ```dart
/// final decoder = DartJwtDecoder.withJwkSet(
///   RemoteJwkSetSource(Uri.parse('https://issuer.example.com/jwks')),
///   allowedAlgorithms: JwsAlgorithms.rsa,
///   validator: JwtValidator(expectedIssuer: 'https://issuer.example.com'),
/// );
/// ```
/// {@endtemplate}
final class DartJwtDecoder implements JwtDecoder {
  final JwtKey? _staticKey;
  final JwkSetSource? _jwkSetSource;

  /// Validator applied after cryptographic signature verification.
  final JwtValidator validator;

  /// Algorithms this decoder accepts. The untrusted header never widens it.
  final Set<String> allowedAlgorithms;

  /// {@macro dart_jwt_decoder}
  ///
  /// Configures a single pinned verification key.
  ///
  /// ### Parameters
  /// - [key] — the key used for every token; its family must match `alg`.
  /// - [validator] — claim policy; defaults to a permissive-issuer
  ///   [JwtValidator] with standard clock skew.
  /// - [allowedAlgorithms] — explicit algorithm allowlist; defaults to
  ///   [JwsAlgorithms.all].
  DartJwtDecoder.withKey(
    JwtKey key, {
    JwtValidator? validator,
    Set<String>? allowedAlgorithms,
  })  : _staticKey = key,
        _jwkSetSource = null,
        validator = validator ?? JwtValidator(),
        allowedAlgorithms = allowedAlgorithms ?? JwsAlgorithms.all;

  /// {@macro dart_jwt_decoder}
  ///
  /// Configures dynamic key lookup from a JWKS source.
  ///
  /// ### Parameters
  /// - [jwkSetSource] — supplies the verification key by `kid`.
  /// - [validator] — claim policy applied after signature verification.
  /// - [allowedAlgorithms] — explicit algorithm allowlist; defaults to
  ///   [JwsAlgorithms.all].
  DartJwtDecoder.withJwkSet(
    JwkSetSource jwkSetSource, {
    JwtValidator? validator,
    Set<String>? allowedAlgorithms,
  })  : _jwkSetSource = jwkSetSource,
        _staticKey = null,
        validator = validator ?? JwtValidator(),
        allowedAlgorithms = allowedAlgorithms ?? JwsAlgorithms.all;

  /// {@macro jwt_decoder.decode}
  ///
  /// The decoding pipeline is: parse segments, check `alg` against
  /// [allowedAlgorithms], resolve and filter the key, verify the signature,
  /// decode the payload, then run [validator]. Any failure is reported as
  /// [BadCredentialsException] (or rethrown as [JwtValidationException]).
  @override
  Future<JwtClaimsSet> decode(String token) async {
    try {
      final parts = token.split('.');
      if (parts.length != 3 || parts.any((p) => p.isEmpty)) {
        throw BadCredentialsException('Malformed JWT token');
      }

      final header = _decodeJson(parts[0]);
      final algorithm = header['alg'];
      if (algorithm is! String || !allowedAlgorithms.contains(algorithm)) {
        throw BadCredentialsException('JWT algorithm is not allowed by this decoder');
      }

      final signingInput = utf8.encode('${parts[0]}.${parts[1]}');
      final signature = JwtBase64Url.decode(parts[2]);
      final key = await _resolveKey(algorithm, header['kid'] as String?);

      final verified = _verify(algorithm, key, signingInput, signature);
      if (!verified) {
        throw BadCredentialsException('Invalid JWT signature');
      }

      final claims = JwtClaimsSet(_decodeJson(parts[1]));
      validator.validate(claims);
      return claims;
    } on AuthenticationException {
      rethrow;
    } catch (e) {
      throw BadCredentialsException('Failed to decode JWT token', e);
    }
  }

  /// Decodes a base64url JSON segment, rejecting non-object payloads.
  ///
  /// Throws [BadCredentialsException] when the segment is not valid base64url
  /// UTF-8 JSON.
  Map<String, Object?> _decodeJson(String segment) {
    try {
      final decoded = jsonDecode(utf8.decode(JwtBase64Url.decode(segment)));
      return decoded is Map<String, Object?>
          ? decoded
          : Map<String, Object?>.from(decoded as Map);
    } catch (e) {
      throw BadCredentialsException('Invalid JWT segment', e);
    }
  }

  /// Resolves the verification key for [algorithm] and optional [kid].
  ///
  /// A static key bypasses lookup but is still used only if its family matches
  /// the algorithm (checked in [_verify]). For JWKS keys, [Jwk.canVerify] and
  /// the decoder allowlist are applied before conversion to a [JwtKey]; a
  /// missing or unusable key fails closed with [BadCredentialsException].
  Future<JwtKey> _resolveKey(String algorithm, String? kid) async {
    final staticKey = _staticKey;
    if (staticKey != null) return staticKey;
    final jwk = await _jwkSetSource!.resolveKey(kid);
    if (jwk == null || !jwk.canVerify(algorithm) || !allowedAlgorithms.contains(algorithm)) {
      throw BadCredentialsException('No suitable JWK found for kid "$kid"');
    }
    return switch (jwk) {
      Jwk(:final kty) when kty == 'oct' => JwtSecretKey(jwk.kBytes ?? const []),
      Jwk(:final kty) when kty == 'RSA' => JwtRsaKey(n: jwk.n, e: jwk.e),
      Jwk(:final kty) when kty == 'EC' => JwtEcKey(crv: jwk.crv ?? '', x: jwk.x, y: jwk.y),
      _ => throw BadCredentialsException('Unsupported JWK'),
    };
  }

  /// Verifies [signature] over [signingInput] with [key].
  ///
  /// Each branch also checks that the key family matches [algorithm]: an HMAC
  /// secret is never used for RSA or EC, an RSA key is never used for EC, and
  /// an EC key must be on the curve required by the algorithm. An unmatched
  /// family returns `false` without invoking cryptography.
  bool _verify(String algorithm, JwtKey key, List<int> signingInput, List<int> signature) {
    if (key case JwtSecretKey(:final bytes)) {
      return JwsAlgorithms.hmac.contains(algorithm) && JwtCrypto.verifyHmac(algorithm, bytes, signingInput, signature);
    }

    if (key case JwtRsaKey(:final n, :final e)) {
      return n != null &&
        e != null &&
        JwsAlgorithms.rsa.contains(algorithm) &&
        JwtCrypto.verifyRsa(
          algorithm,
          n: n, e: e,
          data: signingInput,
          signature: signature,
        );
    }
    if (key case JwtEcKey(:final crv, :final x, :final y)) {
      return crv == JwsAlgorithms.ecCurve(algorithm) &&
          x != null &&
          y != null &&
          JwtCrypto.verifyEc(
            algorithm,
            x: x, y: y,
            data: signingInput,
            signature: signature,
          );
    }
    return false;
  }
}
