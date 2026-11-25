import 'package:jetleaf_security/core.dart';
import 'package:jetleaf_web/annotation.dart';

/// Demonstrates the second, session-backed filter chain with Basic auth.
@RestController()
class SessionController {
  @GetMapping(path: '/session/profile')
  Future<Map<String, Object?>> profile() async {
    final authentication = SecurityContextHolder.getContext().authentication;
    return {
      'name': authentication?.name,
      'authenticated': authentication?.isAuthenticated ?? false,
      'authorities': authentication?.authorities
              .map((authority) => authority.authority)
              .toList() ??
          const [],
    };
  }
}