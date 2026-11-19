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

import '../annotation/query.dart';
import '../mapping/entity_metadata.dart';
import 'part_tree.dart';
import 'query_execution.dart';
import 'return_kind.dart';

export 'query_execution.dart';
export 'return_kind.dart';

/// {@template jetleaf_query_method}
/// Analyzed representation of a repository query method, pairing its
/// reflective [Method] handle with its parsed [PartTree] or declared [Query],
/// target [EntityMetadata], [QueryExecution] strategy, and [ReturnKind].
///
/// ### See Also
/// - [PartTree]
/// - [Query]
/// - [ReturnKind]
/// - [QueryExecution]
/// {@endtemplate}
final class QueryMethod with EqualsAndHashCode {
  /// Reflective [Class] handle for [QueryMethod].
  static final Class<QueryMethod> CLASS =
      Class<QueryMethod>(null, PackageNames.DATA);

  final Method _method;
  final EntityMetadata<dynamic> _metadata;
  final Query? _declaredQuery;
  final Modifying? _modifying;
  final PartTree? _tree;
  final QueryExecution _execution;
  final ReturnKind _returnKind;

  const QueryMethod._({
    required Method method,
    required EntityMetadata<dynamic> metadata,
    required Query? declaredQuery,
    required Modifying? modifying,
    required PartTree? tree,
    required QueryExecution execution,
    required ReturnKind returnKind,
  })  : _method = method,
        _metadata = metadata,
        _declaredQuery = declaredQuery,
        _modifying = modifying,
        _tree = tree,
        _execution = execution,
        _returnKind = returnKind;

  /// Analyzes [method] against [metadata] to construct a [QueryMethod].
  factory QueryMethod.of(Method method, EntityMetadata<dynamic> metadata) {
    final declaredQuery = method.getDirectAnnotation<Query>();
    final modifying = method.getDirectAnnotation<Modifying>();
    final returnKind = resolveReturnKind(method);

    if (declaredQuery != null) {
      return QueryMethod._(
        method: method,
        metadata: metadata,
        declaredQuery: declaredQuery,
        modifying: modifying,
        tree: null,
        execution: QueryExecution.declared,
        returnKind: returnKind,
      );
    }

    return QueryMethod._(
      method: method,
      metadata: metadata,
      declaredQuery: null,
      modifying: modifying,
      tree: PartTree.parse(method.getName(), metadata: metadata),
      execution: QueryExecution.derived,
      returnKind: returnKind,
    );
  }

  /// Returns the reflective [Method].
  Method getMethod() => _method;

  /// Returns the target [EntityMetadata].
  EntityMetadata<dynamic> getMetadata() => _metadata;

  /// Returns the `@Query` annotation, if declared.
  Query? getDeclaredQuery() => _declaredQuery;

  /// Returns the `@Modifying` annotation, if declared.
  Modifying? getModifying() => _modifying;

  /// Returns the parsed [PartTree] for derived queries, or `null` for
  /// `@Query`-declared methods.
  PartTree? getTree() => _tree;

  /// Returns the [QueryExecution] mode (`derived` or `declared`).
  QueryExecution getExecution() => _execution;

  /// Returns the semantic [ReturnKind] of the method.
  ReturnKind getReturnKind() => _returnKind;

  /// Returns the method name.
  String getName() => _method.getName();

  /// Returns `true` if this method executes a data-modifying statement.
  bool isModifying() {
    final query = _declaredQuery;
    return _modifying != null ||
        (_tree?.isDelete() ?? false) ||
        (query != null && _isMutationSql(query.getValue()));
  }

  /// Returns `true` if this method is a derived `count` query.
  bool isCountQuery() => _tree?.isCount() ?? false;

  static bool _isMutationSql(String value) {
    final trimmed = value.trimLeft().toLowerCase();
    return trimmed.startsWith('update') ||
        trimmed.startsWith('delete') ||
        trimmed.startsWith('insert') ||
        trimmed.startsWith('merge');
  }

  /// Resolves the [ReturnKind] of [method] from its declared return type.
  static ReturnKind resolveReturnKind(Method method) {
    try {
      final component = method.componentType<dynamic>();
      if (component != null) {
        final name = component.getSimpleName();
        if (name == 'List' ||
            name == 'Iterable' ||
            name == 'Set' ||
            name == 'Collection') {
          return ReturnKind.collection;
        }
        if (name == 'Page') return ReturnKind.page;
        if (name == 'Slice') return ReturnKind.slice;
        if (name == 'int' || name == 'long') return ReturnKind.count;
        if (name == 'bool') return ReturnKind.exists;
        if (name == 'num' || name == 'double' || name == 'BigInt') {
          return ReturnKind.scalar;
        }
        return ReturnKind.single;
      }
    } catch (_) {
      // Fallback to return type string inspection.
    }

    final raw = method.getReturnType().toString();
    final inner = _unwrapFuture(raw).replaceAll(' ', '');

    if (inner == 'void' || inner == 'Null') return ReturnKind.void$;
    if (inner.startsWith('List<') ||
        inner.startsWith('Iterable<') ||
        inner.startsWith('Set<') ||
        inner.startsWith('Collection<')) {
      return ReturnKind.collection;
    }
    if (inner.startsWith('Page<')) return ReturnKind.page;
    if (inner.startsWith('Slice<')) return ReturnKind.slice;
    if (inner == 'int' || inner == 'long') return ReturnKind.count;
    if (inner == 'bool') return ReturnKind.exists;
    if (inner.startsWith('num') ||
        inner.startsWith('double') ||
        inner.startsWith('BigInt')) {
      return ReturnKind.scalar;
    }

    return ReturnKind.single;
  }

  static String _unwrapFuture(String raw) {
    var current = raw.trim();
    while (true) {
      if (current.startsWith('Future<') && current.endsWith('>')) {
        current = current.substring('Future<'.length, current.length - 1).trim();
        continue;
      }
      if (current.startsWith('FutureOr<') && current.endsWith('>')) {
        current =
            current.substring('FutureOr<'.length, current.length - 1).trim();
        continue;
      }
      return current;
    }
  }

  @override
  List<Object?> equalizedProperties() => [
        _method,
        _metadata.getEntityType(),
        _execution,
        _returnKind,
      ];

  @override
  String toString() =>
      'QueryMethod(${_method.getName()}; execution: $_execution; return: $_returnKind)';
}
