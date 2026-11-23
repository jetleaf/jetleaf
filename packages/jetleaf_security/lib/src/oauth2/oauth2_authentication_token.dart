import 'package:jetleaf_core/lang.dart' show EqualsAndHashCode;

import '../core/authentication.dart';
import '../core/granted_authority.dart';
import 'oauth2_user.dart';
import 'oidc_id_token.dart';

/// {@template oauth2_authentication_token}
/// An [Authentication] representing an authenticated OAuth2/OIDC user.
///
/// The [user] is the principal; the [authorizedClientRegistrationId] records
/// which provider produced it. An OIDC flow additionally supplies an [idToken],
/// while a pure OAuth2 flow may carry only an [accessToken].
///
/// - **Trust:** the constructor grants trust explicitly; the `isAuthenticated`
///   setter is revoke-only and throws when asked to grant it.
/// - **Authority safety:** authorities are copied into an unmodifiable set,
///   defaulting to the authorities declared by [user].
/// - **Credential erasure:** [eraseCredentials] clears the access token; the
///   ID token and user attributes remain available for authorization.
///
/// ### See also
/// - [OAuth2User] — the authenticated principal.
/// - [OidcIdToken] — the verified identity token from an OIDC flow.
///
/// ### Example
/// ```dart
/// final authentication = OAuth2AuthenticationToken(
///   user: user,
///   authorizedClientRegistrationId: 'google',
///   idToken: idToken,
/// );
/// ```
/// {@endtemplate}
class OAuth2AuthenticationToken with EqualsAndHashCode implements Authentication {
  /// The authenticated OAuth2/OIDC user.
  final OAuth2User user;

  /// Provider registration id (for example `'google'`, `'apple'`, `'github'`).
  final String authorizedClientRegistrationId;

  /// Optional OIDC ID token when authenticated via OpenID Connect.
  final OidcIdToken? idToken;

  /// Optional OAuth2 access token; cleared by [eraseCredentials].
  String? accessToken;

  @override
  final Set<GrantedAuthority> authorities;

  @override
  final Object? details;

  bool _isAuthenticated;

  @override
  bool get isAuthenticated => _isAuthenticated;

  @override
  set isAuthenticated(bool value) {
    checkAuthenticationRevocation(value);
    _isAuthenticated = false;
  }

  /// {@macro oauth2_authentication_token}
  ///
  /// ### Parameters
  /// - [user] — the authenticated principal.
  /// - [authorizedClientRegistrationId] — provider identifier.
  /// - [idToken] — optional verified OIDC ID token.
  /// - [accessToken] — optional OAuth2 access token.
  /// - [authorities] — explicit authorities; defaults to [user]'s authorities.
  /// - [details] — optional request context.
  /// - [isAuthenticated] — whether trust is granted at construction; defaults
  ///   to `true`.
  OAuth2AuthenticationToken({
    required this.user,
    required this.authorizedClientRegistrationId,
    this.idToken,
    this.accessToken,
    Set<GrantedAuthority>? authorities,
    this.details,
    bool isAuthenticated = true,
  })  : authorities = Set.unmodifiable(authorities ?? user.authorities),
        _isAuthenticated = isAuthenticated;

  /// The authenticated [user].
  @override
  Object? get principal => user;

  /// The access token, or the raw ID token when no access token is present.
  @override
  Object? get credentials => accessToken ?? idToken?.tokenValue;

  /// The display name of the authenticated [user].
  @override
  String get name => user.name;

  /// {@template oauth2_authentication_token.erase_credentials}
  /// Clears the access token from memory after authentication completes.
  ///
  /// The verified [user] and [idToken] remain available for authorization.
  /// {@endtemplate}
  @override
  void eraseCredentials() {
    accessToken = null;
  }

  @override
  String toString() => 'OAuth2AuthenticationToken(provider: $authorizedClientRegistrationId, user: ${user.name})';

  /// Contributes the stable authentication identity to equality and hashing.
  ///
  /// [accessToken] and [idToken] are excluded because they carry secrets and
  /// the access token is mutable.
  ///
  /// ### Returns
  /// The ordered list of properties used by [EqualsAndHashCode].
  @override
  List<Object?> equalizedProperties() => [
    runtimeType,
    user,
    authorizedClientRegistrationId,
    authorities,
    isAuthenticated,
    details,
  ];
}
