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
import 'list_crud_repository.dart';
import 'list_paging_and_sort_repository.dart';

/// {@template jetleaf_jetleaf_repository}
/// The flagship repository contract — CRUD + list semantics + paging/sorting
/// + JPA-style batch and synchronization operations.
///
/// Equivalent of Spring Data's `JpaRepository`. Typical application
/// repositories extend or implement this class and add derived `findBy…` or
/// `@Query` methods:
///
/// ```dart
/// @Repository()
/// class UserRepository extends JetleafRepository<User, String> {
///   Future<User?> findByEmail(String email) async => query();
///   Future<List<User>> findByAgeGreaterThanEqualAndActiveTrue(int age) async => queryList();
/// }
/// ```
/// {@endtemplate}
@Generic(JetleafRepository)
abstract class JetleafRepository<T, ID> extends ListCrudRepository<T, ID>
    implements ListPagingAndSortRepository<T, ID> {
  /// Reflective handle for the `JetleafRepository` contract.
  static final Class<JetleafRepository> CLASS =
      Class<JetleafRepository>(null, PackageNames.DATA);

  @override
  Future<List<T>> findAllSorted(Sort sort) async =>
      List<T>.from(await getExecutor()?.findAllSorted(sort, this) ?? const []);

  @override
  Future<Page<T>> findPage(Pageable pageable) async =>
      await getExecutor()?.findPage(pageable, this) ?? Page.empty();

  /// Flushes any pending changes to the underlying store.
  Future<void> flush() async => await getExecutor()?.flush<T, ID>(this);

  /// Saves [entity] and flushes immediately.
  Future<S> saveAndFlush<S extends T>(S entity) async =>
      await getExecutor()?.saveAndFlush<T, ID, S>(entity, this) ?? entity;

  /// Saves [entities] and flushes immediately.
  Future<List<S>> saveAllAndFlush<S extends T>(Iterable<S> entities) async =>
      await getExecutor()?.saveAllAndFlush<T, ID, S>(entities, this) ?? const [];

  /// Deletes [entities] in a single batch statement.
  Future<void> deleteAllInBatch(Iterable<T> entities) async =>
      await getExecutor()?.deleteAllInBatch<T, ID>(entities, this);

  /// Deletes [entities] in a single batch statement (alias of [deleteAllInBatch]).
  Future<void> deleteInBatch(Iterable<T> entities) async =>
      deleteAllInBatch(entities);
}
