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

/// 🗺 **JetLeaf Entity Mapping & Type Conversion Library**
///
/// Provides metadata extraction, naming strategies, auditing hooks, and
/// bidirectional attribute-to-column type conversion:
/// - [EntityMetadata], [ColumnMetadata], [RelationshipMetadata], [EntityIndex]
/// - [EntityMetadataBuilder], [EntityMetadataRegistry],
///   [ConfigurableEntityMetadataRegistry], [DefaultEntityMetadataRegistry]
/// - [NamingStrategy], [SnakeCaseNamingStrategy], [CamelCaseNamingStrategy],
///   [KebabCaseNamingStrategy]
/// - [TypeConverter], [BaseTypeConverter], [TypeConverterRegistry],
///   [DefaultTypeConverterRegistry], and built-in converters
/// - [AuditorAware] — current principal lookup for `@CreatedBy` / `@LastModifiedBy`
///
/// ### Usage Example
/// ```dart
/// import 'package:jetleaf_data/mapping.dart';
///
/// final registry = DefaultEntityMetadataRegistry();
/// final metadata = registry.get<User>();
/// print(metadata.getTableName());
/// ```
library;

export 'src/mapping/auditor_aware.dart';
export 'src/mapping/built_in_type_converters.dart';
export 'src/mapping/column_metadata.dart';
export 'src/mapping/default_entity_metadata_registry.dart';
export 'src/mapping/default_type_converter_registry.dart';
export 'src/mapping/entity_metadata.dart';
export 'src/mapping/entity_metadata_builder.dart';
export 'src/mapping/entity_metadata_registry.dart';
export 'src/mapping/naming_strategies.dart';
export 'src/mapping/naming_strategy.dart';
export 'src/mapping/relationship_metadata.dart';
export 'src/mapping/type_converter.dart';
export 'src/mapping/type_converter_registry.dart';