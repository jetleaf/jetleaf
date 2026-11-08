/// 🫘 **Jetleaf Pod Dependency Injection & IoC Subsystem**
///
/// This library provides the core dependency-injection (DI) and Inversion of Control (IoC)
/// engine used throughout Jetleaf, built around **Pods** — lightweight, configurable,
/// lifecycle-managed application components.
///
/// It exposes the complete pod lifecycle pipeline, factory abstractions, scope boundaries,
/// definition registries, aliasing systems, name generation strategies, and startup hooks.
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
/// │ 3. Dependency Wiring   Constructor / Field / Method Injection          │
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
/// ### 🏭 Core Factories
/// - [PodFactory] — the root interface for accessing components from the IoC container.
/// - [AbstractPodFactory] — base type resolution and circular dependency detection.
/// - [AbstractAutowirePodFactory] — autowiring, injection strategies, and post-processor orchestration.
/// - [DefaultListablePodFactory] — the primary, fully-featured production IoC container implementation.
///
/// ### 🧱 Pod Definitions & Registries
/// - [PodDefinition] — metadata blueprint describing how a pod is created, scoped, and wired.
/// - [RootPodDefinition] — standard concrete pod definition holder.
/// - [PodDefinitionRegistry] — interface for registering, querying, and managing definitions.
/// - [SimplePodDefinitionRegistry] — default in-memory registry implementation.
///
/// ### 🏷️ Alias & Name Management
/// - [AliasRegistry] — maintains symbolic aliases and indirect names for pods.
/// - [SimpleAliasRegistry] — default in-memory alias mapping registry.
/// - [PodNameGenerator] — strategy interface for naming unnamed pod definitions.
/// - [SimplePodNameGenerator] — default decapitalized class name generator.
///
/// ### 📍 Scopes & Caching
/// - [Scope] — boundary contract for pod instances (`singleton`, `prototype`, request-bound).
/// - [SingletonPodRegistry] — manages cached singleton instances and shared locks.
///
/// ### 🔄 Lifecycle Contracts & Processors
/// - [InitializingPod] — interface implemented by pods requiring startup initialization via [onReady].
/// - [DisposablePod] — interface implemented by pods requiring cleanup on container shutdown via [onDestroy].
/// - [PodPostProcessor] — hook allowing custom modification of new pod instances.
///
/// ### 🧰 Helpers & Expressions
/// - [NullablePod] — safe wrapper for optional dependency injection.
/// - [PodExpression] — dynamic expression-based instantiation evaluator.
///
/// ---
///
/// ## 🎯 Usage Example: Dependency Injection & Lifecycle
///
/// ```dart
/// import 'package:jetleaf_core/lang.dart';
/// import 'package:jetleaf_core/pod.dart';
///
/// class DatabaseConnectionPool implements InitializingPod, DisposablePod {
///   bool isConnected = false;
///
///   @override
///   String getPackageName() => 'my_app';
///
///   @override
///   Future<void> onReady() async {
///     isConnected = true;
///     print('Database pool initialized and connected.');
///   }
///
///   @override
///   Future<void> onDestroy() async {
///     isConnected = false;
///     print('Database pool connections drained.');
///   }
/// }
///
/// class UserRepository {
///   final DatabaseConnectionPool pool;
///   UserRepository(this.pool);
/// }
///
/// void main() async {
///   final factory = DefaultListablePodFactory();
///
///   // 1. Register DatabaseConnectionPool
///   await factory.registerDefinition('pool', RootPodDefinition(
///     type: Class<DatabaseConnectionPool>(),
///     instanceSupplier: (f) => DatabaseConnectionPool(),
///   ));
///
///   // 2. Register UserRepository with constructor injection
///   await factory.registerDefinition('userRepository', RootPodDefinition(
///     type: Class<UserRepository>(),
///     instanceSupplier: (f) async {
///       final pool = await f.getPod<DatabaseConnectionPool>('pool');
///       return UserRepository(pool!);
///     },
///   ));
///
///   // 3. Eagerly instantiate singletons & trigger onReady()
///   await factory.preInstantiateSingletons();
///
///   // 4. Retrieve wired pod
///   final repo = await factory.getPod<UserRepository>('userRepository');
///   print('Repository wired with pool: ${repo?.pool.isConnected}');
///
///   // 5. Cleanly destroy all singletons & trigger onDestroy()
///   await factory.destroySingletons();
/// }
/// ```
library;

export 'src/pod/alias/alias_registry.dart';
export 'src/pod/alias/simple_alias_registry.dart';

export 'src/pod/core/pod_factory.dart';
export 'src/pod/core/abstract_autowire_pod_factory.dart';
export 'src/pod/core/abstract_pod_factory.dart';
export 'src/pod/core/abstract_pod_provider_factory.dart';
export 'src/pod/core/default_listable_pod_factory.dart';
export 'src/pod/core/factory_aware_order_source_provider.dart';

export 'src/pod/definition/pod_definition_registry.dart';
export 'src/pod/definition/pod_definition.dart';
export 'src/pod/definition/commons.dart';
export 'src/pod/definition/simple_pod_definition_registry.dart';

export 'src/pod/expression/pod_expression.dart';

export 'src/pod/helpers/enums.dart';
export 'src/pod/helpers/nullable_pod.dart';
export 'src/pod/helpers/object.dart';

export 'src/pod/instantiation/executable_strategy.dart';
export 'src/pod/instantiation/argument_value_holder.dart';

export 'src/pod/lifecycle/pod_processors.dart';
export 'src/pod/lifecycle/lifecycle.dart';

export 'src/pod/name_generator/pod_name_generator.dart';
export 'src/pod/name_generator/simple_pod_name_generator.dart';

export 'src/pod/scope/scope.dart';

export 'src/pod/singleton/singleton_pod_registry.dart';

export 'src/pod/startup/startup.dart';
export 'src/pod/startup/application_startup.dart';

export 'src/pod/resolver/embedded_value_resolver.dart';
export 'src/pod/resolver/string_value_resolver.dart';

export 'src/pod/exceptions.dart';
