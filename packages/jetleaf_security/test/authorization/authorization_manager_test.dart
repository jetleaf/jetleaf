import 'package:jetleaf_security/jetleaf_security.dart';
import 'package:test/test.dart';

Authentication authenticated(String name, List<String> authorities) =>
    UsernamePasswordAuthenticationToken.authenticated(
      principal: name,
      authorities: {
        for (final authority in authorities) SimpleGrantedAuthority(authority),
      },
    );

void main() {
  Authentication? current;

  setUp(() => current = null);

  group('Typed authorization managers', () {
    test('AuthorityAuthorizationManager grants matching roles', () {
      current = authenticated('alice', ['ROLE_ADMIN']);
      final manager =
          AuthorityAuthorizationManager<Object?>.hasRole('ADMIN');

      expect(manager.check(() => current, null).isGranted, isTrue);
      expect(
        AuthorityAuthorizationManager<Object?>('READ_BILLING')
            .check(() => current, null)
            .isGranted,
        isFalse,
      );
    });

    test('role hierarchy expands granted authorities', () {
      current = authenticated('alice', ['ROLE_ADMIN']);
      final hierarchy = RoleHierarchy('ROLE_ADMIN > ROLE_USER');
      final manager = AuthorityAuthorizationManager<Object?>.hasRole(
        'USER',
        roleHierarchy: hierarchy,
      );

      expect(manager.check(() => current, null).isGranted, isTrue);
    });

    test('anyOf short-circuits and allOf denies on first failure', () {
      current = authenticated('alice', ['ROLE_USER']);
      final hasUser = AuthorityAuthorizationManager<Object?>.hasRole('USER');
      final hasAdmin = AuthorityAuthorizationManager<Object?>.hasRole('ADMIN');

      expect(
        AuthorizationManagers.anyOf([hasAdmin, hasUser])
            .check(() => current, null)
            .isGranted,
        isTrue,
      );
      expect(
        AuthorizationManagers.allOf([hasUser, hasAdmin])
            .check(() => current, null)
            .isGranted,
        isFalse,
      );
    });

    test('anonymous principals are never fully authenticated', () {
      current = AnonymousAuthenticationToken();
      final manager =
          AuthenticatedAuthorizationManager<Object?>.fullyAuthenticated();

      expect(manager.check(() => current, null).isGranted, isFalse);
      expect(
        const AuthenticationTrustResolverImpl().isAnonymous(current),
        isTrue,
      );
    });

    test('null authentication is denied', () {
      final manager = AuthorityAuthorizationManager<Object?>('ROLE_USER');
      expect(manager.check(() => current, null).isGranted, isFalse);
    });
  });
}
