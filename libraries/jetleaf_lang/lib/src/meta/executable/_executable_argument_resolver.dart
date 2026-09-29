part of 'executable_argument_resolver.dart';

/// {@template _executable_argument_resolver}
/// Default implementation of [ExecutableArgumentResolver] that resolves
/// executable parameters based on **type bindings** and **predicate bindings**.
///
/// This resolver supports a two-tier resolution strategy:
/// 1. **Predicate bindings** – highest priority, allows matching parameters
///    via custom conditions (name, annotation, metadata, etc.)
/// 2. **Type bindings** – fallback, matches parameters based on registered types
///    and assignability rules.
///
/// The resolved arguments are returned as an [ExecutableArgument], which
/// provides both positional and named arguments ready for invocation.
///
/// ---
/// ## 🔧 Internals
/// - `_typeBindings` stores all type-instance mappings added via `.and(...)`
/// - `_predicateBindings` stores all predicate-instance mappings added via
///   `.when(...)`
///
/// Resolution proceeds parameter by parameter in the executable's declared order:
/// - Each parameter is first tested against all predicate bindings.
/// - If no predicate matches, type bindings are tested in order of registration.
/// - Parameters with no matching binding are skipped.
///
/// ---
/// ## 🧪 Example
/// ```dart
/// final resolver = _ExecutableArgumentResolver()
///   .and(Class<ApplicationContext>(), context)
///   .when((param) => param.getName() == "logger", myLogger);
///
/// final args = resolver.resolve(constructor);
/// final instance = constructor.newInstance(
///   args.getNamedArguments(),
///   args.getPositionalArguments(),
/// );
/// ```
///
/// ---
/// ## ⚠️ Notes
/// - The first matching binding (predicate or type) is used per parameter.
/// - Skipped parameters are not automatically filled; caller must ensure the
///   executable can be invoked.
/// - Predicates override type bindings when both match the same parameter.
/// {@endtemplate}
final class _ExecutableArgumentResolver implements ExecutableArgumentResolver {
  /// Ordered list of type bindings added via `.and(...)`.
  final List<_TypeBinding> _typeBindings = [];

  /// Ordered list of predicate bindings added via `.when(...)`.
  final List<_PredicateBinding> _predicateBindings = [];

  /// {@macro _executable_argument_resolver}
  _ExecutableArgumentResolver();

  @override
  ExecutableArgumentResolver and<T>(Class<T> type, T? instance, [bool isAssignableFrom = true]) {
    if (instance != null && !type.isInstance(instance)) {
      throw IllegalStateException("Instance '${instance.runtimeType}' cannot be assigned to parameter of type '${type.getQualifiedName()}'");
    }

    _typeBindings.add(_TypeBinding(type, instance, isAssignableFrom));
    return this;
  }

  @override
  ExecutableArgumentResolver when(Predicate<Parameter> matcher, Object? instance) {
    _predicateBindings.add(_PredicateBinding(matcher, instance));
    return this;
  }

  @override
  ExecutableArgument resolve(Executable executable) {
    final named = <String, Object?>{};
    final positional = <Object?>[];
    final params = executable.getParameters();

    for (final param in params) {
      final paramClass = param.getReturnClass();
      Object? resolved;

      // -------------------------------------------------------------
      // 1. Predicate bindings have highest specificity — evaluate first.
      // -------------------------------------------------------------
      if (_predicateBindings.isNotEmpty) {
        for (final binding in _predicateBindings) {
          if (binding.matcher(param)) {
            resolved = binding.instance;
            break;
          }
        }
      }

      // -------------------------------------------------------------
      // 2. If no predicate matched, try type bindings.
      // -------------------------------------------------------------
      if (resolved == null && _typeBindings.isNotEmpty) {
        for (final binding in _typeBindings) {
          if (binding.matches(paramClass)) {
            resolved = binding.instance;
            break;
          }
        }
      }

      if (param.isNamed()) {
        named[param.getName()] = resolved;
      } else {
        positional.insert(param.getIndex(), resolved);
      }
    }

    return ExecutableArgument.unmodified(named, positional);
  }
}

/// {@template type_binding}
/// Internal representation of a single type-to-instance mapping used by
/// the argument resolution system.
///
/// A `_TypeBinding` pairs:
/// - a reflective [Class] type,
/// - an associated [instance] to supply for parameters of that type,
/// - and an `isAssignableFrom` rule describing how type matching should behave.
///
/// These bindings act as the core units used by the `ExecutableArgumentResolver`
/// to decide which values should populate the parameters of a constructor,
/// method, or function.
///
/// This class is **not** intended for public use and is only consumed by the
/// internal resolver implementation.
/// {@endtemplate}
final class _TypeBinding {
  /// The reflective type this binding targets.
  ///
  /// During argument resolution, a parameter whose type matches this [`type`]
  /// (based on the assignability rules described by [isAssignableFrom])
  /// will receive the associated [instance].
  final Class type;

