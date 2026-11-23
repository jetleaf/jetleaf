import 'package:jetleaf_core/utils.dart' show ParserException;
import 'package:jetleaf_core/lang.dart' show IllegalArgumentException;
import 'dart:typed_data';

import 'package:pointycastle/api.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:pointycastle/digests/sha256.dart';
import 'package:pointycastle/digests/sha384.dart';
import 'package:pointycastle/digests/sha512.dart';
import 'package:pointycastle/ecc/api.dart';
import 'package:pointycastle/ecc/curves/secp256r1.dart';
import 'package:pointycastle/ecc/curves/secp384r1.dart';
import 'package:pointycastle/ecc/curves/secp521r1.dart';
import 'package:pointycastle/macs/hmac.dart';
import 'package:pointycastle/signers/ecdsa_signer.dart';
import 'package:pointycastle/signers/rsa_signer.dart';

import '../crypto/password_encoder.dart';
import 'jws_algorithms.dart';

/// {@template _rsa_public_param}
/// Internal adapter exposing an RSA public key to the signing primitive.
///
/// The wrapper adds no parameters of its own; it exists so public and private
/// key material cannot be interchanged accidentally at call sites.
/// {@endtemplate}
final class _RsaPublicParam extends AsymmetricKeyParameter<RSAAsymmetricKey> {
  /// {@macro _rsa_public_param}
  _RsaPublicParam(super.key);
}

/// {@template _rsa_private_param}
/// Internal adapter exposing RSA private key material to the signing primitive.
///
/// Keeping this distinct from [_RsaPublicParam] makes the sign/verify intent
/// explicit and prevents a private key from being passed where a public key is
/// expected.
/// {@endtemplate}
final class _RsaPrivateParam extends AsymmetricKeyParameter<RSAAsymmetricKey> {
  /// {@macro _rsa_private_param}
  _RsaPrivateParam(super.key);
}

/// {@template jwt_crypto}
/// In-house JWS signing and verification engine.
///
/// Supports the three algorithm families in [JwsAlgorithms]: HMAC with a
/// shared secret, RSA PKCS#1 v1.5 with a digest-info prefix, and ECDSA with
/// signatures encoded as the raw concatenation R‖S required by JWS.
///
/// - **Algorithm selection:** every entry point takes an explicit JWA
///   identifier. An unsupported identifier throws [ArgumentError] rather than
///   defaulting to a weaker algorithm.
/// - **Parameter validation:** callers must have already matched the key family
///   to the algorithm; the primitives themselves reject malformed lengths and
///   unusable parameters.
/// - **Fail-closed verification:** verification methods return `false` on a
///   bad signature. HMAC comparison uses [constantTimeEquals] so signature
///   bytes cannot be recovered through timing differences.
///
/// ### See also
/// - [JwsAlgorithms] — the closed algorithm allowlist and family helpers.
///
/// ### Example
/// ```dart
/// final signature = JwtCrypto.signHmac(
///   JwsAlgorithms.hs256,
///   secretBytes,
///   signingInput,
/// );
/// final ok = JwtCrypto.verifyHmac(
///   JwsAlgorithms.hs256,
///   secretBytes,
///   signingInput,
///   signature,
/// );
/// ```
/// {@endtemplate}
abstract final class JwtCrypto {
  /// {@macro jwt_crypto}
  const JwtCrypto._();

  /// Selects the digest for [algorithm] (SHA-256, SHA-384, or SHA-512).
  ///
  /// Throws [ArgumentError] when the identifier is not supported.
  static Digest _digest(String algorithm) => switch (algorithm) {
    JwsAlgorithms.hs256 || JwsAlgorithms.rs256 || JwsAlgorithms.es256 => SHA256Digest(),
    JwsAlgorithms.hs384 || JwsAlgorithms.rs384 || JwsAlgorithms.es384 => SHA384Digest(),
    JwsAlgorithms.hs512 || JwsAlgorithms.rs512 || JwsAlgorithms.es512 => SHA512Digest(),
    _ => throw IllegalArgumentException('algorithm: Unsupported (got )'),
  };

  /// Returns the HMAC block size in bytes for [algorithm].
  ///
  /// Throws [ArgumentError] when [algorithm] is not an HMAC identifier.
  static int _hmacBlockSize(String algorithm) => switch (algorithm) {
    JwsAlgorithms.hs256 => 64,
    JwsAlgorithms.hs384 || JwsAlgorithms.hs512 => 128,
    _ => throw IllegalArgumentException('algorithm: Not an HMAC algorithm (got )'),
  };

