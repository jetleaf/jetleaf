import '../class/class.dart';
import '../constructor/constructor.dart';
import 'executable_argument_resolver.dart';
import 'executable_selector.dart';

part '_executable_instantiator.dart';

/// {@template executable_instantiator}
/// Provides a **high-level, reflection-based utility** to dynamically instantiate
/// classes and invoke methods on objects at runtime, while automatically resolving
/// arguments and selecting the most appropriate executable.
///
/// The [ExecutableInstantiator] is designed for frameworks or libraries that
/// require **dynamic execution** of constructors or methods without static knowledge
/// of their signatures. It leverages:
/// - **Executable selectors** to choose the best matching constructor or method
/// - **Argument resolvers** to automatically provide values for positional and named parameters
///
/// ---
/// ## Core Responsibilities
/// 1. Dynamically instantiate classes discovered at runtime
/// 2. Dynamically invoke instance methods on objects
/// 3. Automatically select the best executable using configurable rules
/// 4. Auto-resolve constructor and method parameters based on type bindings or predicates
/// 5. Provide fluent API for chaining selectors and argument resolvers
///
/// ---
/// ## Use Cases
/// - Dynamic plugin or module instantiation
/// - Runtime method invocation with dependency injection support
/// - Reflection-based framework utilities
/// - Dynamic wiring of services or components discovered at runtime
///
/// ---
/// ## Example
/// ```dart
/// final instantiator = ExecutableInstantiator.of(MyClass)
///   .withSelector(ExecutableSelector().and(Class<ApplicationContext>()))
///   .withArgumentResolver(ExecutableArgumentResolver().and(Class<ApplicationContext>(), context);
///
/// // Create a new instance
/// final instance = instantiator.newInstance<MyClass>();
///
/// // Invoke a method dynamically
/// final result = instantiator.invoke<String>(instance, "doWork");
/// ```
/// {@endtemplate}
abstract interface class ExecutableInstantiator {
  /// Creates a new [ExecutableInstantiator] for the specified class [cls].
  ///
  /// The returned instance uses the internal implementation `_ExecutableInstantiator`.
  /// This is the primary entry point for dynamic instantiation and method invocation.
  ///
  /// ### Parameters
  /// - [cls]: The class to instantiate or whose methods will be invoked dynamically.
  ///
  /// ### Returns
  /// A configured [ExecutableInstantiator] ready to accept selectors and argument resolvers.
  /// 
  /// {@macro executable_instantiator}
  factory ExecutableInstantiator.of(Class cls) = _ExecutableInstantiator;

  /// Assigns a custom [ExecutableSelector] to determine which executable
  /// (constructor or method) will be used when creating instances or invoking methods.
  ///
  /// The selector allows fine-grained control over parameter matching, prioritizing
  /// certain types or using predicate-based rules.
  ///
  /// ### Parameters
  /// - [selector]: The executable selector defining selection rules.
  ///
  /// ### Returns
  /// `this` for fluent chaining.
  ExecutableInstantiator withSelector(ExecutableSelector selector);

  /// Assigns a custom [ExecutableArgumentResolver] used to resolve the arguments
  /// of constructors or methods dynamically.
  ///
  /// Argument resolution supports both positional and named parameters, and can
  /// automatically bind values based on type or custom predicates.
  ///
  /// ### Parameters
  /// - [resolver]: The argument resolver instance.
  ///
  /// ### Returns
  /// `this` for fluent chaining.
  ExecutableInstantiator withArgumentResolver(ExecutableArgumentResolver resolver);

  /// Dynamically invokes a method with the specified [methodName] on the given [instance].
  ///
  /// The invocation process includes:
  /// 1. Selecting the best matching method using the configured selector
  /// 2. Resolving parameters using the argument resolver
  /// 3. Returning the method result, cast to [Executed]
  ///
  /// ### Parameters
  /// - [instance]: The target object on which to invoke the method
  /// - [methodName]: The name of the method to invoke dynamically
  ///
  /// ### Returns
  /// The result of the method invocation cast to [Executed], or `null` if invocation fails.
  Executed? invoke<Executed>(Object? instance, String methodName);

  /// Dynamically creates a new instance of the underlying class [cls].
  ///
  /// The instantiation process follows these steps:
  /// 1. If [checkNoArgFirst] is `true`, attempts to invoke a no-argument constructor
  ///    before applying selectors and argument resolution.
  /// 2. Selects the best matching constructor using the configured selector.
  /// 3. Resolves constructor arguments using the argument resolver.
  /// 4. If [tryDefault] is `true`, attempts to invoke the default constructor of the class
  ///    when all fails.
  ///
  /// ### Parameters
  /// - [checkNoArgFirst]: If true, prioritizes no-argument constructor invocation.
  /// - [tryDefault]: If true, it will try with default constructor if there is no arg and no best constructor found.
  ///
  /// ### Returns
  /// The newly instantiated object cast to [Executed], or `null` if instantiation fails.
  Executed? newInstance<Executed>({bool checkNoArgFirst = true, bool tryDefault = false});
}