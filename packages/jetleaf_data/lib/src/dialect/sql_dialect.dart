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

import '../exception/data_access_exception.dart';
import '../mapping/column_metadata.dart';
import '../mapping/default_entity_metadata_registry.dart';
import '../mapping/entity_metadata.dart';
import '../mapping/naming_strategies.dart';
import '../paging/sort.dart';
import '../query/part.dart';
import '../query/part_tree.dart';
import '../query/query_criteria.dart';
import 'database_dialect.dart';
import 'sql_type_mapper.dart';

/// {@template jetleaf_sql_parameter_style}
/// Defines the **parameter placeholder syntax** emitted by a [SqlDialect].
/// {@endtemplate}
enum SqlParameterStyle {
  /// Positional question-mark placeholders (`?`), used by MySQL, MariaDB, and
  /// SQLite.
  questionMark,

  /// 1-based dollar-numbered placeholders (`$1, $2, ...`), used by PostgreSQL
  /// and CockroachDB.
  dollarNumbered,
}

/// {@template jetleaf_sql_dialect}
/// Abstract base class for **relational SQL dialects** (PostgreSQL, MySQL,
/// MariaDB, SQLite, CockroachDB, etc.).
///
/// Implements standard ANSI SQL rendering for `SELECT`, `COUNT`, `EXISTS`,
/// `INSERT`, `UPDATE`, `DELETE`, `CREATE TABLE`, `CREATE INDEX`, and
/// `DROP TABLE`, including:
/// - `AND`/`OR` predicate precedence and `IN` list placeholder expansion
/// - Implicit `INNER JOIN` generation for nested to-one relationship paths
/// - Optimistic locking (`@DataVersion`) predicates on `UPDATE` and `DELETE`
/// - `LIMIT` and `OFFSET` pagination
///
/// ### See Also
/// - [DatabaseDialect]
/// - [SqlParameterStyle]
/// - [SqlTypeMapper]
/// {@endtemplate}
abstract class SqlDialect extends DatabaseDialect {
  /// Reflective [Class] handle for [SqlDialect].
  static final Class<SqlDialect> CLASS = Class<SqlDialect>(null, PackageNames.DATA);

  /// {@macro jetleaf_sql_dialect}
  const SqlDialect();

  /// Returns the [SqlParameterStyle] placeholder convention used by this SQL
  /// engine.
  SqlParameterStyle getParameterStyle();

  /// Returns `true` if this SQL engine supports `INSERT ... RETURNING`.
  bool supportsReturning();

  /// Returns `true` if this SQL engine supports `CREATE INDEX IF NOT EXISTS`.
  bool supportsCreateIndexIfNotExists();

  /// Returns the literal used for unbounded `LIMIT` when an `OFFSET` is
  /// specified without a `LIMIT` (`'-1'` for PostgreSQL/SQLite,
  /// `'18446744073709551615'` for MySQL).
  String getUnboundedLimitLiteral();

  /// Returns `true` if the auto-increment column type inline-declares
  /// `PRIMARY KEY` (such as SQLite's `INTEGER PRIMARY KEY AUTOINCREMENT`).
  bool hasInlineAutoIncrementPrimaryKey() => false;

  @override
  bool isRelational() => true;

  @override
  SqlTypeMapper getTypeMapper();

  @override
  String escapeIdentifier(String identifier) => '"${identifier.replaceAll('"', '""')}"';

  /// Formats the fully qualified and escaped table reference for [metadata].
  String getQualifiedTable(EntityMetadata<dynamic> metadata) {
    final table = escapeIdentifier(metadata.getTableName());
    final schema = metadata.getSchema();
    final catalog = metadata.getCatalog();

    if (schema != null && catalog != null) {
      return '${escapeIdentifier(catalog)}.${escapeIdentifier(schema)}.$table';
    }
    if (schema != null) {
      return '${escapeIdentifier(schema)}.$table';
    }
    return table;
  }

  /// Alias for [getQualifiedTable].
  String qualifiedTable(EntityMetadata<dynamic> metadata) => getQualifiedTable(metadata);

  // ---------------------------------------------------------------------------
  // SELECT / COUNT / EXISTS / DELETE Rendering
  // ---------------------------------------------------------------------------

