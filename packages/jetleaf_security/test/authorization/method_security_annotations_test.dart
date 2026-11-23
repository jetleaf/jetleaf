import 'package:jetleaf_core/lang.dart';
import 'package:jetleaf_security/jetleaf_security.dart';
import 'package:test/test.dart';

void main() {
  group('Method security annotations', () {
    test('authorization annotations are reflectable Jetleaf annotations', () {
      const pre = PreAuthorize("hasRole('ADMIN')");
      const post = PostAuthorize('returnObject.owner == authentication.name');
      const secured = Secured(['ROLE_USER']);
      const roles = RolesAllowed(['USER']);

      expect(pre, isA<ReflectableAnnotation>());
      expect(post, isA<ReflectableAnnotation>());
      expect(secured, isA<ReflectableAnnotation>());
      expect(roles, isA<ReflectableAnnotation>());

      expect(pre.annotationType, PreAuthorize);
      expect(post.annotationType, PostAuthorize);
      expect(secured.annotationType, Secured);
      expect(roles.annotationType, RolesAllowed);
    });

    test('enable annotations are reflectable', () {
      expect(const EnableWebSecurity(), isA<ReflectableAnnotation>());
      expect(const EnableMethodSecurity(), isA<ReflectableAnnotation>());
      expect(const EnableMethodSecurity().annotationType, EnableMethodSecurity);
    });

    test('annotation value semantics are stable', () {
      expect(const PreAuthorize('a'), equals(const PreAuthorize('a')));
      expect(const PreAuthorize('a').hashCode, equals(const PreAuthorize('a').hashCode));
      expect(const Secured(['A']), isNot(equals(const Secured(['B']))));
    });
  });

  group('Method security managers', () {
    test('secured manager denies a principal without the authority', () {
      final manager = SecuredAuthorizationManager(['ROLE_ADMIN']);
      final authentication = UsernamePasswordAuthenticationToken.authenticated(
        principal: 'alice',
        authorities: {const SimpleGrantedAuthority('ROLE_USER')},
      );

      expect(
        manager.check(() => authentication, const MethodAuthorizationContext()).isGranted,
        isFalse,
      );
    });

    test('jsr250 manager normalises role names', () {
      final manager = Jsr250AuthorizationManager(['USER']);
      final authentication = UsernamePasswordAuthenticationToken.authenticated(
        principal: 'alice',
        authorities: {const SimpleGrantedAuthority('ROLE_USER')},
      );

      expect(
        manager.check(() => authentication, const MethodAuthorizationContext()).isGranted,
        isTrue,
      );
    });
  });
}
