import '../core/typedefs.dart';
import '../core/authentication.dart';
import 'authorization_decision.dart';
import 'authorization_manager.dart';
import 'role_hierarchy.dart';

/// {@template authority_authorization_manager}
/// Checks whether the authenticated principal holds a single authority or role.
///
/// The manager compares [authority] against the granted authorities carried by
/// the current [Authentication]. When a [RoleHierarchy] is configured, the
/// principal's authorities are first expanded to everything reachable through
/// the hierarchy, so holding a senior role implies holding its subordinates.
///
/// ### Contract and invariants
/// - A `null` authentication, or one whose `isAuthenticated` is `false`, is denied.
/// - The comparison is an exact string match; [authority] is used verbatim,
///   including any `ROLE_` prefix.
/// - [hasRole] normalizes a bare role name by adding the `ROLE_` prefix, while
///   the main constructor does not.
/// - When [roleHierarchy] is `null`, only the authorities actually granted are
///   considered.
/// - The generic [context] is ignored; the decision depends only on the
///   authentication supplier and the configured authority.
///
/// ### Example
/// ```dart
/// final byAuthority =
///     AuthorityAuthorizationManager<RequestAuthorizationContext>('users:write');
/// final byRole = AuthorityAuthorizationManager<RequestAuthorizationContext>.hasRole('ADMIN');
///
/// // Expand ROLE_ADMIN into its implied roles before comparing.
/// final hierarchy = RoleHierarchy('ROLE_ADMIN > ROLE_MODERATOR');
/// final withHierarchy = byRole.withHierarchy(hierarchy);
/// ```
/// {@endtemplate}
final class AuthorityAuthorizationManager<T> implements AuthorizationManager<T> {
  /// Required authority string, including any `ROLE_` prefix.
  ///
  /// This value is compared as-is against each granted authority. Use [hasRole]
  /// when a bare role name should be prefixed automatically.
  final String authority;

  /// Optional role hierarchy used to expand granted authorities.
  ///
  /// When set, a principal holding a role also holds every role reachable from
  /// it, as computed by [RoleHierarchy.getReachableGrantedAuthorities].
  final RoleHierarchy? roleHierarchy;

  /// {@macro authority_authorization_manager}
  ///
  /// Creates a manager requiring exactly [authority].
  ///
  /// ### Parameters
  /// - [authority]: the authority string to match, prefix included.
  /// - [roleHierarchy]: optional expansion rules for implied authorities.
  const AuthorityAuthorizationManager(this.authority, {this.roleHierarchy});

  /// {@template authority_authorization_manager_has_role}
  /// Creates a manager that requires [role], prefixed with `ROLE_` when needed.
  ///
  /// A name that already starts with `ROLE_` is left untouched, so callers may
  /// pass either `ADMIN` or `ROLE_ADMIN` interchangeably.
  ///
  /// ### Parameters
  /// - [role]: the role name to require.
  /// - [roleHierarchy]: optional expansion rules for implied authorities.
  ///
  /// ### Returns
  /// An [AuthorityAuthorizationManager] whose [authority] is the normalized
  /// role name.
  /// {@endtemplate}
  /// {@macro authority_authorization_manager}
  factory AuthorityAuthorizationManager.hasRole(String role, {
    RoleHierarchy? roleHierarchy,
  }) {
    final normalized = role.startsWith('ROLE_') ? role : 'ROLE_$role';
    return AuthorityAuthorizationManager<T>(
      normalized,
      roleHierarchy: roleHierarchy,
    );
  }

  /// {@template authority_authorization_manager_with_hierarchy}
  /// Returns a copy of this manager that expands roles through [hierarchy].
  ///
  /// The original manager is left unchanged; the returned instance keeps the
  /// same [authority] and adds the supplied hierarchy.
  ///
  /// ### Parameters
  /// - [hierarchy]: the reachability rules applied before matching.
  ///
  /// ### Returns
  /// A new [AuthorityAuthorizationManager] using [hierarchy].
  /// {@endtemplate}
  AuthorityAuthorizationManager<T> withHierarchy(RoleHierarchy hierarchy) => AuthorityAuthorizationManager<T>(authority, roleHierarchy: hierarchy);

  /// {@template authority_authorization_manager_check}
  /// Decides whether the current authentication grants [authority].
  ///
  /// The authentication is resolved lazily through [authentication]. When a
  /// hierarchy is configured, the principal's authorities are expanded before
  /// the exact-match comparison. The [context] value is ignored.
  ///
  /// ### Parameters
  /// - [authentication]: supplier for the current [Authentication], or `null`
  ///   when no authentication is present.
  /// - [context]: the caller's context; ignored by this manager.
  ///
  /// ### Returns
  /// A granted [AuthorizationDecision] as soon as a matching authority is
  /// found, otherwise a denied decision.
  ///
  /// ### Example
  /// ```dart
  /// final decision = manager.check(() => currentAuthentication, context);
  /// print(decision.isGranted); // true when ROLE_ADMIN is granted
  /// ```
  /// {@endtemplate}
  @override
  AuthorizationDecision check(AuthenticationSupplier authentication, T context) {
    final auth = authentication();
    if (auth == null || !auth.isAuthenticated) {
      return const AuthorizationDecision(false);
    }

    final effective = roleHierarchy?.getReachableGrantedAuthorities(auth.authorities) ?? auth.authorities;
    for (final granted in effective) {
      if (granted.authority == authority) {
        return const AuthorizationDecision(true);
      }
    }
    return const AuthorizationDecision(false);
  }
}