  @override
  RenderedQuery renderQuery(QueryCriteria criteria) {
    final metadata = criteria.getMetadata();
    final ctx = _SqlRenderContext(this, criteria.getValues());

    if (criteria.getType() == QueryType.delete) {
      final where = _renderWhere(
        criteria.getPredicate(),
        metadata,
        ctx,
        _JoinPlan.build(metadata, criteria),
        null,
      );
      final buffer = StringBuffer('DELETE FROM ${getQualifiedTable(metadata)}');
      if (where != null) {
        buffer.write(' WHERE $where');
      }
      return RenderedQuery(
        sql: buffer.toString(),
        parameters: ctx.effectiveValues,
      );
    }

    final joinPlan = _JoinPlan.build(metadata, criteria);
    final needsAlias = joinPlan.hasJoins ||
        _hasNestedPath(criteria.getPredicate()) ||
        criteria.getSort().toList().any((order) => order.property.contains('.'));
    final alias = needsAlias ? 'e' : null;
    final from = alias == null
        ? getQualifiedTable(metadata)
        : '${getQualifiedTable(metadata)} AS ${escapeIdentifier(alias)}';

    final joins = joinPlan.render(this);
    final projection = _renderProjection(criteria, metadata, alias);
    final where = _renderWhere(
      criteria.getPredicate(),
      metadata,
      ctx,
      joinPlan,
      alias,
    );
    final orderBy = _renderSort(criteria.getSort(), metadata, joinPlan, alias);
    final limit = _limitOf(criteria);
    final pagination = _renderLimitOffset(limit, criteria.getOffset());

    final buffer = StringBuffer('SELECT $projection FROM $from');
    if (joins.isNotEmpty) {
      buffer.write(' $joins');
    }
    if (where != null) {
      buffer.write(' WHERE $where');
    }
    if (orderBy.isNotEmpty) {
      buffer.write(' ORDER BY $orderBy');
    }
    if (pagination.isNotEmpty) {
      buffer.write(' $pagination');
    }

    return RenderedQuery(
      sql: buffer.toString(),
      parameters: ctx.effectiveValues,
    );
  }

  bool _hasNestedPath(Criterion? predicate) =>
      predicate != null &&
      predicate.getParts().any((part) => part.getProperty().contains('.'));

  int? _limitOf(QueryCriteria criteria) {
    if (criteria.getType() == QueryType.exists) {
      return 1;
    }
    return criteria.getLimit();
  }

  String _renderProjection(QueryCriteria criteria, EntityMetadata<dynamic> metadata, String? alias) {
    switch (criteria.getType()) {
      case QueryType.count:
        return 'COUNT(*)';
      case QueryType.exists:
        return '1';
      case QueryType.delete:
      case QueryType.update:
        return _fullProjection(metadata, alias);
      case QueryType.select:
        final distinct = criteria.isDistinct() ? 'DISTINCT ' : '';
        return '$distinct${_fullProjection(metadata, alias)}';
    }
  }

  String _fullProjection(EntityMetadata<dynamic> metadata, String? alias) => metadata
    .getSelectColumns()
    .map((column) => alias == null
      ? escapeIdentifier(column.getName())
      : '${escapeIdentifier(alias)}.${escapeIdentifier(column.getName())}',
    )
    .join(', ');

  String? _renderWhere(
    Criterion? predicate,
    EntityMetadata<dynamic> metadata,
    _SqlRenderContext ctx,
    _JoinPlan joinPlan,
    String? alias,
  ) {
    if (predicate == null) return null;
    return _renderCriterion(predicate, metadata, ctx, joinPlan, alias);
  }

  String _renderCriterion(
    Criterion criterion,
    EntityMetadata<dynamic> metadata,
    _SqlRenderContext ctx,
    _JoinPlan joinPlan,
    String? alias,
  ) {
    return switch (criterion) {
      PartCriterion() => _renderPart(criterion.getPart(), metadata, ctx, joinPlan, alias),
      CompositeCriterion() => '(${criterion.getChildren().map((child) => _renderCriterion(child, metadata, ctx, joinPlan, alias)).join(criterion.isOr() ? ' OR ' : ' AND ')})',
    };
  }

