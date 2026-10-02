part of 'executable_selector.dart';

/// {@template _executable_selector}
/// Default implementation of [ExecutableSelector] that selects the most suitable
/// [Executable] (constructor, method, or function) from a list based on **type**
/// and **predicate-based rules**.
///
/// The selector evaluates each executable’s parameters against registered
/// selection criteria and assigns a **score** to determine the best match:
/// - **Predicate bindings** take precedence and add to the score for matching
///   parameters.
/// - **Type bindings** are evaluated next and also contribute to the score.
///
/// The executable with the highest total score is returned. If no executable
/// matches any binding, `null` is returned.
///
/// ---
/// ## 🔧 Internals
/// - `_typeBindings` – List of `_TypeSelectBinding` entries representing type-based
///   selection rules.
/// - `_predicateBindings` – List of `_PredicateSelectBinding` entries representing
///   custom predicate rules.
///
/// ---
/// ## 🧪 Example
/// ```dart
/// final selector = ExecutableSelector()
///   .and(Class<ApplicationContext>())
///   .when((param) => param.isNamed && param.getName() == "logger");
///
/// final bestConstructor = selector.select(myClass.getConstructors());
/// final args = ExecutableArgumentResolver()
///   .and(Class<ApplicationContext>(), context)
///   .resolve(bestConstructor!);
///
/// final instance = bestConstructor.newInstance(
///   args.getNamedArguments(),
///   args.getPositionalArguments(),
/// );
/// ```
///
/// ---
/// ## ⚠️ Notes
/// - Predicates override type bindings when both match the same parameter.
/// - Selection is purely based on matching score; ties are resolved by first
///   executable encountered with the highest score.
/// - If no executable matches any binding, `select` returns `null`.
/// {@endtemplate}
final class _ExecutableSelector implements ExecutableSelector {
  /// Ordered list of type-based selection rules.
  final List<_TypeSelectBinding> _typeBindings = [];

  /// Ordered list of predicate-based selection rules.
  final List<_PredicateSelectBinding> _predicateBindings = [];

  /// {@macro _executable_selector}
  _ExecutableSelector();

  @override
  ExecutableSelector and(Class type, [bool isAssignableFrom = true]) {
    _typeBindings.add(_TypeSelectBinding(type, isAssignableFrom));
    return this;
  }

  @override
  ExecutableSelector when(Predicate<Parameter> matcher) {
    _predicateBindings.add(_PredicateSelectBinding(matcher));
    return this;
  }

  @override
  E? select<E extends Executable>(Iterable<E> executables) {
    E? best;
    int bestScore = -1;

    for (final exec in executables) {
      int score = 0;

      for (final param in exec.getParameters()) {
        // Predicate bindings have priority
        if (_predicateBindings.any((b) => b.matches(param))) {
          score++;
          continue;
        }

        // Then type bindings
        if (_typeBindings.any((b) => b.matches(param))) {
          score++;
        }
      }

      if (score > bestScore) {
        bestScore = score;
        best = exec;
      }
    }

    return best;
  }
}

