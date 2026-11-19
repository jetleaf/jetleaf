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

import 'package:jetleaf_core/intercept.dart';
import 'package:jetleaf_core/lang.dart';

import '../../repository.dart';
import '../core/zone_repository_invocation_holder.dart';
import '../paging/page.dart';
import '../paging/pageable.dart';
import '../paging/sort.dart';

/// {@template jetleaf_default_repository_executor}
/// Default production implementation of [RepositoryExecutor] backed by
/// [RepositoryFactorySupport].
///
/// [DefaultRepositoryExecutor] bridges JetLeaf's class-based repository
/// hierarchy ([Repository], [CrudRepository], [ListCrudRepository],
/// [PagingAndSortRepository], [ListPagingAndSortRepository],
/// [JetleafRepository]) with the entity-mapping, dialect, and query-derivation
/// engine in [SimpleJetleafRepository] and [DynamicRepositoryProxy].
///
/// ### Capabilities
/// - **CRUD, Paging & Batch Operations**: Delegates all standard repository
///   methods (`findById`, `findAll`, `save`, `delete`, `findPage`, `flush`,
///   `deleteAllInBatch`, etc.) to the entity's [SimpleJetleafRepository].
/// - **Intercepted Custom Methods (`query()`, `queryList()`, `querySet()`)**:
///   When a custom method on a `@Repository`-annotated class is intercepted by
///   `RepositoryMethodInterceptor`, the active [MethodInvocation] is bound in
///   [ZoneRepositoryInvocationHolder]. Calling `query()` or `queryList()` inside
///   that method automatically parses the method name via `PartTree` (or reads
///   its `@Query` annotation), binds the invocation arguments, and executes the
///   query against the configured dialect and client.
/// {@endtemplate}
class DefaultRepositoryExecutor extends RepositoryExecutor with EqualsAndHashCode {
  /// Reflective class descriptor for [DefaultRepositoryExecutor].
  static final Class<DefaultRepositoryExecutor> CLASS =
      Class<DefaultRepositoryExecutor>(null, PackageNames.DATA);

  final RepositoryFactorySupport _factory;

  /// {@macro jetleaf_default_repository_executor}
  const DefaultRepositoryExecutor(this._factory);

  /// Returns the backing [RepositoryFactorySupport].
  RepositoryFactorySupport getFactory() => _factory;

  SimpleJetleafRepository<T, ID> _repoFor<T, ID>(Repository<T, ID> repository) {
    if (T != dynamic && T != Object) {
      return _factory.createSimple<T, ID>();
    }
    final entityType = repository.getType();
    return _factory.createForType(entityType) as SimpleJetleafRepository<T, ID>;
  }

  @override
  Future<T?> execute<T>([Repository<dynamic, dynamic>? repository]) async {
    final invocation = ZoneRepositoryInvocationHolder.getCurrent();
    if (invocation == null) {
      return null;
    }

    final result = await _dispatchInvocation(invocation, repository);
    if (result is Iterable) {
      return result.isEmpty ? null : result.first as T?;
    }
    return result as T?;
  }

  @override
  Future<Iterable<T>> executeIterable<T>([
    Repository<dynamic, dynamic>? repository,
  ]) async {
    final invocation = ZoneRepositoryInvocationHolder.getCurrent();
    if (invocation == null) {
      return const [];
    }

    final result = await _dispatchInvocation(invocation, repository);
    if (result == null) {
      return const [];
    }
    if (result is Iterable) {
      return result.cast<T>();
    }
    return <T>[result as T];
  }

