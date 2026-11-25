import 'package:jetleaf_security/jetleaf_security.dart';
import 'package:jetleaf_web/jetleaf_web.dart';
import 'package:test/test.dart';

import '../helpers/mock_http.dart';

Authentication auth(String name) => UsernamePasswordAuthenticationToken.authenticated(
      principal: name,
    );

void main() {
  group('SecurityContextRepository', () {
    test('null repository never touches a session', () async {
      const repository = NullSecurityContextRepository();
      final request = MockServerHttpRequest();
      final response = MockServerHttpResponse();

      final loaded = await repository.loadDeferredContext(request).get();
      expect(loaded.authentication, isNull);

      await repository.saveContext(SecurityContext(auth('alice')), request, response);
      expect(request.session, isNull);
    });

    test('http session repository saves and loads a context', () async {
      final session = HttpSession.create();
      final request = MockServerHttpRequest(
        session: session,
        cookies: [HttpCookie(HttpSession.JSESSIONID, 'test-session')],
      );
      final response = MockServerHttpResponse();
      const repository = HttpSessionSecurityContextRepository();

      await repository.saveContext(SecurityContext(auth('alice')), request, response);

      expect(
        session.getAttribute(HttpSessionSecurityContextRepository.SECURITY_CONTEXT_KEY),
        isA<SecurityContext>(),
      );
      final loaded = await repository.loadDeferredContext(request).get();
      expect(loaded.authentication?.name, 'alice');
    });

    test('saving an empty context removes the session attribute', () async {
      final session = HttpSession.create();
      final request = MockServerHttpRequest(
        session: session,
        cookies: [HttpCookie(HttpSession.JSESSIONID, 'test-session')],
      );
      const repository = HttpSessionSecurityContextRepository();

      await repository.saveContext(SecurityContext(auth('alice')), request, MockServerHttpResponse());
      await repository.saveContext(SecurityContext(), request, MockServerHttpResponse());

      final loaded = await repository.loadDeferredContext(request).get();
      expect(loaded.authentication, isNull);
    });

    test('deferred context loads at most once', () async {
      var loads = 0;
      final deferred = DeferredSecurityContext(() async {
        loads++;
        return SecurityContext(auth('alice'));
      });

      await deferred.get();
      await deferred.get();

      expect(loads, 1);
      expect(deferred.isLoaded, isTrue);
    });
  });
}