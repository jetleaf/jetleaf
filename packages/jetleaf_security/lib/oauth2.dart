/// 🌐 **Jetleaf OAuth2/OIDC Subsystem**
///
/// Resource-server bearer-token verification and client-side provider verifiers
/// for OpenID Connect identity tokens and OAuth2 user-info endpoints. Provider
/// verifiers run signed ID tokens through the JWT decoder — checking issuer,
/// audience, nonce, and client claims — before constructing a principal.
///
/// All paths are fail-closed: an unverified token never yields an authenticated
/// user, missing email verification is represented as `false`, and empty
/// credentials are rejected before any network request is made.
///
/// ---
///
/// ## 📦 Exports Categorization
///
/// ### 🔑 Principals & Tokens
/// - [OAuth2User] — authenticated provider user with attributes and authorities.
/// - [OidcIdToken] — verified OIDC ID token with decoded claims.
/// - [OAuth2AuthenticationToken] — authentication wrapping a user and optional token.
///
/// ### 🛡️ Resource Server
/// - [OAuth2ResourceServer] — verifies bearer JWTs and maps scopes to authorities.
///
/// ### 🧩 Provider Verifiers
/// - [AppleOAuth2Provider] — verifies Apple OIDC ID tokens against Apple's JWKS.
/// - [GoogleOAuth2Provider] — verifies Google OIDC ID tokens against Google's JWKS.
/// - [GitHubOAuth2Provider] — resolves GitHub user profiles with an access token.
///
/// ---
///
/// ## 🎯 Usage Example
///
/// ```dart
/// import 'package:jetleaf_security/oauth2.dart';
///
/// void main() async {
///   final server = OAuth2ResourceServer.withJwkSetUri(
///     Uri.parse('https://issuer.example.com/jwks'),
///     expectedIssuer: 'https://issuer.example.com',
///     expectedAudience: 'orders-api',
///   );
///
///   final authentication = await server.authenticateBearer(compactJwt);
///   print(authentication.name);
/// }
/// ```
library;

export 'src/oauth2/oauth2_authentication_token.dart';
export 'src/oauth2/oauth2_resource_server.dart';
export 'src/oauth2/oauth2_user.dart';
export 'src/oauth2/oidc_id_token.dart';
export 'src/oauth2/providers/apple_oauth2_provider.dart';
export 'src/oauth2/providers/github_oauth2_provider.dart';
export 'src/oauth2/providers/google_oauth2_provider.dart';
