import 'package:jetleaf_security/authentication.dart';
import 'package:jetleaf_security/core.dart';

import 'api_key_authentication_token.dart';

/// Verifies API keys for service-to-service calls.
final class ApiKeyAuthenticationProvider implements AuthenticationProvider {
  /// Creates a provider from a map of key to client name.
  const ApiKeyAuthenticationProvider(this._clients);

  final Map<String, String> _clients;

  @override
  bool supports(Authentication authentication) =>
      authentication is ApiKeyAuthenticationToken;

  @override
  Future<Authentication?> authenticate(Authentication authentication) async {
    if (authentication is! ApiKeyAuthenticationToken) return null;
    final key = authentication.credentials as String?;
    final client = key == null ? null : _clients[key];
    if (client == null) {
      throw BadCredentialsException('Unknown API key');
    }
    return ApiKeyAuthenticationToken.authenticated(
      principal: client,
      authorities: {SimpleGrantedAuthority('ROLE_SERVICE')},
      details: authentication.details,
    );
  }
}