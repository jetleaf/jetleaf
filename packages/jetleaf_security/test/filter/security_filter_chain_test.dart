import 'package:jetleaf_security/jetleaf_security.dart';
import 'package:jetleaf_web/jetleaf_web.dart' hide CorsConfiguration;
import 'package:test/test.dart';

import '../helpers/mock_http.dart';

void main() {
  group('SecurityFilterChain & HttpSecurity', () {
    late JwtTokenProvider jwtProvider;
    late SecurityFilterChain chain;

    setUp(() {
      jwtProvider = JwtTokenProvider.hmac(
        secret: 'integration-test-secret-key-32-bytes!',
      );
      final authManager = ProviderManager([jwtProvider]);

      chain = (HttpSecurity()
            ..csrf((c) => c.disable())
            ..cors((c) => c.configuration(
                  const CorsConfiguration(
                    allowedOrigins: ['https://app.example.com'],
                  ),
                ))
            ..sessionManagement(
              (s) => s.sessionCreationPolicy(SessionCreationPolicy.stateless),
            )
            ..authenticationManager(authManager)
            ..authorizeHttpRequests((auth) {
              auth.requestMatchers(['/health', '/api/auth/**']).permitAll();
              auth.requestMatcher('/api/admin/**').hasRole('ADMIN');
              auth.anyRequest().authenticated();
            }))
          .build();
    });

    test('allows permitAll routes without authentication and sets security headers', () async {
      final req = MockServerHttpRequest(path: '/health');
      final res = MockServerHttpResponse();
      final next = RecordingFilterChain();

      await FilterChainProxy([chain]).doFilter(req, res, next);

      expect(next.called, isTrue);
      expect(res.status, equals(HttpStatus.OK));
      expect(res.getHeaders().getFirst('X-Content-Type-Options'), equals('nosniff'));
      expect(res.getHeaders().getFirst('X-Frame-Options'), equals('DENY'));
    });

    test('returns 401 Unauthorized when accessing protected route without token', () async {
      final req = MockServerHttpRequest(path: '/api/orders');
      final res = MockServerHttpResponse();
      final next = RecordingFilterChain();

      await FilterChainProxy([chain]).doFilter(req, res, next);

      expect(next.called, isFalse);
      expect(res.status, equals(HttpStatus.UNAUTHORIZED));
      expect(res.getHeaders().getFirst('WWW-Authenticate'), contains('Bearer'));
    });

    test('returns 403 Forbidden when authenticated user lacks required role', () async {
      final token = jwtProvider.generateAccessToken(
        subject: 'bob',
        roles: ['ROLE_USER'],
      );
      final req = MockServerHttpRequest(
        path: '/api/admin/users',
        headers: {'Authorization': 'Bearer $token'},
      );
      final res = MockServerHttpResponse();
      final next = RecordingFilterChain();

      await FilterChainProxy([chain]).doFilter(req, res, next);

      expect(next.called, isFalse);
      expect(res.status, equals(HttpStatus.FORBIDDEN));
    });

    test('allows authorized request and clears SecurityContext after completion', () async {
      final token = jwtProvider.generateAccessToken(
        subject: 'alice',
        roles: ['ROLE_ADMIN'],
      );
      final req = MockServerHttpRequest(
        path: '/api/admin/users',
        headers: {'Authorization': 'Bearer $token'},
      );
      final res = MockServerHttpResponse();
      String? observedPrincipal;
      final next = RecordingFilterChain(
        onNext: (_, _) {
          observedPrincipal = SecurityContextHolder.getContext().authentication?.name;
        },
      );

      await FilterChainProxy([chain]).doFilter(req, res, next);

      expect(next.called, isTrue);
      expect(observedPrincipal, equals('alice'));
      expect(SecurityContextHolder.getContext().authentication, isNull);
    });

    test('handles CORS preflight OPTIONS request', () async {
      final req = MockServerHttpRequest(
        method: HttpMethod.OPTIONS,
        path: '/api/orders',
        headers: {
          'Origin': 'https://app.example.com',
          'Access-Control-Request-Method': 'POST',
        },
      );
      final res = MockServerHttpResponse();
      final next = RecordingFilterChain();

      await FilterChainProxy([chain]).doFilter(req, res, next);

      expect(next.called, isFalse);
      expect(res.status, equals(HttpStatus.NO_CONTENT));
      expect(
        res.getHeaders().getFirst('Access-Control-Allow-Origin'),
        equals('https://app.example.com'),
      );
    });
  });
}