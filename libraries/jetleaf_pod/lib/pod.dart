/// 🫘 **Jetleaf Pod Dependency Injection**
///
/// This library provides the core dependency-injection (DI) system used by
/// Jetleaf, built around **pods**—lightweight, configurable, and pluggable
/// components.
///
/// It exposes the full pod lifecycle, factory system, scopes, definition
/// registry, aliasing, name generation, and startup integration.
///
///
/// ## 🔑 Key Concepts
///
/// ### 🫘 Pods
/// A *pod* represents a managed dependency:
/// - can be created on demand or eagerly
/// - supports constructor, factory, and expression-based creation
/// - participates in lifecycle processing
///
///
/// ## 📦 Exports Overview
///
/// ### 🏷 Alias Management
/// - `AliasRegistry` — maintains type/name indirections  
/// - `SimpleAliasRegistry` — default implementation
///
/// Allows referencing pods under multiple names.
///
///
/// ### 🏭 Core Factories
/// - `PodFactory` — main access point for retrieving pods  
/// - `AbstractPodFactory` — base type resolution logic  
/// - `AbstractAutowirePodFactory` — constructor + dependency injection  
/// - `AbstractPodProviderFactory` — provider-based resolution  
/// - `DefaultListablePodFactory` — primary production implementation  
/// - `FactoryAwareOrderSourceProvider` — ordering integration
///
/// The **factory** orchestrates creation, injection, and caching.
///
///
/// ### 🧱 Pod Definitions
/// - `PodDefinitionRegistry` — stores and manages definitions  
/// - `PodDefinition` — metadata describing how a pod is created  
/// - `SimplePodDefinitionRegistry` — default registry  
/// - `commons.dart` — shared helpers
///
/// Definitions describe *what* a pod is before *creating* it.
///
///
/// ### 🧮 Expressions
/// - `PodExpression` — supports expression-based pod construction
///
/// Useful for dynamic or configuration-driven instantiation.
///
///
/// ### 🧰 Helper Types
/// - enums and utility classes supporting DI behavior  
/// - `NullablePod` — safe optional pod access  
/// - object utilities for injection resolution
///
///
/// ### ⚙️ Instantiation Pipeline
/// - `ExecutableStrategy` — determines how a pod is created  
/// - `ArgumentValueHolder` — stores resolved constructor arguments
///
///
/// ### 🔄 Lifecycle Management
/// - `PodProcessors` — post-processing callbacks  
/// - `Lifecycle` — initialization and destruction phases
///
/// Enables customization hooks similar to post-processors.
///
///
/// ### 🏷 Name Generation
/// - `PodNameGenerator` — strategy for naming pods  
/// - `SimplePodNameGenerator` — default implementation
///
///
/// ### 📍 Scopes
/// - `Scope` — defines lifecycle boundaries (singleton, prototype, etc.)
///
///
/// ### ♾️ Singleton Handling
/// - `SingletonPodRegistry` — manages cached pod instances
///
///
/// ### 🚀 Application Startup
/// - `Startup` — DI startup abstraction  
/// - `ApplicationStartup` — bootstrapping integration
///
/// Supports ordered and observable initialization.
///
///
/// ### ⚠️ Exceptions
/// - framework-level errors for invalid definitions, cycles, and resolution failures
///
///
/// ## 🎯 Intended Usage
///
/// Most applications will obtain pods through the factory:
/// ```dart
/// final factory = DefaultListablePodFactory();
/// final service = factory.getPod('myService');
/// ```
///
/// This system is designed for framework composition, plugin ecosystems,
/// and advanced application architectures.
///
///
/// © 2025 Hapnium & Jetleaf Contributors
library;

export 'src/alias/alias_registry.dart';
export 'src/alias/simple_alias_registry.dart';

export 'src/core/pod_factory.dart';
export 'src/core/abstract_autowire_pod_factory.dart';
export 'src/core/abstract_pod_factory.dart';
export 'src/core/abstract_pod_provider_factory.dart';
export 'src/core/default_listable_pod_factory.dart';
export 'src/core/factory_aware_order_source_provider.dart';

export 'src/definition/pod_definition_registry.dart';
export 'src/definition/pod_definition.dart';
export 'src/definition/commons.dart';
export 'src/definition/simple_pod_definition_registry.dart';

export 'src/expression/pod_expression.dart';

export 'src/helpers/enums.dart';
export 'src/helpers/nullable_pod.dart';
export 'src/helpers/object.dart';

export 'src/instantiation/executable_strategy.dart';
export 'src/instantiation/argument_value_holder.dart';

export 'src/lifecycle/pod_processors.dart';
export 'src/lifecycle/lifecycle.dart';

export 'src/name_generator/pod_name_generator.dart';
export 'src/name_generator/simple_pod_name_generator.dart';

export 'src/scope/scope.dart';

export 'src/singleton/singleton_pod_registry.dart';

export 'src/startup/startup.dart';
export 'src/startup/application_startup.dart';

export 'src/resolver/embedded_value_resolver.dart';
export 'src/resolver/string_value_resolver.dart';

export 'src/exceptions.dart';