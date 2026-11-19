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

/// {@template jetleaf_schema_generation_result}
/// Immutable container holding the DDL statements generated for a single
/// `@Entity` by `SchemaGenerator`.
/// {@endtemplate}
final class SchemaGenerationResult with EqualsAndHashCode {
  /// Reflective [Class] handle for [SchemaGenerationResult].
  static final Class<SchemaGenerationResult> CLASS =
      Class<SchemaGenerationResult>(null, PackageNames.DATA);

  final Type _entityType;
  final String _tableName;
  final List<String> _statements;

  /// {@macro jetleaf_schema_generation_result}
  SchemaGenerationResult({
    required Type entityType,
    required String tableName,
    required List<String> statements,
  })  : _entityType = entityType,
        _tableName = tableName,
        _statements = List.unmodifiable(statements);

  /// Returns the entity [Type] the DDL was generated for.
  Type getEntityType() => _entityType;

  /// Returns the physical table or collection name.
  String getTableName() => _tableName;

  /// Returns the ordered DDL statements (`CREATE TABLE`, `CREATE INDEX`, etc.).
  List<String> getStatements() => _statements;

  @override
  List<Object?> equalizedProperties() => [
        _entityType,
        _tableName,
        _statements,
      ];
}
