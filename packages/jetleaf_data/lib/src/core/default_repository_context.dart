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

import 'package:jetleaf_core/core.dart';
import 'package:jetleaf_core/lang.dart';
import 'package:jetleaf_core/logging.dart';
import 'package:jetleaf_core/pod.dart';

import 'data_configurer.dart';
import '../annotation/entity.dart';
import '../dialect/database_dialect.dart';
import '../dialect/default_dialect_registry.dart';
import '../dialect/dialect_registry.dart';
import '../driver/connection_pool.dart';
import '../driver/database_client.dart';
import '../mapping/auditor_aware.dart';
import '../mapping/default_entity_metadata_registry.dart';
import '../mapping/default_type_converter_registry.dart';
import '../mapping/entity_metadata_registry.dart';
import '../mapping/type_converter_registry.dart';
import '../migration/schema_synchronizer.dart';
import '../repository/default_repository_executor.dart';
import '../repository/repository_executor.dart';
import '../repository/repository_factory_support.dart';
import 'repository_context.dart';

/// {@template jetleaf_default_repository_context}
/// The default runtime implementation of [RepositoryContext], responsible for
/// **discovering repository classes**, **building repository method definitions**,
/// **invoking [DataConfigurer] pods**, **synchronizing `@Entity` schemas**, and
/// **providing the active [RepositoryExecutor]** for repository operations.
/// {@endtemplate}
final class DefaultRepositoryContext extends AbstractRepositoryContext implements ApplicationContextAware, InitializingPod, DisposablePod {
  /// Reflective class descriptor for [DefaultRepositoryContext].
  static final Class<DefaultRepositoryContext> CLASS = Class<DefaultRepositoryContext>(null, PackageNames.DATA);

  late ApplicationEventBus _eventBus;
  late ApplicationContext _applicationContext;
  RepositoryExecutor? _executor;

  /// Active [AutoSchemaSynchronizer] retained for `createDrop` cleanup on shutdown.
  AutoSchemaSynchronizer? _schemaSynchronizer;

  /// Discovered `@Entity` types synchronized during [onReady].
  List<Type> _synchronizedEntities = const [];

  final Log _logger = LogFactory.getLog("repositoryContext");

  /// {@macro jetleaf_default_repository_context}
  DefaultRepositoryContext();

  @override
  String getPackageName() => PackageNames.DATA;

  @override
  List<Object?> equalizedProperties() => [_executor, runtimeType];

  @override
  ApplicationEventBus getEventBus() => _eventBus;

  @override
  RepositoryExecutor getExecutor() {
    final executor = _executor;

    if (executor == null) {
      throw IllegalStateException(
        "No RepositoryExecutor available. You must provide a RepositoryExecutor, "
        "RepositoryFactorySupport, DatabaseClient, or ConnectionPool via the "
        "application context before accessing it.",
      );
    }

    return executor;
  }

  @override
  Future<void> onReady() async {
    await _applyDataConfigurers();

    if (await _applicationContext.containsType(RepositoryExecutor.CLASS)) {
      _executor = await _applicationContext.get(RepositoryExecutor.CLASS);
    } else if (await _applicationContext.containsType(RepositoryFactorySupport.CLASS)) {
      final factory = await _applicationContext.get(RepositoryFactorySupport.CLASS);
      _executor = DefaultRepositoryExecutor(factory);
    } else {
      final resolvedFactory = await _tryCreateRepositoryFactory();
      if (resolvedFactory != null) {
        _executor = DefaultRepositoryExecutor(resolvedFactory);
      }
    }

    await _discoverAndBuildDefinition();
    await _synchronizeEntitySchemas();
  }

  @override
  Future<void> onDestroy() async {
    final synchronizer = _schemaSynchronizer;
    if (synchronizer != null && synchronizer.getMode() == DdlAutoMode.createDrop && _synchronizedEntities.isNotEmpty) {
      await synchronizer.dropAll(_synchronizedEntities);
    }
  }

