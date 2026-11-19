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

/// 🗄 **JetLeaf Data Library**
///
/// Provides enterprise-grade repository, query derivation, entity mapping,
/// transaction management, connection pooling, and schema migration
/// abstractions for JetLeaf applications.
///
/// ### Strict Dialect & Engine Isolation
/// The core `package:jetleaf_data/jetleaf_data.dart` library exports only
/// engine-agnostic abstractions ([DatabaseDialect], [SqlDialect],
/// [DocumentDialect], [DialectRegistry], [DatabaseClient], etc.). Concrete
/// database dialects are isolated in their own dedicated sub-libraries so
/// applications working with MongoDB never see PostgreSQL symbols and vice versa:
/// - `package:jetleaf_data/postgres.dart` — PostgreSQL dialect & type mapper
/// - `package:jetleaf_data/mysql.dart` — MySQL / MariaDB dialect & type mapper
/// - `package:jetleaf_data/sqlite.dart` — SQLite dialect & type mapper
/// - `package:jetleaf_data/mongo.dart` — MongoDB dialect & BSON type mapper
/// - `package:jetleaf_data/sql.dart` — SQL-specific dialect contracts
/// - `package:jetleaf_data/document.dart` — Document-specific dialect contracts
///
/// © 2025 Hapnium & JetLeaf Contributors
library;

// =========================================================================
// Annotations
// =========================================================================
export 'annotation.dart';

// =========================================================================
// Exceptions
// =========================================================================
export 'src/exception/data_access_exception.dart';

// =========================================================================
// Core repository infrastructure & events
// =========================================================================
export 'src/core/abstract_repository_context.dart';
export 'src/core/configurable_repository_context.dart';
export 'src/core/data_repository_definition.dart';
export 'src/core/default_repository_context.dart';
export 'src/core/repository_application_module.dart';
export 'src/core/repository_aware_processor.dart';
export 'src/core/repository_context.dart';
export 'src/core/repository_context_aware.dart';
export 'src/core/repository_definition.dart';
export 'src/core/repository_method_interceptor.dart';
export 'src/core/repository_type.dart';
export 'src/core/zone_repository_invocation_holder.dart';

export 'src/event/intercepted_repository_method_event.dart';
export 'src/event/repository_event.dart';

// =========================================================================
// Paging & sorting
// =========================================================================
export 'paging.dart';

// =========================================================================
// Repository contracts & runtime
// =========================================================================
export 'repository.dart' hide Repository;

// =========================================================================
// Query derivation engine
// =========================================================================
export 'query.dart';

// =========================================================================
// Entity mapping & type conversion
// =========================================================================
export 'mapping.dart';

// =========================================================================
// Engine-agnostic dialect contracts (concrete engines live in sub-libraries:
// postgres.dart, mysql.dart, sqlite.dart, mongo.dart)
// =========================================================================
export 'src/dialect/configurable_dialect_registry.dart';
export 'src/dialect/database_dialect.dart';
export 'src/dialect/default_dialect_registry.dart';
export 'src/dialect/dialect_registry.dart';
export 'src/dialect/document_dialect.dart';
export 'src/dialect/document_type_mapper.dart';
export 'src/dialect/rendered_query.dart';
export 'src/dialect/sql_dialect.dart';
export 'src/dialect/sql_parameter_style.dart';
export 'src/dialect/sql_type_mapper.dart';

// =========================================================================
// Driver & connection pooling
// =========================================================================
export 'driver.dart';

// =========================================================================
// Transaction management
// =========================================================================
export 'transaction.dart';

// =========================================================================
// Schema migration
// =========================================================================
export 'migration.dart';

// =========================================================================
// Auto-configuration & customizers
// =========================================================================
export 'src/config/data_configurer.dart';
export 'src/config/transaction_manager_binder.dart';
export 'src/data_auto_configuration.dart';
