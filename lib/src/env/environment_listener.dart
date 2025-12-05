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

import 'package:jetleaf_env/env.dart';
import 'package:jetleaf_lang/lang.dart';

import '../context/bootstrap_context.dart';
import 'abstract_environment_support.dart';
import 'environment_parser.dart';
import 'models.dart';

/// {@template environment_listener}
/// A listener that prepares and configures the application environment.
///
/// The [EnvironmentListener] is responsible for:
/// - Parsing environment configuration files (JSON, YAML, properties, env)
/// - Handling Dart-based configuration sources
/// - Fallback to `ConfigurationProperty` subclasses for backward compatibility
/// - Registering property sources into the environment
/// - Determining active and default profiles
///
/// This ensures that when your application starts, the environment is
/// properly populated with all available configuration sources.
///
/// ### Example
/// ```dart
/// void main() {
///   final context = ConfigurableBootstrapContext();
///   final environment = ConfigurableEnvironment();
///
///   final listener = EnvironmentListener();
///   listener.onEnvironmentPrepared(context, environment);
///
///   // After execution, environment contains all parsed property sources.
///   print(environment.getPropertySources());
/// }
/// ```
/// {@endtemplate}
final class EnvironmentListener extends AbstractEnvironmentSupport {
  /// {@macro environment_listener}
  EnvironmentListener();

  @override
  void onEnvironmentPrepared(ConfigurableBootstrapContext context, ConfigurableEnvironment environment) {
    final parsedEnvironmentSources = getParsedEnvironmentSources();
    final environmentSources = getEnvironmentSources(parsedEnvironmentSources);

    prepareEnvironmentSources(environmentSources, environment);
    addVersionedPropertySource(environment, context.getApplicationClass());
    configureEnvironmentProfile(environment);
    setupLoggingProperties(environment, environmentSources);
  }

  /// Discovers and parses all environment definition assets available at runtime,
  /// returning them as a list of normalized [ParsedEnvironmentSource] instances.
  ///
  /// This method scans every asset provided by [Runtime.getAllAssets] and attempts
  /// to parse each using a supported [EnvironmentParser]. Parsing follows a
  /// prioritized strategy:
  ///
  /// 1. **Non-Dart parsers (in order):**
  ///    - [EnvEnvironmentParser]
  ///    - [JsonEnvironmentParser]
  ///    - [PropertiesEnvironmentParser]
  ///    - [YamlEnvironmentParser]
  ///
  ///    The first parser that reports `canParse(asset)` is used.
  ///
  /// 2. **Dart-based parser:**
  ///    - [DartEnvironmentParser]  
  ///      Used only if none of the above parsers match.
  ///
  /// If parsing succeeds, the method extracts the package name, associated
  /// profile, and the parsed property map. The property map is then passed through
  /// `flattenAndNormalizeMap` to ensure consistent key structure (e.g.,
  /// converting nested maps into `dot.notation` keys).
  ///
  /// ### Returns
  /// A list of [ParsedEnvironmentSource] objects, each representing:
  /// - The originating package
  /// - The profile the environment data belongs to
  /// - The normalized property entries
  ///
  /// Assets that fail to parse or throw exceptions are silently skipped.
  List<ParsedEnvironmentSource> getParsedEnvironmentSources() {
    final otherParsers = <EnvironmentParser>[
      EnvEnvironmentParser(),
      JsonEnvironmentParser(),
      PropertiesEnvironmentParser(),
      YamlEnvironmentParser(),
    ];
    final dartParser = DartEnvironmentParser();
    final assets = Runtime.getAllAssets();

    // --- 1) Collect parsed entries with package info -------------------------

    final sources = <ParsedEnvironmentSource>[];
    final parsed = <String>{};
    for (final asset in assets) {
      if (!parsed.add(asset.getFilePath())) {
        continue;
      }

      final parser = otherParsers.find((p) => p.canParse(asset));
      ParsedEnvironmentSource? parsedSource;

      try {
        if (parser != null) {
          parsedSource = parser.load(asset);
        } else if (dartParser.canParse(asset)) {
          parsedSource = dartParser.load(asset);
        }
      } catch (e, st) {
        if (logger.getIsErrorEnabled()) {
          logger.error(e is Throwable ? e.getMessage() : e.toString(), error: e, stacktrace: st);
        }
      }

      if (parsedSource != null) {
        sources.add(ParsedEnvironmentSource(
          parsedSource.packageName,
          parsedSource.profile,
          flattenAndNormalizeMap(parsedSource.properties)
        ));
      }
    }

    return sources;
  }
}