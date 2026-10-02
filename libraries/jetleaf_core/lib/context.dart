/// 🌱 **Jetleaf Core Context**
///
/// This library provides the core infrastructure for application
/// context management in Jetleaf, including:
/// - Application context abstractions and implementations
/// - Lifecycle management
/// - Event publishing and listener support
/// - Pod (dependency) registration and post-processing
/// - Exit code handling for graceful shutdown
/// - Type filtering for conditional component registration
///
/// It serves as the foundation for dependency injection, component
/// lifecycle, and event-driven communication within Jetleaf
/// applications.
///
///
/// ## 🔑 Core Components
///
/// ### 🏛 Application Context
/// Core abstractions and implementations of application contexts:
/// - `abstract_application_context.dart` — base abstract class for
///   application contexts
/// - `generic_application_context.dart` — generic implementation of
///   an application context
/// - `annotation_config_application_context.dart` — context
///   supporting annotation-based configuration
/// - `pod_post_processor_manager.dart` — manages lifecycle post-
///   processing of pods
/// - `pod_spec.dart` — defines pod metadata and specifications
///
///
/// ### ⚡ Event Infrastructure
/// Application event publishing and listener support:
/// - `application_event.dart` — base class for application events
/// - `event_listener.dart` — interface for event listeners
/// - `application_event_method_adapter.dart` — adapts methods as
///   event listeners
/// - `simple_application_event_bus.dart` — simple event bus
///   implementation for publishing and dispatching events
///
///
/// ### 🛑 Exit Code Management
/// Tools for handling exit codes during application shutdown:
/// - `exit_code.dart` — represents exit codes
/// - `exit_code_generator.dart` — generates exit codes based on
///   application state or events
///
///
/// ### 🔍 Type Filtering
/// Conditional component registration using type filters:
/// - `type_filter.dart` — base type filter abstraction
/// - `annotation_type_filter.dart` — filter based on annotations
/// - `assignable_type_filter.dart` — filter based on type
///   assignability
/// - `regex_pattern_type_filter.dart` — filter based on class
///   name patterns
///
///
/// ### 🔄 Lifecycle Management
/// Supports bean/pod lifecycle and annotated lifecycle processing:
/// - `lifecycle.dart` — core lifecycle definitions
/// - `application_annotated_lifecycle_processor.dart` — processes
///   annotated lifecycle hooks
/// - `lifecycle_processor.dart` — interface for lifecycle processors
///
///
/// ### ⚙ Application Base Utilities
/// Core utilities and interfaces for application context management:
/// - `keep_alive.dart` — ensures pods remain active as required
/// - `helpers.dart` — general-purpose context helpers
/// - `application_context.dart` — interface for accessing the
///   application context
/// - `application_type.dart` — type metadata for applications
/// - `application_module.dart` — defines modules within the
///   application context
/// - `pod_registrar.dart` — pod/component registration support
/// - `application_conversion_service.dart` — handles type
///   conversion within the application
/// - `application_environment.dart` — access to environment
///   configuration
/// - `pod_factory_customizer.dart` — customize pod factories during
///   initialization
///
///
/// ## 🎯 Intended Usage
///
/// Import this library to manage application context and dependency
/// injection in Jetleaf projects:
/// ```dart
/// import 'package:jetleaf_core/context.dart';
///
/// final context = GenericApplicationContext();
/// context.registerPod<MyService>();
/// ```
///
/// Provides the foundation for dependency injection, lifecycle
/// management, events, and environment awareness in Jetleaf.
///
///
/// © 2025 Hapnium & Jetleaf Contributors
library;

/// Core application context implementations and abstractions.
export 'src/context/core/generic_application_context.dart';
export 'src/context/core/abstract_application_context.dart';
export 'src/context/core/annotation_config_application_context.dart';
export 'src/context/core/pod_post_processor_manager.dart';
export 'src/context/core/pod_spec.dart';

/// Application event publication and listener infrastructure.
export 'src/context/event/application_event.dart';
export 'src/context/event/event_listener.dart';
export 'src/context/event/application_event_method_adapter.dart';
export 'src/context/event/simple_application_event_bus.dart';

/// Exit code management for graceful application shutdown.
export 'src/context/exit_code/exit_code.dart';
export 'src/context/exit_code/exit_code_generator.dart';

/// Type filtering for conditional component registration.
export 'src/context/type_filters/type_filter.dart';
export 'src/context/type_filters/annotation_type_filter.dart';
export 'src/context/type_filters/assignable_type_filter.dart';
export 'src/context/type_filters/regex_pattern_type_filter.dart';

// Lifecycle
export 'src/context/lifecycle/lifecycle.dart';
export 'src/context/lifecycle/application_annotated_lifecycle_processor.dart';
export 'src/context/lifecycle/lifecycle_processor.dart';

/// Lifecycle management, utilities, and core application interfaces.
export 'src/context/base/keep_alive.dart';
export 'src/context/base/helpers.dart' hide EnabledImportClass, DisabledImportClass;
export 'src/context/base/application_context.dart';
export 'src/context/base/application_type.dart';
export 'src/context/base/application_module.dart';
export 'src/context/base/pod_registrar.dart';
export 'src/context/base/application_conversion_service.dart';
export 'src/context/base/application_environment.dart';
export 'src/context/base/pod_factory_customizer.dart';