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

import 'crud_repository.dart';

/// {@template jetleaf_list_crud_repository}
/// A generic **list-based CRUD repository** extending [CrudRepository],
/// ensuring that all multi-entity operations return [List] instead of
/// general [Iterable].
/// {@endtemplate}
@Generic(ListCrudRepository)
abstract class ListCrudRepository<T, ID> extends CrudRepository<T, ID> {
  /// The reflective [Class] handle representing the `ListCrudRepository` interface.
  static final Class<ListCrudRepository> CLASS =
      Class<ListCrudRepository>(null, PackageNames.DATA);

  /// Retrieves all entities as a [List] instead of a generic [Iterable].
  @override
  Future<List<T>> findAll() async => List.from(await super.findAll());

  /// Retrieves all entities matching the given [ids] as a [List].
  @override
  Future<List<T>> findAllById(Iterable<ID> ids) async =>
      List.from(await super.findAllById(ids));

  /// Saves multiple [entities] and returns the result as a [List].
  @override
  Future<List<S>> saveAll<S extends T>(Iterable<S> entities) async =>
      List.from(await super.saveAll(entities));
}
