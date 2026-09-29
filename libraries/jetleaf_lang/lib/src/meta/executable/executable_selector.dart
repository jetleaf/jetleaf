import '../../commons/typedefs.dart';
import '../class/class.dart';
import '../core.dart';
import '../parameter/parameter.dart';

part '_executable_selector.dart';

/// {@template executable_selector}
/// A flexible **executable filtering and selection utility** used to pick a
/// single [Executable] (e.g., a constructor, method, or function overload) from
/// a provided list based on declarative matching rules.
///
/// `ExecutableSelector` supports two categories of selection criteria:
///
/// ### 1. **Type-Based Matching**
/// Using [and], you can require that at least one parameter of the executable
/// matches a given [Class] type.
///
/// Matching behavior depends on `isAssignableFrom`:
///
/// - If `true` (default):  
///   The executable’s parameter type may be a **subtype** of the given type.  
///   Example: selecting constructors accepting `ApplicationContext` when
///   registering `ContextAware`.
///
/// - If `false`:  
///   The executable’s parameter type must be a **supertype** or exact match.
///   Useful when selecting overloads with more specific parameter constraints.
///
///
/// ### 2. **Predicate-Based Matching**
/// Using [when], callers can register arbitrary custom filters that operate on
/// individual parameters.  
///
/// These allow highly granular control such as:
/// - selecting executables with parameters named `"config"`  
/// - matching only positional parameters  
/// - detecting the presence of certain annotations  
/// - checking for nullability, generic types, or metadata flags  
///
/// Predicates are evaluated against **all parameters** of each executable.  
/// If *any* parameter satisfies the predicate, the executable qualifies for that rule.
///
///
/// ---
/// ## 🔍 Selection Process
///
/// When [select] is invoked:
///
/// 1. All registered type-based and predicate-based rules are applied to each
///    executable in the provided list.
/// 2. An executable must satisfy **all** rules to be considered a match.
/// 3. If multiple matches exist, the internal implementation may apply
///    prioritization (e.g., first declared, most specific, etc.).
/// 4. The selected executable is returned; if none match, an error may be
///    thrown or `null` returned depending on the implementation.
///
///
/// ---
/// ## 🧪 Example
/// ```dart
/// final selector = ExecutableSelector()
///   .and(Class<ApplicationContext>())
///   .when((param) => param.isNamed && param.name == 'logger');
///
/// final executable = selector.select(myClass.getConstructors());
/// ```
///
/// This example selects a constructor or method that:
/// - has a parameter assignable from `ApplicationContext`  
/// - AND has a named parameter called `"logger"`  
///
///
/// ---
/// ## 🧩 Use Cases
///
/// - Choosing the “best” constructor when instantiating classes via reflection  
/// - Selecting method overloads based on runtime type information  
/// - Filtering plugin entry points or lifecycle methods  
/// - Creating extensible and declarative DI-friendly selection logic  
///
///
/// ---
/// ## ⚠️ Notes
///
/// - Selection rules are **additive**; an executable must satisfy every rule.  
/// - Ordering of rules does not affect correctness but may influence
///   optimization in internal implementations.  
/// - If the list contains only one executable, selection may short-circuit.  
///
/// {@endtemplate}
abstract interface class ExecutableSelector {
  /// Creates a new selector backed by the internal implementation
  /// [_ExecutableSelector].
  ///
  /// {@macro executable_selector}
  factory ExecutableSelector() => _ExecutableSelector();

  /// Adds a **type-based selection rule**.
  ///
  /// The selector will require that matching executables contain at least one
  /// parameter whose type relation satisfies the provided [type] and
  /// [isAssignableFrom] rule.
  ///
  /// ### Parameters
  /// - **type**: The [Class] to match parameter types against.  
  /// - **isAssignableFrom**:  
  ///   - `true` → executable parameters may be subtypes of `type`  
  ///   - `false` → executable parameters must be assignable *to* `type`  
  ///
  /// ### Returns
  /// Returns `this` for fluent chaining.
  ExecutableSelector and(Class type, [bool isAssignableFrom = true]);

  /// Adds a **predicate-based rule** evaluated against each parameter.
  ///
  /// The executable qualifies for this rule if *any* of its parameters cause the
  /// [matcher] predicate to return `true`.
  ///
  /// This allows fine-grained matching conditions such as:
  /// - parameter name  
  /// - metadata or annotations  
  /// - nullability  
  /// - positional vs named  
  /// - generic type details  
  ///
  /// ### Returns
  /// Returns `this` for fluent chaining.
  ExecutableSelector when(Predicate<Parameter> matcher);

  /// Selects a single executable from the given list based on all previously
  /// registered rules.
  ///
  /// ### Behavior
  /// - Every rule must match at least one parameter of the executable.  
  /// - If multiple executables match, the internal implementation determines how
  ///   ties are resolved (commonly the first or most specific).  
  /// - If none match, the implementation may throw, return `null`, or use
  ///   fallback logic.
  ///
  /// ### Parameters
  /// - **executables** – The list of potential executables (constructors,
  ///   methods, or functions) to choose from.
  ///
  /// ### Returns
  /// The selected [E] that satisfies all rules.
  E? select<E extends Executable>(Iterable<E> executables);
}