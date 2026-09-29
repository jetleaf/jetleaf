import 'dart:async';

import 'package:jetleaf_build/jetleaf_build.dart';

import '../../commons/version.dart';
import '../../exceptions.dart';
import '../../utils/lang_utils.dart';
import '../../utils/method_utils.dart';
import '../class/class_type.dart';
import '../annotation/annotation.dart';
import '../class/class.dart';
import '../core.dart';
import '../generic_source.dart';
import '../parameter/parameter.dart';
import '../protection_domain/protection_domain.dart';

part '_method.dart';

/// {@template method_interface}
/// Provides reflective access to class method metadata and invocation capabilities.
///
/// This interface enables runtime inspection and invocation of class methods,
/// including access to:
/// - Method signatures and return types
/// - Parameter metadata
/// - Modifiers (static, abstract, etc.)
/// - Type parameters
/// - Override information
///
/// {@template method_interface_features}
/// ## Key Features
/// - Type-safe method invocation
/// - Full signature inspection
/// - Parameter metadata access
/// - Override hierarchy navigation
/// - Generic type support
///
/// ## Implementation Notes
/// Concrete implementations typically wrap platform-specific reflection objects
/// while providing this uniform interface.
/// {@endtemplate}
///
/// {@template method_interface_example}
/// ## Example Usage
/// ```dart
/// // Get method metadata
/// final toStringMethod = objectClass.getMethod('toString');
///
/// // Inspect method properties
/// print('Return type: ${toStringMethod.getReturnType<String>().getName()}');
///
/// // Invoke the method
/// final result = toStringMethod.invoke(myObject);
/// print('Result: $result');
///
/// // Check override status
/// if (toStringMethod.isOverride()) {
///   print('This overrides a superclass method');
/// }
/// ```
/// {@endtemplate}
/// {@endtemplate}
abstract final class Method extends Executable implements Member, GenericSource {
  @override
  MethodDeclaration getDeclaration();

  /// Checks if this method is static.
  ///
  /// {@template method_is_static}
  /// Returns:
  /// - `true` if declared with `static` modifier
  /// - `false` for instance methods
  /// {@endtemplate}
  bool isStatic();
  
  /// Checks if this method is abstract.
  ///
  /// {@template method_is_abstract}
  /// Returns:
  /// - `true` if declared with `abstract` modifier
  /// - `false` for concrete methods
  ///
  /// Note:
  /// Abstract methods cannot be invoked.
  /// {@endtemplate}
  bool isAbstract();
  
  /// Checks if this method is a getter.
  ///
  /// {@template method_is_getter}
  /// Returns:
  /// - `true` if declared with `get` keyword
  /// - `false` otherwise
  ///
  /// Note:
  /// Getters have no parameters and return a value.
  /// {@endtemplate}
  bool isGetter();
  
  /// Checks if this method is a setter.
  ///
  /// {@template method_is_setter}
  /// Returns:
  /// - `true` if declared with `set` keyword
  /// - `false` otherwise
  ///
  /// Note:
  /// Setters have exactly one parameter and return void.
  /// {@endtemplate}
  bool isSetter();
  
  /// Checks if this method is a factory constructor.
  ///
  /// {@template method_is_factory}
  /// Returns:
  /// - `true` if declared with `factory` keyword
  /// - `false` otherwise
  ///
  /// Note:
  /// Factory methods may return subtypes of the declaring class.
  /// {@endtemplate}
  bool isFactory();

  /// Checks if this method overrides a superclass method.
  ///
  /// {@template method_is_override}
  /// Returns:
  /// - `true` if declared with `@override` or matches superclass signature
  /// - `false` otherwise
  ///
  /// See also:
  /// - [getOverriddenMethod] to retrieve the superclass method
  /// {@endtemplate}
  bool isOverride();

  /// {@template method_isVoid}
  /// Determines whether this method declares a `void` return type.
  ///
  /// This method inspects the method's declared return type and returns `true`
  /// if it is explicitly `void`. It is useful for AOP frameworks, reflection
  /// systems, and code generation tools that need to distinguish between
  /// methods that produce values and those that perform side effects only.
  ///
  /// ## Example
  /// ```dart
  /// class Logger {
  ///   void log(String message) {}
  ///   int countLogs() => 42;
  /// }
  ///
  /// final logMethod = Class(Logger).getMethod('log');
  /// final countMethod = Class(Logger).getMethod('countLogs');
  ///
  /// print(logMethod.isVoid());   // true
  /// print(countMethod.isVoid()); // false
  /// ```
  ///
  /// @return `true` if the method’s return type is `void`,
  ///         `false` otherwise.
  /// {@endtemplate}
  bool isVoid();