  /// The instance to inject for parameters matching [type].
  ///
  /// May be `null` if the parameter allows null values.
  final Object? instance;

  /// Controls the direction of type assignability checks used to determine
  /// whether this binding applies to a given parameter type.
  ///
  /// ### Assignability Behavior
  /// - **When `true` (default):**  
  ///   The parameter type must be *assignable from* the registered type.  
  ///   This means the registered type may be a **subtype** of the parameter.
  ///
  ///   Example:  
  ///   ```dart
  ///   Binding: Class<ApplicationContext>
  ///   Parameter: Class<ConfigurableApplicationContext>
  ///   ```
  ///   Matches if `ConfigurableApplicationContext` extends `ApplicationContext`.
  ///
  /// - **When `false`:**  
  ///   The check is reversed: the registered type must be assignable from the
  ///   parameter type. The parameter may be a **subtype** of the registered type.
  ///
  ///   Useful when you want strict type narrowing or reversed hierarchy matching.
  final bool isAssignableFrom;

  /// Creates a new type binding used internally by the resolver.
  ///
  /// - [type] — The reflective type this binding applies to  
  /// - [instance] — The value to inject for matching parameters  
  /// - [isAssignableFrom] — Optional assignability mode (defaults to `true`)
  /// 
  /// {@macro type_binding}
  const _TypeBinding(this.type, this.instance, [this.isAssignableFrom = true]);

  /// Determines whether this binding applies to a parameter whose reflective
  /// type is [paramType].
  ///
  /// The matching logic depends on [isAssignableFrom]:
  ///
  /// ### `isAssignableFrom == true` (default)
  /// Checks whether:
  /// ```dart
  /// paramType.isAssignableFrom(type)
  /// ```
  /// Meaning:
  /// - The registered type may be a **subclass** of the parameter type.
  /// - Commonly used when you want to pass a more specific instance to a
  ///   general parameter.
  ///
  /// ### `isAssignableFrom == false`
  /// Uses the reversed relationship:
  /// ```dart
  /// type.isAssignableFrom(paramType)
  /// ```
  /// Meaning:
  /// - The parameter type may be a **subclass** of the registered type.
  ///
  /// This is useful when the caller wants strict or narrower matching.
  ///
  /// Returns `true` if the types are considered compatible under the selected
  /// rule, otherwise returns `false`.
  bool matches(Class paramType) {
    if (isAssignableFrom) {
      // Registered type applies if the parameter is assignable from it.
      return type.isAssignableFrom(paramType);
    } else {
      // Reverse direction: parameter must be assignable to the registered type.
      return type.isAssignableTo(paramType);
    }
  }
}

/// {@template predicate_binding}
/// Internal representation of a **predicate-based binding** used by
/// [ExecutableArgumentResolver] to supply argument values during resolution.
///
/// A `_PredicateBinding` pairs:
/// - a **matcher** — a predicate function that receives a [Parameter] and
///   determines whether the binding applies to it
/// - an **instance** — the value to inject when the matcher evaluates to `true`
///
/// Predicate bindings enable highly flexible matching strategies beyond simple
/// type-based resolution, including matching by:
/// - parameter name  
/// - position (named vs positional)  
/// - annotations or metadata  
/// - nullability  
/// - any other property exposed by reflective [Parameter] data  
///
/// These bindings are evaluated in the order they were registered, and the
/// first predicate returning `true` claims the parameter.
///
/// This class is private and intended solely as part of the resolver’s internal
/// binding infrastructure.
///
/// ### Example (illustrative)
/// ```dart
/// final binding = _PredicateBinding(
///   (p) => p.name == 'timeout' && p.type == Class.forType(int),
///   5000,
/// );
/// ```
///
/// In this example, the binding injects the value `5000` for any parameter named
/// `timeout` whose type is `int`.
/// {@endtemplate}
class _PredicateBinding {
  /// The predicate used to determine whether this binding applies to
  /// a given [Parameter].
  final Predicate<Parameter> matcher;

  /// The value to inject when [matcher] evaluates to `true`.
  ///
  /// May be `null` when null is an acceptable or intentional argument.
  final Object? instance;

  /// Creates a new predicate binding with a [matcher] and an associated [instance].
  /// 
  /// {@macro predicate_binding}
  const _PredicateBinding(this.matcher, this.instance);
}