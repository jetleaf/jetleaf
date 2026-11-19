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

import '../../exception/data_access_exception.dart';
import '../../mapping/column_metadata.dart';
import '../../mapping/default_entity_metadata_registry.dart';
import '../../mapping/entity_metadata.dart';
import '../../mapping/relationship_metadata.dart';
import '../../mapping/snake_case_naming_strategy.dart';
import '../../paging/sort.dart';
import '../../query/part.dart';
import '../../query/part_tree.dart';
import '../../query/query_criteria.dart';
import '../database_dialect.dart';
import '../document_dialect.dart';
import 'mongo_type_mapper.dart';

/// {@template jetleaf_mongo_dialect}
/// MongoDB implementation of [DocumentDialect] translating `QueryCriteria`
/// into BSON filter, sort, and update documents.
/// {@endtemplate}
final class MongoDialect extends DocumentDialect {
  /// Reflective [Class] handle for [MongoDialect].
  static final Class<MongoDialect> CLASS =
      Class<MongoDialect>(null, PackageNames.DATA);

  /// {@macro jetleaf_mongo_dialect}
  const MongoDialect();

  @override
  String getName() => 'mongodb';

  @override
  MongoTypeMapper getTypeMapper() => MongoTypeMapper();

  @override
  String escapeIdentifier(String identifier) =>
      identifier.replaceAll('"', '\\"');

  @override
  Map<String, Object?> buildFilterDocument(QueryCriteria criteria) =>
      _renderCriterionInner(
        criteria.getPredicate(),
        _FilterContext(criteria.getValues()),
        criteria.getMetadata(),
      );

  Map<String, Object?> _renderCriterionInner(
    Criterion? criterion,
    _FilterContext ctx,
    EntityMetadata<dynamic> metadata,
  ) {
    switch (criterion) {
      case null:
        return {};
      case PartCriterion():
        return _renderPart(criterion.getPart(), ctx, metadata);
      case CompositeCriterion():
        final rendered = criterion
            .getChildren()
            .map((child) => _renderCriterionInner(child, ctx, metadata))
            .where((filter) => filter.isNotEmpty)
            .toList();
        if (rendered.isEmpty) return {};
        if (rendered.length == 1) return rendered.first;
        if (!criterion.isOr()) {
          return _mergeAnd(rendered);
        }
        return {'\$or': rendered};
    }
  }

  Map<String, Object?> _mergeAnd(List<Map<String, Object?>> filters) {
    final merged = <String, Object?>{};
    for (final filter in filters) {
      for (final entry in filter.entries) {
        final existing = merged[entry.key];
        if (existing == null) {
          merged[entry.key] = _copyValue(entry.value);
          continue;
        }
        merged[entry.key] = _mergeValues(existing, entry.value);
      }
    }
    return merged;
  }

  Object? _mergeValues(Object? left, Object? right) {
    if (left is Map<String, Object?> && right is Map<String, Object?>) {
      final out = Map<String, Object?>.from(left);
      for (final entry in right.entries) {
        out[entry.key] = out.containsKey(entry.key)
            ? _mergeValues(out[entry.key], entry.value)
            : _copyValue(entry.value);
      }
      return out;
    }
    return _copyValue(right);
  }

  Object? _copyValue(Object? value) {
    if (value is Map<String, Object?>) {
      return Map<String, Object?>.from(value);
    }
    if (value is List) {
      return List<Object?>.from(value);
    }
    return value;
  }

