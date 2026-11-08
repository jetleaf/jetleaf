/// 🏷️ **Jetleaf Core Annotations Subsystem**
///
/// This library provides the complete declarative metadata annotation suite for Jetleaf applications.
/// Annotations enable declarative configuration, dependency injection, lifecycle interception,
/// conditional component activation, and architectural stereotyping without runtime boilerplate.
///
/// ---
///
/// ## 📦 Annotation Hierarchy
///
/// ```text
/// ┌─────────────────────────────────────────────────────────────┐
/// │                     Jetleaf Annotations                     │
/// ├─────────────────────────────────────────────────────────────┤
/// │ • Stereotypes:      @Component, @Service, @Repository      │
/// │ • Configuration:    @Configuration, @Pod, @Import          │
/// │ • Injection:        @Autowired, @Value, @Qualifier, @Primary│
/// │ • Lifecycle:        @PostConstruct, @PreDestroy, @Lazy     │
/// │ • Conditionals:     @Conditional, @Profile, @Conditional...│
/// │ • Order & Scopes:   @Order, @Scope                         │
/// └─────────────────────────────────────────────────────────────┘
/// ```
///
/// ---
///
/// ## 📦 Exports Categorization
///
/// ### 🏛️ Stereotypes & Components
/// - [Component] — marks a target Dart class as an auto-detectable managed pod.
/// - [Service] — specializes [Component] for business service layers.
/// - [Repository] — specializes [Component] for data access and storage layers.
/// - [Controller] — specializes [Component] for web and presentation routing layers.
///
/// ### ⚙️ Configuration & Module Definition
/// - [Configuration] — marks a class containing pod definitions annotated with `@Pod`.
/// - [Pod] — marks factory methods inside a `@Configuration` class as pod producers.
///
/// ### 💉 Dependency Injection & Wiring
/// - [Autowired] — marks constructors, fields, or setter methods for automatic dependency resolution.
/// - [Value] — injects property values from active environment sources (`@Value('\${server.port:8080}')`).
/// - [Qualifier] — specifies the unique name or qualifier when multiple candidate pods exist.
/// - [Primary] — designates a pod definition as the primary candidate when multiple matches exist.
///
/// ### 🔄 Lifecycle & Ordering
/// - [PostConstruct] — marks a method to execute immediately after dependency injection completes.
/// - [PreDestroy] — marks a method to execute before singleton disposal during context shutdown.
/// - [Order] — sets priority or execution order for pods, interceptors, and listeners.
/// - [Lazy] — defers singleton instantiation until first requested.
///
/// ### 🔍 Conditionals & Profiles
/// - [Conditional] — base annotation associating a custom [Condition] predicate.
/// - [Profile] — restricts component registration to specific active environment profiles.
///
/// ---
///
/// ## 🎯 Usage Example: Declarative Component & Injection
///
/// ```dart
/// import 'package:jetleaf_core/annotation.dart';
///
/// @Configuration()
/// class ApplicationConfig {
///   @Pod()
///   DatabaseDriver databaseDriver(@Value('\${db.url:localhost}') String url) {
///     return DatabaseDriver(url);
///   }
/// }
///
/// @Service()
/// class OrderService {
///   final DatabaseDriver driver;
///
///   @Autowired()
///   OrderService(this.driver);
///
///   @PostConstruct()
///   void init() {
///     print('OrderService initialized and ready.');
///   }
///
///   @PreDestroy()
///   void shutdown() {
///     print('OrderService shutting down.');
///   }
/// }
/// ```
library;

export 'src/core/annotations/lifecycle.dart';
export 'src/core/annotations/autowired.dart';
export 'src/core/annotations/configuration.dart' hide CommonConfiguration;
export 'src/core/annotations/conditional.dart';
export 'src/core/annotations/others.dart';
export 'src/core/annotations/pod.dart';
export 'src/core/annotations/stereotype.dart';
export 'src/core/annotations/intercept.dart';
