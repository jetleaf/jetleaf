import 'package:jetleaf_security/jetleaf_security.dart';
import 'package:jetleaf_web/jetleaf_web.dart' hide CorsConfiguration, CorsFilter, CsrfFilter;
import 'package:test/test.dart';

import '../helpers/mock_http.dart';

final class _RecordingFilter extends SecurityFilter {
  @override
  int get order => 0;

  @override
  Future<void> doFilter(
    ServerHttpRequest request,
    ServerHttpResponse response,
    FilterChain chain,
  ) =>
      chain.next(request, response);
}

void main() {
  group('Request security configuration', () {
    test('addFilterBefore and addFilterAfter place filters relative to anchors',
        () {
      final before = _RecordingFilter();
      final after = _RecordingFilter();
      final chain = (HttpSecurity()
            ..addFilterBefore(before, AuthorizationFilter)
            ..addFilterAfter(after, AuthorizationFilter))
          .build();

      final orders = chain.filters.map((f) => f.order).toList();
      expect(orders, contains(-1));
      expect(orders, contains(1));
      expect(orders.indexOf(-1), lessThan(orders.indexOf(0)));
      expect(orders.indexOf(1), greaterThan(orders.indexOf(0)));
    });

    test('stateless policy selects the null context repository', () {
      final chain = (HttpSecurity()
            ..sessionManagement(
              (session) =>
                  session.sessionCreationPolicy(SessionCreationPolicy.stateless),
            ))
          .build();

      final holder = chain.filters.whereType<SecurityContextHolderFilter>().single;
      expect(holder.contextRepository, isA<NullSecurityContextRepository>());
    });

    test('stateful policy selects a session-backed repository', () {
      for (final policy in [
        SessionCreationPolicy.always,
        SessionCreationPolicy.ifRequired,
        SessionCreationPolicy.never,
      ]) {
        final chain = (HttpSecurity()
              ..sessionManagement(
                (session) => session.sessionCreationPolicy(policy),
              ))
            .build();
        final holder =
            chain.filters.whereType<SecurityContextHolderFilter>().single;
        expect(holder.contextRepository, isA<HttpSessionSecurityContextRepository>());
      }
    });

    test('header writers can be replaced', () async {
      final response = MockServerHttpResponse();
      final filter = SecurityHeadersFilter(
        const SecurityHeadersConfig(),
        [StaticHeaderWriter('X-Custom', 'yes')],
      );

      await filter.doFilter(
        MockServerHttpRequest(),
        response,
        RecordingFilterChain(),
      );

      expect(response.getHeaders().getFirst('X-Custom'), 'yes');
      expect(response.getHeaders().getFirst('X-Frame-Options'), isNull);
    });
  });
}
