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

/// {@template jetleaf_data_access_exception}
/// Root exception class for all **data access and persistence errors** thrown
/// by the JetLeaf Data module.
///
/// Mirrors Spring Data's `DataAccessException` hierarchy, providing callers
/// with a store-agnostic exception model across relational SQL and document
/// databases while preserving the underlying driver [cause].
///
/// ### Usage Example
/// ```dart
/// try {
///   await userRepository.save(user);
/// } on OptimisticLockException catch (e) {
///   // Handle concurrent modification conflict
/// } on DataAccessException catch (e) {
///   // Handle general persistence failure
/// }
/// ```
///
/// ### See Also
/// - [OptimisticLockException]
/// - [DuplicateKeyException]
/// - [EntityMappingException]
/// - [QueryDerivationException]
/// - [TransactionException]
/// {@endtemplate}
class DataAccessException extends RuntimeException {
  /// {@macro jetleaf_data_access_exception}
  DataAccessException(super.message, [Object? cause]) : super(cause: cause);
}

/// {@template jetleaf_bad_sql_grammar_exception}
/// Thrown when a database rejects a statement due to invalid syntax or
/// references to non-existent tables or columns.
/// {@endtemplate}
class BadSqlGrammarException extends DataAccessException {
  /// {@macro jetleaf_bad_sql_grammar_exception}
  BadSqlGrammarException(super.message, [super.cause]);
}

/// {@template jetleaf_duplicate_key_exception}
/// Thrown when an `INSERT` or `UPDATE` operation violates a primary key or
/// unique index constraint.
/// {@endtemplate}
class DuplicateKeyException extends DataAccessException {
  /// {@macro jetleaf_duplicate_key_exception}
  DuplicateKeyException(super.message, [super.cause]);
}

/// {@template jetleaf_optimistic_lock_exception}
/// Thrown when an optimistic locking conflict is detected on an entity carrying
/// a `@DataVersion` field during an `UPDATE` or `DELETE` operation.
/// {@endtemplate}
class OptimisticLockException extends DataAccessException {
  /// {@macro jetleaf_optimistic_lock_exception}
  OptimisticLockException(super.message, [super.cause]);
}

/// {@template jetleaf_entity_not_found_exception}
/// Thrown when an entity expected to exist cannot be found in the store.
/// {@endtemplate}
class EntityNotFoundException extends DataAccessException {
  /// The runtime type of the missing entity.
  final Type? entityType;

  /// The identifier that was looked up.
  final Object? id;

  /// {@macro jetleaf_entity_not_found_exception}
  EntityNotFoundException(
    String message, {
    this.entityType,
    this.id,
    Object? cause,
  }) : super(message, cause);

  /// Returns the runtime [Type] of the missing entity, if known.
  Type? getEntityType() => entityType;

  /// Returns the identifier that was looked up, if known.
  Object? getId() => id;
}

/// {@template jetleaf_incorrect_result_size_exception}
/// Thrown when a query expected to return a specific number of rows (typically
/// `1`) returns a different count.
/// {@endtemplate}
class IncorrectResultSizeDataAccessException extends DataAccessException {
  /// The expected number of rows.
  final int expectedSize;

  /// The actual number of rows returned, if known.
  final int? actualSize;

  /// {@macro jetleaf_incorrect_result_size_exception}
  IncorrectResultSizeDataAccessException(
    super.message,
    this.expectedSize, [
    this.actualSize,
  ]);

  /// Returns the expected number of rows.
  int getExpectedSize() => expectedSize;

  /// Returns the actual number of rows returned, if known.
  int? getActualSize() => actualSize;
}

/// {@template jetleaf_cannot_get_connection_exception}
/// Thrown when a connection cannot be acquired from a `ConnectionFactory` or
/// `ConnectionPool` (for example, when the pool is closed or checkout times out).
/// {@endtemplate}
class CannotGetDatabaseConnectionException extends DataAccessException {
  /// {@macro jetleaf_cannot_get_connection_exception}
  CannotGetDatabaseConnectionException(super.message, [super.cause]);
}

/// Type alias preserving Spring JDBC naming compatibility for
/// [CannotGetDatabaseConnectionException].
typedef CannotGetJdbcConnectionException = CannotGetDatabaseConnectionException;

/// {@template jetleaf_data_access_resource_failure_exception}
/// Thrown when a data access resource (connection, cursor, or result stream)
/// fails completely.
/// {@endtemplate}
class DataAccessResourceFailureException extends DataAccessException {
  /// {@macro jetleaf_data_access_resource_failure_exception}
  DataAccessResourceFailureException(super.message, [super.cause]);
}

/// {@template jetleaf_query_timeout_exception}
/// Thrown when a query execution exceeds its configured timeout duration.
/// {@endtemplate}
class QueryTimeoutException extends DataAccessException {
  /// {@macro jetleaf_query_timeout_exception}
  QueryTimeoutException(super.message, [super.cause]);
}

/// {@template jetleaf_transaction_exception}
/// Base exception for declarative and programmatic transaction management
/// failures.
/// {@endtemplate}
class TransactionException extends DataAccessException {
  /// {@macro jetleaf_transaction_exception}
  TransactionException(super.message, [super.cause]);
}

/// {@template jetleaf_mandatory_transaction_exception}
/// Thrown when a method configured with `Propagation.mandatory` is invoked
/// without an active ambient transaction.
/// {@endtemplate}
class MandatoryTransactionException extends TransactionException {
  /// {@macro jetleaf_mandatory_transaction_exception}
  MandatoryTransactionException(super.message, [super.cause]);
}

/// {@template jetleaf_nested_transaction_exception}
/// Thrown when a nested transaction or savepoint operation is not supported by
/// the underlying driver.
/// {@endtemplate}
class NestedTransactionException extends TransactionException {
  /// {@macro jetleaf_nested_transaction_exception}
  NestedTransactionException(super.message, [super.cause]);
}

/// {@template jetleaf_transaction_system_exception}
/// Thrown when a general transaction system error occurs (such as missing a
/// `PlatformTransactionManager` or violating `Propagation.never`).
/// {@endtemplate}
class TransactionSystemException extends TransactionException {
  /// {@macro jetleaf_transaction_system_exception}
  TransactionSystemException(super.message, [super.cause]);
}

/// {@template jetleaf_entity_mapping_exception}
/// Thrown when an entity class or attribute cannot be mapped to or from its
/// persistent representation.
/// {@endtemplate}
class EntityMappingException extends DataAccessException {
  /// The entity type that failed to map.
  final Type? entityType;

  /// {@macro jetleaf_entity_mapping_exception}
  EntityMappingException(
    String message, {
    this.entityType,
    Object? cause,
  }) : super(message, cause);

  /// Returns the entity [Type] that failed to map, if known.
  Type? getEntityType() => entityType;
}

/// {@template jetleaf_query_derivation_exception}
/// Thrown when a repository query method name cannot be parsed or references
/// an unmapped property path.
/// {@endtemplate}
class QueryDerivationException extends DataAccessException {
  /// The repository method name that failed derivation.
  final String? methodName;

  /// {@macro jetleaf_query_derivation_exception}
  QueryDerivationException(
    String message, {
    this.methodName,
    Object? cause,
  }) : super(message, cause);

  /// Returns the repository method name that failed derivation, if known.
  String? getMethodName() => methodName;
}

/// {@template jetleaf_migration_exception}
/// Thrown when a schema migration fails validation, checksum verification, or
/// execution.
/// {@endtemplate}
class MigrationException extends DataAccessException {
  /// {@macro jetleaf_migration_exception}
  MigrationException(super.message, [super.cause]);
}
