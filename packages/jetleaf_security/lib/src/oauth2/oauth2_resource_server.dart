import '../authentication/authentication_provider.dart';
import '../core/authentication.dart';
import '../core/exceptions.dart';
import '../core/granted_authority.dart';
import '../core/simple_granted_authority.dart';
import '../jwt/jwk_set_source.dart';
import '../jwt/jwt_authentication_token.dart';
import '../jwt/jwt_claims_set.dart';
import '../jwt/jwt_decoder.dart';
import '../jwt/jwt_validator.dart';

/// {@template oauth2_resource_server}
/// OAuth2 resource-server support for bearer JWT verification.
///
/// The server delegates all cryptographic work to a [JwtDecoder] — typically
/// one backed by a remote JWKS endpoint — and converts the verified `scope`,
/// `scp`, and `roles` claims into [GrantedAuthority] instances. The decoder's
/// algorithm allowlist, key filtering, signature check, and claim validation
/// all run before any authority is produced.
///
/// - **Fail-closed:** an empty bearer token is rejected, a failed decode throws
///   an [AuthenticationException], and unsupported authentication objects are
///   ignored by returning `null`.
/// - **Scope mapping:** space- or list-valued scopes receive
///   [scopeAuthorityPrefix] (default `SCOPE_`); roles are taken verbatim.
/// - **No local signing:** this component only verifies tokens issued by an
///   authorization server.
///
/// ### See also
/// - [DartJwtDecoder] — the decoder used by the JWKS convenience factory.
/// - [JwtAuthenticationToken] — the authentication object produced here.
///
/// ### Example
/// ```dart
/// final server = OAuth2ResourceServer.withJwkSetUri(
///   Uri.parse('https://issuer.example.com/jwks'),
///   expectedIssuer: 'https://issuer.example.com',
///   expectedAudience: 'orders-api',
/// );
/// final authentication = await server.authenticateBearer(compactJwt);
/// ```
/// {@endtemplate}
class OAuth2ResourceServer implements AuthenticationProvider {
  /// Decoder used to verify incoming bearer tokens.
  final JwtDecoder jwtDecoder;

  /// Prefix applied to extracted scopes. Defaults to `'SCOPE_'`.
  final String scopeAuthorityPrefix;

  /// {@macro oauth2_resource_server}
  ///
  /// ### Parameters
  /// - [jwtDecoder] — verifies signatures and validates claims.
  /// - [scopeAuthorityPrefix] — prefix prepended to each scope-derived
  ///   authority.
  const OAuth2ResourceServer({
    required this.jwtDecoder,
    this.scopeAuthorityPrefix = 'SCOPE_',
  });

  /// {@template oauth2_resource_server.with_jwk_set_uri}
  /// Configures verification against a remote JWKS endpoint.
  ///
  /// Builds a [RemoteJwkSetSource] with the supplied cache lifetime, a
  /// [DartJwtDecoder] whose allowlist covers all supported algorithms, and a
  /// [JwtValidator] enforcing the optional issuer and audience.
  ///
  /// ### Parameters
  /// - [jwksUri] — the authorization server's JWKS document URL.
  /// - [expectedIssuer] — exact issuer URI to require, or `null`.
  /// - [expectedAudience] — required audience, or `null`.
  /// - [cacheTtl] — how long fetched keys are cached.
  /// - [scopeAuthorityPrefix] — prefix for scope-derived authorities.
  ///
  /// ### Returns
  /// A configured [OAuth2ResourceServer].
  /// {@endtemplate}
  /// {@macro oauth2_resource_server}
  factory OAuth2ResourceServer.withJwkSetUri(
    Uri jwksUri, {
    String? expectedIssuer,
    String? expectedAudience,
    Duration cacheTtl = const Duration(minutes: 15),
    String scopeAuthorityPrefix = 'SCOPE_',
  }) {
    final source = RemoteJwkSetSource(jwksUri, cacheTtl: cacheTtl);
    final decoder = DartJwtDecoder.withJwkSet(
      source,
      validator: JwtValidator(
        expectedIssuer: expectedIssuer,
        expectedAudience: expectedAudience,
      ),
    );
    return OAuth2ResourceServer(
      jwtDecoder: decoder,
      scopeAuthorityPrefix: scopeAuthorityPrefix,
    );
  }

