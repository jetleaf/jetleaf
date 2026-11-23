import 'package:jetleaf_security/authentication.dart';
import 'package:jetleaf_security/core.dart';

/// Demonstrates the authentication event seam with an in-memory audit log.
final class AuditEventPublisher implements AuthenticationEventPublisher {
  AuditEventPublisher();

  final List<String> events = [];

  @override
  void publishAuthenticationSuccess(Authentication authentication) {
    events.add('SUCCESS ${authentication.name}');
  }

  @override
  void publishAuthenticationFailure(
    Authentication authentication,
    AuthenticationException exception,
  ) {
    events.add('FAILURE ${authentication.name}: ${exception.message}');
  }
}
