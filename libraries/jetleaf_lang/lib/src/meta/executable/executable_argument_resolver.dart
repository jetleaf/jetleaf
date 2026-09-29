import 'package:jetleaf_build/jetleaf_build.dart';

import '../../commons/typedefs.dart';
import '../../exceptions.dart';
import '../class/class.dart';
import '../core.dart';
import '../parameter/parameter.dart';

part '_executable_argument_resolver.dart';

/// {@template executable_argument_resolver}
/// A type-driven dependency injection utility for resolving arguments required
/// by an [Executable] such as a constructor, method, or function.
///
/// The `ExecutableArgumentResolver` allows you to associate specific **types**
/// with **instances**, and later compute the correct positional and named
/// arguments expected by an executable's parameter list.
///
/// This provides a lightweight, reflection-based alternative to traditional
/// dependency injection containers—particularly useful when dynamically
/// instantiating classes discovered at runtime.
///
/// ---
/// ## 🔍 How Resolution Works
///
/// When resolving arguments:
///
/// 1. The executable’s parameter metadata is inspected.  
/// 2. For each registered type binding:
///    - The resolver searches for a parameter whose type matches the registered
///      type.
///    - Matching behavior depends on `isAssignableFrom`:  
///      - `true` → The parameter type may be a *subtype* of the registered type.  
///      - `false` → The parameter type must match exactly or be assignable *to* it.
/// 3. When a parameter is matched:
///    - If it is a **named** parameter → added to the named argument map  
///    - If it is a **positional** parameter → placed at its correct index  
///
/// The final result is an [ExecutableArgument] object containing both positional
/// and named arguments ready for invocation.
///
/// ---
/// ## 🧩 Use Cases
///
/// - Dynamic instantiation of classes discovered via reflection
/// - Utility-level dependency injection for frameworks
/// - Supporting user-defined plug-ins or modules with unknown constructor shapes
/// - Auto-resolution of common types during runtime assembly
///
/// ---
/// ## 🧪 Example
/// ```dart
/// final resolver = ExecutableArgumentResolver()
///   .and(Class<ApplicationContext>(), context)
///   .and(Class<Logger>(), Logger("MyClass"));
///
/// final constructor = myClass.getBestConstructor([Class<ApplicationContext>()]);
/// final args = resolver.resolve(constructor);
///
/// final instance = constructor.newInstance(
///   args.getNamedArguments(),
///   args.getPositionalArguments(),
/// );
/// ```
///
/// ---
/// ## ⚠️ Notes
/// - If multiple parameters match the same type, the first matching parameter
///   reported by reflection is used.
/// - Unmatched parameters are **not** filled automatically; callers must ensure
///   the executable can be invoked with the resolved arguments.
/// - Registered instances are not validated for nullability or compatibility
///   until resolution time.
///
/// {@endtemplate}
abstract interface class ExecutableArgumentResolver {
  /// Creates a new default resolver backed by the internal
  /// implementation class `_ExecutableArgumentResolver`.
  ///
  /// {@macro executable_argument_resolver}
  factory ExecutableArgumentResolver() => _ExecutableArgumentResolver();

  /// Registers a mapping between a reflective [type] and a concrete [instance].
  ///
  /// The resolver uses these mappings to populate parameters during argument
  /// resolution.
  ///
  /// ### Parameters
  /// - **type** – A [Class] representing the type to match against executable
  ///   parameter types.
  /// - **instance** – The object to supply whenever a matching parameter is
  ///   found. Nullable in case the executable accepts nullable parameters.
  /// - **isAssignableFrom** –  
  ///   If `true` (default), parameters whose type is *assignable from* the
  ///   registered type (i.e., supertype matching) are eligible.  
  ///   If `false`, parameters whose type is *assignable to* the registered type
  ///   (i.e., subtype matching) are eligible.
  ///
  /// ### Returns
  /// Returns `this` to allow fluent chaining:
  /// ```dart
  /// resolver
  ///   .and(Class<Foo>(), foo)
  ///   .and(Class<Bar>(), bar);
  /// ```
  ExecutableArgumentResolver and<T>(Class<T> type, T? instance, [bool isAssignableFrom = true]);

  /// Registers a **conditional parameter matcher** that supplies [instance]
  /// whenever the provided [matcher] function returns `true` for a parameter.
  ///
  /// Unlike [and], which binds values by **type**, `when` enables more flexible,
  /// rule-based resolution based on full [Parameter] metadata such as:
  ///
  /// - Parameter **name**
  /// - Parameter **type**
  /// - Whether the parameter is **named** or **positional**
  /// - Nullability, annotations, or any other reflective attributes
  ///
  /// This is useful when type-matching alone is insufficient—e.g., when
  /// multiple parameters share the same type, or when matching by name or other
  /// structural characteristics is required.
  ///
  /// ### Parameters
  /// - **matcher** – A function that receives a [Parameter] and returns `true`
  ///   if the supplied [instance] should be used for that parameter.
  /// - **instance** – The object value to provide for all parameters that
  ///   satisfy the [matcher] predicate.
  ///
  /// ### Behavior
  /// During resolution:
  /// - The resolver iterates over parameters in declaration order.
  /// - For each parameter, all registered `.when()` matchers are evaluated.
  /// - The *first* matching predicate supplies the argument value.
  /// - If no predicate matches, type-based `.and()` bindings may still apply.
  ///
  /// ### Example
  /// Match by **parameter name**:
  /// ```dart
  /// resolver.when(
  ///   (p) => p.name == 'configPath',
  ///   '/etc/myapp/config.json',
  /// );
  /// ```
  ///
  /// Match only **named parameters** of type `String`:
  /// ```dart
  /// resolver.when(
  ///   (p) => p.isNamed && p.type == Class.forType(String),
  ///   'default',
  /// );
  /// ```
  ///
  /// Match parameters annotated with `@Inject` (hypothetical):
  /// ```dart
  /// resolver.when(
  ///   (p) => p.metadata.any((m) => m.type == Class.forType(Inject)),
  ///   myService,
  /// );
  /// ```
  ///
  /// ### Returns
  /// Returns `this` for fluent chaining.
  ExecutableArgumentResolver when(Predicate<Parameter> matcher, Object? instance);

  /// Resolves the argument list for the provided [executable].
  ///
  /// This method examines the executable's parameters and attempts to match them
  /// with previously registered type-instance mappings. Each parameter may result
  /// in:
  ///
  /// - A **positional argument** inserted at the correct index  
  /// - A **named argument** inserted using the parameter name  
  ///
  /// Unmatched parameters are left out of the result, meaning the caller must
  /// ensure the executable can still be invoked successfully.
  ///
  /// ### Returns
  /// An [ExecutableArgument] containing:
  /// - A list of positional argument values  
  /// - A map of named parameters to values  
  ///
  /// These can be passed directly to `Executable.newInstance()`.
  ExecutableArgument resolve(Executable executable);
}