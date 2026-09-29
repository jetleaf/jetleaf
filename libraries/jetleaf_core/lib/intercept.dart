/// 🔄 **Jetleaf Core Interception**
///
/// This library provides support for method-level interception and
/// cross-cutting concerns in Jetleaf applications. It enables
/// behaviors such as logging, metrics collection, transaction
/// management, and custom method interception to be applied
/// declaratively to objects.
///
/// ## Example
///
/// ```dart
/// import 'package:jetleaf_core/intercept.dart';
///
/// class UserService with Interceptable {
///   @LogExecution()
///   Future<String> greet(String name) async => when(() async {
///     return 'Hello, $name';
///   });
/// }
/// ```
///
/// In this example, the `Interceptable` mixin allows Jetleaf to
/// automatically apply cross-cutting behaviors to the `greet`
/// method using the `@LogExecution` annotation.
///
///
/// ## 🔑 Core Components
///
/// ### Method Dispatching
/// - `abstract_method_dispatcher.dart` — base abstraction for
///   dispatching method invocations through interceptors
///
/// ### Interceptors
/// - `method_interceptor.dart` — defines the interceptor interface
/// - `default_method_interceptor.dart` — default method interceptor
///   implementation
///
/// ### Interceptable Objects
/// - `interceptable.dart` — mixin that makes classes interceptable
///   and supports method interception hooks
/// - `method_invocation.dart` — encapsulates method invocation
///   details for interception
/// - `method_argument.dart` — represents method arguments for
///   intercepted calls
///
/// ### Interceptor Management
/// - `intercept_registry.dart` — manages and registers method
///   interceptors for various classes and methods
///
///
/// ## 🎯 Intended Usage
///
/// Import this library to add cross-cutting behaviors to your
/// services or components. Use the `Interceptable` mixin along with
/// method annotations to declaratively apply interceptors:
///
/// ```dart
/// class LoggingService with Interceptable {
///   @LogExecution()
///   void performAction() {
///     // Logging occurs automatically before and after execution
///   }
/// }
/// ```
///
/// Provides a foundation for AOP-style programming in Jetleaf.
///
/// {@category Interception}
library;

export 'src/intercept/abstract_method_dispatcher.dart';
export 'src/intercept/default_method_interceptor.dart';
export 'src/intercept/interceptable.dart';
export 'src/intercept/method_invocation.dart';
export 'src/intercept/method_interceptor.dart';
export 'src/intercept/intercept_registry.dart';