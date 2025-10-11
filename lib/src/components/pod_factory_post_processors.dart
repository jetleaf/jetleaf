// ---------------------------------------------------------------------------
// 🍃 JetLeaf Framework - https://jetleaf.hapnium.com
//
// Copyright © 2025 Hapnium & JetLeaf Contributors. All rights reserved.
//
// This source file is part of the JetLeaf Framework and is protected
// under copyright law. You may not copy, modify, or distribute this file
// except in compliance with the JetLeaf license.
//
// For licensing terms, see the LICENSE file in the root of this project.
// ---------------------------------------------------------------------------
// 
// 🔧 Powered by Hapnium — the Dart backend engine 🍃

import 'package:jetleaf_core/context.dart';
import 'package:jetleaf_core/core.dart';
import 'package:jetleaf_env/env.dart';
import 'package:jetleaf_env/property.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_logging/logging.dart';
import 'package:jetleaf_pod/pod.dart';

/// {@template lazy_initialization_pod_aware_processor}
/// 🦥 Post-processor that enables lazy initialization for all eligible pods.
///
/// The [LazyInitializationPodAwareProcessor] is a [PodFactoryPostProcessor]
/// that automatically configures pods for lazy initialization, meaning they
/// are created only when first requested rather than during application startup.
///
/// ### Key Features:
/// - **Performance Optimization**: Reduces application startup time
/// - **Memory Efficiency**: Only instantiate pods when actually needed
/// - **Selective Application**: Skips infrastructure and already-lazy pods
/// - **High Priority**: Executes early in the post-processing phase
///
/// ### Processing Logic:
/// 1. **Iterates** through all pod definitions in the factory
/// 2. **Skips** infrastructure pods (framework internals)
/// 3. **Preserves** existing lazy configuration
/// 4. **Applies** lazy initialization to remaining pods
/// 5. **Re-registers** modified definitions with the factory
///
/// ### Pod Eligibility:
/// - ✅ Regular application pods (services, repositories, components)
/// - ✅ Configuration pods with `@Configuration` annotation
/// - ❌ Infrastructure pods (`DesignRole.INFRASTRUCTURE`)
/// - ❌ Already lazy pods (existing `lifecycle.isLazy = true`)
/// - ❌ Framework internal components
///
/// ### Usage Example:
/// ```dart
/// @Configuration
/// class AppConfig {
///   @Pod
///   LazyInitializationPodAwareProcessor lazyProcessor() {
///     return LazyInitializationPodAwareProcessor();
///   }
/// }
/// ```
///
/// ### Integration Points:
/// - Implements [PriorityOrdered] with `HIGHEST_PRECEDENCE - 2`
/// - Executes before most other post-processors
/// - Compatible with other pod factory customization
///
/// ### Performance Impact:
/// - **Startup Time**: Significantly reduced
/// - **Memory Usage**: Lower initial footprint
/// - **First Request**: Slightly slower (pod instantiation cost)
/// - **Overall**: Better for applications with many rarely-used pods
///
/// See also:
/// - [PodFactoryPostProcessor] for the base post-processor interface
/// - [PriorityOrdered] for execution order control
/// - [DesignRole] for pod role definitions
/// {@endtemplate}
final class LazyInitializationPodAwareProcessor implements PodFactoryPostProcessor, PriorityOrdered {
  /// {@template lazy_initialization_pod_aware_processor.logger}
  /// Logger instance for tracking processor operations and debugging.
  /// 
  /// Used at various log levels:
  /// - `DEBUG`: Major processing phases
  /// - `TRACE`: Individual pod processing decisions
  /// - `INFO`: Configuration summary and statistics
  /// {@endtemplate}
  final Log _logger = LogFactory.getLog(LazyInitializationPodAwareProcessor);

  @override
  int getOrder() => Ordered.HIGHEST_PRECEDENCE - 2;
  
  @override
  Future<void> postProcessFactory(ConfigurableListablePodFactory podFactory) async {
    if (_logger.getIsTraceEnabled()) {
      _logger.trace('Applying lazy initialization to all eligible pods.');
    }
    
    final names = podFactory.getDefinitionNames();
    for (final name in names) {
      final definition = podFactory.getDefinition(name);
      bool isAlreadyLazy = definition.lifecycle.isLazy != null && definition.lifecycle.isLazy!;

      // Skip infrastructure/internal beans
      if (definition.design.role == DesignRole.INFRASTRUCTURE) {
        if (_logger.getIsTraceEnabled()) {
          _logger.trace("Skipping infrastructure pod: $name");
        }

        continue;
      }

      if (isAlreadyLazy) {
        if (_logger.getIsTraceEnabled()) {
          _logger.trace('Skipping pod $name since it is already marked as lazy');
        }

        continue;
      }

      definition.lifecycle.isLazy = true;
      podFactory.removeDefinition(name);
      podFactory.registerDefinition(name, definition);

      if (_logger.getIsTraceEnabled()) {
        _logger.trace('Pod $name is now marked as lazy');
      }
    }

    if (_logger.getIsTraceEnabled()) {
      _logger.trace('Applied lazy initialization to pod definitions');
    }
  }
}

