import 'package:jetleaf_security/jetleaf_security.dart';
import 'package:jetleaf_web/jetleaf_web.dart';
import 'package:test/test.dart';

import '../helpers/mock_http.dart';

Authentication auth(String name) => UsernamePasswordAuthenticationToken.authenticated(
      principal: name,
    );

class _CountingStrategy implements SessionAuthenticationStrategy {
  int calls = 0;

  @override
  Future<void> onAuthentication(
    Authentication authentication,
    ServerHttpRequest request,
    ServerHttpResponse response,
  ) async {
    calls++;
  }
}

void main() {
  group('Session management', () {
    test('fixation protection migrates attributes and emits a new cookie', () async {
      final previous = HttpSession.create();
      previous.setAttribute('cart', 'abc');
      final request = MockServerHttpRequest(session: previous);
      final response = MockServerHttpResponse();

      await const ChangeSessionIdAuthenticationStrategy()
          .onAuthentication(auth('alice'), request, response);

      expect(previous.isValid(), isFalse);
      expect(
        response.getHeaders().getFirst(HttpHeaders.SET_COOKIE),
        contains('JSESSIONID='),
      );
    });

    test('composite strategy runs every delegate in order', () async {
      final first = _CountingStrategy();
      final second = _CountingStrategy();
      final composite = CompositeSessionAuthenticationStrategy([first, second]);

      await composite.onAuthentication(
        auth('alice'),
        MockServerHttpRequest(),
        MockServerHttpResponse(),
      );

      expect(first.calls, 1);
      expect(second.calls, 1);
    });

    test('null strategy does nothing', () async {
      await const NullAuthenticatedSessionStrategy().onAuthentication(
        auth('alice'),
        MockServerHttpRequest(),
        MockServerHttpResponse(),
      );
    });

    test('session registry tracks and expires sessions', () {
      final registry = SessionRegistry();
      final info = registry.registerNewSession('session-1', 'alice');

      expect(registry.getSessionInformation('session-1'), same(info));
      expect(registry.getAllSessions('alice'), hasLength(1));

      info.expire();
      expect(registry.getAllSessions('alice'), isEmpty);
      expect(registry.getAllSessions('alice', includeExpired: true), hasLength(1));
    });

    test('anonymous filter installs a token only when none exists', () async {
      final filter = AnonymousAuthenticationFilter();
      final request = MockServerHttpRequest();
      final response = MockServerHttpResponse();
      Authentication? observed;
      final next = RecordingFilterChain(
        onNext: (_, _) => observed =
            SecurityContextHolder.getContext().authentication,
      );

      await SecurityContextHolder.runWithContext(
        () => filter.doFilter(request, response, next),
      );

      expect(next.called, isTrue);
      expect(observed, isA<AnonymousAuthenticationToken>());
    });
  });
}