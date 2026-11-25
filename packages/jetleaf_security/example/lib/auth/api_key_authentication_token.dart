import 'package:jetleaf_security/core.dart';

/// A custom credential type used to demonstrate provider extensibility.
///
/// Clients send it as an `X-Api-Key` header; [ApiKeyAuthenticationProvider]
/// verifies it and returns an authenticated instance.
final class ApiKeyAuthenticationToken implements Authentication {
  ApiKeyAuthenticationToken.unauthenticated(this.credentials, {this.details})
      : principal = null,
        authorities = const {},
        _isAuthenticated = false;

  ApiKeyAuthenticationToken.authenticated({
    required this.principal,
    required this.authorities,
    this.details,
  })  : credentials = null,
        _isAuthenticated = true;

  @override
  final Object? principal;

  @override
  Object? credentials;

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

  @override
  String get name => principal?.toString() ?? 'api-key-client';

  @override
  void eraseCredentials() => credentials = null;
}