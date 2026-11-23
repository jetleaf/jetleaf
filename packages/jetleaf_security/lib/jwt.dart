/// 🔐 **Jetleaf JWT Subsystem**
///
/// A self-contained JWT/JWS toolkit: compact-token encoding and verification,
/// a closed set of JWA algorithm identifiers, JWK parsing and JWKS key lookup,
/// claim validation with configurable clock skew, and a high-level token
/// provider for access and refresh credentials.
///
/// The engine uses specification terminology throughout — JWS (RFC 7515), JWA
/// (RFC 7518), JWT (RFC 7519), and JWK (RFC 7517) — and keeps every trust
/// decision explicit: algorithms come from an allowlist, keys are filtered by
/// use and type, and claims are validated after the signature is verified.
///
/// ---
///
/// ## 📦 Exports Categorization
///
/// ### 🧩 Claims & Authentication Tokens
/// - [JwtClaimsSet] — immutable standard and custom JWT payload claims.
/// - [JwtAuthenticationToken] — bearer request or authenticated JWT principal.
///
/// ### 🔑 Keys, Algorithms & JWKS
/// - [JwtKey], [JwtSecretKey], [JwtRsaKey], [JwtEcKey] — signing and verification keys.
/// - [JwsAlgorithms] — closed HMAC, RSA, and EC algorithm identifiers and families.
/// - [Jwk] — parsed JSON Web Key with strict algorithm and key-type filtering.
/// - [JwkSetSource], [RemoteJwkSetSource], [StaticJwkSetSource] — key lookup by `kid`.
///
/// ### ✍️ Encoding & Verification
/// - [JwtEncoder], [DartJwtEncoder] — sign claims into compact JWS strings.
/// - [JwtDecoder], [DartJwtDecoder] — verify signatures and decode claims.
/// - [JwtValidator], [JwtValidationException] — claim policy and its failure signal.
///
/// ### 🧰 Primitives & Utilities
/// - [JwtCrypto] — HMAC, RSA PKCS#1 v1.5, and ECDSA signing primitives.
/// - [JwtBase64Url] — unpadded base64url encoding for segments and JWK integers.
///
/// ### 🚀 High-Level Service
/// - [JwtTokenProvider] — issues and verifies access and refresh tokens.
///
/// ---
///
/// ## 🎯 Usage Example
///
/// ```dart
/// import 'package:jetleaf_security/jwt.dart';
///
/// void main() async {
///   final provider = JwtTokenProvider.hmac(
///     secret: 'a-long-random-secret',
///     issuer: 'https://issuer.example.com',
///     audience: 'orders-api',
///     clockSkew: const Duration(seconds: 30),
///   );
///
///   final token = provider.generateAccessToken(
///     subject: 'alice',
///     roles: ['USER'],
///   );
///
///   final claims = await provider.verifyToken(token);
///   print(claims.subject); // alice
/// }
/// ```
library;

export 'src/jwt/jwk.dart';
export 'src/jwt/jwk_set_source.dart';
export 'src/jwt/jws_algorithms.dart';
export 'src/jwt/jwt_authentication_token.dart';
export 'src/jwt/jwt_base64_url.dart';
export 'src/jwt/jwt_claims_set.dart';
export 'src/jwt/jwt_crypto.dart';
export 'src/jwt/jwt_decoder.dart';
export 'src/jwt/jwt_encoder.dart';
export 'src/jwt/jwt_key.dart';
export 'src/jwt/jwt_token_provider.dart';
export 'src/jwt/jwt_validator.dart';
export 'src/jwt/typedefs.dart';
