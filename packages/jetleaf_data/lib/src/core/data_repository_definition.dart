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

import 'repository_definition.dart';

/// {@template jetleaf_data_repository_definition}
/// A concrete implementation of [RepositoryDefinition] that stores metadata
/// about a repository method, including its type, reflection metadata,
/// and whether it should be treated as an internal framework method.
/// {@endtemplate}
final class DataRepositoryDefinition extends RepositoryDefinition {
  /// Reflective class descriptor for [DataRepositoryDefinition].
  static final Class<DataRepositoryDefinition> CLASS =
      Class<DataRepositoryDefinition>(null, PackageNames.DATA);

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
