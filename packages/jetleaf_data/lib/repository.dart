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

/// 🗄 **JetLeaf Repository Contracts & Runtime Library**
///
/// Provides the repository hierarchy, dynamic proxy/executor runtime, and
/// default repository implementation:
/// - [Repository], [CrudRepository], [ListCrudRepository],
///   [PagingAndSortRepository], [ListPagingAndSortRepository], [JetleafRepository]
/// - [RepositoryExecutor], [DefaultRepositoryExecutor],
///   [RepositoryFactorySupport]
/// - [SimpleJetleafRepository] & [DynamicRepositoryProxy]
///
/// ### Usage Example
/// ```dart
/// import 'package:jetleaf_data/annotation.dart';
/// import 'package:jetleaf_data/repository.dart';
///
/// @Repository()
/// abstract class UserRepository extends JetleafRepository<User, String> {
///   Future<User?> findByEmail(String email);
/// }
/// ```
library;

import 'package:jetleaf_core/lang.dart';

import 'src/repository/crud_repository.dart';
import 'src/repository/repository_executor.dart';

export 'src/repository/crud_repository.dart';
export 'src/repository/default_repository_executor.dart';
export 'src/repository/jetleaf_repository.dart';
export 'src/repository/paging_and_sort_repository.dart';
export 'src/repository/repository_executor.dart';
export 'src/repository/repository_factory_support.dart';
export 'src/repository/internal/repository_proxy_generator.dart';
export 'src/repository/internal/simple_jetleaf_repository.dart';

/// {@template jetleaf_repository}
/// A generic **repository base class** providing basic query execution and type
/// information for entities of type [T] identified by [ID].
///
/// This abstract class is extended by [CrudRepository], [ListCrudRepository],
/// [PagingAndSortRepository], [ListPagingAndSortRepository], [JetleafRepository],
/// and [SimpleJetleafRepository]. Queries are delegated to an optional
/// [RepositoryExecutor].
/// {@endtemplate}
@Generic(Repository)
abstract class Repository<T, ID> {
  /// The reflective [Class] handle representing the base `Repository` interface.
  static final Class<Repository> CLASS = Class<Repository>(null, PackageNames.DATA);

  /// Optional executor used to perform repository operations.
  RepositoryExecutor? executor;

  /// Returns the assigned [RepositoryExecutor], or `null` if none is set.
  RepositoryExecutor? getExecutor() => executor;

  /// Sets the [RepositoryExecutor] used to perform repository operations.
  void setExecutor(RepositoryExecutor? executor) {
    this.executor = executor;
  }

  /// Executes a query returning a single result of type [U].
  Future<U?> query<U>() async {
    final activeExecutor = getExecutor();
    if (activeExecutor == null) {
      return null;
    }
    return activeExecutor.execute<U>(this);
  }

  /// Executes a query returning multiple results as an [Iterable] of [U].
  Future<Iterable<U>> queryIterable<U>() async {
    final activeExecutor = getExecutor();
    if (activeExecutor == null) {
      return [];
    }
    return activeExecutor.executeIterable<U>(this);
  }

  /// Executes a query returning results as a [List] of [U].
  Future<List<U>> queryList<U>() async => List.from(await queryIterable<U>());

  /// Executes a query returning results as a [Set] of [U].
  Future<Set<U>> querySet<U>() async => Set.from(await queryIterable<U>());

  /// Returns the [Class] representing the entity type [T].
  Class<T> getDartType() => Class<T>();

  /// Returns the [Class] representing the ID type [ID].
  Class<ID> getIdType() => Class<ID>();

  /// Returns the Dart runtime [Type] of the entity [T].
  Type getType() => T;

  /// Returns the Dart runtime [Type] of the entity identifier [ID].
  Type getId() => ID;
}