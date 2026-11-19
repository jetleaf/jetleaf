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

import '../../dialect/database_dialect.dart';
import '../../dialect/document_dialect.dart';
import '../../dialect/sql_dialect.dart';
import '../../driver/database_client.dart';
import '../../driver/entity_row_mapper.dart';
import '../../exception/data_access_exception.dart';
import '../../mapping/entity_metadata.dart';
import '../../paging/page_request.dart';
import '../../paging/pageable.dart';
import '../../paging/simple_page.dart';
import '../../paging/sort.dart';
import '../../query/parameter_binder.dart';
import '../../query/part_tree.dart';
import '../../query/query_criteria.dart';
import '../../query/query_method.dart';
import '../../transaction/zone_transaction_holder.dart';
import 'simple_jetleaf_repository.dart';

/// {@template jetleaf_dynamic_repository_proxy}
/// A runtime, `noSuchMethod`-based proxy and method dispatcher for a
/// repository contract.
///
/// The proxy answers both the standard CRUD surface (`findById`, `save`, …)
/// and **derived query methods** (`findByEmailAndActiveTrue(…)`) plus
/// `@Query`-declared methods.
///
/// ### Where It Is Used
/// - `dynamic` call sites via `RepositoryFactorySupport.createDynamic`.
/// - `DefaultRepositoryExecutor` when executing custom methods on
///   `@Repository`-annotated classes intercepted by `RepositoryMethodInterceptor`.
/// {@endtemplate}
final class DynamicRepositoryProxy {
  /// Reflective class descriptor for [DynamicRepositoryProxy].
  static final Class<DynamicRepositoryProxy> CLASS =
      Class<DynamicRepositoryProxy>(null, PackageNames.DATA);

  final Class<dynamic> _repositoryClass;
  final EntityMetadata<dynamic> _metadata;
  final DatabaseClient _client;
  final DatabaseDialect _dialect;
  final SimpleJetleafRepository<dynamic, Object?> _simple;
  final ParameterBinder _binder = ParameterBinder();

  /// {@macro jetleaf_dynamic_repository_proxy}
  DynamicRepositoryProxy({
    required Class<dynamic> repositoryClass,
    required EntityMetadata<dynamic> metadata,
    required DatabaseClient client,
    required DatabaseDialect dialect,
    SimpleJetleafRepository<dynamic, Object?>? simple,
  })  : _repositoryClass = repositoryClass,
        _metadata = metadata,
        _client = client,
        _dialect = dialect,
        _simple = simple ??
            SimpleJetleafRepository<dynamic, Object?>(metadata, client, dialect);

  /// Returns the reflective [Class] of the proxied repository contract.
  Class<dynamic> getRepositoryClass() => _repositoryClass;

  /// Returns the [EntityMetadata] for the proxied entity.
  EntityMetadata<dynamic> getMetadata() => _metadata;

  /// Returns the fallback [DatabaseClient].
  DatabaseClient getClient() => _client;

  /// Returns the [DatabaseDialect] producing SQL or document queries.
  DatabaseDialect getDialect() => _dialect;

  /// Returns the underlying [SimpleJetleafRepository].
  SimpleJetleafRepository<dynamic, Object?> getSimpleRepository() => _simple;

  @override
  String toString() => 'DynamicRepositoryProxy<${_repositoryClass.getName()}>';

  @override
  int get hashCode => _repositoryClass.getName().hashCode;

  @override
  bool operator ==(Object other) =>
      other is DynamicRepositoryProxy &&
      other._repositoryClass == _repositoryClass;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final memberName = _symbolName(invocation.memberName);

    if (memberName == 'toString') {
      return toString();
    }

    if (memberName == 'hashCode') {
      return hashCode;
    }

    if (memberName == '==') {
      return invocation.positionalArguments.isNotEmpty &&
          this == invocation.positionalArguments.first;
    }