  /// {@template method_isFutureVoid}
  /// Determines whether this method declares a `Future<void>` return type.
  ///
  /// This method inspects the declared return type of the method and returns
  /// `true` if it represents an asynchronous computation that completes with
  /// no value (i.e., a `Future<void>`).  
  ///
  /// It is particularly useful in reflection, proxy generation, or method
  /// interceptors where you need to distinguish between:
  /// - **Asynchronous void methods** (`Future<void>`) that perform side effects,
  /// - **Asynchronous value-returning methods** (`Future<T>`), and
  /// - **Synchronous void methods** (`void`).
  ///
  /// ## Example
  /// ```dart
  /// class Example {
  ///   Future<void> save() async {}
  ///   Future<int> compute() async => 42;
  ///   void reset() {}
  /// }
  ///
  /// final saveMethod = Class(Example).getMethod('save');
  /// final computeMethod = Class(Example).getMethod('compute');
  /// final resetMethod = Class(Example).getMethod('reset');
  ///
  /// print(saveMethod.isFutureVoid());   // true
  /// print(computeMethod.isFutureVoid()); // false
  /// print(resetMethod.isFutureVoid());   // false
  /// ```
  ///
  /// @return `true` if the method’s return type is `Future<void>`,
  ///         `false` otherwise.
  /// {@endtemplate}
  bool isFutureVoid();

  /// {@template method_isFutureDynamic}
  /// Determines whether this method declares a `Future<dynamic>` return type.
  ///
  /// This method inspects the declared return type of the method and returns
  /// `true` if it represents an asynchronous computation that completes with
  /// no value (i.e., a `Future<dynamic>`).  
  ///
  /// It is particularly useful in reflection, proxy generation, or method
  /// interceptors where you need to distinguish between:
  /// - **Asynchronous dynamic methods** (`Future<dynamic>`) that perform side effects,
  /// - **Asynchronous value-returning methods** (`Future<T>`), and
  /// - **Synchronous dynamic methods** (`dynamic`).
  ///
  /// ## Example
  /// ```dart
  /// class Example {
  ///   Future<dynamic> save() async {}
  ///   Future<int> compute() async => 42;
  ///   dynamic reset() {}
  /// }
  ///
  /// final saveMethod = Class(Example).getMethod('save');
  /// final computeMethod = Class(Example).getMethod('compute');
  /// final resetMethod = Class(Example).getMethod('reset');
  ///
  /// print(saveMethod.isFutureDynamic());   // true
  /// print(computeMethod.isFutureDynamic()); // false
  /// print(resetMethod.isFutureDynamic());   // false
  /// ```
  ///
  /// @return `true` if the method’s return type is `Future<dynamic>`,
  ///         `false` otherwise.
  /// {@endtemplate}
  bool isFutureDynamic();

  /// {@template method_isAsync}
  /// Determines whether this method is **asynchronous** — i.e., declared using
  /// the `async` keyword or returning a [Future]-like type.
  ///
  /// Unlike [isFutureVoid], which specifically checks for a `Future<void>`
  /// return type, this method performs a broader inspection to determine
  /// whether the method represents *any* asynchronous computation.
  ///
  /// ### Typical Uses
  /// - **Dynamic invocation frameworks**: to decide whether to `await` the result.
  /// - **Proxy or interceptor implementations**: to preserve correct async semantics.
  /// - **Runtime analysis tools**: to distinguish between synchronous and asynchronous flows.
  ///
  /// ### Example
  /// ```dart
  /// class Example {
  ///   Future<void> save() async {}
  ///   Future<int> compute() async => 42;
  ///   void reset() {}
  /// }
  ///
  /// final saveMethod = Class(Example).getMethod('save');
  /// final computeMethod = Class(Example).getMethod('compute');
  /// final resetMethod = Class(Example).getMethod('reset');
  ///
  /// print(saveMethod.isAsync());   // true
  /// print(computeMethod.isAsync()); // true
  /// print(resetMethod.isAsync());   // false
  /// ```
  ///
  /// ### Return
  /// `true` if the method is declared as asynchronous (returns a [Future] or
  /// is marked with `async`), otherwise `false`.
  /// {@endtemplate}
  bool isAsync();

  /// Determines whether this method is a **top-level function** rather than a
  /// class, mixin, or extension member.
  ///
  /// Top-level methods are functions declared directly within a library scope,
  /// such as:
  /// ```dart
  /// void main() {}
  /// int add(int a, int b) => a + b;
  /// ```
  ///
  /// Returns:
  /// - `true` if the method originates from a library’s top-level scope  
  /// - `false` if it belongs to a class, mixin, or extension
  bool getIsTopLevel();

  /// Determines whether this method represents a Dart **entrypoint**, typically
  /// used as the starting execution method for an application.
  ///
  /// A method is considered an entrypoint if:
  /// - Its name is `main`
  /// - It is a top-level function
  /// - It matches one of Dart’s supported entrypoint signatures:
  ///   - `void main()`
  ///   - `void main(List<String> args)`
  ///   - `Future<void> main()`
  ///   - `Future<void> main(List<String> args)`
  ///
  /// Returns:
  /// - `true` if the method is recognized as an application entrypoint  
  /// - `false` otherwise
  bool getIsEntryPoint();

  /// Checks whether this method is declared using the `external` keyword.
  ///
  /// External methods are **implemented outside Dart**, commonly in:
  /// - Native extensions  
  /// - FFI bindings  
  /// - Platform-provided method bodies  
  ///
  /// Because external methods lack a Dart body, reflection and invocation
  /// semantics may differ depending on the runtime.
  ///
  /// **Experimental** — API surface or behavior may change.
  ///
  /// Returns:
  /// - `true` if the method is marked `external`
  /// - `false` otherwise
  bool isExternal();

