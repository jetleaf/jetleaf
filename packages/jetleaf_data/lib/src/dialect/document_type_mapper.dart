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

import '../mapping/column_metadata.dart';
import '../mapping/type_converter_registry.dart';

/// {@template jetleaf_document_type_mapper}
/// Abstract base class mapping Dart entity attribute values to and from
/// document-store (BSON/JSON) field representations.
///
/// ### See Also
/// - `DocumentDialect`
/// - [ColumnMetadata]
/// - [TypeConverterRegistry]
/// {@endtemplate}
abstract class DocumentTypeMapper with EqualsAndHashCode {
  /// Reflective [Class] handle for [DocumentTypeMapper].
  static final Class<DocumentTypeMapper> CLASS = Class<DocumentTypeMapper>(null, PackageNames.DATA);

  final TypeConverterRegistry _converters;

  /// {@macro jetleaf_document_type_mapper}
  DocumentTypeMapper([TypeConverterRegistry? converters])
      : _converters = converters ?? TypeConverterRegistry.instance;

  /// Returns the [TypeConverterRegistry] backing value conversions.
  TypeConverterRegistry getConverters() => _converters;

  /// Converts an entity attribute [value] into its document field representation.
  Object? toDocument(Object? value, ColumnMetadata column) {
    if (value == null) return null;
    return _converters.toColumn(value, value.runtimeType);
  }

  /// Converts a document field [value] back into the declared attribute type
  /// of [column].
  Object? fromDocument(Object? value, ColumnMetadata column) {
    if (value == null) return null;
    return _converters.fromColumn(value, column.getFieldType());
  }

  @override
  List<Object?> equalizedProperties() => [runtimeType, _converters];
}