import 'package:jetleaf_security/jetleaf_security.dart';
import 'package:test/test.dart';

void main() {
  const resolver = AuthenticationTrustResolverImpl();

  group('AuthenticationTrustResolver', () {
    test('null authentication is anonymous', () {
      expect(resolver.isAnonymous(null), isTrue);
      expect(resolver.isRememberMe(null), isFalse);
      expect(resolver.isFullyAuthenticated(null), isFalse);
    });

    test('an anonymous token is not fully authenticated', () {
      final token = AnonymousAuthenticationToken();

      expect(token.isAuthenticated, isTrue);
      expect(resolver.isAnonymous(token), isTrue);
      expect(resolver.isFullyAuthenticated(token), isFalse);
    });

    test('a real authenticated token is fully authenticated', () {
      final token = UsernamePasswordAuthenticationToken.authenticated(
        principal: 'alice',
      );

      expect(resolver.isAnonymous(token), isFalse);
      expect(resolver.isFullyAuthenticated(token), isTrue);
    });

    test('revoking trust makes a token no longer fully authenticated', () {
      final token = UsernamePasswordAuthenticationToken.authenticated(
        principal: 'alice',
      );
      token.isAuthenticated = false;

      expect(resolver.isFullyAuthenticated(token), isFalse);
    });
  });
}