  Map<String, Object?> _renderPart(
    Part part,
    _FilterContext ctx,
    EntityMetadata<dynamic> metadata,
  ) {
    final field = _columnKey(part.getProperty(), metadata);
    final operator = part.getOperator();
    final ignoreCase = part.isIgnoreCase();

    switch (operator) {
      case PartOperator.equals:
        final value = ctx.take();
        if (value == null) return {field: null};
        if (ignoreCase && value is String) {
          return {
            field: {'\$regex': '^${RegExp.escape(value)}\$', '\$options': 'i'},
          };
        }
        return {field: value};
      case PartOperator.notEquals:
        final value = ctx.take();
        if (value == null) {
          return {
            field: {'\$ne': null},
          };
        }
        if (ignoreCase && value is String) {
          return {
            field: {
              '\$not': {
                '\$regex': '^${RegExp.escape(value)}\$',
                '\$options': 'i',
              },
            },
          };
        }
        return {
          field: {'\$ne': value},
        };
      case PartOperator.like:
        return {
          field: {
            '\$regex':
                _pattern(ctx.take(), anchorPrefix: true, anchorSuffix: true),
            if (ignoreCase) '\$options': 'i',
          },
        };
      case PartOperator.notLike:
        return {
          field: {
            '\$not': {
              '\$regex':
                  _pattern(ctx.take(), anchorPrefix: true, anchorSuffix: true),
              if (ignoreCase) '\$options': 'i',
            },
          },
        };
      case PartOperator.startingWith:
        return {
          field: {
            '\$regex':
                _pattern(ctx.take(), anchorPrefix: true, anchorSuffix: false),
            if (ignoreCase) '\$options': 'i',
          },
        };
      case PartOperator.endingWith:
        return {
          field: {
            '\$regex':
                _pattern(ctx.take(), anchorPrefix: false, anchorSuffix: true),
            if (ignoreCase) '\$options': 'i',
          },
        };
      case PartOperator.containing:
        return {
          field: {
            '\$regex': _pattern(
              ctx.take(),
              anchorPrefix: false,
              anchorSuffix: false,
              literal: true,
            ),
            if (ignoreCase) '\$options': 'i',
          },
        };
      case PartOperator.notContaining:
        return {
          field: {
            '\$not': {
              '\$regex': _pattern(
                ctx.take(),
                anchorPrefix: false,
                anchorSuffix: false,
                literal: true,
              ),
              if (ignoreCase) '\$options': 'i',
            },
          },
        };
      case PartOperator.greaterThan:
        return {
          field: {'\$gt': ctx.take()},
        };
      case PartOperator.greaterThanEqual:
        return {
          field: {'\$gte': ctx.take()},
        };
      case PartOperator.lessThan:
        return {
          field: {'\$lt': ctx.take()},
        };
      case PartOperator.lessThanEqual:
        return {
          field: {'\$lte': ctx.take()},
        };
      case PartOperator.before:
        return {
          field: {'\$lt': ctx.take()},
        };
      case PartOperator.after:
        return {
          field: {'\$gt': ctx.take()},
        };
      case PartOperator.between:
        final lower = ctx.take();
        final upper = ctx.take();
        return {
          field: {'\$gte': lower, '\$lte': upper},
        };
      case PartOperator.in_:
        final value = ctx.take();
        final items =
            value is Iterable ? value.toList(growable: false) : [value];
        return {
          field: {'\$in': items},
        };
      case PartOperator.notIn:
        final value = ctx.take();
        final items =
            value is Iterable ? value.toList(growable: false) : [value];
        return {
          field: {'\$nin': items},
        };
      case PartOperator.isTrue:
        return {field: true};
      case PartOperator.isFalse:
        return {field: false};
      case PartOperator.isNull:
        return {field: null};
      case PartOperator.isNotNull:
        return {
          field: {'\$ne': null},
        };
    }
  }

  String _pattern(
    Object? raw, {
    required bool anchorPrefix,
    required bool anchorSuffix,
    bool literal = false,
  }) {
    final source = raw?.toString() ?? '';
    String pattern;

    if (literal) {
      pattern = _escapeRegex(source);
    } else {
      pattern = _escapeRegex(source).replaceAll('%', '.*').replaceAll('_', '.');
    }

    final prefix = anchorPrefix ? '^' : '';
    final suffix = anchorSuffix ? '\$' : '';
    return '$prefix$pattern$suffix';
  }

  String _escapeRegex(String value) {
    final buffer = StringBuffer();
    for (var i = 0; i < value.length; i++) {
      final char = value[i];
      if ('\\.^\$*+?()[]{}|'.contains(char)) {
        buffer.write('\\$char');
        continue;
      }
      buffer.write(char);
    }
    return buffer.toString();
  }

  String _columnKey(String propertyPath, EntityMetadata<dynamic> metadata) {
    final segments = propertyPath.split('.');
    var current = metadata;
    final keys = <String>[];

    for (var i = 0; i < segments.length; i++) {
      final segment = segments[i];
      final isLast = i == segments.length - 1;

      if (!isLast) {
        final relationship = current.getRelationshipByProperty(segment);
        if (relationship == null) {
          throw QueryDerivationException(
            'Segment "$segment" of path "$propertyPath" is not a relationship — cannot navigate deeper',
          );
        }

        keys.add(
          _columnKey(
            relationship.getJoinColumn() ??
                _defaultJoinColumn(relationship, segment),
            current,
          ),
        );
        current = DefaultEntityMetadataRegistry.instance
            .getForType(relationship.getTargetEntity());
        continue;
      }

      final column = current.getColumnByProperty(segment);
      if (column == null) {
        throw QueryDerivationException(
          'No column "$segment" on ${current.getSimpleName()} for path "$propertyPath"',
        );
      }

      keys.add(column.getName());
    }

    return keys.join('.');
  }

  String _defaultJoinColumn(
    RelationshipMetadata relationship,
    String property,
  ) {
    final targetMeta = DefaultEntityMetadataRegistry.instance
        .getForType(relationship.getTargetEntity());
    return '${SnakeCaseNamingStrategy.toSnakeCase(property)}_${targetMeta.getIdColumn()?.getName() ?? 'id'}';
  }

  @override
  Map<String, Object?> buildSortDocument(
    Sort sort,
    EntityMetadata<dynamic> metadata,
  ) {
    final spec = <String, Object?>{};
    for (final order in sort.toList()) {
      spec[_columnKey(order.property, metadata)] =
          order.direction.isDescending() ? -1 : 1;
    }
    return spec;
  }

