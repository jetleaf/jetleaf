import 'package:jetleaf_web/annotation.dart';

import '../audit/authentication_audit_listener.dart';

/// Unauthenticated endpoints used to prove `permitAll()` rules.
@RestController()
class PublicController {
  @GetMapping(path: '/api/public/health')
  Future<Map<String, Object?>> health() async => {
        'status': 'UP',
        'service': 'jetleaf-security-example',
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      };

  @GetMapping(path: '/api/public/events')
  Future<Map<String, Object?>> events() async => {
        'events': AuthenticationAuditListener.events.toList(),
      };

  @GetMapping(path: '/api/public/echo')
  Future<Map<String, Object?>> echo(
    @RequestParam(value: 'message') String message,
  ) async =>
      {'echo': message};
}
