/// 🍃 **Jetleaf Core Framework**
///
/// The unified core runtime library powering the Jetleaf ecosystem.
/// `jetleaf_core` consolidates inversion of control (IoC), dependency injection,
/// hierarchical environment configuration, declarative metadata annotations,
/// event-driven messaging, structured logging, high-performance collections,
/// and extensible type conversion into a single, cohesive framework.
///
/// Engineered from the ground up for **pure Dart Ahead-Of-Time (AOT)** compilation
/// (`dart compile exe`) with zero reliance on `dart:mirrors` and zero reflection runtime overhead.
///
/// ---
///
/// ## 🏛️ Subsystem Topology
///
/// ```text
/// ┌────────────────────────────────────────────────────────────────────────┐
/// │                          jetleaf_core (2.0.0)                          │
/// ├──────────────┬──────────────┬──────────────┬──────────────┬────────────┤
/// │   core/      │   pod/       │   env/       │   logging/   │  convert/  │
/// │ Context,     │ IoC Pods,    │ Profiles,    │ Structured,  │ Type-Safe  │
/// │ Lifecycle,   │ Injection,   │ YAML/JSON/ENV│ Leveled,     │ Converters,│
/// │ Event Bus    │ Lifecycles   │ Sources      │ Colorized    │ Registry   │
/// ├──────────────┴──────────────┴──────────────┴──────────────┴────────────┤
/// │                          lang/ & utils/                                │
/// │  Class<T>, Mirrorless Introspection, Custom Collections, Stream I/O   │
/// └────────────────────────────────────────────────────────────────────────┘
/// ```
///
/// ---
///
/// ## 📦 Subsystems Overview
///
/// 1. **Core Context (`core.dart`, `context.dart`)**:
///    - Application context lifecycle (`AnnotationConfigApplicationContext`, `GenericApplicationContext`).
///    - Event bus (`ApplicationEvent`, `ApplicationListener`, `SimpleApplicationEventMulticaster`).
///    - Conditional evaluation (`@Conditional`, `ConditionEvaluator`).
///    - Application availability states (`LivenessState`, `ReadinessState`).
///
/// 2. **Dependency Injection & Pods (`pod.dart`)**:
///    - Inversion of Control container (`DefaultListablePodFactory`).
///    - Declarative pod definitions (`RootPodDefinition`, `PodDefinition`).
///    - Lifecycle integration (`InitializingPod`, `DisposablePod`, `@PostConstruct`, `@PreDestroy`).
///    - Flexible scopes (`singleton`, `prototype`).
///
/// 3. **Environment & Configuration (`env.dart`, `property.dart`)**:
///    - Hierarchical property sources (`MapPropertySource`, `SystemEnvironmentPropertySource`).
///    - Environment profiles (`dev`, `prod`, `test`).
///    - Type-safe property resolution with default fallbacks.
///
/// 4. **Logging Engine (`logging.dart`, `printers.dart`)**:
///    - Leveled, structured diagnostic logging (`Logger`).
///    - ANSI colorized terminal formatting (`PrettyPrinter`).
///    - Custom log processor and listener pipelines.
///
/// 5. **Type Conversion (`convert.dart`)**:
///    - Extensible type conversion subsystem (`DefaultConversionService`).
///    - Two-way converters (`Converter<S, T>`).
///    - Built-in converters for dates, durations, primitives, collections, and enums.
///
/// 6. **Language Primitives & Reflection (`lang.dart`, `collections.dart`, `io.dart`)**:
///    - Type-safe reflection abstraction (`Class<T>`, `Method`, `Constructor`, `Field`).
///    - Specialized collections (`ArrayList`, `LinkedQueue`, `CaseInsensitiveMap`).
///    - Reactive I/O and stream building (`BaseStream`, `StreamBuilder`).
///
/// 7. **Framework Utilities (`utils.dart`)**:
///    - Property placeholder resolution (`${app.port:8080}`).
///    - Configuration parsing (YAML, JSON, Properties, ENV).
///    - Sanitized stack trace decoding and assertion helpers.
///
/// ---
///
/// ## 🚀 Complete Context Example
///
/// ```dart
/// import 'package:jetleaf_core/jetleaf_core.dart';
///
/// // 1. Define a domain service with lifecycle contracts
/// class PaymentGateway implements InitializingPod, DisposablePod {
///   final String apiKey;
///   bool _connected = false;
///
///   PaymentGateway({required this.apiKey});
///
///   @override
///   String getPackageName() => 'my_app';
///
///   @override
///   Future<void> onReady() async {
///     _connected = true;
///     print('PaymentGateway connected successfully.');
///   }
///
///   @override
///   Future<void> onDestroy() async {
///     _connected = false;
///     print('PaymentGateway disconnected.');
///   }
///
///   bool charge(double amount) => _connected && amount > 0;
/// }
///
/// // 2. Bootstrap the application container
/// void main() async {
///   final log = Logger(name: 'Main');
///   log.info('Starting Jetleaf Core container...');
///
///   // Set up environment with custom properties
///   final env = ApplicationEnvironment();
///   env.getPropertySources().addLast(MapPropertySource('app-props', {
///     'gateway.key': 'secret_live_key_9948',
///     'gateway.timeout': '00:05',
///   }));
///
///   // Initialize IoC factory
///   final factory = DefaultListablePodFactory();
///
///   // Register pod definition with constructor injection
///   await factory.registerDefinition('paymentGateway', RootPodDefinition(
///     type: Class<PaymentGateway>(),
///     instanceSupplier: (f) => PaymentGateway(
///       apiKey: env.getProperty('gateway.key', 'default_key')!,
///     ),
///   ));
///
///   // Pre-instantiate singletons & trigger onReady()
///   await factory.preInstantiateSingletons();
///
///   // Retrieve and execute the pod
///   final gateway = await factory.getPod<PaymentGateway>('paymentGateway');
///   final success = gateway?.charge(99.95) ?? false;
///   log.info('Payment processed: $success');
///
///   // Cleanly dispose container singletons
///   await factory.destroySingletons();
/// }
/// ```
library;

export 'lang.dart';
export 'convert.dart';
export 'logging.dart';
export 'utils.dart';
export 'env.dart';
export 'pod.dart';
export 'core.dart';
