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

import 'repository_type.dart';

export 'repository_type.dart';

/// {@template jetleaf_repository_definition}
/// Defines the metadata and characteristics of a repository method.
///
/// A [RepositoryDefinition] describes:
/// - The reflected method being intercepted
/// - The repository category ([RepositoryType])
/// - Whether the method is considered *internal* (used internally by the
///   repository framework and not executed via user-level dispatch)
/// {@endtemplate}
abstract class RepositoryDefinition with EqualsAndHashCode {
  /// Reflective class descriptor for [RepositoryDefinition].
  static final Class<RepositoryDefinition> CLASS =
      Class<RepositoryDefinition>(null, PackageNames.DATA);

  /// {@macro jetleaf_repository_definition}
  const RepositoryDefinition();

  /// Returns the reflected repository [Method] this definition applies to.
  Method getMethod();

  /// Returns the type classification of this repository method.
  RepositoryType getType();

  /// Indicates whether this method is an internal framework method.
  bool isInternalMethod() => false;
}
