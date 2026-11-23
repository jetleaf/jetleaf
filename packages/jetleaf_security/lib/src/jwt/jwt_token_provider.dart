import '../authentication/authentication_provider.dart';
import '../core/authentication.dart';
import '../core/exceptions.dart';
import '../core/granted_authority.dart';
import '../core/simple_granted_authority.dart';
import 'jwt_authentication_token.dart';
import 'jwt_claims_set.dart';
import 'jws_algorithms.dart';
import 'jwt_decoder.dart';
import 'jwt_encoder.dart';
import 'jwt_key.dart';
import 'jwt_validator.dart';

/// {@template jwt_token_provider}
/// High-level JWT service and [AuthenticationProvider] for issuing and
/// verifying access and refresh tokens.
///
/// The provider composes a [JwtEncoder] and a [JwtDecoder], adds the standard
/// `sub`, `type`, and optional `aud` claims, and converts configured role
/// claims into [GrantedAuthority] values. Token verification is delegated to
/// the decoder, which enforces signature, algorithm allowlist, key filtering,
/// and claim validation before any authority is derived.
///
/// - **Token separation:** access and refresh tokens are distinguished by the
///   `type` claim. A refresh token is rejected as an authentication credential.
/// - **Fail-closed verification:** an empty or invalid token produces `null`
///   or an [AuthenticationException]; authorities are never extracted from an
///   unverified token.
/// - **Configurable lifetimes:** defaults are 15 minutes for access tokens and
///   7 days for refresh tokens, overridable per call.
///
/// ### See also
/// - [JwtEncoder] and [JwtDecoder] — the signing and verification primitives.
/// - [JwtAuthenticationToken] — the authentication object produced here.
///
/// ### Example
/// ```dart
/// final provider = JwtTokenProvider.hmac(
///   secret: 'a-long-random-secret',
///   issuer: 'https://issuer.example.com',
///   audience: 'orders-api',
/// );
/// final access = provider.generateAccessToken(
///   subject: 'alice',
///   roles: ['USER'],
/// );
/// final claims = await provider.verifyToken(access);
/// ```
/// {@endtemplate}
class JwtTokenProvider implements AuthenticationProvider {
  /// Encoder used to sign newly generated tokens.
  final JwtEncoder encoder;

  /// Decoder used to verify incoming tokens.
  final JwtDecoder decoder;

  /// Default access-token lifetime.
  final Duration accessTokenExpiration;

  /// Default refresh-token lifetime.
  final Duration refreshTokenExpiration;

  /// Claim name holding granted roles or authorities. Defaults to `'roles'`.
  final String authoritiesClaimName;

  /// Audience injected into every issued token and required on validation.
  final String? audience;

  /// {@macro jwt_token_provider}
  ///
  /// ### Parameters
  /// - [encoder] — signs generated tokens.
  /// - [decoder] — verifies incoming tokens and validates their claims.
  /// - [accessTokenExpiration] — default lifetime for access tokens.
  /// - [refreshTokenExpiration] — default lifetime for refresh tokens.
  /// - [authoritiesClaimName] — payload key holding the role list.
  /// - [audience] — optional audience added to issued tokens.
  JwtTokenProvider({
    required this.encoder,
    required this.decoder,
    this.accessTokenExpiration = const Duration(minutes: 15),
    this.refreshTokenExpiration = const Duration(days: 7),
    this.authoritiesClaimName = 'roles',
    this.audience,
  });

  /// {@template jwt_token_provider.hmac}
  /// Creates a provider that signs and verifies with one symmetric HMAC secret.
  ///
  /// A shared [secret] configures both the encoder and the decoder with the
  /// `HS256` algorithm. The same [issuer] and [audience] are enforced on
  /// validation, and [clockSkew] is forwarded to the [JwtValidator].
  ///
  /// ### Parameters
  /// - [secret] — the shared secret; use a cryptographically random value.
  /// - [issuer] — expected issuer URI, or `null` to skip issuer checks.
  /// - [audience] — expected audience, or `null` to skip audience checks.
  /// - [accessTokenExpiration] — default access-token lifetime.
  /// - [refreshTokenExpiration] — default refresh-token lifetime.
  /// - [clockSkew] — tolerance for timestamp validation.
  /// - [authoritiesClaimName] — payload key holding the role list.
  ///
  /// ### Returns
  /// A ready-to-use [JwtTokenProvider] with matching HMAC key material.
  /// {@endtemplate}
  /// {@macro jwt_token_provider}
  factory JwtTokenProvider.hmac({
    required String secret,
    String? issuer,
    String? audience,
    Duration accessTokenExpiration = const Duration(minutes: 15),
    Duration refreshTokenExpiration = const Duration(days: 7),
    Duration clockSkew = const Duration(seconds: 30),
    String authoritiesClaimName = 'roles',
  }) {
    final key = JwtSecretKey.fromString(secret);
    return JwtTokenProvider(
      encoder: DartJwtEncoder(
        signingKey: key,
        algorithm: JwsAlgorithms.hs256,
        issuer: issuer,
      ),
      decoder: DartJwtDecoder.withKey(
        key,
        validator: JwtValidator(
          expectedIssuer: issuer,
          expectedAudience: audience,
          clockSkew: clockSkew,
        ),
      ),
      accessTokenExpiration: accessTokenExpiration,
      refreshTokenExpiration: refreshTokenExpiration,
      authoritiesClaimName: authoritiesClaimName,
      audience: audience,
    );
  }

