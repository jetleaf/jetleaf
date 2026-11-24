import 'package:jetleaf_core/intercept.dart';
import 'package:jetleaf_core/lang.dart';

import 'package:jetleaf_security/annotation.dart';
import 'package:jetleaf_web/annotation.dart';

/// Demonstrates `@Secured`, `@RolesAllowed` and role-hierarchy expansion.
@RestController()
class AdminController with Interceptable {
  late final Class<AdminController> _class =
      Class.fromQualifiedName(
        'package:jetleaf_security_example/controller/admin_controller.dart.AdminController',
      );

  @GetMapping(path: '/api/admin/stats')
  @Secured(['ROLE_ADMIN'])
  Future<Map<String, Object?>> stats() => when(
        () async => {
          'users': 3,
          'sessions': 12,
          'signing': 'argon2id + bcrypt + pbkdf2',
        },
        this,
        'stats',
        ExecutableArgument.optional(),
        _class,
      );

  @GetMapping(path: '/api/admin/user-access')
  @PreAuthorize("hasRole('USER')")
  Future<Map<String, Object?>> userAccess() => when(
        () async => {'grantedByHierarchy': true},
        this,
        'userAccess',
        ExecutableArgument.optional(),
        _class,
      );

  @GetMapping(path: '/api/admin/audit')
  @RolesAllowed(['ADMIN'])
  Future<Map<String, Object?>> audit() => when(
        () async => {'events': ['login', 'refresh', 'denied']},
        this,
        'audit',
        ExecutableArgument.optional(),
        _class,
      );
}
