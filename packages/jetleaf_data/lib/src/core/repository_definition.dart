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

/// {@template jetleaf_repository_definition_type}
/// Represents the different **repository implementation categories** used
/// in JetLeaf's repository architecture.
///
/// These types classify how a repository method is expected to behave,
/// which executor logic to apply, and how the framework should interpret
/// the method during interception, analysis, or code generation.
/// {@endtemplate}
enum RepositoryType {
  /// A user-defined method that does not map to any built-in
  /// repository behavior. Typical for derived queries or `@Query` definitions.
  CUSTOM,

  /// A simple repository method that does not involve CRUD or pageable semantics.
  BASE,

  /// Matches CRUD-style repository methods such as `findById`, `save`, or `delete`.
  CRUD,

  /// CRUD repository behavior with list-based return semantics (e.g., returning `List<T>`).
  LIST_CRUD,

  /// Repository methods supporting sorting or pagination.
  PAGEABLE,

  /// Pageable behavior but explicitly returning lists.
  LIST_PAGEABLE,
}

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
  static final Class<RepositoryDefinition> CLASS = Class<RepositoryDefinition>(null, PackageNames.DATA);

  /// {@macro jetleaf_repository_definition}
  const RepositoryDefinition();

  /// Returns the reflected repository [Method] this definition applies to.
  Method getMethod();

  /// Returns the type classification of this repository method.
  RepositoryType getType();

  /// Indicates whether this method is an internal framework method.
  bool isInternalMethod() => false;
}

/// {@template jetleaf_data_repository_definition}
/// A concrete implementation of [RepositoryDefinition] that stores metadata
/// about a repository method, including its type, reflection metadata,
/// and whether it should be treated as an internal framework method.
/// {@endtemplate}
final class DataRepositoryDefinition extends RepositoryDefinition {
  /// Reflective class descriptor for [DataRepositoryDefinition].
  static final Class<DataRepositoryDefinition> CLASS = Class<DataRepositoryDefinition>(null, PackageNames.DATA);

  /// Indicates whether the method is considered internal.
  final bool _isInternal;

  /// The reflected repository method this definition describes.
  final Method _method;

  /// The classification for this repository method.
  final RepositoryType _type;

  /// {@macro jetleaf_data_repository_definition}
  const DataRepositoryDefinition(this._isInternal, this._method, this._type);

  @override
  List<Object?> equalizedProperties() => [_isInternal, _method, _type];

  @override
  Method getMethod() => _method;

  @override
  RepositoryType getType() => _type;

  @override
  bool isInternalMethod() => _isInternal;
}