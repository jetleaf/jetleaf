/// 🌱 **Jetleaf Core Subsystem**
///
/// This library provides the fundamental application runtime kernel for Jetleaf,
/// encapsulating:
/// - **Application Context Abstractions:** Lifecycle-aware execution environments.
/// - **Application Availability & Health:** Standardized `LivenessState` and `ReadinessState` probing.
/// - **Conditional Infrastructure:** Fine-grained evaluation of `@Conditional` predicates.
/// - **Failure Diagnostics:** Automated analysis and human-readable reporting of startup failures.
/// - **Ordering & Precedence:** Annotation-aware comparator contracts.
///
/// ---
///
/// ## 🚦 Availability State Machine
///
/// Jetleaf models application availability using two distinct lifecycle dimensions:
///
/// ```text
/// ┌─────────────────────────────────────────────────────────────┐
/// │                     Application Availability                │
/// ├──────────────────────────────┬──────────────────────────────┤
/// │        LivenessState         │        ReadinessState        │
/// ├──────────────────────────────┼──────────────────────────────┤
/// │ • CORRECT                    │ • ACCEPTING_TRAFFIC          │
/// │   (Internal state is valid)  │   (Ready to serve requests)  │
/// │                              │                              │
/// │ • BROKEN                     │ • REFUSING_TRAFFIC           │
/// │   (Fatal error, must restart)│   (Warmup, draining, busy)   │
/// └──────────────────────────────┴──────────────────────────────┘
/// ```
///
/// ---
///
/// ## 📦 Exports Categorization
///
/// ### 🚦 Availability & Health Probing
/// - [ApplicationAvailability] — interface for querying active liveness and readiness states.
/// - [AvailabilityChangeEvent] — published when application availability changes.
/// - [LivenessState], [ReadinessState] — standard availability status enums.
///
/// ### 🔍 Conditional Component Registration
/// - [Condition] — functional contract determining whether a component definition should register.
/// - [ConditionEvaluator] — evaluates conditions against active environment properties and container state.
/// - [Conditions] — built-in condition strategies (e.g., conditional on property, profile, or pod presence).
///
/// ### 🩺 Diagnostics & Failure Analysis
/// - [ExceptionDiagnoser] — analyzes raw exceptions and produces structured [ApplicationDiagnostics].
/// - [ExceptionReporter] — renders diagnostic analysis to logs, consoles, or monitoring sinks.
/// - [LoggableExceptionDiagnosisReporter] — formatted diagnostic output engine.
///
/// ### 🏷️ Scopes & Order
/// - [ScopeMetadataResolver] — resolves lifecycle scopes from class annotations.
/// - [AnnotationAwareOrderComparator] — sorts pods and interceptors honoring `@Order` semantics.
///
/// ---
///
/// ## 🎯 Usage Example: Probing Availability & Handling Diagnostics
///
/// ```dart
/// import 'package:jetleaf_core/core.dart';
///
/// void main() async {
///   final context = AnnotationConfigApplicationContext();
///   await context.refresh();
///
///   // Query application availability
///   final availability = context.getPod<ApplicationAvailability>();
///   if (availability != null) {
///     print('Liveness: ${availability.getLivenessState()}');
///     print('Readiness: ${availability.getReadinessState()}');
///
///     // Change availability state (e.g. during maintenance or warmup)
///     AvailabilityChangeEvent.publish(
///       context,
///       ReadinessState.REFUSING_TRAFFIC,
///     );
///   }
///
///   await context.close();
/// }
/// ```
library;

export 'src/core/availability/application_availability.dart';
export 'src/core/availability/application_availability_auto_configuration.dart';
export 'src/core/availability/availability_event.dart';
export 'src/core/availability/availability_state.dart';

export 'src/core/context/condition/condition.dart';
export 'src/core/context/condition/conditions.dart';
export 'src/core/context/condition/condition_evaluator.dart';

export 'src/core/diagnostics/application_diagnostics.dart' hide ExceptionDiagnosticsManager;
export 'src/core/diagnostics/abstract_exception_diagnoser.dart';
export 'src/core/diagnostics/exception_diagnoser.dart';
export 'src/core/diagnostics/exception_reporter.dart';
export 'src/core/diagnostics/loggable_exception_diagnosis_reporter.dart';

export 'src/core/scope/annotated_scope_metadata_resolver.dart';
export 'src/core/scope/scope_metadata_resolver.dart';

export 'src/core/startup/startup_event.dart';

export 'src/core/aware.dart';
export 'src/core/exceptions.dart';
export 'src/core/resource.dart';
export 'src/core/annotation_aware_order_comparator.dart';

export 'annotation.dart';
export 'context.dart';
export 'format.dart';
export 'intercept.dart';
export 'message.dart';