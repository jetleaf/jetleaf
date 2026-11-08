/// 🍃 **Jetleaf Framework: The Comprehensive Enterprise Application Engine**
///
/// The central entry point for the Jetleaf application framework. This library
/// unifies the entire Jetleaf ecosystem, aggregating application bootstrapping,
/// dependency injection, environment configuration, structured logging, type conversion,
/// cross-cutting method interception, and graceful shutdown handling.
///
/// ---
///
/// ## 🏛️ Unified Modular Architecture
///
/// Jetleaf organizes its runtime capabilities into clean, high-performance submodules
/// that can be imported together via `package:jetleaf/jetleaf.dart` or imported individually
/// for targeted boundaries:
///
/// ```text
/// ┌────────────────────────────────────────────────────────────────────────┐
/// │                     Jetleaf Framework (v2.0.0)                         │
/// ├─────────────────────┬──────────────────────┬───────────────────────────┤
/// │ • jetleaf/jetleaf   │ Root aggregator      │ Complete unified engine   │
/// │ • jetleaf/core      │ Context & AOP        │ Core context, events, AOP │
/// │ • jetleaf/pod       │ Dependency Injection │ PodFactory, IoC container │
/// │ • jetleaf/env       │ Configuration        │ Profiles, PropertySources │
/// │ • jetleaf/logging   │ Diagnostics          │ Leveled structured logger │
/// │ • jetleaf/convert   │ Data Transformation  │ Type conversion pipeline  │
/// │ • jetleaf/utils     │ Utilities            │ Strings, Assert, Optional │
/// │ • jetleaf/lang      │ Language Primitives  │ Reflective Class tokens   │
/// └─────────────────────┴──────────────────────┴───────────────────────────┘
/// ```
///
/// ---
///
/// ## 🔑 Core Capabilities
///
/// - **Application Bootstrap:** [JetleafApplication] and [JetleafApplicationStarter]
///   manage the startup sequence, environment parsing, banner display, and shutdown hooks.
/// - **Inversion of Control (IoC):** Advanced pod container supporting constructor,
///   field (`@Autowired`), and factory method (`@Pod`) dependency injection.
/// - **Ahead-Of-Time (AOT) Tooling:** 100% mirror-free execution compatible with
///   `dart compile exe` via compile-time static AST code synthesis (`jetleaf_tools`).
/// - **Hierarchical Environment:** Dynamic profile activation (`@Profile`, `--jetleaf.profiles.active`)
///   and cascading configuration property resolution.
/// - **Lifecycle Management:** Deterministic hook execution: `@PostConstruct`, `@PreDestroy`,
///   `@OnApplicationStarting`, and `@OnApplicationReady`.
/// - **Application Runners:** Dedicated execution interfaces: [CommandLineRunner]
///   and [ApplicationRunner] for CLI and batch workflows.
///
/// ---
///
/// ## 🎯 Usage Example: Bootstrapping a Complete Application
///
/// ```dart
/// import 'package:jetleaf/jetleaf.dart';
///
/// // 1. Service with injected properties
/// @Service('greetingService')
/// class GreetingService {
///   @Value('#{app.greeting:Hello}')
///   late String prefix;
///
///   String greet(String recipient) => '$prefix, $recipient!';
/// }
///
/// // 2. Main application starter implementing CommandLineRunner
/// @JetleafApplicationStarter()
/// class MyApplication implements CommandLineRunner {
///   final GreetingService _service;
///
///   MyApplication(this._service);
///
///   @override
///   void run(List<String> args) {
///     print(_service.greet('Jetleaf Developer'));
///   }
/// }
///
/// // 3. Bootstrap entry point
/// void main(List<String> args) async {
///   await JetleafApplication.run(
///     MyApplication,
///     args,
///   );
/// }
/// ```
///
/// {@category Jetleaf}
library;

export 'main.dart';
export 'lang.dart';
export 'env.dart';
export 'core.dart';
export 'pod.dart';
export 'convert.dart';
export 'logging.dart';
export 'utils.dart';