  @override
  Map<String, Object?> buildInsertDocument(
    EntityMetadata<dynamic> metadata,
    Map<String, Object?> values,
  ) =>
      Map<String, Object?>.from(values);

  @override
  Map<String, Object?> buildUpdateDocument(
    EntityMetadata<dynamic> metadata,
    Map<String, Object?> values,
  ) =>
      {'\$set': Map<String, Object?>.from(values)};

  @override
  Map<String, Object?> buildIdFilter(
    EntityMetadata<dynamic> metadata,
    Object? idValue,
    Object? versionValue,
  ) {
    final id = metadata.getIdColumn();
    final filter = <String, Object?>{if (id != null) id.getName(): idValue};
    final version = metadata.getVersionColumn();
    if (versionValue != null && version != null) {
      filter[version.getName()] = versionValue;
    }
    return filter;
  }

  @override
  RenderedQuery renderQuery(QueryCriteria criteria) {
    final collection = criteria.getMetadata().getTableName();
    final filter = buildFilterDocument(criteria);
    final sort = buildSortDocument(criteria.getSort(), criteria.getMetadata());

    switch (criteria.getType()) {
      case QueryType.select:
      case QueryType.exists:
        final buffer = StringBuffer(
          'db.$collection.find(${DocumentDialect.formatDebugDocument(filter)}',
        );
        if (sort.isNotEmpty) {
          buffer.write(
            ').sort(${DocumentDialect.formatDebugDocument(sort)}',
          );
        }
        if (criteria.getLimit() != null) {
          buffer.write(').limit(${criteria.getLimit()}');
        }
        buffer.write(')');
        return RenderedQuery(sql: buffer.toString(), document: filter);
      case QueryType.count:
        return RenderedQuery(
          sql:
              'db.$collection.countDocuments(${DocumentDialect.formatDebugDocument(filter)})',
          document: filter,
        );
      case QueryType.delete:
        return RenderedQuery(
          sql:
              'db.$collection.deleteMany(${DocumentDialect.formatDebugDocument(filter)})',
          document: filter,
        );
      case QueryType.update:
        return RenderedQuery(
          sql:
              'db.$collection.updateMany(${DocumentDialect.formatDebugDocument(filter)}, { \$set: {...} })',
          document: filter,
        );
    }
  }

  @override
  String buildCreateTableQuery(EntityMetadata<dynamic> metadata) =>
      'db.createCollection("${metadata.getTableName()}")';

  @override
  String buildCreateIndexQuery(
    EntityMetadata<dynamic> metadata,
    EntityIndex index,
  ) {
    final keys = index
        .getColumnList()
        .split(',')
        .map((entry) {
          final trimmed = entry.trim();
          final parts = trimmed.split(RegExp(r'\s+'));
          final direction =
              parts.length > 1 && parts[1].toLowerCase() == 'desc' ? -1 : 1;
          return '"${parts.first}": $direction';
        })
        .join(', ');

    return 'db.${metadata.getTableName()}.createIndex({ $keys }, { name: "${index.getName()}", unique: ${index.isUnique()} })';
  }

  @override
  String buildInsertQuery(EntityMetadata<dynamic> metadata) {
    final columns = metadata
        .getInsertColumns()
        .map((ColumnMetadata column) => '"${column.getName()}": :${column.getProperty()}')
        .join(', ');
    return 'db.${metadata.getTableName()}.insertOne({ $columns })';
  }

  @override
  String buildUpdateQuery(EntityMetadata<dynamic> metadata) {
    final id = metadata.getIdColumn();
    final version = metadata.getVersionColumn();
    final set = metadata
        .getUpdateColumns()
        .map((column) => '"${column.getName()}": :${column.getProperty()}')
        .join(', ');
    final filter = [
      if (id != null) '"${id.getName()}": :${id.getProperty()}',
      if (version != null) '"${version.getName()}": :${version.getProperty()}',
    ].join(', ');

    return 'db.${metadata.getTableName()}.updateOne({ $filter }, { \$set: { $set } })';
  }

  @override
  String buildDeleteQuery(EntityMetadata<dynamic> metadata) {
    final id = metadata.getIdColumn();
    final version = metadata.getVersionColumn();
    final filter = [
      if (id != null) '"${id.getName()}": :${id.getProperty()}',
      if (version != null) '"${version.getName()}": :${version.getProperty()}',
    ].join(', ');

    return 'db.${metadata.getTableName()}.deleteOne({ $filter })';
  }
}

final class _FilterContext {
  final List<Object?> source;
  int _index = 0;

  _FilterContext(this.source);

  Object? take() {
    if (_index >= source.length) {
      throw IllegalStateException(
        'Filter consumes more values than supplied',
      );
    }
    return source[_index++];
  }
}
