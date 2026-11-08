/// 🔄 **Jetleaf Core Interception (AOP) Subsystem**
///
/// This library provides runtime method-level interception and cross-cutting concern
/// management for Jetleaf applications. It enables behaviors such as auditing, logging,
/// performance metrics, security authorization, and transaction boundaries to be applied
/// cleanly and declaratively.
///
/// ---
///
/// ## ⛓️ Interceptor Chain Pipeline
///
/// ```text
/// ┌─────────────────────────────────────────────────────────────┐
/// │                     Method Invocation                       │
/// │                   service.performAction()                   │
/// ├─────────────────────────────────────────────────────────────┤
/// │ 1. MethodInterceptor 1   [Before Advice: Logging]          │
/// │                               │                             │
/// │ 2. MethodInterceptor 2   [Around Advice: Security / Auth]   │
/// │                               │                             │
/// │ 3. Target Execution      [Original Method Body Executed]    │
/// │                               │                             │
/// │ 4. Return Value / After  [After Returning / Exception Advice│
/// └─────────────────────────────────────────────────────────────┘
/// ```
///
/// ---
///
/// ## 📦 Exports Categorization
///
/// ### 🔀 Dispatchers & Invocations
/// - [AbstractMethodDispatcher] — orchestrates interceptor chain traversal.
/// - [MethodInvocation] — encapsulates the targeted method, arguments, target instance, and proceed handle.
///
/// ### 🛡️ Interceptor Contracts
/// - [MethodInterceptor] — interceptor interface implementing `invoke(MethodInvocation invocation)`.
/// - [DefaultMethodInterceptor] — default delegating interceptor implementation.
/// - [InterceptRegistry] — registry mapping method signatures to interceptor chains.
///
/// ### 🔌 Interceptables
/// - [Interceptable] — mixin enabling target classes to participate in method interception pipelines.
///
/// ---
///
/// ## 🎯 Usage Example: Custom Logging Method Interceptor
///
/// ```dart
/// import 'package:jetleaf_core/intercept.dart';
///
/// class AuditLoggingInterceptor implements MethodInterceptor {
///   @override
///   Future<Object?> invoke(MethodInvocation invocation) async {
///     final methodName = invocation.getMethod().getName();
///     print('[AOP BEFORE] Invoking method: $methodName');
///
///     final stopwatch = Stopwatch()..start();
///     try {
///       final result = await invocation.proceed();
///       print('[AOP AFTER] Method $methodName completed in ${stopwatch.elapsedMilliseconds} ms');
///       return result;
///     } catch (e) {
///       print('[AOP ERROR] Method $methodName threw: $e');
///       rethrow;
///     }
///   }
/// }
/// ```
library;

export 'src/core/intercept/abstract_method_dispatcher.dart';
export 'src/core/intercept/default_method_interceptor.dart';
export 'src/core/intercept/interceptable.dart';
export 'src/core/intercept/method_invocation.dart';
export 'src/core/intercept/method_interceptor.dart';
export 'src/core/intercept/intercept_registry.dart';