    return _dispatchAsync(
      memberName,
      invocation.positionalArguments,
      invocation.namedArguments,
    );
  }

  /// Invokes a reflected repository [method] with [positional] and [named] arguments.
  Future<dynamic> invokeMethod(
    Method method,
    List<Object?> positional, [
    Map<Symbol, Object?> named = const {},
  ]) async {
    final memberName = method.getName();
    final crud = await _dispatchCrud(memberName, positional);
    if (crud != _NotHandled.instance) {
      return crud;
    }

    final queryMethod = QueryMethod.of(method, _metadata);
    final ordered = ParameterBinder.normalizeArguments(
      positional,
      named,
      method,
      methodName: memberName,
    );

    if (queryMethod.getExecution() == QueryExecution.declared) {
      return _executeDeclared(queryMethod, ordered);
    }

    return _executeDerived(queryMethod, ordered);
  }

  Future<dynamic> _dispatchAsync(
    String memberName,
    List<Object?> positional,
    Map<Symbol, Object?> named,
  ) async {
    final crud = await _dispatchCrud(memberName, positional);
    if (crud != _NotHandled.instance) {
      return crud;
    }

    final method = _repositoryClass.getMethod(memberName);
    if (method == null) {
      throw UnsupportedOperationException(
        '${_repositoryClass.getName()} has no method "$memberName"',
      );
    }

    return invokeMethod(method, positional, named);
  }

  // =========================================================================
  // CRUD dispatch
  // =========================================================================

  Future<dynamic> _dispatchCrud(String name, List<Object?> positional) async {
    dynamic single() => positional.isNotEmpty ? positional[0] : null;

    switch (name) {
      case 'findById':
        return _simple.findById(single() as Object);
      case 'existsById':
        return _simple.existsById(single() as Object);
      case 'findAll':
        return _simple.findAll();
      case 'findAllById':
        return _simple.findAllById((single() as Iterable).cast<Object>());
      case 'save':
        return _simple.save(single());
      case 'saveAll':
        return _simple.saveAll((single() as Iterable).cast());
      case 'saveAndFlush':
        return _simple.saveAndFlush(single());
      case 'saveAllAndFlush':
        return _simple.saveAllAndFlush((single() as Iterable).cast());
      case 'deleteById':
        return _simple.deleteById(single() as Object);
      case 'delete':
        return _simple.delete(single());
      case 'deleteAllById':
        return _simple.deleteAllById((single() as Iterable).cast<Object>());
      case 'deleteAllByEntities':
        return _simple.deleteAllByEntities((single() as Iterable).cast());
      case 'deleteAll':
        return positional.isEmpty
            ? _simple.deleteAll()
            : _simple.deleteAll((single() as Iterable).cast());
      case 'deleteAllInBatch':
      case 'deleteInBatch':
        return _simple.deleteAllInBatch((single() as Iterable).cast());
      case 'flush':
        return _simple.flush();
      case 'getCount':
      case 'count':
        return _simple.count();
      case 'findAllSorted':
        return _simple.findAllSorted(single() as Sort);
      case 'findPage':
        return _simple.findPage(single() as Pageable);
      default:
        return _NotHandled.instance;
    }
  }

  // =========================================================================
  // Derived queries
  // =========================================================================

  Future<dynamic> _executeDerived(
    QueryMethod queryMethod,
    List<Object?> orderedArguments,
  ) async {
    final tree = queryMethod.getTree()!;
    final pageable = orderedArguments.whereType<Pageable>().firstOrNull;
    final explicitSort = orderedArguments.whereType<Sort>().firstOrNull;

    final bound = _binder.bindDerived(
      orderedArguments,
      tree,
      methodName: queryMethod.getName(),
    );

    if (tree.isCount()) {
      return _simple.executeQueryCount(tree, bound.getPositional());
    }

    if (tree.isExists()) {
      return _simple.executeQueryExists(tree, bound.getPositional());
    }

    if (tree.isDelete()) {
      return _simple.executeQueryDelete(tree, bound.getPositional());
    }

    switch (queryMethod.getReturnKind()) {
      case ReturnKind.single:
        final criteria = _selectCriteria(
          tree,
          bound.getPositional(),
          explicitSort,
          pageable,
          cap: 2,
        );
        final rows = await _fetchMapped(criteria);
        if (rows.length > 1) {
          throw IncorrectResultSizeDataAccessException(
            'Expected at most one ${_metadata.getSimpleName()} for ${queryMethod.getName()}, got ${rows.length}',
            1,
            rows.length,
          );
        }

        return rows.firstOrNull;
      case ReturnKind.collection:
        final criteria = _selectCriteria(
          tree,
          bound.getPositional(),
          explicitSort,
          pageable,
          cap: tree.getLimit(),
        );
        return _fetchMapped(criteria);
      case ReturnKind.page:
      case ReturnKind.slice:
        final effectivePageable = pageable ?? PageRequest(0, 20);
        final criteria = _selectCriteria(
          tree,
          bound.getPositional(),
          null,
          effectivePageable,
          cap: effectivePageable.getPageSize(),
        );
        final rows = await _fetchMapped(criteria);
        final total = queryMethod.getReturnKind() == ReturnKind.page
            ? await _simple.countByCriteria(
                QueryCriteria.count(
                  metadata: _metadata,
                  predicate: tree.getPredicate(),
                  values: bound.getPositional(),
                ),
              )
            : rows.length;
        return SimplePage<dynamic>(rows, effectivePageable, total);
      case ReturnKind.count:
        return _simple.executeQueryCount(tree, bound.getPositional());
      case ReturnKind.exists:
        return _simple.executeQueryExists(tree, bound.getPositional());
      case ReturnKind.scalar:
        return _simple.executeQueryCount(tree, bound.getPositional());
      case ReturnKind.void$:
        await _simple.executeQueryDelete(tree, bound.getPositional());
        return null;
    }
  }

  QueryCriteria _selectCriteria(
    PartTree tree,
    List<Object?> values,
    Sort? sort,
    Pageable? pageable, {
    int? cap,
  }) {
    final selectSort = pageable != null && pageable.getSort().isSorted()
        ? pageable.getSort()
        : (sort ?? tree.getSort());

    return QueryCriteria.select(
      metadata: _metadata,
      predicate: tree.getPredicate(),
      values: values,
      sort: selectSort,
      limit: pageable?.isPaged() ?? false
          ? pageable!.getPageSize()
          : tree.getLimit() ?? cap,
      offset: pageable?.isPaged() ?? false ? pageable!.getOffset() : null,
      distinct: tree.isDistinct(),
    );
  }

  Future<List<dynamic>> _fetchMapped(QueryCriteria criteria) async {
    if (_dialect is DocumentDialect) {
      final documentDialect = _dialect;
      final documents = await _getAmbientClient().findDocuments(
        _metadata.getTableName(),
        documentDialect.buildFilterDocument(criteria),
        sort: criteria.getSort().isSorted()
            ? documentDialect.buildSortDocument(criteria.getSort(), _metadata)
            : null,
        limit: criteria.getLimit(),
        skip: criteria.getOffset(),
      );

      final mapper = EntityRowMapper<dynamic>(_metadata);
      return [for (final document in documents) mapper.mapRow(document)];
    }

    final rendered = (_dialect as SqlDialect).renderQuery(criteria);
    final result = await _getAmbientClient().query(
      rendered.getSql(),
      parameters: rendered.getParameters(),
    );
    final mapper = EntityRowMapper<dynamic>(_metadata);
    return [for (final row in result.getRows()) mapper.mapRow(row)];
  }

  DatabaseClient _getAmbientClient() =>
      ZoneTransactionHolder.getCurrent()?.getConnection() ?? _client;

  // =========================================================================
  // Declared queries (@Query)
  // =========================================================================

  Future<dynamic> _executeDeclared(
    QueryMethod queryMethod,
    List<Object?> orderedArguments,
  ) async {
    final declared = queryMethod.getDeclaredQuery()!;
    final bound = _binder.bindNamed(
      orderedArguments,
      queryMethod.getMethod(),
      methodName: queryMethod.getName(),
      query: declared.getValue(),
    );

    final sql = declared.isNativeQuery()
        ? declared.getValue()
        : _translateJql(declared.getValue());
    final expanded = _expandNamedParameters(sql, bound.getNamed());

    if (queryMethod.isModifying()) {
      final affected = await _getAmbientClient().execute(
        expanded.sql,
        parameters: expanded.parameters,
      );
      return switch (queryMethod.getReturnKind()) {
        ReturnKind.count || ReturnKind.scalar => affected,
        _ => null,
      };
    }

    final result = await _getAmbientClient().query(
      expanded.sql,
      parameters: expanded.parameters,
    );
    final mapper = EntityRowMapper<dynamic>(_metadata);

    switch (queryMethod.getReturnKind()) {
      case ReturnKind.single:
        if (result.getRows().isEmpty) {
          return null;
        }

        if (result.getRows().length > 1) {
          throw IncorrectResultSizeDataAccessException(
            'Expected at most one row for ${queryMethod.getName()}, got ${result.getRows().length}',
            1,
            result.getRows().length,
          );
        }

        return mapper.mapRow(result.getRows().single);
      case ReturnKind.collection:
        return [for (final row in result.getRows()) mapper.mapRow(row)];
      case ReturnKind.count:
        return (result.getRows().firstOrNull?.values.first as num?)?.toInt() ?? 0;
      case ReturnKind.exists:
        return result.getRows().isNotEmpty;
      case ReturnKind.scalar:
        return result.getRows().firstOrNull?.values.first;
      case ReturnKind.void$:
        return null;
      case ReturnKind.page:
      case ReturnKind.slice:
        throw UnsupportedOperationException(
          '@Query methods returning Page/Slice are not supported — derive a page from a list instead',
        );
    }
  }

  /// Translates a JQL statement into SQL (JQL-lite).
  String _translateJql(String jql) {
    final sqlDialect = _dialect as SqlDialect;
    var sql = jql;

    final entityMatch = RegExp(
      r'\b(FROM|UPDATE|DELETE)(?:\s+FROM)?\s+([A-Za-z_][A-Za-z0-9_]*)(\s+(?:AS\s+)?([A-Za-z_][A-Za-z0-9_]*))?',
      caseSensitive: false,
    ).firstMatch(sql);

    String? alias;
    if (entityMatch != null) {
      final verb = entityMatch.group(1)!.toUpperCase();
      final keyword = verb == 'DELETE' ? 'DELETE FROM' : verb;
      alias = entityMatch.group(4);

      if (alias != null &&
          const {
            'WHERE',
            'ORDER',
            'GROUP',
            'SET',
            'LEFT',
            'INNER',
            'JOIN',
            'ON',
            'UNION',
          }.contains(alias.toUpperCase())) {
        alias = null;
      }

      final table = sqlDialect.qualifiedTable(_metadata);
      final replacement =
          alias != null ? '$keyword $table AS $alias' : '$keyword $table';
      sql = sql.replaceRange(entityMatch.start, entityMatch.end, replacement);
    }

    if (alias != null) {
      for (final column in _metadata.getColumns()) {
        final pattern = RegExp(
          '\\b${RegExp.escape(alias)}\\.${RegExp.escape(column.getProperty())}\\b',
          caseSensitive: false,
        );
        sql = sql.replaceAll(
          pattern,
          '$alias.${_dialect.escapeIdentifier(column.getName())}',
        );
      }
    }

    for (final column in _metadata.getColumns()) {
      final pattern = RegExp(
        r'(?<![\w.:"])' +
            RegExp.escape(column.getProperty()) +
            r'(?![\w.:"])',
        caseSensitive: false,
      );
      sql = sql.replaceAll(
        pattern,
        _dialect.escapeIdentifier(column.getName()),
      );
    }

    final entityPattern =
        RegExp(r'\b' + RegExp.escape(_metadata.getSimpleName()) + r'\b');
    if (entityPattern.hasMatch(sql)) {
      sql = sql.replaceAll(entityPattern, sqlDialect.qualifiedTable(_metadata));
    }

    if (alias != null) {
      final selectMatch =
          RegExp(r'\bSELECT\s+(DISTINCT\s+)?', caseSensitive: false)
              .firstMatch(sql);
      final fromIndex = sql.toLowerCase().indexOf(' from ');
      if (selectMatch != null && fromIndex > selectMatch.end) {
        final projection = _metadata
            .getSelectColumns()
            .map((column) => _dialect.escapeIdentifier(column.getName()))
            .join(', ');
        final before = sql.substring(0, fromIndex);
        final after = sql.substring(fromIndex);
        final selectList = before.substring(selectMatch.end).replaceAllMapped(
              RegExp(r'(?<![\w.])' + RegExp.escape(alias) + r'(?![\w.])'),
              (_) => projection,
            );
        sql = '${before.substring(0, selectMatch.end)}$selectList$after';
      }
    }

    return sql;
  }

  /// Expands `:name` placeholders into positional bindings in order of appearance.
  ({String sql, List<Object?> parameters}) _expandNamedParameters(
    String sql,
    Map<String, Object?> named,
  ) {
    final parameters = <Object?>[];
    final dollarStyle = _dialect is SqlDialect &&
        _dialect.getParameterStyle() == SqlParameterStyle.dollarNumbered;
    final buffer = StringBuffer();

    var last = 0;
    for (final match in RegExp(r':([A-Za-z_][A-Za-z0-9_]*)').allMatches(sql)) {
      buffer.write(sql.substring(last, match.start));
      final name = match.group(1)!;
      if (!named.containsKey(name)) {
        throw QueryDerivationException(
          'No argument bound for parameter ":$name"',
          methodName: name,
        );
      }

      parameters.add(named[name]);
      buffer.write(dollarStyle ? '\$${parameters.length}' : '?');
      last = match.end;
    }

    buffer.write(sql.substring(last));
    return (sql: buffer.toString(), parameters: parameters);
  }

  static String _symbolName(Symbol symbol) {
    final raw = symbol.toString();
    final match =
        RegExp(r'Symbol\("([A-Za-z_][A-Za-z0-9_]*)"\)').firstMatch(raw);
    return match?.group(1) ?? (raw.startsWith('#') ? raw.substring(1) : raw);
  }
}

final class _NotHandled {
  static const _NotHandled instance = _NotHandled._();

  const _NotHandled._();
}
