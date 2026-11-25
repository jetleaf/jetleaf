import 'package:jetleaf_core/lang.dart' show IllegalStateException;
import 'package:jetleaf_security/jetleaf_security.dart';
import 'package:test/test.dart';

class _RecordingPublisher implements AuthenticationEventPublisher {
  final List<AuthenticationEvent> events = [];

  @override
  void publishAuthenticationSuccess(Authentication authentication) =>
      events.add(AuthenticationSuccessEvent(authentication));

  @override
  void publishAuthenticationFailure(
    Authentication authentication,
    AuthenticationException exception,
  ) =>
      events.add(AuthenticationFailureEvent(authentication, exception));
}

class _ThrowingPublisher implements AuthenticationEventPublisher {
  @override
  void publishAuthenticationSuccess(Authentication authentication) =>
      throw IllegalStateException('publisher failed');

  @override
  void publishAuthenticationFailure(
    Authentication authentication,
    AuthenticationException exception,
  ) =>
      throw IllegalStateException('publisher failed');
}

void main() {
  group('ProviderManager', () {
    test('publishes exactly one success event', () async {
      // Use JwtTokenProvider so no user store is needed.
      final jwt = JwtTokenProvider.hmac(secret: 'provider-manager-test-secret-32-bytes!');
      final publisher = _RecordingPublisher();
      final manager = ProviderManager([jwt], eventPublisher: publisher);
      final token = jwt.generateAccessToken(subject: 'alice');

      await manager.authenticate(JwtAuthenticationToken.unauthenticated(token));

      expect(publisher.events, hasLength(1));
      expect(publisher.events.single, isA<AuthenticationSuccessEvent>());
    });

    test('publishes a failure event carrying the exception', () async {
      final jwt = JwtTokenProvider.hmac(secret: 'provider-manager-test-secret-32-bytes!');
      final publisher = _RecordingPublisher();
      final manager = ProviderManager([jwt], eventPublisher: publisher);

      await expectLater(
        manager.authenticate(JwtAuthenticationToken.unauthenticated('bad')),
        throwsA(isA<AuthenticationException>()),
      );
      expect(publisher.events.single, isA<AuthenticationFailureEvent>());
    });

    test('a failing publisher does not change the outcome', () async {
      final jwt = JwtTokenProvider.hmac(secret: 'provider-manager-test-secret-32-bytes!');
      final manager = ProviderManager(
        [jwt],
        eventPublisher: _ThrowingPublisher(),
      );
      final token = jwt.generateAccessToken(subject: 'alice');

      final result =
          await manager.authenticate(JwtAuthenticationToken.unauthenticated(token));

      expect(result.isAuthenticated, isTrue);
    });

    test('erases credentials on the returned token', () async {
      final jwt = JwtTokenProvider.hmac(secret: 'provider-manager-test-secret-32-bytes!');
      final manager = ProviderManager([jwt]);
      final token = jwt.generateAccessToken(subject: 'alice');

      final result =
          await manager.authenticate(JwtAuthenticationToken.unauthenticated(token));

      expect(result.credentials, isNull);
    });
  });
}