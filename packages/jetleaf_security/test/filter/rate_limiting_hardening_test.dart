import 'package:jetleaf_security/jetleaf_security.dart';
import 'package:jetleaf_web/jetleaf_web.dart';
import 'package:test/test.dart';

import '../helpers/mock_http.dart';

void main() {
  group('RateLimitingFilter hardening', () {
    test('a client-supplied X-Forwarded-For cannot choose its own bucket',
        () async {
      final filter = RateLimitingFilter(
        config: const RateLimitConfig(capacity: 1, refillTokens: 1),
      );

      final first = RecordingFilterChain();
      await filter.doFilter(
        MockServerHttpRequest(headers: {'X-Forwarded-For': '10.0.0.1'}),
        MockServerHttpResponse(),
        first,
      );
      final second = RecordingFilterChain();
      final blocked = MockServerHttpResponse();
      await filter.doFilter(
        MockServerHttpRequest(headers: {'X-Forwarded-For': '10.0.0.2'}),
        blocked,
        second,
      );

      expect(first.called, isTrue);
      expect(second.called, isFalse);
      expect(blocked.status, equals(HttpStatus.TOO_MANY_REQUESTS));
    });

    test('trusted proxies may delegate the client key to X-Forwarded-For',
        () async {
      final filter = RateLimitingFilter(
        config: const RateLimitConfig(
          capacity: 1,
          refillTokens: 1,
          trustedProxies: {'127.0.0.1'},
        ),
      );

      final first = RecordingFilterChain();
      await filter.doFilter(
        MockServerHttpRequest(headers: {'X-Forwarded-For': '10.0.0.1'}),
        MockServerHttpResponse(),
        first,
      );
      final second = RecordingFilterChain();
      await filter.doFilter(
        MockServerHttpRequest(headers: {'X-Forwarded-For': '10.0.0.2'}),
        MockServerHttpResponse(),
        second,
      );

      expect(first.called, isTrue);
      expect(second.called, isTrue);
    });

    test('idle buckets are evicted when the store is full', () async {
      final filter = RateLimitingFilter(
        config: const RateLimitConfig(capacity: 1, refillTokens: 1, maxBuckets: 2),
      );

      for (var i = 0; i < 10; i++) {
        await filter.doFilter(
          MockServerHttpRequest(origin: '10.0.0.$i'),
          MockServerHttpResponse(),
          RecordingFilterChain(),
        );
      }
    });
  });
}