  /// {@template jwt_token_provider.generate_access_token}
  /// Generates a signed access JWT for [subject].
  ///
  /// The payload carries `type: access`, the subject, an optional audience,
  /// and the supplied roles under [authoritiesClaimName]. Extra claims are
  /// merged last, so they can override the defaults — callers should not
  /// override `type` or `sub`.
  ///
  /// ### Parameters
  /// - [subject] — the principal identifier written to `sub`.
  /// - [roles] — role names written to the authorities claim.
  /// - [additionalClaims] — application-specific payload entries.
  /// - [expiresIn] — overrides [accessTokenExpiration] for this token.
  /// - [keyId] — optional `kid` placed in the protected header.
  ///
  /// ### Returns
  /// A signed compact JWT string.
  /// {@endtemplate}
  String generateAccessToken({
    required String subject,
    List<String> roles = const [],
    Map<String, Object?> additionalClaims = const {},
    Duration? expiresIn,
    String? keyId,
  }) {
    final claims = JwtClaimsSet({
      'sub': subject,
      'type': 'access',
      if (audience != null) 'aud': audience,
      if (roles.isNotEmpty) authoritiesClaimName: roles,
      ...additionalClaims,
    });
    return encoder.encode(
      claims,
      expiresIn: expiresIn ?? accessTokenExpiration,
      keyId: keyId,
    );
  }

  /// {@template jwt_token_provider.generate_refresh_token}
  /// Generates a signed refresh JWT for [subject].
  ///
  /// Refresh tokens carry `type: refresh` and no role claim. The verifier
  /// refuses to use them as authentication credentials.
  ///
  /// ### Parameters
  /// - [subject] — the principal identifier written to `sub`.
  /// - [additionalClaims] — application-specific payload entries.
  /// - [expiresIn] — overrides [refreshTokenExpiration] for this token.
  /// - [keyId] — optional `kid` placed in the protected header.
  ///
  /// ### Returns
  /// A signed compact JWT string intended for token renewal only.
  /// {@endtemplate}
  String generateRefreshToken({
    required String subject,
    Map<String, Object?> additionalClaims = const {},
    Duration? expiresIn,
    String? keyId,
  }) {
    final claims = JwtClaimsSet({
      'sub': subject,
      'type': 'refresh',
      if (audience != null) 'aud': audience,
      ...additionalClaims,
    });
    return encoder.encode(
      claims,
      expiresIn: expiresIn ?? refreshTokenExpiration,
      keyId: keyId,
    );
  }

  /// {@template jwt_token_provider.verify_token}
  /// Decodes and validates [token] into a [JwtClaimsSet].
  ///
  /// The decoder verifies the signature and applies the configured claim
  /// policy, including clock skew. No claims are returned for an unverified
  /// token.
  ///
  /// ### Parameters
  /// - [token] — the compact JWT string to verify.
  ///
  /// ### Returns
  /// The verified claims set.
  ///
  /// ### Throws
  /// [AuthenticationException] when verification or validation fails.
  /// {@endtemplate}
  Future<JwtClaimsSet> verifyToken(String token) => decoder.decode(token);

  /// {@template jwt_token_provider.extract_authorities}
  /// Extracts [GrantedAuthority] values from the configured role claim.
  ///
  /// A list of strings is mapped one-to-one to authorities. A non-empty string
  /// is split on whitespace and commas. Missing or unexpected shapes produce
  /// an empty set, so callers must not infer authorization from an unverified
  /// claims set.
  ///
  /// ### Parameters
  /// - [claims] — a verified claims set.
  ///
  /// ### Returns
  /// The granted authorities, possibly empty.
  /// {@endtemplate}
  Set<GrantedAuthority> extractAuthorities(JwtClaimsSet claims) {
    final raw = claims.claims[authoritiesClaimName];
    if (raw is List) {
      return raw.map((e) => SimpleGrantedAuthority(e.toString())).toSet();
    }
    if (raw is String && raw.isNotEmpty) {
      return raw
          .split(RegExp(r'[\s,]+'))
          .where((s) => s.isNotEmpty)
          .map(SimpleGrantedAuthority.new)
          .toSet();
    }
    return const {};
  }

  /// Whether [authentication] is a [JwtAuthenticationToken].
  @override
  bool supports(Authentication authentication) => authentication is JwtAuthenticationToken;

  /// {@template jwt_token_provider.authenticate}
  /// Verifies a JWT bearer request and returns an authenticated token.
  ///
  /// Unsupported requests and empty tokens yield `null`, letting the provider
  /// manager try another provider. A token whose `type` is `refresh` is
  /// rejected with [BadCredentialsException]. On success the verified claims
  /// become the principal and authorities are extracted from the role claim.
  ///
  /// ### Parameters
  /// - [authentication] — a [JwtAuthenticationToken] carrying the raw token.
  ///
  /// ### Returns
  /// An authenticated [JwtAuthenticationToken], or `null` when this provider
  /// does not handle the request.
  ///
  /// ### Throws
  /// [BadCredentialsException] for a refresh token or failed verification;
  /// [AuthenticationException] for other validation failures.
  /// {@endtemplate}
  @override
  Future<Authentication?> authenticate(Authentication authentication) async {
    if (authentication is! JwtAuthenticationToken) {
      return null;
    }
    final rawToken = authentication.token;
    if (rawToken == null || rawToken.isEmpty) {
      return null;
    }
    final claims = await verifyToken(rawToken);
    final type = claims.getClaim<String>('type');
    if (type == 'refresh') {
      throw BadCredentialsException('A refresh token cannot be used as an authentication credential');
    }
    final authorities = extractAuthorities(claims);
    return JwtAuthenticationToken.authenticated(
      claims: claims,
      // The claims map is the principal so `principal.<claim>` paths work in
      // authorization expressions. `name` still resolves to the subject.
      principal: claims.claims,
      token: rawToken,
      authorities: authorities,
      details: authentication.details,
    );
  }
}
