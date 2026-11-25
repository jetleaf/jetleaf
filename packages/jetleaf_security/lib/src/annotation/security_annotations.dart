import 'package:jetleaf_core/lang.dart';
import 'package:meta/meta_meta.dart';

/// {@template pre_authorize}
/// Declares a security expression that must evaluate to `true` before the
/// annotated method is invoked.
///
/// The expression is evaluated against the current authentication and can
/// reference method arguments. A failed evaluation prevents invocation and
/// raises an access-denied error.
///
/// - Targets methods and classes; on a class it applies to every method.
/// - Equality and [toString] are based on [value].
///
/// ### Example
/// ```dart
/// @PreAuthorize("hasRole('ADMIN') or #userId == authentication.name")
/// void updateAccount(String userId) { ... }
/// ```
///
/// ### See also
/// - [PostAuthorize] — checks an expression after invocation.
/// {@endtemplate}
@Target({TargetKind.method, TargetKind.classType})
final class PreAuthorize extends ReflectableAnnotation with EqualsAndHashCode {
  /// The security expression to evaluate before method execution.
  final String value;

  /// {@macro pre_authorize}
  const PreAuthorize(this.value);

  @override
  Type get annotationType => PreAuthorize;

  @override
  List<Object?> equalizedProperties() => [runtimeType, value];

  @override
  String toString() => 'PreAuthorize($value)';
}

/// {@template post_authorize}
/// Declares a security expression that must evaluate to `true` after the
/// annotated method returns.
///
/// The expression may reference `returnObject`, allowing authorization to be
/// based on the value produced by the invocation. A failed evaluation raises an
/// access-denied error after the method body has already run.
///
/// - Targets methods and classes.
/// - Equality and [toString] are based on [value].
///
/// ### Example
/// ```dart
/// @PostAuthorize("returnObject.owner == authentication.name")
/// Document loadDocument(String id) => repository.find(id);
/// ```
///
/// ### See also
/// - [PreAuthorize] — checks an expression before invocation.
/// {@endtemplate}
@Target({TargetKind.method, TargetKind.classType})
final class PostAuthorize extends ReflectableAnnotation with EqualsAndHashCode {
  /// The security expression to evaluate after method execution.
  final String value;

  /// {@macro post_authorize}
  const PostAuthorize(this.value);

  @override
  Type get annotationType => PostAuthorize;

  @override
  List<Object?> equalizedProperties() => [runtimeType, value];

  @override
  String toString() => 'PostAuthorize($value)';
}

/// {@template secured}
/// Declares the authorities required to invoke the annotated method or class.
///
/// At least one entry in [value] must be present on the current authentication.
/// Values are compared verbatim, so callers control whether names use a role
/// prefix or another convention.
///
/// - Targets methods and classes.
/// - An empty list grants access to nobody.
/// - Equality and [toString] are based on [value].
///
/// ### Example
/// ```dart
/// @Secured(['ROLE_ADMIN', 'users:write'])
/// void saveUser(User user) { ... }
/// ```
///
/// ### See also
/// - [RolesAllowed] — the role-oriented alternative.
/// {@endtemplate}
@Target({TargetKind.method, TargetKind.classType})
final class Secured extends ReflectableAnnotation with EqualsAndHashCode {
  /// Required authorities; any match grants access.
  final List<String> value;

  /// {@macro secured}
  const Secured(this.value);

  @override
  Type get annotationType => Secured;

  @override
  List<Object?> equalizedProperties() => [runtimeType, value];

  @override
  String toString() => 'Secured($value)';
}

/// {@template roles_allowed}
/// Declares the roles permitted to invoke the annotated method or class.
///
/// Role names are normalized with a `ROLE_` prefix before comparison when the
/// prefix is not already present, so callers may write either `ADMIN` or
/// `ROLE_ADMIN`.
///
/// - Targets methods and classes.
/// - At least one listed role must be granted.
/// - Equality and [toString] are based on [value].
///
/// ### Example
/// ```dart
/// @RolesAllowed(['ADMIN', 'AUDITOR'])
/// Report buildReport() => ...;
/// ```
///
/// ### See also
/// - [Secured] — the authority-oriented alternative.
/// {@endtemplate}
@Target({TargetKind.method, TargetKind.classType})
final class RolesAllowed extends ReflectableAnnotation with EqualsAndHashCode {
  /// Allowed role names, normalized with `ROLE_` when the prefix is absent.
  final List<String> value;

  /// {@macro roles_allowed}
  const RolesAllowed(this.value);

  @override
  Type get annotationType => RolesAllowed;

  @override
  List<Object?> equalizedProperties() => [runtimeType, value];

  @override
  String toString() => 'RolesAllowed($value)';
}