  /// {@template jetleaf_default_repository_context_synchronize_entity_schemas}
  /// Discovers all concrete `@Entity` classes in the runtime and applies
  /// automatic DDL synchronization using `jetleaf.data.ddl-auto` (defaulting
  /// to [DdlAutoMode.update]) whenever a [ConnectionPool] or [DatabaseClient]
  /// and a [DatabaseDialect] are registered in [_applicationContext].
  /// {@endtemplate}
  Future<void> _synchronizeEntitySchemas() async {
    final configuredMode = _applicationContext.getEnvironment().getProperty('jetleaf.data.ddl-auto');
    final mode = configuredMode != null ? DdlAutoMode.parse(configuredMode) : DdlAutoMode.update;
    if (mode == DdlAutoMode.none) {
      return;
    }

    ConnectionPool? pool;
    DatabaseClient? client;
    if (await _applicationContext.containsType(ConnectionPool.CLASS)) {
      pool = await _applicationContext.get(ConnectionPool.CLASS);
    } else if (await _applicationContext.containsType(DatabaseClient.CLASS)) {
      client = await _applicationContext.get(DatabaseClient.CLASS);
    } else {
      return;
    }

    if (!await _applicationContext.containsType(DatabaseDialect.CLASS)) {
      return;
    }
    final dialect = await _applicationContext.get(DatabaseDialect.CLASS);

    final metadataRegistry = await _applicationContext.containsType(EntityMetadataRegistry.CLASS)
        ? await _applicationContext.get(EntityMetadataRegistry.CLASS)
        : DefaultEntityMetadataRegistry.getSharedInstance();

    final entityTypes = <Type>[];
    for (final cls in Runtime.getAllClasses()) {
      if (!cls.getIsAbstract() && cls.getAnnotations().any((a) => a.getType() == Entity)) {
        entityTypes.add(cls.getType());
      }
    }

    if (entityTypes.isEmpty) {
      return;
    }

    final synchronizer = AutoSchemaSynchronizer(
      client: client,
      connectionFactory: pool,
      dialect: dialect,
      metadataRegistry: metadataRegistry,
      mode: mode,
    );
    _schemaSynchronizer = synchronizer;
    _synchronizedEntities = entityTypes;
    await synchronizer.synchronize(entityTypes);
  }

  Future<void> _applyDataConfigurers() async {
    if (!await _applicationContext.containsType(DataConfigurer.CLASS)) {
      return;
    }

    final dialectRegistry = await _applicationContext.containsType(DialectRegistry.CLASS)
        ? await _applicationContext.get(DialectRegistry.CLASS)
        : DefaultDialectRegistry.getSharedInstance();
    final converterRegistry =
        await _applicationContext.containsType(TypeConverterRegistry.CLASS)
            ? await _applicationContext.get(TypeConverterRegistry.CLASS)
            : DefaultTypeConverterRegistry.getSharedInstance();
    final metadataRegistry =
        await _applicationContext.containsType(EntityMetadataRegistry.CLASS)
            ? await _applicationContext.get(EntityMetadataRegistry.CLASS)
            : DefaultEntityMetadataRegistry.getSharedInstance();

    final configurers = await _applicationContext.getPodsOf(DataConfigurer.CLASS);
    for (final configurer in configurers.values) {
      configurer.configureDialects(dialectRegistry);
      configurer.configureTypeConverters(converterRegistry);
      configurer.configureEntityMetadata(metadataRegistry);
      configurer.configureRepositoryContext(this);
    }
  }

  Future<RepositoryFactorySupport?> _tryCreateRepositoryFactory() async {
    DatabaseClient? client;
    ConnectionPool? pool;

    if (await _applicationContext.containsType(ConnectionPool.CLASS)) {
      pool = await _applicationContext.get(ConnectionPool.CLASS);
    } else if (await _applicationContext.containsType(DatabaseClient.CLASS)) {
      client = await _applicationContext.get(DatabaseClient.CLASS);
    } else {
      return null;
    }

    DatabaseDialect? dialect;
    if (await _applicationContext.containsType(DatabaseDialect.CLASS)) {
      dialect = await _applicationContext.get(DatabaseDialect.CLASS);
    }

    AuditorAware<dynamic>? auditorAware;
    if (await _applicationContext.containsType(AuditorAware.CLASS)) {
      auditorAware = await _applicationContext.get(AuditorAware.CLASS);
    }

    return RepositoryFactorySupport(
      client: client,
      pool: pool,
      dialect: dialect,
      auditorAware: auditorAware,
    );
  }

  Future<void> _discoverAndBuildDefinition() async {
    final names = _applicationContext.getDefinitionNames();
    for (final name in names) {
      final definition = _applicationContext.getDefinition(name);
      final cls = definition.type;

      if (cls.hasDirectAnnotation<Repository>()) {
        if (_logger.getIsTraceEnabled()) {
          _logger.trace("Found a repository annotated class ${cls.getQualifiedName()}");
        }

        final target = await _applicationContext.getPod(name);

        for (final method in cls.getMethods()) {
          if (MethodUtils.getDefaultMethodNames().contains(method.getName())) {
            continue;
          }

          if (target is EqualsAndHashCode && ["equalizedProperties"].contains(method.getName())) {
            continue;
          }

          if (target is ToString && ["toStringOptions"].contains(method.getName())) {
            continue;
          }

          addDefinition(buildDefinition(method, target));

          if (_logger.getIsTraceEnabled()) {
            _logger.trace("Added RepositoryDefinition for ${method.getName()} in ${cls.getQualifiedName()}");
          }
        }
      }
    }
  }

  @override
  void setApplicationContext(ApplicationContext applicationContext) {
    _applicationContext = applicationContext;
  }

  @override
  void setApplicationEventBus(ApplicationEventBus applicationEventBus) {
    _eventBus = applicationEventBus;
  }

  @override
  void setExecutor(RepositoryExecutor executor) {
    _executor = executor;
  }
}