  Future<dynamic> _dispatchInvocation(
    MethodInvocation<dynamic> invocation,
    Repository<dynamic, dynamic>? repository,
  ) async {
    final target = repository ?? invocation.getTarget();
    final method = invocation.getMethod();
    final entityType = target is Repository ? target.getType() : null;
    if (entityType == null || entityType == dynamic || entityType == Object) {
      return null;
    }

    final metadata = _factory.getMetadataRegistry().getForType(entityType);
    final simple = _factory.createForType(entityType);
    final proxy = DynamicRepositoryProxy(
      repositoryClass: method.getDeclaringClass(),
      metadata: metadata,
      client: _factory.getEffectiveClient(),
      dialect: _factory.getDialect(),
      simple: simple,
    );

    final args = invocation.getArgument();
    final positional = args?.getPositionalArguments() ?? const <Object?>[];
    final namedStrings = args?.getNamedArguments() ?? const <String, Object?>{};
    final namedSymbols = <Symbol, Object?>{
      for (final entry in namedStrings.entries) Symbol(entry.key): entry.value,
    };

    return proxy.invokeMethod(method, positional, namedSymbols);
  }

  @override
  Future<T?> findById<T, ID>(ID id, Repository<T, ID> repository) =>
      _repoFor(repository).findById(id);

  @override
  Future<T?> findByProperty<T, ID>(
    String property,
    bool ignoreCase,
    Repository<T, ID> repository, [
    Object? value,
  ]) =>
      _repoFor(repository).findByProperty(property, ignoreCase, value);

  @override
  Future<bool> existsById<T, ID>(ID id, Repository<T, ID> repository) =>
      _repoFor(repository).existsById(id);

  @override
  Future<Iterable<T>> findAll<T, ID>(Repository<T, ID> repository) =>
      _repoFor(repository).findAll();

  @override
  Future<Iterable<T>> findAllById<T, ID>(
    Iterable<ID> ids,
    Repository<T, ID> repository,
  ) =>
      _repoFor(repository).findAllById(ids);

  @override
  Future<int> getCount<T, ID>(Repository<T, ID> repository) =>
      _repoFor(repository).count();

  @override
  Future<S> save<T, ID, S extends T>(
    S entity,
    Repository<T, ID> repository,
  ) =>
      _repoFor(repository).save<S>(entity);

  @override
  Future<Iterable<S>> saveAll<T, ID, S extends T>(
    Iterable<S> entities,
    Repository<T, ID> repository,
  ) =>
      _repoFor(repository).saveAll<S>(entities);

  @override
  Future<void> flush<T, ID>(Repository<T, ID> repository) =>
      _repoFor(repository).flush();

  @override
  Future<S> saveAndFlush<T, ID, S extends T>(
    S entity,
    Repository<T, ID> repository,
  ) =>
      _repoFor(repository).saveAndFlush<S>(entity);

  @override
  Future<List<S>> saveAllAndFlush<T, ID, S extends T>(
    Iterable<S> entities,
    Repository<T, ID> repository,
  ) =>
      _repoFor(repository).saveAllAndFlush<S>(entities);

  @override
  Future<void> deleteById<T, ID>(ID id, Repository<T, ID> repository) =>
      _repoFor(repository).deleteById(id);

  @override
  Future<void> deleteEntity<T, ID>(T entity, Repository<T, ID> repository) =>
      _repoFor(repository).delete(entity);

  @override
  Future<void> deleteAllById<T, ID>(
    Iterable<ID> ids,
    Repository<T, ID> repository,
  ) =>
      _repoFor(repository).deleteAllById(ids);

  @override
  Future<void> deleteAllEntities<T, ID>(
    Iterable<T> entities,
    Repository<T, ID> repository,
  ) =>
      _repoFor(repository).deleteAllByEntities(entities);

  @override
  Future<void> deleteAllInBatch<T, ID>(
    Iterable<T> entities,
    Repository<T, ID> repository,
  ) =>
      _repoFor(repository).deleteAllInBatch(entities);

  @override
  Future<void> deleteAll<T, ID>(Repository<T, ID> repository) =>
      _repoFor(repository).deleteAllRecords();

  @override
  Future<Iterable<T>> findAllSorted<T, ID>(
    Sort sort,
    Repository<T, ID> repository,
  ) =>
      _repoFor(repository).findAllSorted(sort);

  @override
  Future<Page<T>> findPage<T, ID>(
    Pageable pageable,
    Repository<T, ID> repository,
  ) =>
      _repoFor(repository).findPage(pageable);

  @override
  List<Object?> equalizedProperties() => [_factory, runtimeType];
}