  String _renderPart(
    Part part,
    EntityMetadata<dynamic> metadata,
    _SqlRenderContext ctx,
    _JoinPlan joinPlan,
    String? alias,
  ) {
    final reference = _columnReference(part.getProperty(), metadata, joinPlan, alias);
    final operator = part.getOperator();
    final ignoreCase = part.isIgnoreCase();

    String ci(String expr) => ignoreCase ? 'LOWER($expr)' : expr;

    switch (operator) {
      case PartOperator.equals:
        final value = ctx.take();
        if (value == null) return '$reference IS NULL';
        return '${ci(reference)} = ${ignoreCase ? 'LOWER(${ctx.placeholder()})' : ctx.placeholder()}';
      case PartOperator.notEquals:
        final value = ctx.take();
        if (value == null) return '$reference IS NOT NULL';
        return '${ci(reference)} <> ${ignoreCase ? 'LOWER(${ctx.placeholder()})' : ctx.placeholder()}';
      case PartOperator.like:
      case PartOperator.notLike:
      case PartOperator.startingWith:
      case PartOperator.endingWith:
      case PartOperator.containing:
      case PartOperator.notContaining:
        final negate = operator == PartOperator.notLike || operator == PartOperator.notContaining;
        ctx.take();
        return '${ci(reference)} ${negate ? 'NOT ' : ''}LIKE ${ignoreCase ? 'LOWER(${ctx.placeholder()})' : ctx.placeholder()}';
      case PartOperator.greaterThan:
        ctx.take();
        return '$reference > ${ctx.placeholder()}';
      case PartOperator.greaterThanEqual:
        ctx.take();
        return '$reference >= ${ctx.placeholder()}';
      case PartOperator.lessThan:
        ctx.take();
        return '$reference < ${ctx.placeholder()}';
      case PartOperator.lessThanEqual:
        ctx.take();
        return '$reference <= ${ctx.placeholder()}';
      case PartOperator.before:
        ctx.take();
        return '$reference < ${ctx.placeholder()}';
      case PartOperator.after:
        ctx.take();
        return '$reference > ${ctx.placeholder()}';
      case PartOperator.between:
        ctx.take();
        final first = ctx.placeholder();
        ctx.take();
        final second = ctx.placeholder();
        return '$reference BETWEEN $first AND $second';
      case PartOperator.in_:
        return '$reference IN ${_inPlaceholders(ctx)}';
      case PartOperator.notIn:
        return '$reference NOT IN ${_inPlaceholders(ctx)}';
      case PartOperator.isTrue:
        return '$reference = TRUE';
      case PartOperator.isFalse:
        return '$reference = FALSE';
      case PartOperator.isNull:
        return '$reference IS NULL';
      case PartOperator.isNotNull:
        return '$reference IS NOT NULL';
    }
  }

  String _inPlaceholders(_SqlRenderContext ctx) {
    final value = ctx.takeRaw();
    final items = value is Iterable ? value.toList(growable: false) : [value];
    if (items.isEmpty) {
      return '(NULL)';
    }

    final placeholders = StringBuffer();
    for (final item in items) {
      ctx.push(item);
      if (placeholders.isNotEmpty) {
        placeholders.write(', ');
      }
      placeholders.write(ctx.placeholder());
    }
    return '($placeholders)';
  }

  String _columnReference(
    String path,
    EntityMetadata<dynamic> metadata,
    _JoinPlan joinPlan,
    String? alias,
  ) {
    final segments = path.split('.');
    var current = metadata;
    var currentAlias = alias;

    for (var i = 0; i < segments.length; i++) {
      final segment = segments[i];
      final isLast = i == segments.length - 1;

      if (!isLast) {
        final relationship = current.getRelationshipByProperty(segment);
        if (relationship == null) {
          throw QueryDerivationException('Segment "$segment" of path "$path" is not a relationship — cannot navigate deeper');
        }

        final prefix = segments.take(i + 1).join('.');
        currentAlias = joinPlan.aliasFor(pathPrefix: prefix);
        current = joinPlan.metadataFor(pathPrefix: prefix);
        continue;
      }

      final column = current.getColumnByProperty(segment);
      if (column == null) {
        throw QueryDerivationException('No column "$segment" on ${current.getSimpleName()} for path "$path"');
      }

      final reference = escapeIdentifier(column.getName());
      return currentAlias == null
        ? reference
        : '${escapeIdentifier(currentAlias)}.$reference';
    }

    throw QueryDerivationException('Unable to resolve property path "$path"');
  }

