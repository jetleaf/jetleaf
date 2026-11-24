import 'package:jetleaf_security/authentication.dart';
import 'package:jetleaf_security/authorization.dart';
import 'package:jetleaf_security/config.dart';
import 'package:jetleaf_security/core.dart';
import 'package:jetleaf_security/filter.dart';
import 'package:jetleaf_security/jwt.dart';
import 'package:jetleaf_web/jetleaf_web.dart';
import 'package:test/test.dart';

import '../helpers/mock_http.dart';

void main() {
  group('Production hardening', () {
    test('firewall rejects ambiguous paths before the chain', () async {
      final chain = (HttpSecurity()
            ..authorizeHttpRequests((auth) => auth.anyRequest().permitAll()))
          .build();
      final response = MockServerHttpResponse();
      final next = RecordingFilterChain();

      await FilterChainProxy([chain]).doFilter(
        MockServerHttpRequest(method: HttpMethod.GET, path: '/api//admin/stats'),
        response,
        next,
      );

      expect(next.called, isFalse);
      expect(response.status, HttpStatus.BAD_REQUEST);
    });

    test('anonymous requests get an anonymous token in the context', () async {
      final manager = ProviderManager([
        JwtTokenProvider.hmac(secret: 'regression-test-signing-secret-32-bytes!'),
      ]);
      final chain = (HttpSecurity()
            ..authenticationManager(manager)
            ..authorizeHttpRequests((auth) => auth.anyRequest().permitAll()))
          .build();
      Authentication? observed;
      final next = RecordingFilterChain(
        onNext: (_, _) => observed =
            SecurityContextHolder.getContext().authentication,
      );

      await FilterChainProxy([chain]).doFilter(
        MockServerHttpRequest(path: '/api/public/health'),
        MockServerHttpResponse(),
        next,
      );

      expect(observed, isA<AnonymousAuthenticationToken>());
    });

    test('CSRF ignore prefixes match on segment boundaries', () async {
      final chain = (HttpSecurity()
            ..csrf((csrf) => csrf.ignoringRequestMatchers(['/api/webhook']))
            ..authorizeHttpRequests((auth) => auth.anyRequest().permitAll()))
          .build();
      final response = MockServerHttpResponse();
      final next = RecordingFilterChain();

      await FilterChainProxy([chain]).doFilter(
        MockServerHttpRequest(
          method: HttpMethod.POST,
          path: '/api/webhook_secret',
        ),
        response,
        next,
      );

      expect(next.called, isFalse);
      expect(response.status, HttpStatus.FORBIDDEN);
    });

    test('.access(...) rules use the configured role hierarchy', () async {
      final jwt = JwtTokenProvider.hmac(
        secret: 'access-rule-test-signing-secret-32-bytes!',
      );
      final chain = (HttpSecurity()
            ..sessionManagement(
              (session) =>
                  session.sessionCreationPolicy(SessionCreationPolicy.stateless),
            )
            ..authenticationManager(ProviderManager([jwt]))
            ..roleHierarchy(RoleHierarchy('ROLE_ADMIN > ROLE_USER'))
            ..authorizeHttpRequests(
              (auth) => auth.anyRequest().access("hasRole('USER')"),
            ))
          .build();
      final token = jwt.generateAccessToken(
        subject: 'admin',
        roles: const ['ROLE_ADMIN'],
      );
      final next = RecordingFilterChain();

      await FilterChainProxy([chain]).doFilter(
        MockServerHttpRequest(
          path: '/api/admin/stats',
          headers: {'Authorization': 'Bearer $token'},
        ),
        MockServerHttpResponse(),
        next,
      );

      expect(next.called, isTrue);
    });

    test('anonymous context does not create an HTTP session', () async {
      final request = MockServerHttpRequest();
      const repository = HttpSessionSecurityContextRepository();

      await repository.saveContext(
        SecurityContext(AnonymousAuthenticationToken()),
        request,
        MockServerHttpResponse(),
      );

      expect(request.session, isNull);
    });
  });
}
