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

import '../../repository.dart';
import 'configurable_repository_context.dart';
import 'data_repository_definition.dart';
import 'repository_definition.dart';
import 'repository_method_interceptor.dart';

export 'data_repository_definition.dart';

/// {@template jetleaf_abstract_repository_context}
/// An abstract base implementation of a repository context that stores and
/// provides metadata ([RepositoryDefinition]) for repository methods.
///
/// This context participates in the interception pipeline via
/// [RepositoryMethodInterceptor], allowing it to:
/// - Identify repository methods before invocation.
/// - Publish interception events.
/// - Resolve definitions for methods based on their declaring repository type.
/// - Maintain a synchronized registry of known repository method definitions.
/// {@endtemplate}
abstract class AbstractRepositoryContext extends RepositoryMethodInterceptor
    implements ConfigurableRepositoryContext {
  /// Reflective class descriptor for [AbstractRepositoryContext].
  static final Class<AbstractRepositoryContext> CLASS =
      Class<AbstractRepositoryContext>(null, PackageNames.DATA);

  /// Internal registry mapping `"<qualified-class>#<method-name>" → RepositoryDefinition`.
  final Map<String, RepositoryDefinition> _definitions = {};

  @override
  RepositoryDefinition? getDefinition(Method method) {
    return synchronized(_definitions, () {
      final key = _buildKey(method);
      return _definitions[key];
    });
  }

  @override
  void addDefinition(RepositoryDefinition definition) {
    return synchronized(_definitions, () {
      final key = _buildKey(definition.getMethod());
      _definitions.remove(key);
      _definitions.add(key, definition);
    });
  }

  /// Constructs a unique cache key for the given [method] based on its declaring
  /// class and method name.
  String _buildKey(Method method) =>
      "${method.getDeclaringClass().getQualifiedName()}#${method.getName()}";

  /// Builds a new [RepositoryDefinition] for the given reflected [method]
  /// and repository object [target].
  RepositoryDefinition buildDefinition(Method method, Object target) {
    bool isInternal = false;
    RepositoryType type = RepositoryType.CUSTOM;

    if (ListCrudRepository.CLASS.getMethod(method.getName()) != null && target is ListCrudRepository) {
      isInternal = true;
      type = RepositoryType.LIST_CRUD;
    } else if (CrudRepository.CLASS.getMethod(method.getName()) != null && target is CrudRepository) {
      isInternal = true;
      type = RepositoryType.CRUD;
    } else if (ListPagingAndSortRepository.CLASS.getMethod(method.getName()) != null && target is ListPagingAndSortRepository) {
      isInternal = true;
      type = RepositoryType.LIST_PAGEABLE;
    } else if (PagingAndSortRepository.CLASS.getMethod(method.getName()) != null && target is PagingAndSortRepository) {
      isInternal = true;
      type = RepositoryType.PAGEABLE;
    } else if (Repository.CLASS.getMethod(method.getName()) != null && target is Repository) {
      isInternal = true;
      type = RepositoryType.BASE;
    }

    return DataRepositoryDefinition(isInternal, method, type);
  }
}