  String _renderSort(
    Sort sort,
    EntityMetadata<dynamic> metadata,
    _JoinPlan joinPlan,
    String? alias,
  ) {
    if (sort.isEmpty()) return '';

    final orders = <String>[];
    for (final order in sort.toList()) {
      final reference = _columnReference(order.property, metadata, joinPlan, alias);
      final direction = order.direction.isDescending() ? 'DESC' : 'ASC';
      if (order.ignoreCase) {
        orders.add('LOWER($reference) $direction');
        continue;
      }
      orders.add('$reference $direction');
    }

    return orders.join(', ');
  }

  String _renderLimitOffset(int? limit, int? offset) {
    final buffer = StringBuffer();
    if (limit != null) {
      buffer.write('LIMIT ${_checkInt(limit)}');
    }

    if (offset != null) {
      if (buffer.isNotEmpty) {
        buffer.write(' ');
      } else {
        buffer.write('LIMIT ${getUnboundedLimitLiteral()} ');
      }
      buffer.write('OFFSET ${_checkInt(offset)}');
    }

    return buffer.toString();
  }

  static int _checkInt(int value) {
    if (value < 0) {
      throw IllegalArgumentException('LIMIT/OFFSET must not be negative (got $value)');
    }
    return value;
  }

  // ---------------------------------------------------------------------------
  // INSERT / UPDATE / DELETE BY ID
  // ---------------------------------------------------------------------------

  @override
  String buildInsertQuery(EntityMetadata<dynamic> metadata) {
    final columns = metadata.getInsertColumns();

    if (columns.isEmpty) {
      return 'INSERT INTO ${getQualifiedTable(metadata)} DEFAULT VALUES';
    }

    final columnList = columns.map((column) => escapeIdentifier(column.getName())).join(', ');
    final placeholders = List<String>.generate(columns.length, _placeholderAt).join(', ');

    final buffer = StringBuffer('INSERT INTO ${getQualifiedTable(metadata)} ($columnList) VALUES ($placeholders)');
    if (supportsReturning()) {
      final id = metadata.getIdColumn();
      if (id != null) {
        buffer.write(' RETURNING ${escapeIdentifier(id.getName())}');
      }
    }

    return buffer.toString();
  }

  String _placeholderAt(int index) => switch (getParameterStyle()) {
    SqlParameterStyle.questionMark => '?',
    SqlParameterStyle.dollarNumbered => '\$${index + 1}',
  };

  @override
  String buildUpdateQuery(EntityMetadata<dynamic> metadata) {
    final id = metadata.getIdColumn();
    if (id == null) {
      throw EntityMappingException(
        '${metadata.getSimpleName()} has no @Id column — cannot build UPDATE',
        entityType: metadata.getEntityType(),
      );
    }

    var position = 0;
    String next() => _placeholderAt(position++);

    final sets = metadata
      .getUpdateColumns()
      .map((column) => '${escapeIdentifier(column.getName())} = ${next()}')
      .join(', ');

    final buffer = StringBuffer('UPDATE ${getQualifiedTable(metadata)} SET $sets WHERE ${escapeIdentifier(id.getName())} = ${next()}');

    final version = metadata.getVersionColumn();
    if (version != null) {
      buffer.write(' AND ${escapeIdentifier(version.getName())} = ${next()}');
    }

    return buffer.toString();
  }

  @override
  String buildDeleteQuery(EntityMetadata<dynamic> metadata) {
    final id = metadata.getIdColumn();
    if (id == null) {
      throw EntityMappingException(
        '${metadata.getSimpleName()} has no @Id column — cannot build DELETE',
        entityType: metadata.getEntityType(),
      );
    }

    var position = 0;
    String next() => _placeholderAt(position++);

    final buffer = StringBuffer('DELETE FROM ${getQualifiedTable(metadata)} WHERE ${escapeIdentifier(id.getName())} = ${next()}');

    final version = metadata.getVersionColumn();
    if (version != null) {
      buffer.write(' AND ${escapeIdentifier(version.getName())} = ${next()}');
    }

    return buffer.toString();
  }

