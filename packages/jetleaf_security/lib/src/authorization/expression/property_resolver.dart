import 'package:jetleaf_core/lang.dart';

/// {@template security_expression_property_resolver}
/// Resolves a named property from a target object during expression evaluation.
///
/// Implementations are consulted by [SecurityExpressionPropertyResolvers] in
/// registration order. They make dotted value paths such as
/// `principal.organizationId` work for objects that are not covered by the
/// default reflective resolver.
///
/// ### Contract
/// - Return the property value when the [property] is recognized on [target].
/// - Return [SecurityExpressionPropertyResolvers.notResolved] when this
///   resolver cannot handle the pair, so the registry can try the next one.
/// - Returning `null` is a valid resolved value and stops the search; it does
///   not mean "defer".
/// - Resolvers should be side-effect free: expressions may be evaluated many
///   times for the same rule.
///
/// ### Example
/// ```dart
/// final class ProfileResolver implements SecurityExpressionPropertyResolver {
///   const ProfileResolver();
///
///   @override
///   Object? resolve(Object target, String property) {
///     if (target is User && property == 'organizationId') {
///       return target.organization.id;
///     }
///     return SecurityExpressionPropertyResolvers.notResolved;
///   }
/// }
/// ```
///
/// ### See also
/// - [SecurityExpressionPropertyResolvers]
/// - [SecurityExpressionPropertyResolvers.register]
/// {@endtemplate}
abstract interface class SecurityExpressionPropertyResolver {
  /// {@template security_expression_property_resolver_resolve}
  /// Returns the value of [property] on [target], or
  /// [SecurityExpressionPropertyResolvers.notResolved] to defer.
  ///
  /// ### Parameters
  /// - [target]: the object whose property should be read.
  /// - [property]: the property name from the expression's value path.
  ///
  /// ### Returns
  /// The resolved value (possibly `null`), or the `notResolved` sentinel to let
  /// another resolver try.
  /// {@endtemplate}
  Object? resolve(Object target, String property);
}

/// {@template security_expression_property_resolvers}
/// Registry of property resolvers used by the expression evaluator.
///
/// Resolution follows this order: `null` targets yield `null`, [Map] targets
/// are indexed by key, each registered [SecurityExpressionPropertyResolver] is
/// consulted in registration order, and finally the default reflective field
/// lookup is attempted. The sentinel
/// [SecurityExpressionPropertyResolvers.notResolved] tells the registry that a
/// resolver declined to answer.
///
/// ### Invariants
/// - Registration order is preserved; the first non-deferring answer wins.
/// - The registry is process-wide and is normally populated at startup.
/// - [clear] exists primarily for test isolation.
///
/// ### Example
/// ```dart
/// SecurityExpressionPropertyResolvers.register(const ProfileResolver());
/// final organizationId =
///     SecurityExpressionPropertyResolvers.resolve(principal, 'organizationId');
/// ```
///
/// ### See also
/// - [SecurityExpressionPropertyResolver]
/// {@endtemplate}
abstract final class SecurityExpressionPropertyResolvers {
  /// Sentinel returned by a resolver that cannot handle a property.
  ///
  /// Compare with [identical] rather than `==`; the sentinel's identity, not
  /// its equality, signals that resolution should continue.
  static final Object notResolved = Object();

  /// Registered custom resolvers, in consultation order.
  static final List<SecurityExpressionPropertyResolver> _resolvers = [];

  /// {@macro security_expression_property_resolvers}
  const SecurityExpressionPropertyResolvers._();

  /// {@template security_expression_property_resolvers_register}
  /// Adds a resolver. Resolvers are consulted in registration order.
  ///
  /// ### Parameters
  /// - [resolver]: the resolver to append to the chain.
  /// {@endtemplate}
  static void register(SecurityExpressionPropertyResolver resolver) => _resolvers.add(resolver);

  /// {@template security_expression_property_resolvers_clear}
  /// Removes all custom resolvers (primarily for tests).
  ///
  /// The default reflective field lookup is always available and is unaffected
  /// by this method.
  /// {@endtemplate}
  static void clear() => _resolvers.clear();

  /// {@template security_expression_property_resolvers_resolve}
  /// Resolves [property] on [target].
  ///
  /// A `null` [target] resolves to `null`. [Map] targets are indexed by the
  /// property name. Custom resolvers are then tried until one returns a value
  /// other than [notResolved]. If all defer, a reflected field of the same
  /// name is read when available.
  ///
  /// ### Parameters
  /// - [target]: the object to inspect; may be `null`.
  /// - [property]: the property name to resolve.
  ///
  /// ### Returns
  /// The property value, or `null` when the target is `null` or the property
  /// cannot be found.
  ///
  /// ### Example
  /// ```dart
  /// final value = SecurityExpressionPropertyResolvers.resolve(user, 'name');
  /// ```
  /// {@endtemplate}
  static Object? resolve(Object? target, String property) {
    if (target == null) return null;
    if (target is Map) return target[property];

    for (final resolver in _resolvers) {
      final value = resolver.resolve(target, property);
      if (!identical(value, notResolved)) return value;
    }

    final field = target.getClass().getField(property);
    return field?.getValue(target);
  }
}
