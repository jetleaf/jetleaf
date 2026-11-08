/// 🫘 **Jetleaf Pod Subsystem & Dependency Injection Container**
///
/// This library provides the core dependency-injection (DI) and Inversion of Control (IoC)
/// engine used throughout Jetleaf, built around **Pods** — lightweight, configurable,
/// lifecycle-managed application components.
///
/// It exposes the complete pod lifecycle pipeline, container factory abstractions,
/// scope boundaries, definition registries, aliasing mechanisms, name generation strategies,
/// and startup hooks.
///
/// ---
///
/// ## 🔄 Pod Lifecycle Sequence
///
/// ```text
/// ┌────────────────────────────────────────────────────────────────────────┐
/// │                          Pod Lifecycle Pipeline                        │
/// ├────────────────────────────────────────────────────────────────────────┤
/// │ 1. Registration        [PodDefinitionRegistry.registerDefinition]     │
/// │                                    │                                   │
/// │ 2. Instantiation       [InstanceSupplier] / AOT Constructor Dispatch   │
/// │                                    │                                   │
/// │ 3. Dependency Wiring   Constructor / Field / Setter Injection          │
/// │                                    │                                   │
/// │ 4. Aware Callbacks     [ApplicationContextAware], [EnvironmentAware]   │
/// │                                    │                                   │
/// │ 5. Pre-Initialization  [PodPostProcessor.postProcessBeforeInitialization]│
/// │                                    │                                   │
/// │ 6. Lifecycle Ready     [InitializingPod.onReady] / @PostConstruct      │
/// │                                    │                                   │
/// │ 7. Post-Initialization [PodPostProcessor.postProcessAfterInitialization] │
/// │                                    │                                   │
/// │                           >>> POD IS READY <<<                         │
/// │                                    │                                   │
/// │ 8. Disposal            [DisposablePod.onDestroy] / @PreDestroy         │
/// └────────────────────────────────────────────────────────────────────────┘
/// ```
///
/// ---
///
/// ## 📦 Exports Categorization
///
/// ### 🏭 Core Container Factories
/// - [PodFactory] — the primary read-only interface for retrieving components from the container.
/// - [ConfigurablePodFactory] — configuration interface for scopes, converters, and customizers.
/// - [ConfigurableListablePodFactory] — combined interface for definition inspection and pre-instantiation.
/// - [DefaultListablePodFactory] — the standard, high-performance production IoC container.
///
/// ### 🧱 Pod Definitions & Registries
/// - [PodDefinition] — reflective blueprint describing creation, scope, and wiring rules for a pod.
/// - [RootPodDefinition] — standard concrete pod definition holder.
/// - [PodDefinitionRegistry] — interface for registering, querying, and managing definitions.
/// - [SimplePodDefinitionRegistry] — default in-memory registry implementation.
///
/// ### 🏷️ Alias & Name Management
/// - [AliasRegistry] — maintains symbolic aliases and indirect names for pods.
/// - [SimpleAliasRegistry] — default in-memory alias mapping registry.
/// - [PodNameGenerator] — strategy interface for naming unnamed component definitions.
/// - [SimplePodNameGenerator] — default decapitalized class name generator.
///
/// ### 📍 Scopes & Post-Processors
/// - [Scope] — lifecycle scope boundary strategy (`singleton`, `prototype`).
/// - [PodPostProcessor] — allows custom modification of new pod instances before/after initialization.
/// - [PodFactoryPostProcessor] — allows custom modification of the container's pod definitions.
/// - [SmartInitializingSingleton] — triggered after all singletons have been instantiated.
///
/// ---
///
/// ## 🎯 Usage Example: Programmatic Pod Definition & Injection
///
/// ```dart
/// import 'package:jetleaf/pod.dart';
/// import 'package:jetleaf/lang.dart';
///
/// class DatabasePool {
///   final String url;
///   DatabasePool(this.url);
/// }
///
/// class UserRepository {
///   final DatabasePool pool;
///   UserRepository(this.pool);
/// }
///
/// Future<void> main() async {
///   final factory = DefaultListablePodFactory();
///
///   // 1. Register database pool singleton
///   await factory.registerSingleton(
///     'databasePool',
///     Class<DatabasePool>(),
///     object: ObjectHolder(DatabasePool('postgres://localhost:5432/main')),
///   );
///
///   // 2. Register repository with factory supplier
///   await factory.registerDefinition(
///     'userRepository',
///     RootPodDefinition(
///       type: Class<UserRepository>(),
///       instanceSupplier: (factory) async =>
///           UserRepository(await factory.get<DatabasePool>(Class<DatabasePool>())),
///     ),
///   );
///
///   // 3. Pre-instantiate singletons and retrieve wired instance
///   await factory.preInstantiateSingletons();
///   final repo = await factory.getPod<UserRepository>('userRepository');
///   print('Connected to database: ${repo.pool.url}');
/// }
/// ```
///
/// {@category Jetleaf}
library;

export 'package:jetleaf_core/pod.dart';