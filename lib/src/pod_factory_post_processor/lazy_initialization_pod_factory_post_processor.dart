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
import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_logging/logging.dart';
import 'package:jetleaf_pod/pod.dart';

/// {@template lazy_initialization_pod_aware_processor}
/// 🦥 Post-processor that enables lazy initialization for all eligible pods.
///
/// The [LazyInitializationPodFactoryPostProcessor] is a [PodFactoryPostProcessor]
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
///   LazyInitializationPodProcessor lazyProcessor() {
///     return LazyInitializationPodProcessor();
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
final class LazyInitializationPodFactoryPostProcessor implements PodFactoryPostProcessor, PriorityOrdered {
  /// {@template lazy_initialization_pod_aware_processor.logger}
  /// Logger instance for tracking processor operations and debugging.
  ///
  /// Used at various log levels:
  /// - `DEBUG`: Major processing phases
  /// - `TRACE`: Individual pod processing decisions
  /// - `INFO`: Configuration summary and statistics
  /// {@endtemplate}
  final Log _logger = LogFactory.getLog(LazyInitializationPodFactoryPostProcessor);

  /// {@macro lazy_initialization_pod_aware_processor}
  LazyInitializationPodFactoryPostProcessor();

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

      // Skip infrastructure/internal pods
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