  /// {@template jwt_crypto.sign_hmac}
  /// Computes an HMAC signature over [data] with [secret].
  ///
  /// ### Parameters
  /// - [algorithm] — one of [JwsAlgorithms.hs256], [JwsAlgorithms.hs384],
  ///   or [JwsAlgorithms.hs512].
  /// - [secret] — the shared secret bytes; must be kept confidential.
  /// - [data] — the exact signing input (`base64url(header).base64url(payload)`).
  ///
  /// ### Returns
  /// The raw HMAC bytes, ready for base64url encoding into the compact JWS.
  ///
  /// ### Throws
  /// [ArgumentError] when [algorithm] is not an HMAC identifier.
  /// {@endtemplate}
  static Uint8List signHmac(String algorithm, List<int> secret, List<int> data) {
    final hmac = HMac(_digest(algorithm), _hmacBlockSize(algorithm))
      ..init(KeyParameter(Uint8List.fromList(secret)));
    return Uint8List.fromList(hmac.process(Uint8List.fromList(data)));
  }

  /// {@template jwt_crypto.verify_hmac}
  /// Verifies an HMAC signature in constant time.
  ///
  /// The comparison uses [constantTimeEquals] so a mismatch does not reveal
  /// how many signature bytes matched. A malformed or wrong signature returns
  /// `false`; it never throws.
  ///
  /// ### Parameters
  /// - [algorithm] — the HMAC identifier used when the token was signed.
  /// - [secret] — the same shared secret used for signing.
  /// - [data] — the exact signing input from the token.
  /// - [signature] — the decoded signature segment.
  ///
  /// ### Returns
  /// `true` only when the recomputed HMAC equals [signature] byte for byte.
  /// {@endtemplate}
  static bool verifyHmac(String algorithm, List<int> secret, List<int> data, List<int> signature) =>
    constantTimeEquals(signHmac(algorithm, secret, data), signature);

  /// {@template jwt_crypto.sign_rsa}
  /// Signs [data] with an RSA private key using PKCS#1 v1.5.
  ///
  /// All four private components are required. Supplying only the public pair
  /// is not sufficient and results in an error rather than a partial signature.
  ///
  /// ### Parameters
  /// - [algorithm] — one of [JwsAlgorithms.rs256], [JwsAlgorithms.rs384],
  ///   or [JwsAlgorithms.rs512].
  /// - [n] — the RSA modulus.
  /// - [d] — the private exponent.
  /// - [p] — the first prime factor.
  /// - [q] — the second prime factor.
  /// - [data] — the exact signing input.
  ///
  /// ### Returns
  /// The raw RSA signature bytes.
  ///
  /// ### Throws
  /// [ArgumentError] when [algorithm] is not an RSA identifier.
  /// {@endtemplate}
  static Uint8List signRsa(
    String algorithm, {
    required BigInt n,
    required BigInt d,
    required BigInt p,
    required BigInt q,
    required List<int> data,
  }) {
    final signer = RSASigner(_digest(algorithm), JwsAlgorithms.rsaDigestIdentifier(algorithm))
      ..init(
        true,
        _RsaPrivateParam(RSAPrivateKey(n, d, p, q)),
      );
    return signer.generateSignature(Uint8List.fromList(data)).bytes;
  }

  /// {@template jwt_crypto.verify_rsa}
  /// Verifies an RSA PKCS#1 v1.5 signature with a public key.
  ///
  /// Only the public pair (`n`, `e`) is consulted; private components are never
  /// needed. A bad signature fails closed by returning `false`.
  ///
  /// ### Parameters
  /// - [algorithm] — the RSA identifier used when the token was signed.
  /// - [n] — the RSA modulus.
  /// - [e] — the public exponent.
  /// - [data] — the exact signing input from the token.
  /// - [signature] — the decoded signature segment.
  ///
  /// ### Returns
  /// `true` only when the signature is valid for [data] under this key.
  ///
  /// ### Throws
  /// [ArgumentError] when [algorithm] is not an RSA identifier.
  /// {@endtemplate}
  static bool verifyRsa(
    String algorithm, {
    required BigInt n,
    required BigInt e,
    required List<int> data,
    required List<int> signature,
  }) {
    final signer = RSASigner(_digest(algorithm), JwsAlgorithms.rsaDigestIdentifier(algorithm))
      ..init(false, _RsaPublicParam(RSAPublicKey(n, e)));
    return signer.verifySignature(
      Uint8List.fromList(data),
      RSASignature(Uint8List.fromList(signature)),
    );
  }

  /// Selects the EC domain parameters for [algorithm].
  ///
  /// Throws [ArgumentError] when [algorithm] is not an EC identifier.
  static ECDomainParameters _domain(String algorithm) => switch (algorithm) {
    JwsAlgorithms.es256 => ECCurve_secp256r1(),
    JwsAlgorithms.es384 => ECCurve_secp384r1(),
    JwsAlgorithms.es512 => ECCurve_secp521r1(),
    _ => throw IllegalArgumentException('algorithm: Not an EC algorithm (got )'),
  };

