import 'package:jetleaf_security/authentication.dart';
import 'package:jetleaf_security/authorization.dart';
import 'package:jetleaf_security/core.dart';
import 'package:test/test.dart';

import '../helpers/mock_http.dart';

Authentication authenticated(String role) =>
    UsernamePasswordAuthenticationToken.authenticated(
      principal: 'admin',
      authorities: {SimpleGrantedAuthority(role)},
    );

void main() {
  group('Role hierarchy propagation', () {
    final hierarchy = RoleHierarchy('ROLE_ADMIN > ROLE_USER');

    test('authority managers expand roles through the hierarchy', () {
      final manager = AuthorityAuthorizationManager<RequestAuthorizationContext>.hasRole(
        'USER',
        roleHierarchy: hierarchy,
      );
      expect(
        manager
            .check(
              () => authenticated('ROLE_ADMIN'),
              RequestAuthorizationContext(MockServerHttpRequest()),
            )
            .isGranted,
        isTrue,
      );
    });

    test('expression managers honour the same hierarchy', () {
      final manager = ExpressionAuthorizationManager<RequestAuthorizationContext>(
        "hasRole('USER')",
        roleHierarchy: hierarchy,
      );
      expect(
        manager
            .check(
              () => authenticated('ROLE_ADMIN'),
              RequestAuthorizationContext(MockServerHttpRequest()),
            )
            .isGranted,
        isTrue,
      );
    });

    test('withRoleHierarchy copies an expression manager', () {
      final original = ExpressionAuthorizationManager<RequestAuthorizationContext>(
        "hasRole('USER')",
      );
      final copy = original.withRoleHierarchy(hierarchy);
      expect(copy.expression, original.expression);
      expect(copy.roleHierarchy, same(hierarchy));
      expect(
        copy
            .check(
              () => authenticated('ROLE_ADMIN'),
              RequestAuthorizationContext(MockServerHttpRequest()),
            )
            .isGranted,
        isTrue,
        reason: 'the copied manager must use the new hierarchy at evaluation time',
      );
    });
  });
}
