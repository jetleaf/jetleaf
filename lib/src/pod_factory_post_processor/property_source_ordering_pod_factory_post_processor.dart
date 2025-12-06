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
import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_logging/logging.dart';
import 'package:jetleaf_pod/pod.dart';

import '../env/jetleaf_property_source_order_rule.dart';

/// {@template property_source_ordering_pod_aware_processor}
/// 🔄 Post-processor that reorders property sources for optimal resolution.
///
/// The [PropertySourceOrderingPodFactoryPostProcessor] ensures property sources
/// are ordered with the correct precedence for property resolution, following
/// the principle that more specific sources should override more general ones.
///
/// ### Property Source Precedence (Highest to Lowest):
/// 1. **Command Line Arguments**: `--property=value` (most specific)
/// 2. **System Properties**: DVM/Dart VM system properties
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
///   PropertySourceOrderingPodProcessor propertyOrdering() {
///     return PropertySourceOrderingPodProcessor();
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
final class PropertySourceOrderingPodFactoryPostProcessor implements PodFactoryPostProcessor, PriorityOrdered {
  /// {@template property_source_ordering_pod_aware_processor.logger}
  /// Logger instance for tracking property source ordering operations.
  ///
  /// Provides detailed tracing of the reordering process at various levels:
  /// - `DEBUG`: Overall processing phases and summary
  /// - `TRACE`: Individual source extraction and ordering decisions
  /// - `INFO`: Final property source order configuration
  /// {@endtemplate}
  final Log _logger = LogFactory.getLog(PropertySourceOrderingPodFactoryPostProcessor);

  /// {@template property_source_ordering_pod_aware_processor.application_context}
  /// The application context instance provided via [ApplicationContextAware].
  ///
  /// Used to access the environment and its property sources for reordering.
  /// {@endtemplate}
  final ApplicationContext _applicationContext;

  /// {@macro property_source_ordering_pod_aware_processor}
  PropertySourceOrderingPodFactoryPostProcessor(this._applicationContext);

  @override
  int getOrder() => Ordered.LOWEST_PRECEDENCE + 2;

  @override
  Future<void> postProcessFactory(ConfigurableListablePodFactory podFactory) async {
    if (_logger.getIsTraceEnabled()) {
      _logger.trace('Applying propertySourceOrdering to pod definitions');
    }

    final env = _applicationContext.getEnvironment();
    if (env is ConfigurableEnvironment) {
      if (_logger.getIsTraceEnabled()) {
        _logger.trace('Starting property source ordering process');
      }

      final profiles = env.getActiveProfiles().isEmpty ? env.getDefaultProfiles() : env.getActiveProfiles();
      env.getPropertySources().reorder([JetleafPropertySourceOrderRule(profiles)]);

      if (_logger.getIsTraceEnabled()) {
        final names = env.getPropertySources().map((s) => s.getName()).join(", ");
        _logger.trace('New property source order applied: $names');
      }
    }
  }
}