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
import 'package:jetleaf_core/lang.dart';
import 'package:jetleaf_core/logging.dart';
import 'package:jetleaf_core/pod.dart';

import '../../repository.dart';
import 'repository_context.dart';

/// {@template repository_context_aware}
/// Indicates that a class is aware of and can receive a [RepositoryContext].
///
/// Implementing this interface allows the container, factory, or repository
/// infrastructure to inject the current repository context into the class,
/// enabling access to repository metadata, configuration, or lifecycle hooks.
///
/// ### Usage
/// ```dart
/// class MyRepository implements RepositoryContextAware {
///   late RepositoryContext _context;
///
///   @override
///   void setRepositoryContext(RepositoryContext context) {
///     _context = context;
///   }
///
///   void doSomething() {
///     print('Repository name: ${_context.repositoryName}');
///   }
/// }
/// ```
///
/// ### Notes
/// - Typically used in repository or data access classes that need
///   contextual information from the framework.
/// - The [setRepositoryContext] method is usually called automatically
///   by the repository infrastructure during initialization.
/// {@endtemplate}
abstract interface class RepositoryContextAware {
  /// A typed reference to the [RepositoryContextAware] class.
  ///
  /// This is used by the dependency injection container to look up all pods
  /// that implement or extend **RepositoryContextAware**, allowing the framework
  /// to automatically inject a [RepositoryContext] where required.
  static Class<RepositoryContextAware> CLASS = Class<RepositoryContextAware>();

  /// Injects the active [RepositoryContext] into this component.
  ///
  /// Classes that implement [RepositoryContextAware] receive the repository
  /// context before they are used. This allows them to:
  /// - Access repository metadata or configuration
  /// - Register repository-related callbacks
  /// - Interact with repository execution pipelines
  ///
  /// The container guarantees that this method is called exactly once during
  /// initialization, before any repository operations occur.
  void setRepositoryContext(RepositoryContext context);
}

/// {@template jetleaf_repository_aware_processor}
/// A [PodInitializationProcessor] that **automatically wires repository-related
/// infrastructure** into pods during the initialization phase.
///
/// This processor integrates with the [ApplicationContext] to:
/// - Inject a [RepositoryExecutor] into all [Repository] pods
/// - Inject a [RepositoryContext] into all [RepositoryContextAware] pods
/// {@endtemplate}
final class RepositoryAwareProcessor extends PodInitializationProcessor implements PriorityOrdered {
  /// Reflective class descriptor for [RepositoryAwareProcessor].
  static final Class<RepositoryAwareProcessor> CLASS = Class<RepositoryAwareProcessor>(null, PackageNames.DATA);

  /// The application context used to resolve and retrieve the active
  /// [RepositoryContext].
  final ApplicationContext _context;

  /// Cached instance of the resolved [RepositoryContext].
  RepositoryContext? _repositoryContext;

  /// Logger used for emitting diagnostic information related to repository
  /// context processing.
  final Log _logger = LogFactory.getLog(RepositoryAwareProcessor);

  /// {@macro jetleaf_repository_aware_processor}
  RepositoryAwareProcessor(this._context);

  @override
  int getOrder() => 1;

  @override
  Future<bool> shouldProcessBeforeInitialization(Object pod, Class podClass, String name) async {
    return await _context.containsType(RepositoryContext.CLASS) && (pod is Repository || pod is RepositoryContextAware);
  }

  @override
  Future<Object?> processBeforeInitialization(Object pod, Class podClass, String name) async {
    final instance = pod;

    if (instance is Repository) {
      final repositoryContext = await _getContext();
      instance.setExecutor(repositoryContext.getExecutor());
    }

    if (instance is RepositoryContextAware) {
      final repositoryContext = await _getContext();
      instance.setRepositoryContext(repositoryContext);
    }

    return instance;
  }

  /// Resolves and returns the active [RepositoryContext] instance.
  Future<RepositoryContext> _getContext() async {
    RepositoryContext repositoryContext;
    if (_repositoryContext case final context?) {
      repositoryContext = context;
    } else {
      repositoryContext = await _context.get(RepositoryContext.CLASS);
    }

    if (_logger.getIsDebugEnabled()) {
      _logger.trace("Provided $repositoryContext for repository execution");
    }

    return _repositoryContext = repositoryContext;
  }
}

/// {@template jetleaf_repository_application_module}
/// An application module that **registers repository-related infrastructure**
/// into the JetLeaf runtime by adding a [RepositoryAwareProcessor] to the
/// [ApplicationContext].
/// {@endtemplate}
final class RepositoryApplicationModule implements ApplicationModule {
  /// Reflective class descriptor for [RepositoryApplicationModule].
  static final Class<RepositoryApplicationModule> CLASS = Class<RepositoryApplicationModule>(null, PackageNames.DATA);

  /// {@macro jetleaf_repository_application_module}
  const RepositoryApplicationModule();

  @override
  Future<void> configure(ApplicationContext context) async {
    context.addPodProcessor(RepositoryAwareProcessor(context));
  }

  @override
  List<Object?> equalizedProperties() => [RepositoryApplicationModule];
}