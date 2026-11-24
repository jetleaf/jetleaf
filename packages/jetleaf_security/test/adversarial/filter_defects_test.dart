import 'package:jetleaf_security/jetleaf_security.dart';
import 'package:jetleaf_web/jetleaf_web.dart' hide CorsConfiguration, CorsFilter, CsrfFilter;
import 'package:test/test.dart';

import '../helpers/mock_http.dart';

/// Red-phase tests for defects 7 and 8 in the rewrite specification.
void main() {
  group('Filter defects (red phase)', () {
    test('a CSRF denial is translated into a JSON 403 response', () async {
      final chain = SecurityFilterChain(
        filters: [
          ExceptionTranslationFilter(),
          CsrfFilter(),
        ],
      );
      final request = MockServerHttpRequest(
        method: HttpMethod.POST,
        path: '/api/orders',
      );
      final response = MockServerHttpResponse();
      final next = RecordingFilterChain();

      await FilterChainProxy([chain]).doFilter(request, response, next);

      expect(next.called, isFalse);
      expect(response.status, equals(HttpStatus.FORBIDDEN));
      expect(response.bodyAsString, isNotEmpty);
    });

    test('a preflight request for a disallowed method is rejected', () async {
      final filter = CorsFilter(
        const CorsConfiguration(
          allowedOrigins: ['https://app.example.com'],
          allowedMethods: ['GET'],
        ),
      );
      final request = MockServerHttpRequest(
        method: HttpMethod.OPTIONS,
        path: '/api/orders',
        headers: {
          'Origin': 'https://app.example.com',
          'Access-Control-Request-Method': 'DELETE',
        },
      );
      final response = MockServerHttpResponse();

      await filter.doFilter(request, response, RecordingFilterChain());

      expect(
        response.status,
        isNot(HttpStatus.NO_CONTENT),
        reason: 'An unapproved preflight must not be answered with 204',
      );
    });
  });
}
