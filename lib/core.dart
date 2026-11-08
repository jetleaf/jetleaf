/// 🌱 **Jetleaf Core Subsystem & Runtime Context**
///
/// This library provides the primary application kernel, declarative annotations,
/// application context abstractions, event dispatching, method interception,
/// and internationalized messaging for the Jetleaf framework.
///
/// It aggregates and re-exports core functionality from `jetleaf_core`:
/// - **Stereotype Annotations:** `@Component`, `@Service`, `@Repository`, `@Controller`, `@RestController`, `@Configuration`, `@Pod`.
/// - **Injection & Wiring Annotations:** `@Autowired`, `@Value`, `@Primary`, `@Order`, `@Lazy`, `@Scope`, `@Profile`.
/// - **Lifecycle Hooks:** `@PostConstruct`, `@PreDestroy`, `@OnApplicationReady`, `@OnApplicationStarting`.
/// - **Application Contexts:** [ApplicationContext], [ConfigurableApplicationContext], [AnnotationConfigApplicationContext].
/// - **Event Bus:** [ApplicationEvent], [ApplicationListener], [ApplicationEventPublisher].
/// - **Health & Availability:** [ApplicationAvailability], [LivenessState], [ReadinessState].
/// - **Method Interception:** `@Intercept`, [Interceptable], [MethodInterceptor], [InvocationContext].
/// - **Message Sources:** [MessageSource], localized string resolution.
///
/// ---
///
/// ## 🏛️ Core Context & Application Topology
///
/// ```text
/// ┌────────────────────────────────────────────────────────────────────────┐
/// │                     Jetleaf Core Application Kernel                    │
/// ├─────────────────────┬──────────────────────┬───────────────────────────┤
/// │    Context Model    │  Event Infrastructure│    Cross-Cutting AOP      │
/// ├─────────────────────┼──────────────────────┼───────────────────────────┤
/// │ • ApplicationContext│ • ApplicationEvent   │ • @Intercept              │
/// │ • AnnotationConfig  │ • EventPublisher     │ • MethodInterceptor       │
/// │ • GenericContext    │ • ApplicationListener│ • InvocationContext       │
/// ├─────────────────────┴──────────────────────┴───────────────────────────┤
/// │                     Availability & Health Lifecycle                    │
/// ├───────────────────────────────────────────┬────────────────────────────┤
/// │            LivenessState                  │       ReadinessState       │
/// ├───────────────────────────────────────────┼────────────────────────────┤
/// │ • CORRECT (healthy internal state)        │ • ACCEPTING_TRAFFIC (ready)│
/// │ • BROKEN  (fatal failure, restart needed) │ • REFUSING_TRAFFIC (warmup)│
/// └───────────────────────────────────────────┴────────────────────────────┘
/// ```
///
/// ---
///
/// ## 📦 Exports Categorization
///
/// ### 🏷️ Declarative Component Stereotypes
/// - `@Component` — marks an auto-discoverable managed pod.
/// - `@Service` — business layer stereotype with semantics for transactional/audited processing.
/// - `@Repository` — data access and persistence abstraction layer.
/// - `@Controller`, `@RestController` — web presentation and HTTP API endpoint handlers.
/// - `@Configuration`, `@Pod` — programmatic pod definition factory classes.
///
/// ### 💉 Injection & Wiring Directives
/// - `@Autowired` — container dependency injection directive for fields and properties.
/// - `@Value` — configuration expression evaluation and property value injection.
/// - `@Primary` — designates the primary candidate when multiple pods match a dependency type.
/// - `@Order` — precedence and ordering index for listeners, filters, and runners.
/// - `@Lazy` — defers pod initialization until first explicit retrieval.
/// - `@Profile` — restricts pod registration to specific active environment profiles.
///
/// ### 🔄 Lifecycle & Event Callbacks
/// - `@PostConstruct` — invoked immediately following complete dependency resolution.
/// - `@PreDestroy` — invoked during graceful application shutdown.
/// - `@OnApplicationReady`, `@OnApplicationStarting` — framework startup phase notifications.
/// - [ApplicationEvent], [ApplicationListener] — decoupled observer pub/sub engine.
///
/// ### 🛡️ Method Interception & AOP
/// - `@Intercept` — declarative interception pointcut annotation.
/// - [MethodInterceptor] — around-advice interceptor contract for logging, metrics, or security.
/// - [InvocationContext] — reflective invocation descriptor with target, arguments, and proceed handle.
///
/// ---
///
/// ## 🎯 Usage Example: Service Component with Lifecycle & Events
///
/// ```dart
/// import 'package:jetleaf/core.dart';
///
/// // Custom domain event
/// class UserRegisteredEvent extends ApplicationEvent {
///   final String email;
///   UserRegisteredEvent(this.email) : super(email);
/// }
///
/// @Service('userService')
/// class UserService {
///   final ApplicationEventPublisher _eventPublisher;
///   bool _initialized = false;
///
///   UserService(this._eventPublisher);
///
///   @PostConstruct()
///   void init() {
///     _initialized = true;
///     print('UserService initialized and ready.');
///   }
///
///   void registerUser(String email) {
///     print('Registering user: $email');
///     _eventPublisher.publishEvent(UserRegisteredEvent(email));
///   }
///
///   @PreDestroy()
///   void dispose() {
///     print('UserService shutting down.');
///   }
/// }
///
/// @Component()
/// class WelcomeEmailSender implements ApplicationListener<UserRegisteredEvent> {
///   @override
///   void onApplicationEvent(UserRegisteredEvent event) {
///     print('Sending welcome email to: ${event.email}');
///   }
/// }
/// ```
///
/// {@category Jetleaf}
library;

export 'package:jetleaf_core/annotation.dart';
export 'package:jetleaf_core/core.dart';
export 'package:jetleaf_core/context.dart';
export 'package:jetleaf_core/intercept.dart';
export 'package:jetleaf_core/message.dart';
export 'package:jetleaf_core/jetleaf_core.dart';