  // ---------------------------------------------------------------------------
  // DDL Generation
  // ---------------------------------------------------------------------------

  @override
  String buildCreateTableQuery(EntityMetadata<dynamic> metadata) {
    final buffer = StringBuffer();
    buffer.writeln('CREATE TABLE IF NOT EXISTS ${getQualifiedTable(metadata)} (');

    final columnLines = metadata
      .getColumns()
      .map((column) => '  ${buildColumnDefinition(metadata, column)}')
      .toList();

    final id = metadata.getIdColumn();
    if (id != null && !(hasInlineAutoIncrementPrimaryKey() && id.isDatabaseGenerated())) {
      columnLines.add('  PRIMARY KEY (${escapeIdentifier(id.getName())})');
    }

    buffer.writeln(columnLines.join(',\n'));
    buffer.write(')');
    return buffer.toString();
  }

  /// Renders the SQL DDL column definition for [column] on [metadata].
  String buildColumnDefinition(EntityMetadata<dynamic> metadata, ColumnMetadata column) {
    final constraints = <String>[];

    String type;
    if (column.getColumnDefinition() != null) {
      type = column.getColumnDefinition()!;
    } else if (column.isId() && column.isGenerated()) {
      type = _generatedIdType(column);
    } else {
      type = getTypeMapper().getColumnType(column);
    }

    constraints.add(type);

    final isAutoGenerated = column.isId() && column.isDatabaseGenerated();
    if (!column.isNullable() && !isAutoGenerated) {
      constraints.add('NOT NULL');
    }

    if (column.isUnique() && !column.isId()) {
      constraints.add('UNIQUE');
    }

    return '${escapeIdentifier(column.getName())} ${constraints.join(' ')}';
  }

  /// Alias for [buildColumnDefinition].
  String columnDefinition(
    EntityMetadata<dynamic> metadata,
    ColumnMetadata column,
  ) => buildColumnDefinition(metadata, column);

  /// {@template jetleaf_sql_dialect_build_add_column_query}
  /// Renders an `ALTER TABLE ... ADD COLUMN ...` DDL statement for adding
  /// [column] to an existing [metadata] table.
  ///
  /// ### Usage Example
  /// ```dart
  /// final sql = dialect.buildAddColumnQuery(userMetadata, displayNameColumn);
  /// // ALTER TABLE "users" ADD COLUMN "display_name" TEXT
  /// ```
  /// {@endtemplate}
  String buildAddColumnQuery(EntityMetadata<dynamic> metadata, ColumnMetadata column) =>
      'ALTER TABLE ${getQualifiedTable(metadata)} ADD COLUMN ${buildColumnDefinition(metadata, column)}';

  /// {@template jetleaf_sql_dialect_build_inspect_columns_query}
  /// Renders a metadata introspection query that returns existing column names
  /// for the physical table backing [metadata].
  ///
  /// Used by `AutoSchemaSynchronizer` in `update` and `validate` modes to
  /// detect missing tables or newly added `@Entity` fields.
  /// {@endtemplate}
  String buildInspectColumnsQuery(EntityMetadata<dynamic> metadata) =>
      "SELECT column_name FROM information_schema.columns WHERE table_name = '${metadata.getTableName()}'";

  String _generatedIdType(ColumnMetadata column) => switch (column.getGenerationStrategy()!.name) {
    'autoIncrement' || 'identity' =>
      getTypeMapper().getAutoIncrementColumnType(),
    'uuid' => 'VARCHAR(36)',
    'snowflake' => 'BIGINT',
    _ => getTypeMapper().getColumnType(column),
  };

  @override
  String buildCreateIndexQuery(EntityMetadata<dynamic> metadata, EntityIndex index) {
    final unique = index.isUnique() ? 'UNIQUE ' : '';
    final ifNotExists = supportsCreateIndexIfNotExists() ? 'IF NOT EXISTS ' : '';

    final columns = index
      .getColumnList()
      .split(',')
      .map((column) {
        final trimmed = column.trim();
        final parts = trimmed.split(RegExp(r'\s+'));
        final name = parts.first;
        final direction = parts.length > 1 ? ' ${parts[1].toUpperCase()}' : '';
        return '${escapeIdentifier(name)}$direction';
      })
      .join(', ');

    return 'CREATE ${unique}INDEX $ifNotExists${escapeIdentifier(index.getName())} ON ${getQualifiedTable(metadata)} ($columns)';
  }

