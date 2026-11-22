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

/// {@template jetleaf_crud_repository}
/// A generic **CRUD repository class** extending [Repository], providing
/// standard create, read, update, and delete operations for entities of type [T]
/// identified by [ID].
///
/// This class delegates all operations to an optional [RepositoryExecutor],
/// which performs the actual data access.
///
/// ### Usage Example
/// ```dart
/// @Repository()
/// abstract class UserRepository extends CrudRepository<User, String> {}
///
/// final user = await userRepository.findById('user-1');
/// ```
/// {@endtemplate}
@Generic(CrudRepository)
abstract class CrudRepository<T, ID> extends Repository<T, ID> {
  /// The reflective [Class] handle representing the `CrudRepository` interface.
  static final Class<CrudRepository> CLASS = Class<CrudRepository>(null, PackageNames.DATA);

  /// Finds an entity by its [id].
  Future<T?> findById(ID id) async => getExecutor()?.findById(id, this);

  /// Finds a single entity by a given [property], optionally ignoring case.
  Future<T?> findByProperty(String property, [
    bool ignoreCase = false,
    Object? value,
  ]) async => getExecutor()?.findByProperty(property, ignoreCase, this, value);

  /// Checks if an entity with the given [id] exists.
  Future<bool> existsById(ID id) async => await getExecutor()?.existsById(id, this) ?? false;

  /// Retrieves all entities from the repository.
  Future<Iterable<T>> findAll() async => await getExecutor()?.findAll(this) ?? const [];

  /// Retrieves all entities matching the given [ids].
  Future<Iterable<T>> findAllById(Iterable<ID> ids) async => await getExecutor()?.findAllById(ids, this) ?? const [];

  /// Returns the total number of entities in the repository.
  Future<int> getCount() async => await getExecutor()?.getCount(this) ?? 0;

  /// Returns the total number of entities in the repository (alias of [getCount]).
  Future<int> count() async => getCount();

  /// Saves a single [entity] to the repository.
  Future<S> save<S extends T>(S entity) async => await getExecutor()?.save<T, ID, S>(entity, this) ?? entity;

  /// Saves multiple [entities] to the repository.
  Future<Iterable<S>> saveAll<S extends T>(Iterable<S> entities) async => await getExecutor()?.saveAll<T, ID, S>(entities, this) ?? const [];

  /// Deletes an entity by its [id].
  Future<void> deleteById(ID id) async => await getExecutor()?.deleteById(id, this);

  /// Deletes a specific [entity] from the repository.
  Future<void> delete(T entity) async => await getExecutor()?.deleteEntity(entity, this);

  /// Deletes multiple entities by their [ids].
  Future<void> deleteAllById(Iterable<ID> ids) async => await getExecutor()?.deleteAllById(ids, this);

  /// Deletes multiple [entities] from the repository.
  Future<void> deleteAllByEntities(Iterable<T> entities) async => await getExecutor()?.deleteAllEntities(entities, this);

  /// Deletes all entities in the repository, or the provided [entities] if given.
  Future<void> deleteAll([Iterable<T>? entities]) async {
    if (entities != null) {
      await deleteAllByEntities(entities);
      return;
    }
    await getExecutor()?.deleteAll(this);
  }
}

/// {@template jetleaf_list_crud_repository}
/// A generic **list-based CRUD repository** extending [CrudRepository],
/// ensuring that all multi-entity operations return [List] instead of
/// general [Iterable].
/// {@endtemplate}
@Generic(ListCrudRepository)
abstract class ListCrudRepository<T, ID> extends CrudRepository<T, ID> {
  /// The reflective [Class] handle representing the `ListCrudRepository` interface.
  static final Class<ListCrudRepository> CLASS = Class<ListCrudRepository>(null, PackageNames.DATA);

  /// Retrieves all entities as a [List] instead of a generic [Iterable].
  @override
  Future<List<T>> findAll() async => List.from(await super.findAll());

  /// Retrieves all entities matching the given [ids] as a [List].
  @override
  Future<List<T>> findAllById(Iterable<ID> ids) async => List.from(await super.findAllById(ids));

  /// Saves multiple [entities] and returns the result as a [List].
  @override
  Future<List<S>> saveAll<S extends T>(Iterable<S> entities) async => List.from(await super.saveAll(entities));
}