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

import 'database_dialect.dart';
import 'dialect_registry.dart';
import 'mongo/mongo_dialect.dart';
import 'mysql/mysql_dialect.dart';
import 'postgres/postgres_dialect.dart';
import 'sqlite/sqlite_dialect.dart';

/// {@template jetleaf_default_dialect_registry}
/// Default synchronized implementation of [ConfigurableDialectRegistry].
///
/// Built-in dialects (`postgresql`, `mysql`, `mariadb`, `sqlite`, `mongodb`)
/// are pre-registered when constructed via [DefaultDialectRegistry.defaults] or
/// accessed through [DefaultDialectRegistry.instance].
///
/// ### Usage Example
/// ```dart
/// final registry = DialectRegistry.defaults();
/// final dialect = registry.forUrl('jdbc:postgresql://localhost:5432/app');
/// ```
/// {@endtemplate}
final class DefaultDialectRegistry with EqualsAndHashCode implements ConfigurableDialectRegistry {
  /// Reflective [Class] handle for [DefaultDialectRegistry].
  static final Class<DefaultDialectRegistry> CLASS = Class<DefaultDialectRegistry>(null, PackageNames.DATA);

  /// Process-wide shared default registry instance.
  static final DefaultDialectRegistry instance = DefaultDialectRegistry.defaults();

  /// Returns the process-wide shared default registry instance.
  static DefaultDialectRegistry getSharedInstance() => instance;

  final Map<String, DatabaseDialect Function()> _factories = {};

  /// {@macro jetleaf_default_dialect_registry}
  DefaultDialectRegistry();

  /// Creates a [DefaultDialectRegistry] with built-in dialect factories
  /// registered lazily.
  factory DefaultDialectRegistry.defaults() {
    final registry = DefaultDialectRegistry();
    registry.register('postgresql', PostgreSqlDialect.new);
    registry.register('postgres', PostgreSqlDialect.new);
    registry.register('mysql', MySqlDialect.new);
    registry.register('mariadb', MySqlDialect.new);
    registry.register('sqlite', SqliteDialect.new);
    registry.register('mongodb', MongoDialect.new);
    registry.register('mongo', MongoDialect.new);
    return registry;
  }

  /// Registers a concrete [dialect] instance under its `getName()` and optional [aliases].
  void registerDialect(
    DatabaseDialect dialect, {
    Iterable<String> aliases = const [],
  }) {
    register(dialect.getName(), () => dialect);
    for (final alias in aliases) {
      register(alias, () => dialect);
    }
  }

  @override
  void register(String name, DatabaseDialect Function() factory) {
    synchronized(_factories, () {
      _factories[name.toLowerCase()] = factory;
    });
  }

  @override
  void unregister(String name) {
    synchronized(_factories, () {
      _factories.remove(name.toLowerCase());
    });
  }

  @override
  void clear() {
    synchronized(_factories, _factories.clear);
  }

  @override
  bool supports(String name) => synchronized(_factories, () => _factories.containsKey(name.toLowerCase()));

  @override
  List<String> getNames() => synchronized(_factories, () => _factories.keys.toList()..sort());

  @override
  DatabaseDialect getDialect(String name) {
    final factory = synchronized(
      _factories,
      () => _factories[name.toLowerCase()],
    );
    if (factory == null) {
      throw IllegalArgumentException('Unknown dialect "$name". Available: ${getNames().join(', ')}');
    }
    return factory();
  }

  @override
  DatabaseDialect get(String name) => getDialect(name);

  @override
  DatabaseDialect getDialectForUrl(String url) {
    final lower = url.toLowerCase();

    if (lower.contains('postgres')) {
      return getDialect('postgresql');
    }
    if (lower.contains('mysql') || lower.contains('mariadb')) {
      return getDialect('mysql');
    }
    if (lower.contains('sqlite') || lower.contains(':memory:') || lower.startsWith('file:')) {
      return getDialect('sqlite');
    }
    if (lower.contains('mongo')) {
      return getDialect('mongodb');
    }

    throw IllegalArgumentException('Cannot infer a dialect from url "$url". Register one with DialectRegistry.register()');
  }

  @override
  DatabaseDialect forUrl(String url) => getDialectForUrl(url);

  @override
  List<Object?> equalizedProperties() => [getNames(), runtimeType];
}