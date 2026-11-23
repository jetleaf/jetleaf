import 'package:jetleaf_core/intercept.dart';
import 'package:jetleaf_core/lang.dart';

import 'package:jetleaf_security/annotation.dart';
import 'package:jetleaf_security/core.dart';
import 'package:jetleaf_web/annotation.dart';

/// Demonstrates parameter binding, principal property access and
/// post-invocation checks.
@RestController()
class OrganizationController with Interceptable {
  late final Class<OrganizationController> _class =
      Class.fromQualifiedName(
        'package:jetleaf_security_example/controller/organization_controller.dart.OrganizationController',
      );

  @GetMapping(path: '/api/orgs/{orgId}/reports')
  @PreAuthorize("hasRole('ADMIN') or #orgId == principal.organizationId")
  Future<Map<String, Object?>> reports(
    @PathVariable(value: 'orgId') String orgId,
  ) =>
      when(
        () async => {'orgId': orgId, 'reports': 3},
        this,
        'reports',
        ExecutableArgument.optional(positional: [orgId]),
        _class,
      );

  @GetMapping(path: '/api/orgs/{orgId}/audit')
  @PostAuthorize('returnObject.ownerId == authentication.name')
  Future<Map<String, Object?>> audit(
    @PathVariable(value: 'orgId') String orgId,
  ) =>
      when(
        () async => {
          'orgId': orgId,
          'ownerId': SecurityContextHolder.getContext().authentication?.name,
        },
        this,
        'audit',
        ExecutableArgument.optional(positional: [orgId]),
        _class,
      );

  @GetMapping(path: '/api/orgs/reports')
  @PreAuthorize("hasAuthority('reports:read')")
  Future<Map<String, Object?>> allReports() => when(
        () async => {'reports': ['Q1', 'Q2']},
        this,
        'allReports',
        ExecutableArgument.optional(),
        _class,
      );
}