  @override
  String buildDropTableQuery(EntityMetadata<dynamic> metadata) => 'DROP TABLE IF EXISTS ${getQualifiedTable(metadata)}';
}

final class _SqlRenderContext {
  final SqlDialect dialect;
  final List<Object?> source;
  int _sourceIndex = 0;
  final List<Object?> effectiveValues = [];

  _SqlRenderContext(this.dialect, this.source);

  Object? take() {
    final value = takeRaw();
    effectiveValues.add(value);
    return value;
  }

  Object? takeRaw() {
    if (_sourceIndex >= source.length) {
      throw IllegalStateException('Predicate consumes more values than supplied');
    }
    return source[_sourceIndex++];
  }

  void push(Object? value) => effectiveValues.add(value);

  String placeholder() {
    switch (dialect.getParameterStyle()) {
      case SqlParameterStyle.questionMark:
        return '?';
      case SqlParameterStyle.dollarNumbered:
        return '\$${effectiveValues.length}';
    }
  }
}

final class _JoinPlan {
  final Map<String, _Join> _joins = {};

  _JoinPlan._();

  bool get hasJoins => _joins.isNotEmpty;

  static _JoinPlan build(EntityMetadata<dynamic> metadata, QueryCriteria criteria) {
    final plan = _JoinPlan._();

    final paths = <String>[
      if (criteria.getPredicate() != null) ...[
        ...criteria.getPredicate()!.getParts().map((part) => part.getProperty())
      ],
      ...criteria.getSort().toList().map((order) => order.property),
    ].where((path) => path.contains('.'));

    for (final path in paths) {
      plan._register(metadata, path.split('.'));
    }

    return plan;
  }

  void _register(EntityMetadata<dynamic> current, List<String> segments) {
    var currentMeta = current;
    var prefix = '';

    for (var i = 0; i < segments.length - 1; i++) {
      final property = segments[i];
      final relationship = currentMeta.getRelationshipByProperty(property);
      if (relationship == null) {
        return;
      }

      if (!relationship.isToOne()) {
        throw QueryDerivationException('Cannot join path "${segments.take(i + 1).join('.')}" — only to-one associations support implicit joins');
      }

      prefix = prefix.isEmpty ? property : '$prefix.$property';
      if (_joins.containsKey(prefix)) {
        currentMeta = _joins[prefix]!.target;
        continue;
      }

      final targetMeta = DefaultEntityMetadataRegistry.instance.getForType(relationship.getTargetEntity());
      _joins[prefix] = _Join(
        property: property,
        alias: 'j${_joins.length + 1}',
        target: targetMeta,
        joinColumn: relationship.getJoinColumn() ?? '${SnakeCaseNamingStrategy.toSnakeCase(property)}_${targetMeta.getIdColumn()?.getName() ?? 'id'}',
      );

      currentMeta = targetMeta;
    }
  }

  String aliasFor({required String pathPrefix}) => _joins[pathPrefix]!.alias;

  EntityMetadata<dynamic> metadataFor({required String pathPrefix}) => _joins[pathPrefix]!.target;

  String render(SqlDialect dialect) {
    if (_joins.isEmpty) return '';

    final buffer = StringBuffer();
    var previousAlias = 'e';
    var first = true;

    for (final join in _joins.values) {
      final target = join.target;
      final idColumn = target.getIdColumn()?.getName() ?? 'id';
      if (!first) {
        buffer.write(' ');
      }
      first = false;
      buffer.write(
        'INNER JOIN ${dialect.getQualifiedTable(target)} AS ${dialect.escapeIdentifier(join.alias)} '
        'ON ${dialect.escapeIdentifier(previousAlias)}.${dialect.escapeIdentifier(join.joinColumn)} '
        '= ${dialect.escapeIdentifier(join.alias)}.${dialect.escapeIdentifier(idColumn)}',
      );
      previousAlias = join.alias;
    }

    return buffer.toString();
  }
}

final class _Join {
  final String property;
  final String alias;
  final EntityMetadata<dynamic> target;
  final String joinColumn;

  const _Join({
    required this.property,
    required this.alias,
    required this.target,
    required this.joinColumn,
  });
}