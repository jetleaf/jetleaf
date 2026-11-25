import 'package:jetleaf_core/lang.dart' show IllegalStateException;
import 'package:jetleaf_security/jetleaf_security.dart';
import 'package:test/test.dart';

Authentication auth(String name) => UsernamePasswordAuthenticationToken.authenticated(
      principal: name,
    );

void main() {
  group('SecurityContext', () {
    test('setAuthentication is equivalent to direct assignment', () {
      final context = SecurityContext();
      final token = auth('alice');

      context.setAuthentication(token);
      expect(context.authentication, same(token));

      context.authentication = null;
      expect(context.authentication, isNull);

      context.setAuthentication(null);
      expect(context.authentication, isNull);
    });
  });

  group('SecurityContextHolder', () {
    test('getContext outside a zone returns a fresh empty context', () {
      final first = SecurityContextHolder.getContext();
      first.authentication = auth('alice');

      final second = SecurityContextHolder.getContext();

      expect(second.authentication, isNull);
      expect(identical(first, second), isFalse);
    });

    test('concurrent zones do not share authentication', () async {
      final results = await Future.wait([
        SecurityContextHolder.runWithContext(() async {
          await Future<void>.delayed(const Duration(milliseconds: 2));
          return SecurityContextHolder.getContext().authentication?.name;
        }, SecurityContext(auth('alice'))),
        SecurityContextHolder.runWithContext(() async {
          await Future<void>.delayed(const Duration(milliseconds: 2));
          return SecurityContextHolder.getContext().authentication?.name;
        }, SecurityContext(auth('bob'))),
      ]);

      expect(results, ['alice', 'bob']);
    });

    test('nested zones restore the outer context', () async {
      await SecurityContextHolder.runWithContext(() async {
        expect(SecurityContextHolder.getContext().authentication?.name, 'outer');
        await SecurityContextHolder.runWithContext(() async {
          expect(SecurityContextHolder.getContext().authentication?.name, 'inner');
        }, SecurityContext(auth('inner')));
        expect(SecurityContextHolder.getContext().authentication?.name, 'outer');
      }, SecurityContext(auth('outer')));
    });

    test('setContext outside a bound zone throws', () {
      expect(
        () => SecurityContextHolder.setContext(SecurityContext(auth('alice'))),
        throwsA(isA<IllegalStateException>()),
      );
    });
  });
}