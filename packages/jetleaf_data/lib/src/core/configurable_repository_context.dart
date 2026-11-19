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

import '../repository/repository_executor.dart';
import 'repository_context.dart';
import 'repository_definition.dart';

/// {@template jetleaf_configurable_repository_context}
/// A configurable variant of [RepositoryContext] that allows dynamic
/// registration of [RepositoryDefinition]s and setting of the [RepositoryExecutor].
///
/// ### Usage Example
/// ```dart
/// final context = DefaultRepositoryContext();
/// context.setExecutor(myExecutor);
/// context.addDefinition(myRepositoryDefinition);
/// ```
/// {@endtemplate}
abstract interface class ConfigurableRepositoryContext implements RepositoryContext {
  /// Reflective class descriptor for [ConfigurableRepositoryContext].
  static final Class<ConfigurableRepositoryContext> CLASS =
      Class<ConfigurableRepositoryContext>(null, PackageNames.DATA);

  /// Adds a new [RepositoryDefinition] to the context.
  void addDefinition(RepositoryDefinition definition);

  /// Sets the [RepositoryExecutor] for this context.
  void setExecutor(RepositoryExecutor executor);
}
