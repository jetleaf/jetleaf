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
import 'default_dialect_registry.dart';

/// {@template jetleaf_dialect_registry}
/// Registry contract for resolving [DatabaseDialect] instances by
/// engine name or connection URL.
///
/// ### See Also
/// - [ConfigurableDialectRegistry]
/// - [DefaultDialectRegistry]
/// - [DatabaseDialect]
/// {@endtemplate}
abstract interface class DialectRegistry {
  /// Reflective [Class] handle for [DialectRegistry].
  static final Class<DialectRegistry> CLASS = Class<DialectRegistry>(null, PackageNames.DATA);

  /// Shared process-wide default [DefaultDialectRegistry] instance.
  static final DefaultDialectRegistry instance = DefaultDialectRegistry.instance;

  /// Returns the shared process-wide default [DefaultDialectRegistry] instance.
  static DefaultDialectRegistry getSharedInstance() => DefaultDialectRegistry.getSharedInstance();

  /// Creates an empty [DefaultDialectRegistry].
  factory DialectRegistry() = DefaultDialectRegistry;

  /// Creates a [DefaultDialectRegistry] pre-populated with built-in dialects.
  factory DialectRegistry.defaults() = DefaultDialectRegistry.defaults;

  /// Returns `true` if a dialect is registered under [name] (case-insensitive).
  bool supports(String name);

  /// Returns the sorted list of all registered dialect names.
  List<String> getNames();

  /// Resolves and returns the [DatabaseDialect] registered under [name].
  DatabaseDialect getDialect(String name);

  /// Alias for [getDialect].
  DatabaseDialect get(String name);

  /// Infers and returns the [DatabaseDialect] matching a connection [url].
  DatabaseDialect getDialectForUrl(String url);

  /// Alias for [getDialectForUrl].
  DatabaseDialect forUrl(String url);

  /// Registers [factory] under [name] (case-insensitive).
  void register(String name, DatabaseDialect Function() factory);
}

/// {@template jetleaf_configurable_dialect_registry}
/// Configurable extension of [DialectRegistry] supporting dynamic dialect
/// registration, removal, and clearing.
/// {@endtemplate}
abstract interface class ConfigurableDialectRegistry implements DialectRegistry {
  /// Reflective [Class] handle for [ConfigurableDialectRegistry].
  static final Class<ConfigurableDialectRegistry> CLASS = Class<ConfigurableDialectRegistry>(null, PackageNames.DATA);

  /// Removes the dialect registration for [name].
  void unregister(String name);

  /// Removes all dialect registrations.
  void clear();
}