/// 🌱 **Jetleaf Application Context Subsystem**
///
/// This library provides the core application context abstractions for the Jetleaf framework.
/// The [ApplicationContext] is the central coordinating engine that provides:
/// - **IoC Container Management:** Instantiating, configuring, and wiring pods.
/// - **Event Multicasting:** Decoupled publisher-subscriber event bus infrastructure.
/// - **Lifecycle Orchestration:** Coordinated startup and shutdown phases.
/// - **Environment Integration:** Access to active profiles and property sources.
/// - **Resource & Type Discovery:** Type filtering, classpath scanning, and module modularization.
///
/// ---
///
/// ## 🔄 Application Context Lifecycle Phases
///
/// ```text
/// ┌─────────────────────────────────────────────────────────────┐
/// │                 Application Context Lifecycle               │
/// ├─────────────────────────────────────────────────────────────┤
/// │ 1. Bootstrap Phase      Create context & bind Environment   │
/// │                               │                             │
/// │ 2. Configuration Phase  Register modules & definitions      │
/// │                               │                             │
/// │ 3. Processor Phase      Run PodFactoryPostProcessors        │
/// │                               │                             │
/// │ 4. Singleton Phase      Pre-instantiate singleton pods      │
/// │                               │                             │
/// │ 5. Start Phase          Publish ContextRefreshedEvent       │
/// │                               │                             │
/// │                      >>> CONTEXT RUNNING <<<                │
/// │                               │                             │
/// │ 6. Shutdown Phase       Run @PreDestroy & DisposablePods    │
/// │                               │                             │
/// │ 7. Closed Phase         Publish ContextClosedEvent          │
/// └─────────────────────────────────────────────────────────────┘
/// ```
///
/// ---
///
/// ## 📦 Exports Categorization
///
/// ### 🏛️ Context Implementations
/// - [ApplicationContext] — central interface providing application configuration and runtime capabilities.
/// - [AnnotationConfigApplicationContext] — standalone context accepting annotated classes and modules.
/// - [GenericApplicationContext] — generic context holding a single internal [DefaultListablePodFactory].
/// - [AbstractApplicationContext] — abstract base implementing the standard lifecycle refresh sequence.
///
/// ### 📢 Event-Driven Messaging
/// - [ApplicationEvent] — base class for events published across the application context.
/// - [EventListener] — annotation marking methods as event listeners.
/// - [SimpleApplicationEventBus] — multicaster dispatching events to registered listeners.
///
/// ### 🔄 Lifecycle Processors
/// - [Lifecycle] — common interface defining methods for start/stop lifecycle control.
/// - [LifecycleProcessor] — strategy interface for processing lifecycle beans within the context.
///
/// ### 🔍 Type Filtering
/// - [TypeFilter] — designator matching classes during classpath scanning.
/// - [AnnotationTypeFilter] — matches classes annotated with a specific annotation.
/// - [AssignableTypeFilter] — matches classes assignable to a given target type.
///
/// ---
///
/// ## 🎯 Usage Example: Bootstrapping Context & Event Dispatch
///
/// ```dart
/// import 'package:jetleaf_core/context.dart';
/// import 'package:jetleaf_core/pod.dart';
/// import 'package:jetleaf_core/lang.dart';
///
/// // Custom domain event
/// class OrderPlacedEvent extends ApplicationEvent {
///   final String orderId;
///   OrderPlacedEvent(super.source, this.orderId);
/// }
///
/// void main() async {
///   // 1. Create context
///   final context = AnnotationConfigApplicationContext();
///
///   // 2. Register event listener
///   context.addApplicationListener<OrderPlacedEvent>((event) {
///     print('Event received: Order #${event.orderId} processed.');
///   });
///
///   // 3. Initialize and refresh context
///   await context.refresh();
///
///   // 4. Publish custom event over the bus
///   context.publishEvent(OrderPlacedEvent(context, 'ORD-8821'));
///
///   // 5. Cleanly shut down context
///   await context.close();
/// }
/// ```
library;

export 'src/core/context/core/generic_application_context.dart';
export 'src/core/context/core/abstract_application_context.dart';
export 'src/core/context/core/annotation_config_application_context.dart';
export 'src/core/context/core/pod_post_processor_manager.dart';
export 'src/core/context/core/pod_spec.dart';

export 'src/core/context/event/application_event.dart';
export 'src/core/context/event/event_listener.dart';
export 'src/core/context/event/application_event_method_adapter.dart';
export 'src/core/context/event/simple_application_event_bus.dart';

export 'src/core/context/exit_code/exit_code.dart';
export 'src/core/context/exit_code/exit_code_generator.dart';

export 'src/core/context/type_filters/type_filter.dart';
export 'src/core/context/type_filters/annotation_type_filter.dart';
export 'src/core/context/type_filters/assignable_type_filter.dart';
export 'src/core/context/type_filters/regex_pattern_type_filter.dart';

export 'src/core/context/lifecycle/lifecycle.dart';
export 'src/core/context/lifecycle/application_annotated_lifecycle_processor.dart';
export 'src/core/context/lifecycle/lifecycle_processor.dart';

export 'src/core/context/base/keep_alive.dart';
export 'src/core/context/base/helpers.dart' hide EnabledImportClass, DisabledImportClass;
export 'src/core/context/base/application_context.dart';
export 'src/core/context/base/application_type.dart';
export 'src/core/context/base/application_module.dart';
export 'src/core/context/base/pod_registrar.dart';
export 'src/core/context/base/application_conversion_service.dart';
export 'src/core/context/base/application_environment.dart';
export 'src/core/context/base/pod_factory_customizer.dart';
