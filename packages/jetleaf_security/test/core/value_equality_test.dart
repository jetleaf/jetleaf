import 'package:jetleaf_security/annotation.dart';
import 'package:jetleaf_security/authorization.dart';
import 'package:jetleaf_security/config.dart';
import 'package:jetleaf_security/core.dart';
import 'package:jetleaf_security/authentication.dart';
import 'package:jetleaf_security/jwt.dart';
import 'package:test/test.dart';

void main() {
  group('Value equality', () {
    test('granted authorities compare by value', () {
      final first = SimpleGrantedAuthority('ROLE_USER');
      final second = SimpleGrantedAuthority('ROLE_USER');

      expect(first, equals(second));
      expect(first.hashCode, equals(second.hashCode));
      expect(first, isNot(SimpleGrantedAuthority('ROLE_ADMIN')));
    });

    test('distinct annotation types with the same value are not equal', () {
      expect(const PreAuthorize('x'), isNot(const PostAuthorize('x')));
      expect(const PreAuthorize('x'), equals(const PreAuthorize('x')));
    });

    test('tokens compare by identity-relevant fields only', () {
      final first = UsernamePasswordAuthenticationToken.unauthenticated(
        principal: 'alice',
        credentials: 'secret-one',
      );
      final second = UsernamePasswordAuthenticationToken.unauthenticated(
        principal: 'alice',
        credentials: 'secret-two',
      );

      expect(first, equals(second),
          reason: 'credentials are secrets and must not affect equality');

      final different = UsernamePasswordAuthenticationToken.authenticated(
        principal: 'alice',
        authorities: {const SimpleGrantedAuthority('ROLE_USER')},
      );
      expect(first, isNot(different));
    });

    test('claims and authorization decisions compare by value', () {
      expect(
        JwtClaimsSet({'sub': 'alice'}),
        equals(JwtClaimsSet({'sub': 'alice'})),
      );
      expect(AuthorizationDecision.granted, equals(AuthorizationDecision(true)));
      expect(AuthorizationDecision.granted, isNot(AuthorizationDecision.denied));
    });

    test('configuration objects compare by value', () {
      const first = CorsConfiguration(allowedOrigins: ['https://app.example.com']);
      const second = CorsConfiguration(allowedOrigins: ['https://app.example.com']);

      expect(first, equals(second));
      expect(first.hashCode, equals(second.hashCode));
    });

    test('security context compares by its authentication', () {
      final authentication = UsernamePasswordAuthenticationToken.authenticated(
        principal: 'alice',
      );
      expect(SecurityContext(authentication), equals(SecurityContext(authentication)));
      expect(SecurityContext(authentication), isNot(SecurityContext(null)));
    });
  });
}