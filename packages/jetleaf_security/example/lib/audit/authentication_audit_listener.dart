import 'package:jetleaf_core/annotation.dart';

import 'package:jetleaf_security/authentication.dart';

/// Demonstrates that authentication events reach user `@EventListener` pods
/// through the application event bus.
@Component()
class AuthenticationAuditListener {
  /// Recent event descriptions, exposed by the public audit endpoint.
  static final List<String> events = [];

  @EventListener()
  void onSuccess(AuthenticationSuccessEvent event) {
    events.add('SUCCESS ${event.authentication.name}');
  }

  @EventListener()
  void onFailure(AuthenticationFailureEvent event) {
    events.add('FAILURE ${event.authentication.name}: ${event.exception.message}');
  }
}
