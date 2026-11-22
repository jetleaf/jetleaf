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

import '../paging/page.dart';
import '../paging/pageable.dart';
import '../paging/sort.dart';
import '../../repository.dart';

/// {@template jetleaf_repository_executor}
/// An **abstract executor** for performing CRUD, batch, paging, and query
/// operations on [Repository] instances in a uniform, asynchronous manner.
///
/// This class provides default, no-op implementations for repository
/// operations, returning `null`, empty collections, or default values. It
/// is intended to be **extended** by concrete executor implementations
/// (such as `DefaultRepositoryExecutor`) that interact with actual data stores.
///
/// ### Usage Example
/// ```dart
/// final executor = DefaultRepositoryExecutor(repositoryFactorySupport);
/// final user = await executor.findById<User, String>('user-1', userRepository);
/// ```
/// {@endtemplate}
abstract class RepositoryExecutor {
  /// {@macro jetleaf_repository_executor}
  const RepositoryExecutor();

  /// Holds the [Class] metadata for the [RepositoryExecutor] type.
  static final Class<RepositoryExecutor> CLASS = Class<RepositoryExecutor>(null, PackageNames.DATA);

  /// Executes a generic repository operation and returns a single result of type [T].
  Future<T?> execute<T>([Repository<dynamic, dynamic>? repository]) async => null;

  /// Executes a generic repository operation and returns multiple results of type [T].
  Future<Iterable<T>> executeIterable<T>([Repository<dynamic, dynamic>? repository]) async => const [];

  /// Finds an entity by its [id] using the provided [repository].
  Future<T?> findById<T, ID>(ID id, Repository<T, ID> repository) async => null;

  /// Finds a single entity by a given [property] with optional case-insensitive matching.
  Future<T?> findByProperty<T, ID>(
    String property,
    bool ignoreCase,
    Repository<T, ID> repository, [
    Object? value,
  ]) async => null;

  /// Checks whether an entity with the given [id] exists in the repository.
  Future<bool> existsById<T, ID>(ID id, Repository<T, ID> repository) async => false;

  /// Retrieves all entities from the given [repository].
  Future<Iterable<T>> findAll<T, ID>(Repository<T, ID> repository) async => const [];

  /// Retrieves all entities matching the given [ids] from the repository.
  Future<Iterable<T>> findAllById<T, ID>(
    Iterable<ID> ids,
    Repository<T, ID> repository,
  ) async => const [];

  /// Returns the total number of entities in the repository.
  Future<int> getCount<T, ID>(Repository<T, ID> repository) async => 0;

  /// Saves the given [entity] to the repository.
  Future<S> save<T, ID, S extends T>(S entity, Repository<T, ID> repository) async => entity;

  /// Saves multiple [entities] to the repository.
  Future<Iterable<S>> saveAll<T, ID, S extends T>(
    Iterable<S> entities,
    Repository<T, ID> repository,
  ) async => const [];

  /// Flushes pending changes for [repository].
  Future<void> flush<T, ID>(Repository<T, ID> repository) async {}

  /// Saves [entity] and flushes immediately.
  Future<S> saveAndFlush<T, ID, S extends T>(
    S entity,
    Repository<T, ID> repository,
  ) async {
    final saved = await save<T, ID, S>(entity, repository);
    await flush<T, ID>(repository);
    return saved;
  }

  /// Saves [entities] and flushes immediately.
  Future<List<S>> saveAllAndFlush<T, ID, S extends T>(
    Iterable<S> entities,
    Repository<T, ID> repository,
  ) async {
    final saved = List<S>.from(await saveAll<T, ID, S>(entities, repository));
    await flush<T, ID>(repository);
    return saved;
  }

  /// Deletes an entity by its identifier.
  Future<void> deleteById<T, ID>(ID id, Repository<T, ID> repository) async {}

  /// Deletes the given entity instance.
  Future<void> deleteEntity<T, ID>(T entity, Repository<T, ID> repository) async {}

  /// Deletes multiple entities by their identifiers.
  Future<void> deleteAllById<T, ID>(
    Iterable<ID> ids,
    Repository<T, ID> repository,
  ) async {}

  /// Deletes multiple entity instances.
  Future<void> deleteAllEntities<T, ID>(
    Iterable<T> entities,
    Repository<T, ID> repository,
  ) async {}

  /// Deletes multiple entity instances in a single batch statement.
  Future<void> deleteAllInBatch<T, ID>(
    Iterable<T> entities,
    Repository<T, ID> repository,
  ) async {}

  /// Deletes all entities managed by the repository.
  Future<void> deleteAll<T, ID>(Repository<T, ID> repository) async {}

  /// Returns all entities sorted according to the given [sort].
  Future<Iterable<T>> findAllSorted<T, ID>(
    Sort sort,
    Repository<T, ID> repository,
  ) async => const [];

  /// Returns a page of entities according to [pageable] constraints.
  Future<Page<T>> findPage<T, ID>(
    Pageable pageable,
    Repository<T, ID> repository,
  ) async => Page.empty();
}