  /// Whether [authentication] is a [JwtAuthenticationToken].
  @override
  bool supports(Authentication authentication) =>
      authentication is JwtAuthenticationToken;

  /// {@template oauth2_resource_server.authenticate}
  /// Delegates to [authenticateBearer] for JWT bearer requests. Unsupported
  /// requests or tokens with no credentials return `null` so another provider
  /// can be tried.
  /// {@endtemplate}
  @override
  Future<Authentication?> authenticate(Authentication authentication) async {
    if (authentication is! JwtAuthenticationToken) return null;
    final token = authentication.token;
    if (token == null || token.isEmpty) return null;
    return authenticateBearer(token, details: authentication.details);
  }

  /// {@template oauth2_resource_server.authenticate_bearer}
  /// Verifies a raw bearer [token] and returns an authenticated principal.
  ///
  /// This is a security-critical entry point: the token is passed to
  /// [jwtDecoder], which rejects malformed tokens, unallowed algorithms,
  /// unsuitable keys, invalid signatures, and claim-policy violations before
  /// authorities are extracted. An empty token fails immediately.
  ///
  /// ### Parameters
  /// - [token] — the compact JWT from the `Authorization: Bearer` header.
  /// - [details] — optional request context preserved on the result.
  ///
  /// ### Returns
  /// An authenticated [JwtAuthenticationToken] with the verified claims as its
  /// principal source and the mapped authorities.
  ///
  /// ### Throws
  /// [BadCredentialsException] for an empty token; [AuthenticationException]
  /// for any verification or validation failure.
  ///
  /// ### Example
  /// ```dart
  /// final result = await server.authenticateBearer(
  ///   bearerToken,
  ///   details: requestContext,
  /// );
  /// ```
  /// {@endtemplate}
  Future<JwtAuthenticationToken> authenticateBearer(String token, {
    Object? details,
  }) async {
    if (token.isEmpty) {
      throw BadCredentialsException('Bearer token must not be empty');
    }
    final claims = await jwtDecoder.decode(token);
    final authorities = extractAuthorities(claims);
    return JwtAuthenticationToken.authenticated(
      claims: claims,
      principal: claims.claims,
      token: token,
      authorities: authorities,
      details: details,
    );
  }

  /// {@template oauth2_resource_server.extract_authorities}
  /// Extracts authorities from the `scope`, `scp`, and `roles` claims.
  ///
  /// `scope` (or `scp`) may be a whitespace-separated string or a list; each
  /// value is prefixed with [scopeAuthorityPrefix]. `roles` must be a list and
  /// entries are added verbatim. Only pass verified claims to this method.
  ///
  /// ### Parameters
  /// - [claims] — verified claims from the bearer token.
  ///
  /// ### Returns
  /// The mapped authorities, possibly empty.
  /// {@endtemplate}
  Set<GrantedAuthority> extractAuthorities(JwtClaimsSet claims) {
    final authorities = <GrantedAuthority>{};

    final scope = claims.claims['scope'] ?? claims.claims['scp'];
    if (scope is String && scope.isNotEmpty) {
      for (final s in scope.split(RegExp(r'\s+'))) {
        if (s.isNotEmpty) {
          authorities.add(SimpleGrantedAuthority('$scopeAuthorityPrefix$s'));
        }
      }
    } else if (scope is List) {
      for (final s in scope) {
        authorities.add(SimpleGrantedAuthority('$scopeAuthorityPrefix$s'));
      }
    }

    final roles = claims.claims['roles'];
    if (roles is List) {
      for (final r in roles) {
        authorities.add(SimpleGrantedAuthority(r.toString()));
      }
    }

    return authorities;
  }
}