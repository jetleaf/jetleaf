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
import 'package:jetleaf_env/env.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_logging/logging.dart';

import 'context_factory.dart';

/// {@template default_application_context_factory}
/// The default implementation of [ApplicationContextFactory] in JetLeaf.
///
/// This factory serves as the primary mechanism for creating fully configured
/// application contexts and environments during the startup of a JetLeaf
/// application. Its primary responsibilities are discovery, instantiation,
/// and selection of the appropriate context for the application's runtime
/// type.
///
/// ### Key Responsibilities
///
/// 1. **Discovery of Context Subclasses**
///    - Scans the core package for all non-abstract subclasses of
///      [ConfigurableApplicationContext].
///    - Ensures that only classes that can be instantiated are considered.
///
/// 2. **Instantiation of Contexts**
///    - Attempts to use the no-argument constructor if available.
///    - If no no-arg constructor exists, falls back to the "best" constructor
///      with default parameters.
///    - Logs instantiation attempts and warnings for missing constructors.
///
/// 3. **Selection of the Appropriate Context**
///    - Evaluates all instantiated candidates for support of the requested
///      [ApplicationType].
///    - Returns the first matching context found.
///    - If no supporting context is available, falls back to
///      [AnnotationConfigApplicationContext] as a generic, default context.
///
/// 4. **Environment Resolution**
///    - Determines the environment type based on the application type:
///       - `ApplicationType.NONE` → [GlobalEnvironment]
///       - `ApplicationType.WEB` → [ApplicationEnvironment]
///    - Can create a new environment instance tailored to the application type,
///      falling back to [GlobalEnvironment] if necessary.
///
/// ### Logging and Debugging
/// - Uses [Log] to provide informational messages about which classes are
///   being inspected, which constructors are used, and any warnings
///   encountered during instantiation.
/// - Logs are emitted at the info and warn levels, allowing developers to
///   trace the factory’s behavior without changing runtime code.
///
/// ### Usage Scenario
/// - When a JetLeaf application is launched, this factory is called
///   internally to produce the appropriate [ConfigurableApplicationContext].
/// - Custom application contexts can be discovered automatically if they
///   extend [ConfigurableApplicationContext] and provide a no-arg constructor
///   or a constructor that can be satisfied with default arguments.
/// - Provides a consistent and centralized mechanism for environment creation
///   and context selection, reducing boilerplate across different
///   application types.
///
/// ### Example
/// ```dart
/// final factory = DefaultApplicationContextFactory();
/// final context = factory.create(ApplicationType.WEB);
/// ```
///
/// This ensures that the application has a fully initialized context and
/// environment suitable for runtime operations.
/// {@endtemplate}
final class DefaultApplicationContextFactory implements ApplicationContextFactory {
  /// The logger used for reporting discovery, instantiation, and warning
  /// messages during context creation.
  final Log _logger = LogFactory.getLog(DefaultApplicationContextFactory);

  /// Default constructor for the application context factory.
  ///
  /// Typically, no configuration is needed. Logging is automatically enabled
  /// via [_logger].
  /// 
  /// {@macro default_application_context_factory}
  DefaultApplicationContextFactory();

  @override
  ConfigurableApplicationContext create(ApplicationType applicationType) {
    final cac = Class<ConfigurableApplicationContext>(null, PackageNames.CORE);
    final sources = <ConfigurableApplicationContext>[];
    final classes = cac.getSubClasses().where((cl) => !cl.isAbstract());

    for(final cls in classes) {
      if(_logger.getIsInfoEnabled()) {
        _logger.info("Checking if application type [$applicationType] is supported by ${cls.getName()}");
      }

      final defc = cls.getNoArgConstructor() ?? cls.getBestConstructor([]);
      try {
        if(defc != null) {
          final source = defc.newInstance();
          sources.add(source);
        } else {
          if(_logger.getIsWarnEnabled()) {
            _logger.warn("${cls.getName()} does not have a no-arg constructor");
          }
        }
      } catch (_) {
        // No-op
      }
    }

    if(sources.isNotEmpty) {
      final cac = sources.find((c) => c.supports(applicationType));
      if(cac != null) {
        return cac;
      }
    }

    return AnnotationConfigApplicationContext();
  }
}