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

import 'package:jetleaf_core/core.dart';
import 'package:jetleaf_core/lang.dart';

import '../repository/repository_executor.dart';
import 'repository_definition.dart';

export 'configurable_repository_context.dart';

/// {@template jetleaf_repository_context}
/// A context interface for managing [Repository] definitions and providing
/// a [RepositoryExecutor] for repository operations.
///
/// Implementations are responsible for:
/// - Storing and retrieving [RepositoryDefinition] instances
/// - Providing a consistent [RepositoryExecutor] for executing repository logic
/// - Integrating with the [ApplicationEventBus] to support event-driven workflows
/// {@endtemplate}
abstract interface class RepositoryContext implements ApplicationEventBusAware {
  /// A typed reference to the [RepositoryContext] class.
  static final Class<RepositoryContext> CLASS =
      Class<RepositoryContext>(null, PackageNames.DATA);

  /// Retrieves the registered [RepositoryDefinition] associated with the
  /// specified repository [method].
  RepositoryDefinition? getDefinition(Method method);

  /// Returns the configured [RepositoryExecutor] responsible for executing
  /// repository operations.
  RepositoryExecutor getExecutor();
}