  /// Indicates whether the method’s return type is nullable.
  ///
  /// This examines the declared return type and determines whether it is
  /// explicitly nullable under Dart’s null-safety type system.
  ///
  /// Examples:
  /// ```dart
  /// int? maybeValue() => null;   // nullable → true
  /// int value() => 1;            // non-nullable → false
  /// ```
  ///
  /// **Experimental** — Nullability inference is reflection-backend–specific.
  ///
  /// Returns:
  /// - `true` if the return type is nullable  
  /// - `false` otherwise
  bool hasNullableReturn();

  /// Determines whether the method declares a return type of `dynamic`.
  ///
  /// This includes both:
  /// - Explicit `dynamic` return types  
  /// - Implicitly inferred dynamic types (depending on reflection backend)  
  ///
  /// Example:
  /// ```dart
  /// dynamic foo() => 42;         // true
  /// bar() => 'implicit dynamic'; // may be true depending on backend
  /// int baz() => 5;              // false
  /// ```
  ///
  /// Returns:
  /// - `true` if the method’s return type is `dynamic`
  /// - `false` otherwise
  bool isDynamic();

  /// Checks whether the method's type is a function type.
  ///
  /// {@template parameter_is_function}
  /// Returns:
  /// - `true` if the method's declared type is a function type, such as:
  ///   - `void Function(int)`
  ///   - `T Function(T)`
  ///   - `Future<void> Function()`
  /// - `false` if the method is not a function type.
  ///
  /// ## Notes
  /// - This does **not** check whether the method *evaluates to* a function,
  ///   only whether its *static type* is a function type.
  /// - Useful when generating invocation wrappers, proxies, or stubs.
  ///
  /// ## Example
  /// ```dart
  /// void example(void Function() callback) {}
  ///
  /// final param = method.getParameters().first;
  /// print(param.isFunction()); // true
  /// ```
  /// {@endtemplate}
  bool isFunction();

  /// Gets the underlying link-time declaration for this method.
  ///
  /// {@template parameter_get_link_declaration}
  /// Returns:
  /// - A [LinkDeclaration] representing the method's static declaration
  ///   in the compile-time model.
  ///
  /// ## What This Represents
  /// - The original source-level declaration from build-time metadata.
  /// - Type, name, and annotation information *before* any runtime resolution.
  ///
  /// ## Why This Matters
  /// - Enables tooling that must operate on compile-time structure:
  ///   - Code generation
  ///   - Static analysis
  ///   - AOP weaving
  ///   - Symbolic evaluation
  ///
  /// ## Example
  /// ```dart
  /// final link = param.getLinkDeclaration();
  /// print(link.name);     // Parameter name
  /// print(link.typeName); // Source-level type
  /// ```
  ///
  /// ## Notes
  /// - This does not consider runtime modifications from mirrors or proxies.
  /// {@endtemplate}
  LinkDeclaration getLinkDeclaration();
  
  /// Gets the method that this method overrides.
  ///
  /// {@template method_overridden_method}
  /// Returns:
  /// - The [Method] from the superclass being overridden
  /// - `null` if this doesn't override any method
  ///
  /// Note:
  /// Only checks direct overrides in the immediate superclass.
  /// {@endtemplate}
  Method? getOverriddenMethod();
  
  /// Invokes the method on an instance with named arguments.
  ///
  /// {@template method_invoke}
  /// Parameters:
  /// - [instance]: The object instance (null for static methods)
  /// - [arguments]: Optional named arguments
  ///
  /// Returns:
  /// - The method's return value
  /// - May return `null` for void methods
  ///
  /// Throws:
  /// - [InvalidArgumentException] if arguments don't match parameters
  /// - [MethodNotFoundException] for invalid invocations
  /// - [PrivateMethodInvocationException] if the method is a private method
  /// - [GenericResolutionException] if the method's type cannot be resolved
  ///
  /// Example:
  /// ```dart
  /// final result = method.invoke(instance, {'param1': value});
  /// 
  /// final result = method.invokeWithArgs(instance, null, [arg1, arg2]);
  /// ```
  /// {@endtemplate}
  dynamic invoke(Object? instance, [Map<String, dynamic>? arguments, List<dynamic> args = const []]);
  
  /// Creates a Method instance from reflection metadata.
  ///
  /// {@template method_factory}
  /// Parameters:
  /// - [declaration]: The method reflection metadata
  /// - [domain]: The protection domain for security
  ///
  /// Returns:
  /// - A concrete [Method] implementation
  ///
  /// Typical implementation:
  /// ```dart
  /// static Method declared(MethodDeclaration d, ProtectionDomain p) {
  ///   return _MethodImpl(d, p);
  /// }
  /// ```
  /// {@endtemplate}
  factory Method.declared(MethodDeclaration declaration, ProtectionDomain domain, [ClassDeclaration? parent]) = _Method;
}