/// {@template type_select_binding}
/// Internal binding representing a **type-based selection rule** used by
/// [ExecutableSelector] to determine whether an executable’s parameter matches
/// a required type constraint.
///
/// This binding encapsulates:
/// - A reflective [type] to compare against parameter types  
/// - A directional assignability rule (`isAssignableFrom`) controlling how
///   type compatibility is evaluated
///
/// These bindings are consumed by the selector during executable filtering.
/// They are *not* intended for external use.
///
/// ---
/// ## 🔍 Matching Behavior
///
/// The [matches] method evaluates whether a given [Parameter] satisfies the
/// rule expressed by this binding.  
///
/// Let `T = this.type` and `P = parameter.type`.
///
/// The logic behaves differently depending on the `isAssignableFrom` flag:
///
/// ### When `isAssignableFrom == true` (default)
/// ```
/// match ⇢ P.isAssignableFrom(T)
/// ```
/// Meaning:
/// - The parameter type `P` may be a **supertype** of the registered type `T`  
/// - The executable accepts something broader than what was registered
///
/// **Use case:** Selecting constructors that accept a more general abstraction
/// (e.g., requiring `ApplicationContext` while your instance is of
/// `ConfigurableApplicationContext`).
///
///
/// ### When `isAssignableFrom == false`
/// ```
/// match ⇢ T.isAssignableFrom(P)
/// ```
/// Meaning:
/// - The parameter type `P` must be a **subtype** of the registered type `T`  
/// - The executable must require something as specific or more specific than
///   `T`
///
/// **Use case:** When callers need to ensure the parameter is *not more
/// general* than the given type, often used for narrowing overloads.
///
///
/// ---
/// ## 🧪 Example
/// ```dart
/// final binding = _TypeSelectBinding(Class<ApplicationContext>());
///
/// final matches = binding.matches(param); // param: Parameter
/// ```
///
/// The executable parameter matches if its type is assignable from
/// `ApplicationContext`, based on the direction set by the flag.
///
///
/// ---
/// ## ⚠️ Notes
/// - This binding checks **only type relations**.  
/// - Named/positional metadata or annotations are ignored.  
/// - It is a low-level utility used exclusively by the selector; callers should
///   use the high-level `.and(type)` API instead.
///
/// ---
/// {@endtemplate}
final class _TypeSelectBinding {
  /// The reflective type used for comparison.
  final Class type;

  /// Determines whether the relation is:
  /// - `true` → parameterType.isAssignableFrom(type)  
  /// - `false` → type.isAssignableFrom(parameterType)
  final bool isAssignableFrom;

  /// {@macro type_select_binding}
  const _TypeSelectBinding(this.type, [this.isAssignableFrom = true]);

  /// Returns `true` if the given [param] satisfies this type binding.
  ///
  /// Uses the assignability rule defined by [isAssignableFrom] to evaluate
  /// compatibility.
  bool matches(Parameter param) {
    final pType = param.getReturnClass();
    return isAssignableFrom ? type.isAssignableFrom(pType) : type.isAssignableTo(pType);
  }
}

/// {@template predicate_select_binding}
/// Internal binding representing a **predicate-based selection rule** used by
/// [ExecutableSelector] to determine if an executable’s parameter satisfies
/// arbitrary conditions.
///
/// This binding encapsulates a user-provided [matcher] function that is invoked
/// against each [Parameter] of an executable during selection.
///
/// These bindings are used internally by the selector to apply custom, fine-
/// grained rules beyond simple type matching. They are **not intended for
/// external use**.
///
/// ---
/// ## 🔍 Matching Behavior
///
/// The [matches] method executes the [matcher] predicate against the provided
/// [param]. If the predicate returns `true`, the parameter satisfies the rule.
///
/// Example conditions that can be expressed with a predicate:
/// - Parameter name equals `"logger"`  
/// - Parameter is named or positional  
/// - Parameter type implements a specific interface  
/// - Parameter has a certain annotation or metadata
///
/// ---
/// ## 🧪 Example
/// ```dart
/// final binding = _PredicateSelectBinding(
///   (param) => param.isNamed && param.getName() == "config"
/// );
///
/// final matches = binding.matches(parameter); // true if name is "config" and named
/// ```
///
/// ---
/// ## ⚠️ Notes
/// - The predicate is evaluated for **each parameter** of an executable.  
/// - Multiple predicate bindings can be combined; all must match for the
///   executable to qualify.  
/// - This is a low-level utility; high-level API users should call
///   `ExecutableSelector.when(...)` instead.
///
/// {@endtemplate}
final class _PredicateSelectBinding {
  /// The predicate used to evaluate parameters.
  final Predicate<Parameter> matcher;

  /// {@macro predicate_select_binding}
  const _PredicateSelectBinding(this.matcher);

  /// Returns `true` if the given [param] satisfies the predicate.
  bool matches(Parameter param) => matcher(param);
}