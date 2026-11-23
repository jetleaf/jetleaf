import 'package:jetleaf_core/intercept.dart';
import 'package:jetleaf_core/lang.dart';

import 'package:jetleaf_security/annotation.dart';
import 'package:jetleaf_web/annotation.dart';

/// Demonstrates the custom API-key authentication provider and filter.
@RestController()
class ServiceController with Interceptable {
  late final Class<ServiceController> _class =
      Class.fromQualifiedName(
        'package:jetleaf_security_example/controller/service_controller.dart.ServiceController',
      );

  @GetMapping(path: '/api/service/status')
  @PreAuthorize("hasRole('SERVICE')")
  Future<Map<String, Object?>> status() => when(
        () async => {'service': 'billing', 'healthy': true},
        this,
        'status',
        ExecutableArgument.optional(),
        _class,
      );
}
