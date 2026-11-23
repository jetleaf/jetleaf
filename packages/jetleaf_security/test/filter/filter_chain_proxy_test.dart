import 'package:jetleaf_security/jetleaf_security.dart';
import 'package:test/test.dart';

import '../helpers/mock_http.dart';

void main() {
  group('FilterChainProxy', () {
    test('selects the first matching chain in order', () async {
      final first = SecurityFilterChain(
        requestMatcher: PathPatternMatcher('/api/**'),
        filters: [],
        order: 0,
      );
      final second = SecurityFilterChain(
        requestMatcher: AnyRequestMatcher(),
        filters: [],
        order: 1,
      );
      final proxy = FilterChainProxy([second, first]);
      final next = RecordingFilterChain();

      await proxy.doFilter(
        MockServerHttpRequest(path: '/api/orders'),
        MockServerHttpResponse(),
        next,
      );

      expect(next.called, isTrue);
      expect(proxy.chains.first, same(first));
    });

    test('passes through when no chain matches', () async {
      final chain = SecurityFilterChain(
        requestMatcher: PathPatternMatcher('/api/**'),
        filters: [],
      );
      final proxy = FilterChainProxy([chain]);
      final next = RecordingFilterChain();

      await proxy.doFilter(
        MockServerHttpRequest(path: '/health'),
        MockServerHttpResponse(),
        next,
      );

      expect(next.called, isTrue);
    });

    test('clears the security context after a chain runs', () async {
      final chain = SecurityFilterChain(
        requestMatcher: const AnyRequestMatcher(),
        filters: [
          SecurityContextHolderFilter(),
        ],
      );
      final proxy = FilterChainProxy([chain]);

      await SecurityContextHolder.runWithContext(() async {
        await proxy.doFilter(
          MockServerHttpRequest(path: '/api/orders'),
          MockServerHttpResponse(),
          RecordingFilterChain(),
        );
        expect(SecurityContextHolder.getContext().authentication, isNull);
      });
    });
  });
}
