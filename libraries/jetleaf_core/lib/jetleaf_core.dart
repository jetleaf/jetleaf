/// 🌱 **Jetleaf Core**
///
/// The central library providing foundational infrastructure for
/// Jetleaf applications. It aggregates key modules for:
/// - Dependency injection and application context management
/// - Method interception and cross-cutting concerns
/// - Internationalization (i18n) and message management
/// - Core utilities and base abstractions
/// - Declarative configuration via annotations
///
/// By importing this library, developers gain access to all core
/// functionalities required to build modular, maintainable, and
/// extensible Jetleaf applications.
///
///
/// ## 🔑 Included Modules
///
/// ### 🏷 Annotations
/// Provides lifecycle, dependency injection, configuration, conditional,
/// pod/scoping, stereotype, and interception annotations.
/// - `annotation.dart`
///
/// ### 🏛 Application Context
/// Core abstractions, context lifecycle, pod registration, event
/// management, and environment support.
/// - `context.dart`
///
/// ### 🔄 Interception
/// Method-level interception support for cross-cutting concerns.
/// - `intercept.dart`
///
/// ### 🌐 Messaging
/// Message source management, internationalization, and localization.
/// - `message.dart`
///
/// ### ⚡ Core Utilities
/// Base abstractions, utilities, and foundational components for
/// building Jetleaf applications.
/// - `core.dart`
///
///
/// ## 🎯 Intended Usage
///
/// Import this library to access all core Jetleaf features:
///
/// ```dart
/// import 'package:jetleaf_core/jetleaf_core.dart';
///
/// final context = GenericApplicationContext();
/// context.registerPod<MyService>();
///
/// class UserService with Interceptable {
///   @LogExecution()
///   void greet() => print('Hello!');
/// }
/// ```
///
/// Provides a comprehensive foundation for IoC, AOP, i18n, lifecycle,
/// and modular application architecture.
///
/// {@category Core}
library;

export 'annotation.dart';
export 'context.dart';
export 'intercept.dart';
export 'message.dart';
export 'core.dart';