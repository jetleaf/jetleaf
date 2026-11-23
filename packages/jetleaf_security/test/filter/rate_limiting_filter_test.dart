import 'package:jetleaf_security/jetleaf_security.dart';
import 'package:jetleaf_web/jetleaf_web.dart';
import 'package:test/test.dart';

import '../helpers/mock_http.dart';

void main() {
  group('RateLimitingFilter', () {
    test('enforces capacity and refills tokens over time', () async {
      var now = DateTime.utc(2026, 1, 1, 12, 0, 0);
      final filter = RateLimitingFilter(
        config: const RateLimitConfig(
          capacity: 2,
          refillTokens: 2,
          refillPeriod: Duration(seconds: 10),
        ),
        clock: () => now,
      );

      // 1st request allowed
      final res1 = MockServerHttpResponse();
      final next1 = RecordingFilterChain();
      await filter.doFilter(
        MockServerHttpRequest(headers: {'X-Forwarded-For': '10.0.0.1'}),
        res1,
        next1,
      );
      expect(next1.called, isTrue);
      expect(res1.getHeaders().getFirst('X-RateLimit-Remaining'), equals('1'));

      // 2nd request allowed
      final res2 = MockServerHttpResponse();
      final next2 = RecordingFilterChain();
      await filter.doFilter(
        MockServerHttpRequest(headers: {'X-Forwarded-For': '10.0.0.1'}),
        res2,
        next2,
      );
      expect(next2.called, isTrue);
      expect(res2.getHeaders().getFirst('X-RateLimit-Remaining'), equals('0'));

      // 3rd request blocked (429 Too Many Requests)
      final res3 = MockServerHttpResponse();
      final next3 = RecordingFilterChain();
      await filter.doFilter(
        MockServerHttpRequest(headers: {'X-Forwarded-For': '10.0.0.1'}),
        res3,
        next3,
      );
      expect(next3.called, isFalse);
      expect(res3.status, equals(HttpStatus.TOO_MANY_REQUESTS));
      expect(res3.getHeaders().getFirst('Retry-After'), isNotNull);

      // Advance clock by 5 seconds -> 1 token refilled
      now = now.add(const Duration(seconds: 5));
      final res4 = MockServerHttpResponse();
      final next4 = RecordingFilterChain();
      await filter.doFilter(
        MockServerHttpRequest(headers: {'X-Forwarded-For': '10.0.0.1'}),
        res4,
        next4,
      );
      expect(next4.called, isTrue);
    });
  });
}