  /// Returns the fixed byte width of one ECDSA component for [algorithm].
  static int _componentLength(String algorithm) => switch (algorithm) {
    JwsAlgorithms.es256 => 32,
    JwsAlgorithms.es384 => 48,
    JwsAlgorithms.es512 => 66,
    _ => throw IllegalArgumentException('algorithm: Not an EC algorithm (got )'),
  };

  /// Left-pads [value] to exactly [length] big-endian bytes.
  static Uint8List _toFixedWidth(BigInt value, int length) {
    final bytes = Uint8List(length);
    var v = value;
    for (var i = length - 1; i >= 0; i--) {
      bytes[i] = (v & BigInt.from(0xff)).toInt();
      v >>= 8;
    }
    return bytes;
  }

  /// Encodes an ECSignature as the raw R‖S layout required by JWS.
  static Uint8List _encodeRaw(ECSignature signature, String algorithm) {
    final length = _componentLength(algorithm);
    return Uint8List.fromList([
      ..._toFixedWidth(signature.r, length),
      ..._toFixedWidth(signature.s, length),
    ]);
  }

  /// Decodes a raw R‖S signature, rejecting incorrect lengths.
  ///
  /// Throws [FormatException] when [raw] is not exactly twice the component
  /// width for [algorithm].
  static ECSignature _decodeRaw(List<int> raw, String algorithm) {
    final length = _componentLength(algorithm);
    if (raw.length != length * 2) {
      throw ParserException('Invalid ECDSA signature length');
    }

    BigInt toBigInt(List<int> bytes) => bytes.fold(BigInt.zero, (value, byte) => (value << 8) | BigInt.from(byte));
    return ECSignature(
      toBigInt(raw.sublist(0, length)),
      toBigInt(raw.sublist(length)),
    );
  }

  /// {@template jwt_crypto.sign_ec}
  /// Signs [data] with an ECDSA private scalar [d].
  ///
  /// The resulting signature is encoded as fixed-width R followed by S, the
  /// layout mandated for JWS (as opposed to a DER-encoded signature).
  ///
  /// ### Parameters
  /// - [algorithm] — one of [JwsAlgorithms.es256], [JwsAlgorithms.es384],
  ///   or [JwsAlgorithms.es512].
  /// - [d] — the private scalar for the matching curve.
  /// - [data] — the exact signing input.
  ///
  /// ### Returns
  /// Raw R‖S signature bytes.
  ///
  /// ### Throws
  /// [ArgumentError] when [algorithm] is not an EC identifier.
  /// {@endtemplate}
  static Uint8List signEc(String algorithm, {
    required BigInt d,
    required List<int> data,
  }) {
    final domain = _domain(algorithm);
    final signer = ECDSASigner(_digest(algorithm))
      ..init(true, PrivateKeyParameter(ECPrivateKey(d, domain)));
    return _encodeRaw(
      signer.generateSignature(Uint8List.fromList(data)) as ECSignature,
      algorithm,
    );
  }

  /// {@template jwt_crypto.verify_ec}
  /// Verifies a raw R‖S ECDSA signature with a public point.
  ///
  /// The point is constructed from [x] and [y] on the curve selected by
  /// [algorithm]. Callers must have already checked that the key's curve
  /// matches the algorithm; a mismatched curve fails closed by yielding an
  /// invalid signature rather than throwing.
  ///
  /// ### Parameters
  /// - [algorithm] — the EC identifier used when the token was signed.
  /// - [x] — the public x coordinate.
  /// - [y] — the public y coordinate.
  /// - [data] — the exact signing input from the token.
  /// - [signature] — the decoded raw R‖S signature segment.
  ///
  /// ### Returns
  /// `true` only when the signature is valid for [data] under this point.
  ///
  /// ### Throws
  /// [ArgumentError] when [algorithm] is not an EC identifier;
  /// [FormatException] when [signature] has an invalid length.
  /// {@endtemplate}
  static bool verifyEc(String algorithm, {
    required BigInt x,
    required BigInt y,
    required List<int> data,
    required List<int> signature,
  }) {
    final domain = _domain(algorithm);
    final point = domain.curve.createPoint(x, y);
    final signer = ECDSASigner(_digest(algorithm))
      ..init(false, PublicKeyParameter(ECPublicKey(point, domain)));
    return signer.verifySignature(
      Uint8List.fromList(data),
      _decodeRaw(signature, algorithm),
    );
  }
}
