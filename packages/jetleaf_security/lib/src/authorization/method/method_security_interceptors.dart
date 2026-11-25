import 'package:jetleaf_core/intercept.dart';
import 'package:jetleaf_core/lang.dart';

import '../../core/exceptions.dart';
import '../../core/security_context_holder.dart';
import '../../annotation/security_annotations.dart';
import '../authorization_manager.dart';
import '../role_hierarchy.dart';
import 'method_authorization.dart';
import 'method_security_metadata_source.dart';

/// {@template bind_method_arguments}
/// Binds `#param` names from reflective parameter metadata.
///
/// The invocation's [ExecutableArgument] supplies positional and named values;
/// parameter names come from the reflected [Method], which retains source
/// names in the AOT registry. Positional values are bound by index, named
/// values by name, and all explicitly named arguments are merged last so they
/// take precedence.
///
/// ### Parameters
/// - [invocation]: the invocation whose arguments and method metadata are read.
///
/// ### Returns
/// A map from parameter name to value. An invocation without an
/// [ExecutableArgument] yields an empty map.
///
/// ### Example
/// ```dart
/// final arguments = bindMethodArguments(invocation);
/// // e.g. {'userId': 'alice'} for `getReport(String userId)`.
/// ```
/// {@endtemplate}
Map<String, Object?> bindMethodArguments(MethodInvocation invocation) {
  final bound = <String, Object?>{};
  final arguments = invocation.getArgument();
  if (arguments == null) return bound;

  final positional = arguments.getPositionalArguments();
  final named = arguments.getNamedArguments();
  final parameters = invocation.getMethod().getParameters().toList();

  for (var i = 0; i < parameters.length; i++) {
    final name = parameters[i].getName();
    if (i < positional.length) {
      bound[name] = positional[i];
    } else if (named.containsKey(name)) {
      bound[name] = named[name];
    }
  }
  bound.addAll(named);
  return bound;
}

/// {@template authorization_manager_before_method_interceptor}
/// A Jetleaf `MethodBeforeInterceptor` that enforces pre-authorization.
///
/// The interceptor asks its [metadataSource] for the security attributes on a
/// method, converts each supported attribute into an [AuthorizationManager]
/// through [_managerFor], and throws [AccessDeniedException] when any check
/// denies. Checks run before the target method is invoked.
///
/// ### Contract and invariants
/// - [canIntercept] returns `true` only when the method carries a
///   `PreAuthorize`, `Secured`, or `RolesAllowed` attribute.
/// - A `PostAuthorize` attribute alone does not activate this interceptor.
/// - Arguments are bound with [bindMethodArguments] and exposed to expressions.
/// - The authentication is resolved lazily from [SecurityContextHolder].
/// - A configured [roleHierarchy] is applied to every generated manager.
///
/// ### Example
/// ```dart
/// const interceptor = AuthorizationManagerBeforeMethodInterceptor(
///   metadataSource: PrePostAnnotationSecurityMetadataSource(),
///   roleHierarchy: RoleHierarchy('ROLE_ADMIN > ROLE_USER'),
/// );
/// ```
/// {@endtemplate}
final class AuthorizationManagerBeforeMethodInterceptor implements MethodBeforeInterceptor {
  /// Source of security attributes.
  final MethodSecurityMetadataSource metadataSource;

  /// Optional role hierarchy for expression evaluation.
  final RoleHierarchy? roleHierarchy;

  /// {@macro authorization_manager_before_method_interceptor}
  ///
  /// Creates a pre-authorization interceptor.
  ///
  /// ### Parameters
  /// - [metadataSource]: discovers security attributes; defaults to
  ///   [PrePostAnnotationSecurityMetadataSource].
  /// - [roleHierarchy]: optional rules for expanding implied authorities.
  const AuthorizationManagerBeforeMethodInterceptor({
    this.metadataSource = const PrePostAnnotationSecurityMetadataSource(),
    this.roleHierarchy,
  });

  /// {@template authorization_manager_before_method_interceptor_equalized_properties}
  /// Returns the properties that define this interceptor's equality.
  ///
  /// ### Returns
  /// The [metadataSource] and [roleHierarchy] used by `EqualsAndHashCode`.
  /// {@endtemplate}
  @override
  List<Object?> equalizedProperties() => [runtimeType, metadataSource, roleHierarchy];

  /// {@template authorization_manager_before_method_interceptor_can_intercept}
  /// Reports whether the method carries a supported pre-authorization attribute.
  ///
  /// ### Parameters
  /// - [method]: the method whose attributes are inspected.
  ///
  /// ### Returns
  /// `true` when [metadataSource] exposes a `PreAuthorize`, `Secured`, or
  /// `RolesAllowed` attribute.
  /// {@endtemplate}
  @override
  bool canIntercept(Method method) => metadataSource
    .getAttributes(method)
    .any((a) => a is PreAuthorize || a is Secured || a is RolesAllowed);

  /// {@template authorization_manager_before_method_interceptor_before_invocation}
  /// Checks every pre-authorization attribute before the method proceeds.
  ///
  /// A [MethodAuthorizationContext] is built from the invocation and its bound
  /// arguments. Each recognized attribute is checked in order; the first denial
  /// throws and stops the invocation.
  ///
  /// ### Parameters
  /// - [invocation]: the invocation being guarded.
  ///
  /// ### Returns
  /// A [Future] that completes when all checks pass.
  ///
  /// ### Throws
  /// [AccessDeniedException] when a check denies access.
  /// {@endtemplate}
  @override
  Future<void> beforeInvocation<T>(MethodInvocation<T> invocation) async {
    final context = MethodAuthorizationContext(
      invocation: invocation,
      arguments: bindMethodArguments(invocation),
    );

    for (final attribute in metadataSource.getAttributes(invocation.getMethod())) {
      final manager = _managerFor(attribute);
      if (manager == null) continue;
      if (!manager.check(() => SecurityContextHolder.getContext().authentication, context).isGranted) {
        throw AccessDeniedException('Access denied by $attribute');
      }
    }
  }

