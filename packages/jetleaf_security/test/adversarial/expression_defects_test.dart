import 'package:jetleaf_security/jetleaf_security.dart';
import 'package:test/test.dart';

/// Red-phase tests for defect 12 in the rewrite specification.
class _OwnedResource {
  const _OwnedResource(this.ownerId);
  final String ownerId;
}

class _Principal {
  const _Principal(this.organizationId);
  final String organizationId;
}

/// Jetleaf reflection needs AOT-generated metadata, so ad-hoc test classes are
/// resolved explicitly. Real applications get the same behaviour from `jl build`.
class _TestPropertyResolver implements SecurityExpressionPropertyResolver {
  @override
  Object? resolve(Object target, String property) {
    if (target is _OwnedResource && property == 'ownerId') return target.ownerId;
    if (target is _Principal && property == 'organizationId') {
      return target.organizationId;
    }
    return SecurityExpressionPropertyResolvers.notResolved;
  }
}

void main() {
  const parser = SecurityExpressionParser();

  setUp(() => SecurityExpressionPropertyResolvers.register(_TestPropertyResolver()));
  tearDown(() => SecurityExpressionPropertyResolvers.clear());

  Authentication authenticated(String name) =>
      UsernamePasswordAuthenticationToken.authenticated(
        principal: name,
        authorities: {SimpleGrantedAuthority('ROLE_USER')},
      );

  group('Expression defects (red phase)', () {
    test('hasAnyRole accepts the documented list syntax', () {
      final context = SecurityExpressionContext(authentication: authenticated('alice'));

      expect(
        parser.evaluate("hasAnyRole(['USER', 'ADMIN'])", context),
        isTrue,
      );
    });

    test('hasAnyAuthority accepts the documented list syntax', () {
      final context = SecurityExpressionContext(authentication: authenticated('alice'));

      expect(
        parser.evaluate("hasAnyAuthority(['read', 'write'])", context),
        isFalse,
      );
    });

    test('returnObject resolves properties on a Dart object', () {
      final context = SecurityExpressionContext(
        authentication: authenticated('alice'),
        returnObject: const _OwnedResource('alice'),
      );

      expect(
        parser.evaluate("returnObject.ownerId == 'alice'", context),
        isTrue,
      );
    });

    test('principal resolves properties on a Dart object', () {
      final authentication = UsernamePasswordAuthenticationToken.authenticated(
        principal: const _Principal('acme'),
        authorities: {SimpleGrantedAuthority('ROLE_USER')},
      );
      final context = SecurityExpressionContext(authentication: authentication);

      expect(
        parser.evaluate("principal.organizationId == 'acme'", context),
        isTrue,
      );
    });
  });
}