import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/exceptions.dart';
import '../../core/simple_granted_authority.dart';
import '../oauth2_authentication_token.dart';
import '../oauth2_user.dart';

/// {@template github_oauth2_provider}
/// OAuth2 user-info provider for GitHub (`https://api.github.com/user`).
///
/// Unlike the OIDC providers, this verifier exchanges an already-obtained
/// access token for a user profile; it does not verify a signed identity token.
/// The token is sent only to [userInfoUri] as a bearer credential, and every
/// non-200 response or malformed payload is reported as a
/// [BadCredentialsException].
///
/// - **Email verification:** the GitHub user endpoint does not expose a
///   verified-email claim, so [OAuth2User.emailVerified] is always `false`.
/// - **Fail-closed:** an empty access token is rejected before any request is
///   made, and an unusable response never yields an authenticated token.
///
/// ### See also
/// - [OAuth2AuthenticationToken] — the authentication object produced here.
///
/// ### Example
/// ```dart
/// final provider = GitHubOAuth2Provider();
/// final authentication = await provider.authenticateAccessToken(accessToken);
/// ```
/// {@endtemplate}
class GitHubOAuth2Provider {
  /// GitHub's user API endpoint.
  static final Uri defaultUserInfoUri = Uri.parse('https://api.github.com/user');

  final Uri userInfoUri;
  final http.Client _httpClient;

  /// {@macro github_oauth2_provider}
  ///
  /// ### Parameters
  /// - [userInfoUri] — user-info endpoint; defaults to [defaultUserInfoUri].
  /// - [httpClient] — optional client for injecting test transport.
  GitHubOAuth2Provider({
    Uri? userInfoUri,
    http.Client? httpClient,
  })  : userInfoUri = userInfoUri ?? defaultUserInfoUri,
        _httpClient = httpClient ?? http.Client();

  /// {@template github_oauth2_provider.authenticate_access_token}
  /// Fetches the GitHub user profile and builds an authenticated principal.
  ///
  /// The access token is attached as a bearer header to [userInfoUri]. The
  /// response must be a JSON object with HTTP 200; `id` supplies the user id,
  /// `login` (or `name`, or the id) supplies the display name, and `email` is
  /// optional. The resulting user is granted `ROLE_USER`.
  ///
  /// ### Parameters
  /// - [accessToken] — the OAuth2 access token; must not be empty.
  /// - [details] — optional request context.
  ///
  /// ### Returns
  /// An authenticated [OAuth2AuthenticationToken] for provider `'github'`,
  /// carrying [accessToken] as its credential.
  ///
  /// ### Throws
  /// [BadCredentialsException] for an empty token, a failed request, or an
  /// invalid response body.
  /// {@endtemplate}
  Future<OAuth2AuthenticationToken> authenticateAccessToken(String accessToken, {
    Object? details,
  }) async {
    if (accessToken.isEmpty) {
      throw BadCredentialsException('GitHub access token must not be empty');
    }

    final response = await _httpClient.get(
      userInfoUri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/vnd.github+json',
        'User-Agent': 'jetleaf-security',
      },
    );

    if (response.statusCode != 200) {
      throw BadCredentialsException('GitHub userinfo request failed with status ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    if (data is! Map<String, dynamic>) {
      throw BadCredentialsException('Invalid GitHub userinfo response');
    }

    final id = (data['id'] ?? '').toString();
    final login = (data['login'] ?? data['name'] ?? id).toString();
    final email = data['email'] as String?;

    final user = OAuth2User(
      id: id,
      name: login,
      email: email,
      // GitHub does not expose a verified-email claim here; never assert one.
      emailVerified: false,
      attributes: data,
      authorities: {SimpleGrantedAuthority('ROLE_USER')},
    );

    return OAuth2AuthenticationToken(
      user: user,
      authorizedClientRegistrationId: 'github',
      accessToken: accessToken,
      details: details,
    );
  }
}