  /// {@template authorization_manager_before_method_interceptor_manager_for}
  /// Maps a security attribute to the manager that enforces it.
  ///
  /// `PreAuthorize` maps to [PreAuthorizeAuthorizationManager], `Secured` to
  /// [SecuredAuthorizationManager], and `RolesAllowed` to
  /// [Jsr250AuthorizationManager]. The configured [roleHierarchy] is passed to
  /// each manager.
  ///
  /// ### Parameters
  /// - [attribute]: the discovered security attribute.
  ///
  /// ### Returns
  /// The matching manager, or `null` for attributes this interceptor ignores.
  /// {@endtemplate}
  AuthorizationManager<MethodAuthorizationContext>? _managerFor(Object attribute) {
    if (attribute is PreAuthorize) {
      return PreAuthorizeAuthorizationManager(
        attribute.value,
        roleHierarchy: roleHierarchy,
      );
    }
    if (attribute is Secured) {
      return SecuredAuthorizationManager(
        attribute.value,
        roleHierarchy: roleHierarchy,
      );
    }
    if (attribute is RolesAllowed) {
      return Jsr250AuthorizationManager(
        attribute.value,
        roleHierarchy: roleHierarchy,
      );
    }
    return null;
  }
}

/// {@template authorization_manager_after_method_interceptor}
/// A Jetleaf `AfterReturningInterceptor` that enforces post-authorization.
///
/// After the method returns successfully, the interceptor reads security
/// attributes from [metadataSource] and evaluates every `PostAuthorize` rule
/// against a [MethodAuthorizationContext] that includes the return value. A
/// denial throws [AccessDeniedException].
///
/// ### Contract and invariants
/// - [canIntercept] returns `true` only when a `PostAuthorize` attribute exists.
/// - Non-`PostAuthorize` attributes are ignored during [afterReturning].
/// - `returnObject.*` paths resolve against the method's result.
/// - The authentication is resolved lazily from [SecurityContextHolder].
///
/// ### Example
/// ```dart
/// const interceptor = AuthorizationManagerAfterMethodInterceptor();
/// ```
/// {@endtemplate}
final class AuthorizationManagerAfterMethodInterceptor implements AfterReturningInterceptor {
  /// Source of security attributes.
  final MethodSecurityMetadataSource metadataSource;

  /// Optional role hierarchy for expression evaluation.
  final RoleHierarchy? roleHierarchy;

  /// {@macro authorization_manager_after_method_interceptor}
  ///
  /// Creates a post-authorization interceptor.
  ///
  /// ### Parameters
  /// - [metadataSource]: discovers security attributes; defaults to
  ///   [PrePostAnnotationSecurityMetadataSource].
  /// - [roleHierarchy]: optional rules for expanding implied authorities.
  const AuthorizationManagerAfterMethodInterceptor({
    this.metadataSource = const PrePostAnnotationSecurityMetadataSource(),
    this.roleHierarchy,
  });

  /// {@template authorization_manager_after_method_interceptor_equalized_properties}
  /// Returns the properties that define this interceptor's equality.
  ///
  /// ### Returns
  /// The [metadataSource] and [roleHierarchy] used by `EqualsAndHashCode`.
  /// {@endtemplate}
  @override
  List<Object?> equalizedProperties() => [runtimeType, metadataSource, roleHierarchy];

  /// {@template authorization_manager_after_method_interceptor_can_intercept}
  /// Reports whether the method carries a `PostAuthorize` attribute.
  ///
  /// ### Parameters
  /// - [method]: the method whose attributes are inspected.
  ///
  /// ### Returns
  /// `true` when [metadataSource] exposes a `PostAuthorize` attribute.
  /// {@endtemplate}
  @override
  bool canIntercept(Method method) => metadataSource
    .getAttributes(method)
    .any((a) => a is PostAuthorize);

  /// {@template authorization_manager_after_method_interceptor_after_returning}
  /// Checks every `PostAuthorize` attribute against the returned value.
  ///
  /// The context carries the invocation, bound arguments, and [returnValue].
  /// Each attribute is checked in order; the first denial throws an
  /// [AccessDeniedException] instead of returning the value to the caller.
  ///
  /// ### Parameters
  /// - [invocation]: the invocation that produced [returnValue].
  /// - [returnValue]: the value returned by the method.
  /// - [returnClass]: the reflective type of the return value; not used for
  ///   authorization decisions.
  ///
  /// ### Returns
  /// A [Future] that completes when all post-authorization checks pass.
  ///
  /// ### Throws
  /// [AccessDeniedException] when a check denies access.
  /// {@endtemplate}
  @override
  Future<void> afterReturning<T>(MethodInvocation<T> invocation, Object? returnValue, Class? returnClass) async {
    final context = MethodAuthorizationContext(
      invocation: invocation,
      arguments: bindMethodArguments(invocation),
      returnObject: returnValue,
    );

    for (final attribute in metadataSource.getAttributes(invocation.getMethod())) {
      if (attribute is! PostAuthorize) continue;
      final manager = PostAuthorizeAuthorizationManager(
        attribute.value,
        roleHierarchy: roleHierarchy,
      );
      if (!manager.check(() => SecurityContextHolder.getContext().authentication, context).isGranted) {
        throw AccessDeniedException('Access denied by $attribute');
      }
    }
  }
}