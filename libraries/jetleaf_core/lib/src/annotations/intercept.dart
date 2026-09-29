import 'package:jetleaf_lang/lang.dart';
import 'package:meta/meta_meta.dart';

/// {@template jetleaf_run_before}
/// A reflective annotation that declares that the annotated
/// **interceptor, filter, or handler** should execute **before**
/// one or more specified targets within the Jetleaf request
/// processing pipeline.
///
///
/// ### Overview
///
/// The [RunBefore] annotation is part of Jetleaf’s **interceptor
/// ordering system**, allowing developers to define **explicit
/// execution precedence** between different interceptors or filters.
///
/// When Jetleaf builds the interceptor chain for a given
/// request, it uses these annotations to sort components
/// deterministically—ensuring that certain interceptors
/// (e.g. logging, metrics, security) execute in a specific order.
///
///
/// ### Usage Example
///
/// ```dart
/// @RunBefore([AuthInterceptor, 'metrics_interceptor'])
/// class LoggingInterceptor implements HandlerInterceptor {
///   @override
///   Future<bool> preHandle(req, res, handler) async {
///     print('Incoming request: ${req.getUri()}');
///     return true;
///   }
/// }
/// ```
///
/// In this example:
/// - The `LoggingInterceptor` will always run **before**
///   both `AuthInterceptor` and the interceptor registered
///   under the pod name `'metrics_interceptor'`.
///
///
/// ### Supported Target Types
///
/// - **Type references** (e.g. `AuthInterceptor`)  
///   → Jetleaf resolves these based on class types.
/// - **String pod names** (e.g. `'security_interceptor'`)  
///   → Used when the interceptor is registered dynamically
///     or under a dependency injection pod.
///
///
/// ### Framework Integration
///
/// During interceptor registration, Jetleaf reads all
/// [RunBefore] and [RunAfter] annotations and computes
/// an execution graph.  
///
/// It then uses **topological sorting** to produce a
/// stable and deterministic interceptor order.
///
///
/// ### Example of Combined Usage
///
/// ```dart
/// @RunBefore([AuthInterceptor])
/// class MetricsInterceptor {}
///
/// @RunAfter([MetricsInterceptor])
/// class AuthInterceptor {}
/// ```
///
/// The framework will always ensure:
/// `MetricsInterceptor → AuthInterceptor`
///
///
/// ### Design Notes
///
/// - Used only at **class-level**, enforced via `@Target({TargetKind.classType})`.  
/// - Extends [ReflectableAnnotation] for runtime resolution through Jetleaf’s
///   reflection system.  
/// - The ordering is **advisory**, meaning if a referenced interceptor
///   isn’t registered, the system skips it gracefully.
///
///
/// ### Related Annotations
///
/// - [RunAfter] — declares execution ordering **after** another target.
///
///
/// ### Summary
///
/// The [RunBefore] annotation provides fine-grained control over interceptor
/// execution order, improving modularity and predictability in complex request
/// pipelines.
///
/// {@endtemplate}
@Target({TargetKind.classType})
final class RunBefore extends ReflectableAnnotation {
  /// The list of targets (either [Type]s or [String] pod names)
  /// that this interceptor should execute **before**.
  final List<Object> targets;

  /// {@macro jetleaf_run_before}
  const RunBefore(this.targets);

  @override
  Type get annotationType => RunBefore;
}

/// {@template jetleaf_run_after}
/// A reflective annotation that declares that the annotated
/// **interceptor, filter, or handler** should execute **after**
/// one or more specified targets within the Jetleaf request
/// processing pipeline.
///
///
/// ### Overview
///
/// The [RunAfter] annotation complements [RunBefore], allowing
/// developers to define **relative ordering constraints**
/// between interceptors in Jetleaf’s request execution chain.
///
/// This annotation is crucial when interceptors depend on
/// preconditions or states established by others—for example,
/// ensuring that security validation runs before logging,
/// or that metrics aggregation runs after response finalization.
///
///
/// ### Usage Example
///
/// ```dart
/// @RunAfter([LoggingInterceptor, 'security_interceptor'])
/// class AuthInterceptor implements HandlerInterceptor {
///   @override
///   Future<bool> preHandle(req, res, handler) async {
///     if (!req.headers.containsKey('Authorization')) {
///       throw UnauthorizedException('Missing Authorization header');
///     }
///     return true;
///   }
/// }
/// ```
///
/// In this example:
/// - `AuthInterceptor` will execute **after**
///   both `LoggingInterceptor` and the interceptor registered
///   as `'security_interceptor'`.
///
///
/// ### Supported Target Types
///
/// - **Type references** (e.g. `LoggingInterceptor`)  
/// - **String pod names** (e.g. `'metrics_interceptor'`)
///
///
/// ### Framework Integration
///
/// When Jetleaf constructs the interceptor execution chain,
/// it merges [RunBefore] and [RunAfter] declarations into a
/// unified precedence graph, then performs **topological sorting**
/// to determine the correct invocation sequence.
///
///
/// ### Combined Example
///
/// ```dart
/// @RunBefore([AuthInterceptor])
/// class MetricsInterceptor {}
///
/// @RunAfter([MetricsInterceptor])
/// class AuthInterceptor {}
/// ```
///
/// → Jetleaf will ensure that:
/// `MetricsInterceptor` runs **before** `AuthInterceptor`.
///
///
/// ### Design Notes
///
/// - Used exclusively at **class-level**, enforced via `@Target({TargetKind.classType})`.  
/// - Relies on [ReflectableAnnotation] for runtime introspection.  
/// - Safely ignored if a referenced interceptor does not exist in the current context.  
///
///
/// ### Related Annotations
///
/// - [RunBefore] — declares inverse ordering (run **before** targets).
///
///
/// ### Summary
///
/// The [RunAfter] annotation provides declarative, fine-grained
/// control over interceptor sequencing, ensuring consistent,
/// predictable, and maintainable request processing order.
///
/// {@endtemplate}
@Target({TargetKind.classType})
final class RunAfter extends ReflectableAnnotation {
  /// The list of targets (either [Type]s or [String] pod names)
  /// that this interceptor should execute **after**.
  final List<Object> targets;

  /// {@macro jetleaf_run_after}
  const RunAfter(this.targets);

  @override
  Type get annotationType => RunAfter;
}