import '../core/typedefs.dart';
import 'authorization_decision.dart';
import 'authorization_manager.dart';

/// {@template authorization_managers}
/// Factory helpers for composing [AuthorizationManager] instances.
///
/// The helpers in this class combine managers with boolean logic:
/// [anyOf] grants when at least one delegate grants, and [allOf] grants only
/// when every delegate grants. Both short-circuit, so later delegates are not
/// consulted once the outcome is decided.
///
/// ### Contract and invariants
/// - Returned managers consult their delegates in the order supplied.
/// - [anyOf] stops at the first granted decision; [allOf] stops at the first
///   denial.
/// - An empty delegate list makes [anyOf] deny and [allOf] grant.
/// - Delegate lists are held by reference; callers should not mutate them while
///   checks are in progress.
///
/// ### Example
/// ```dart
/// final manager = AuthorizationManagers.allOf<String>([
///   AuthenticatedAuthorizationManager<String>(),
///   HasAuthorityManager<String>('ROLE_ADMIN'),
/// ]);
///
/// final decision = manager.check(() => currentAuthentication(), 'resource');
/// ```
///
/// ### See also
/// - [AuthorizationManager]
/// - [AuthorizationDecision]
/// {@endtemplate}
abstract final class AuthorizationManagers {
  /// {@template authorization_managers._constructor}
  /// Private constructor preventing instantiation of this utility class.
  /// {@endtemplate}
  /// {@macro authorization_managers}
  const AuthorizationManagers._();

  /// Creates a manager that grants when any [delegates] grants.
  ///
  /// Delegates are evaluated in order and evaluation stops at the first
  /// granted decision.
  ///
  /// ### Parameters
  /// - [delegates] — the managers to combine; an empty list always denies.
  ///
  /// ### Returns
  /// An [AuthorizationManager] implementing the "any of" rule.
  static AuthorizationManager<T> anyOf<T>(List<AuthorizationManager<T>> delegates) => _AnyOfAuthorizationManager(delegates);

  /// Creates a manager that grants only when every [delegates] grants.
  ///
  /// Delegates are evaluated in order and evaluation stops at the first
  /// denial.
  ///
  /// ### Parameters
  /// - [delegates] — the managers to combine; an empty list always grants.
  ///
  /// ### Returns
  /// An [AuthorizationManager] implementing the "all of" rule.
  static AuthorizationManager<T> allOf<T>(List<AuthorizationManager<T>> delegates) => _AllOfAuthorizationManager(delegates);
}

/// {@template permit_all_authorization_manager}
/// An [AuthorizationManager] that always grants access.
///
/// Because it never reads the authentication callback, it is the cheapest rule
/// for public endpoints.
///
/// ### Contract and invariants
/// - [check] always returns [AuthorizationDecision.granted].
/// - The class is stateless and has a `const` constructor.
///
/// ### Example
/// ```dart
/// const manager = PermitAllAuthorizationManager<RequestAuthorizationContext>();
/// assert(manager.check(() => null, context).isGranted);
/// ```
///
/// ### See also
/// - [DenyAllAuthorizationManager]
/// - [AuthorizationManagers]
/// {@endtemplate}
final class PermitAllAuthorizationManager<T> implements AuthorizationManager<T> {
  /// {@macro permit_all_authorization_manager}
  const PermitAllAuthorizationManager();

  /// Returns [AuthorizationDecision.granted] without consulting its arguments.
  ///
  /// ### Parameters
  /// - [authentication] — ignored.
  /// - [context] — ignored.
  ///
  /// ### Returns
  /// [AuthorizationDecision.granted].
  @override
  AuthorizationDecision check(AuthenticationSupplier authentication, T context) => AuthorizationDecision.granted;
}

/// {@template deny_all_authorization_manager}
/// An [AuthorizationManager] that always denies access.
///
/// It is useful for endpoints that are permanently disabled or for building
/// composed rules with an explicit deny fallback.
///
/// ### Contract and invariants
/// - [check] always returns [AuthorizationDecision.denied].
/// - The class is stateless and has a `const` constructor.
///
/// ### Example
/// ```dart
/// const manager = DenyAllAuthorizationManager<RequestAuthorizationContext>();
/// assert(!manager.check(() => null, context).isGranted);
/// ```
///
/// ### See also
/// - [PermitAllAuthorizationManager]
/// - [AuthorizationManagers]
/// {@endtemplate}
final class DenyAllAuthorizationManager<T> implements AuthorizationManager<T> {
  /// {@macro deny_all_authorization_manager}
  const DenyAllAuthorizationManager();

  /// Returns [AuthorizationDecision.denied] without consulting its arguments.
  ///
  /// ### Parameters
  /// - [authentication] — ignored.
  /// - [context] — ignored.
  ///
  /// ### Returns
  /// [AuthorizationDecision.denied].
  @override
  AuthorizationDecision check(AuthenticationSupplier authentication, T context) => AuthorizationDecision.denied;
}

/// {@template authorization_managers._any_of_authorization_manager}
/// Internal manager implementing the "any delegate grants" rule.
///
/// ### Contract and invariants
/// - Created only by [AuthorizationManagers.anyOf].
/// - Stops at the first granted decision and otherwise denies.
/// {@endtemplate}
final class _AnyOfAuthorizationManager<T> implements AuthorizationManager<T> {
  /// Delegates consulted in order.
  final List<AuthorizationManager<T>> delegates;

  /// {@macro authorization_managers._any_of_authorization_manager}
  const _AnyOfAuthorizationManager(this.delegates);

  /// Returns the first granted decision, or denies if none grants.
  ///
  /// ### Parameters
  /// - [authentication] — authentication callback forwarded to each delegate.
  /// - [context] — context forwarded to each delegate.
  ///
  /// ### Returns
  /// [AuthorizationDecision.granted] on the first grant, otherwise
  /// [AuthorizationDecision.denied].
  @override
  AuthorizationDecision check(AuthenticationSupplier authentication, T context) {
    for (final delegate in delegates) {
      if (delegate.check(authentication, context).isGranted) {
        return AuthorizationDecision.granted;
      }
    }

    return AuthorizationDecision.denied;
  }
}

/// {@template authorization_managers._all_of_authorization_manager}
/// Internal manager implementing the "every delegate grants" rule.
///
/// ### Contract and invariants
/// - Created only by [AuthorizationManagers.allOf].
/// - Stops at the first denial and otherwise grants.
/// {@endtemplate}
final class _AllOfAuthorizationManager<T> implements AuthorizationManager<T> {
  /// Delegates consulted in order.
  final List<AuthorizationManager<T>> delegates;

  /// {@macro authorization_managers._all_of_authorization_manager}
  const _AllOfAuthorizationManager(this.delegates);

  /// Returns the first denial, or grants if every delegate grants.
  ///
  /// ### Parameters
  /// - [authentication] — authentication callback forwarded to each delegate.
  /// - [context] — context forwarded to each delegate.
  ///
  /// ### Returns
  /// [AuthorizationDecision.denied] on the first denial, otherwise
  /// [AuthorizationDecision.granted].
  @override
  AuthorizationDecision check(AuthenticationSupplier authentication, T context) {
    for (final delegate in delegates) {
      if (!delegate.check(authentication, context).isGranted) {
        return AuthorizationDecision.denied;
      }
    }
    return AuthorizationDecision.granted;
  }
}