import 'package:jetleaf_core/lang.dart' show IllegalStateException, RuntimeException;
import 'package:jetleaf_security/jetleaf_security.dart';
import 'package:test/test.dart';

void main() {
  group('Security exception hierarchy', () {
    test('every security exception is a Jetleaf RuntimeException', () {
      final exceptions = <SecurityException>[
        SecurityException('base'),
        AuthenticationException('auth'),
        BadCredentialsException(),
        UsernameNotFoundException('alice'),
        AccountStatusException('status'),
        DisabledException(),
        LockedException(),
        AccountExpiredException(),
        CredentialsExpiredException(),
        AccessDeniedException(),
        InsufficientAuthenticationException(),
        InvalidCsrfTokenException(),
        JwtValidationException('invalid'),
      ];

      for (final exception in exceptions) {
        expect(exception, isA<RuntimeException>(), reason: '$exception');
      }
    });

    test('errors keep a readable message and optional cause', () {
      final cause = IllegalStateException('root cause');
      final error = BadCredentialsException('rejected', cause);

      expect(error.message, 'rejected');
      expect(error.cause, same(cause));
      expect(error.toString(), contains('BadCredentialsException'));
    });
  });
}
