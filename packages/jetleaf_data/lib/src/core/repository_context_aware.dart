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

import 'package:jetleaf_core/lang.dart';

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