/// {@template property_source_ordering_pod_aware_processor}
/// 🔄 Post-processor that reorders property sources for optimal resolution.
///
/// The [PropertySourceOrderingPodAwareProcessor] ensures property sources
/// are ordered with the correct precedence for property resolution, following
/// the principle that more specific sources should override more general ones.
///
/// ### Property Source Precedence (Highest to Lowest):
/// 1. **Command Line Arguments**: `--property=value` (most specific)
/// 2. **System Properties**: JVM/Dart VM system properties
/// 3. **Environment Variables**: OS-level environment variables
/// 4. **Application Properties**: application.properties/.yaml files
/// 5. **Default Properties**: Framework defaults (least specific)
///
/// ### Key Features:
/// - **Standard Ordering**: Implements conventional property source precedence
/// - **Annotation Awareness**: Respects `@Order` annotations on custom sources
/// - **Framework Integration**: Aware of standard framework property sources
/// - **Dynamic Reordering**: Adjusts ordering based on detected environment
///
/// ### Processing Logic:
/// 1. **Extracts** high-priority sources (command line, system, environment)
/// 2. **Preserves** remaining sources in existing order
/// 3. **Applies** annotation-aware sorting
/// 4. **Reinserts** sources in correct precedence order
///
/// ### Usage Example:
/// ```dart
/// @Configuration
/// class PropertyConfig {
///   @Pod
///   PropertySourceOrderingPodAwareProcessor propertyOrdering() {
///     return PropertySourceOrderingPodAwareProcessor();
///   }
/// }
/// ```
///
/// ### Integration Points:
/// - Implements [ApplicationContextAware] for environment access
/// - Implements [PriorityOrdered] with `HIGHEST_PRECEDENCE - 1`
/// - Executes after infrastructure setup but before application processing
/// - Requires [GlobalEnvironment] for proper operation
///
/// See also:
/// - [PodFactoryPostProcessor] for the base post-processor interface
/// - [ApplicationContextAware] for application context access
/// - [PriorityOrdered] for execution order control
/// - [GlobalEnvironment] for environment implementation
/// - [AnnotationAwareOrderComparator] for ordering logic
/// {@endtemplate}
final class PropertySourceOrderingPodAwareProcessor implements PodFactoryPostProcessor, PriorityOrdered {
  /// {@template property_source_ordering_pod_aware_processor.logger}
  /// Logger instance for tracking property source ordering operations.
  /// 
  /// Provides detailed tracing of the reordering process at various levels:
  /// - `DEBUG`: Overall processing phases and summary
  /// - `TRACE`: Individual source extraction and ordering decisions
  /// - `INFO`: Final property source order configuration
  /// {@endtemplate}
  final Log _logger = LogFactory.getLog(PropertySourceOrderingPodAwareProcessor);

  /// {@template property_source_ordering_pod_aware_processor.application_context}
  /// The application context instance provided via [ApplicationContextAware].
  /// 
  /// Used to access the environment and its property sources for reordering.
  /// {@endtemplate}
  final ApplicationContext _applicationContext;

  /// {@macro property_source_ordering_pod_aware_processor}
  PropertySourceOrderingPodAwareProcessor(this._applicationContext);

  @override
  int getOrder() => Ordered.LOWEST_PRECEDENCE + 2;

  @override
  Future<void> postProcessFactory(ConfigurableListablePodFactory podFactory) async {
    if (_logger.getIsTraceEnabled()) {
      _logger.trace('Applying propertySourceOrdering to pod definitions');
    }
    
    final env = _applicationContext.getEnvironment();
    if (env is GlobalEnvironment) {
      final sources = env.getPropertySources();

      final ordered = <PropertySource>[];

      // 1️⃣ High-priority system and command-line sources
      final system = sources.remove(GlobalEnvironment.SYSTEM_PROPERTIES_PROPERTY_SOURCE_NAME);
      final envVars = sources.remove(GlobalEnvironment.SYSTEM_ENVIRONMENT_PROPERTY_SOURCE_NAME);
      final cmdLine = sources.remove(CommandLinePropertySource.COMMAND_LINE_PROPERTY_SOURCE_NAME);

      if (cmdLine != null) ordered.add(cmdLine);
      if (system != null) ordered.add(system);
      if (envVars != null) ordered.add(envVars);

      if (_logger.getIsTraceEnabled()) {
        _logger.trace('Adding remaining sources in their existing order: ${ordered.map((s) => s.getName()).join(", ")}');
      }

      // 2️⃣ Add remaining sources in their existing order
      ordered.addAll(sources.toList());

      if (_logger.getIsTraceEnabled()) {
        _logger.trace('Sorting and applying back: ${ordered.map((s) => s.getName()).join(", ")}');
      }

      // 3️⃣ Sort and apply back
      AnnotationAwareOrderComparator.sort(ordered);

      if (_logger.getIsTraceEnabled()) {
        _logger.trace('Applying new order back: ${ordered.map((s) => s.getName()).join(", ")}');
      }

      // 3️⃣ Apply the new order back to the environment
      for (final source in ordered) {
        env.getPropertySources().addFirst(source);
      }

      if (_logger.getIsTraceEnabled()) {
        final ortracest = ordered.map((s) => s.getName()).join(", ");
        
        if (_logger.getIsTraceEnabled()) {
          _logger.trace('Applied propertySourceOrdering to pod definitions: [$ortracest]');
        }
      }
    }
  }
}