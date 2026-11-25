import 'package:jetleaf_security/jetleaf_security.dart';
import 'package:test/test.dart';

void main() {
  group('MethodSecurityInterceptor & RoleHierarchy', () {
    final hierarchy = RoleHierarchy('''
      ROLE_ADMIN > ROLE_MODERATOR
      ROLE_MODERATOR > ROLE_USER
    ''');
    final interceptor = MethodSecurityInterceptor(roleHierarchy: hierarchy);

    test('allows @PreAuthorize with role hierarchy expansion', () async {
      final adminAuth = UsernamePasswordAuthenticationToken.authenticated(
        principal: 'admin1',
        authorities: {SimpleGrantedAuthority('ROLE_ADMIN')},
      );

      final result = await SecurityContextHolder.runWithContext(() {
        return interceptor.intercept<String>(
          annotations: const [PreAuthorize("hasRole('USER')")],
          invocation: () async => 'ok',
        );
      }, SecurityContext(adminAuth));

      expect(result, equals('ok'));
    });

    test('evaluates #argument == authentication.name in @PreAuthorize', () async {
      final userAuth = UsernamePasswordAuthenticationToken.authenticated(
        principal: 'alice',
        authorities: {SimpleGrantedAuthority('ROLE_USER')},
      );

      final allowed = await SecurityContextHolder.runWithContext(() {
        return interceptor.intercept<String>(
          annotations: const [
            PreAuthorize("hasRole('ADMIN') or #userId == authentication.name"),
          ],
          arguments: {'userId': 'alice'},
          invocation: () async => 'profile-data',
        );
      }, SecurityContext(userAuth));
      expect(allowed, equals('profile-data'));

      expect(
        () => SecurityContextHolder.runWithContext(() {
          return interceptor.intercept<String>(
            annotations: const [
              PreAuthorize("hasRole('ADMIN') or #userId == authentication.name"),
            ],
            arguments: {'userId': 'bob'},
            invocation: () async => 'profile-data',
          );
        }, SecurityContext(userAuth)),
        throwsA(isA<AccessDeniedException>()),
      );
    });

    test('enforces @PostAuthorize against returnObject', () async {
      final userAuth = UsernamePasswordAuthenticationToken.authenticated(
        principal: 'alice',
        authorities: {SimpleGrantedAuthority('ROLE_USER')},
      );

      expect(
        () => SecurityContextHolder.runWithContext(() {
          return interceptor.intercept<Map<String, Object?>>(
            annotations: const [
              PostAuthorize('returnObject.owner == authentication.name'),
            ],
            invocation: () async => {'id': 1, 'owner': 'bob'},
          );
        }, SecurityContext(userAuth)),
        throwsA(isA<AccessDeniedException>()),
      );
    });

    test('enforces @Secured and @RolesAllowed', () async {
      final modAuth = UsernamePasswordAuthenticationToken.authenticated(
        principal: 'mod1',
        authorities: {SimpleGrantedAuthority('ROLE_MODERATOR')},
      );

      final res = await SecurityContextHolder.runWithContext(() {
        return interceptor.intercept<int>(
          annotations: const [
            RolesAllowed(['USER']),
            Secured(['ROLE_MODERATOR']),
          ],
          invocation: () async => 200,
        );
      }, SecurityContext(modAuth));

      expect(res, equals(200));
    });
  });
}