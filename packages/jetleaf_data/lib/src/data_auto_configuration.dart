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

import 'package:jetleaf_core/core.dart' hide Repository;
import 'package:jetleaf_core/lang.dart';
import 'package:jetleaf_core/pod.dart';

import '../annotation.dart';
import 'config/transaction_manager_binder.dart';
import 'core/default_repository_context.dart';
import 'core/repository_context.dart';
import 'dialect/dialect_registry.dart';
import 'mapping/default_entity_metadata_registry.dart';
import 'mapping/default_type_converter_registry.dart';
import 'mapping/entity_metadata_registry.dart';
import 'mapping/type_converter_registry.dart';
import 'transaction/transaction_interceptor.dart';

export 'config/data_configurer.dart';
export 'config/transaction_manager_binder.dart';

/// {@template jetleaf_data_auto_configuration}
/// Auto-configuration pod for the **JetLeaf Data module**.
///
/// This configuration registers essential infrastructure pods for repository
/// and transaction management, including:
/// - [RepositoryContext] for repository definitions, method interception, and execution
/// - [DialectRegistry] for database dialect resolution
/// - [EntityMetadataRegistry] for entity mapping metadata
/// - [TypeConverterRegistry] for attribute ↔ column type conversion
/// - [TransactionalMethodInterceptor] for `@Transactional` AOP interception
/// - [TransactionManagerBinder] for activating the transaction interceptor
/// {@endtemplate}
@AutoConfiguration()
@Named(DataAutoConfiguration.NAME)
@ComponentScan(includeFilters: [ComponentScanFilter(FilterType.ANNOTATION, classes: [ClassType<Repository>()])])
final class DataAutoConfiguration {
  /// Reflective class descriptor for [DataAutoConfiguration].
  static final Class<DataAutoConfiguration> CLASS =
      Class<DataAutoConfiguration>(null, PackageNames.DATA);

  /// The name of this data configuration pod.
  static const String NAME = "jetleaf.data.configuration";

  /// The pod name for the repository context.
  static const String REPOSITORY_CONTEXT_POD_NAME = "jetleaf.data.repositoryContext";

  /// The pod name for the shared dialect registry.
  static const String DIALECT_REGISTRY_POD_NAME = "jetleaf.data.dialectRegistry";

  /// The pod name for the shared entity metadata registry.
  static const String ENTITY_METADATA_REGISTRY_POD_NAME = "jetleaf.data.entityMetadataRegistry";

  /// The pod name for the shared type converter registry.
  static const String TYPE_CONVERTER_REGISTRY_POD_NAME = "jetleaf.data.typeConverterRegistry";

  /// The pod name for the shared transactional interceptor.
  static const String TRANSACTIONAL_INTERCEPTOR_POD_NAME = "jetleaf.data.transactionalMethodInterceptor";

  /// The pod name for the transaction-manager binder.
  static const String TRANSACTION_MANAGER_BINDER_POD_NAME = "jetleaf.data.transactionManagerBinder";

  /// Registers a [RepositoryContext] pod if none exists.
  @Role(DesignRole.INFRASTRUCTURE)
  @Pod(value: REPOSITORY_CONTEXT_POD_NAME)
  @ConditionalOnMissingPod(values: [RepositoryContext])
  RepositoryContext repositoryContext() => DefaultRepositoryContext();

  /// Registers the shared [DialectRegistry].
  @Role(DesignRole.INFRASTRUCTURE)
  @Pod(value: DIALECT_REGISTRY_POD_NAME)
  @ConditionalOnMissingPod(values: [DialectRegistry])
  DialectRegistry dialectRegistry() => DefaultDialectRegistry.getSharedInstance();

  /// Registers the shared [EntityMetadataRegistry].
  @Role(DesignRole.INFRASTRUCTURE)
  @Pod(value: ENTITY_METADATA_REGISTRY_POD_NAME)
  @ConditionalOnMissingPod(values: [EntityMetadataRegistry])
  EntityMetadataRegistry entityMetadataRegistry() => DefaultEntityMetadataRegistry.getSharedInstance();

  /// Registers the shared [TypeConverterRegistry].
  @Role(DesignRole.INFRASTRUCTURE)
  @Pod(value: TYPE_CONVERTER_REGISTRY_POD_NAME)
  @ConditionalOnMissingPod(values: [TypeConverterRegistry])
  TypeConverterRegistry typeConverterRegistry() => DefaultTypeConverterRegistry.getSharedInstance();

  /// Registers the [TransactionalMethodInterceptor] for `@Transactional`
  /// interception.
  @Role(DesignRole.INFRASTRUCTURE)
  @Pod(value: TRANSACTIONAL_INTERCEPTOR_POD_NAME)
  TransactionalMethodInterceptor transactionalMethodInterceptor() => TransactionalMethodInterceptor();

  /// Registers the [TransactionManagerBinder] which binds the interceptor to
  /// an available transaction manager at startup.
  @Role(DesignRole.INFRASTRUCTURE)
  @Pod(value: TRANSACTION_MANAGER_BINDER_POD_NAME)
  TransactionManagerBinder transactionManagerBinder() => TransactionManagerBinder();
}
