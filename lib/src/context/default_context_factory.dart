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

import '../env/environment.dart';
import 'context_factory.dart';

/// {@template default_application_context_factory}
/// Default [ApplicationContextFactory] implementation used by JetLeaf.
///
/// - Creates [GenericApplicationContext] for any application.
/// - Provides [GlobalEnvironment] for CLI applications.
/// - Provides [ApplicationEnvironment] for web applications.
///
/// ### Example:
/// ```dart
/// final factory = ApplicationContextFactory.DEFAULT;
/// final ctx = factory.create(ApplicationType.WEB);
/// final env = factory.createEnvironment(ApplicationType.WEB);
/// ```
/// {@endtemplate}
class DefaultApplicationContextFactory implements ApplicationContextFactory {
  final Log _logger = LogFactory.getLog(DefaultApplicationContextFactory);

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
      if(defc != null) {
        final source = defc.newInstance();
        sources.add(source);
      } else {
        if(_logger.getIsWarnEnabled()) {
          _logger.warn("${cls.getName()} does not have a no-arg constructor");
        }
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

  @override
  AbstractEnvironment? getEnvironmentType(ApplicationType applicationType) {
    switch (applicationType) {
      case ApplicationType.NONE:
        return GlobalEnvironment();
      case ApplicationType.WEB:
        return ApplicationEnvironment();
    }
  }

  @override
  ConfigurableEnvironment createEnvironment(ApplicationType applicationType) {
    final environmentType = getEnvironmentType(applicationType);
    if (environmentType != null) {
      return environmentType;
    }
    return GlobalEnvironment();
  }
}