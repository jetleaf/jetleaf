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

import 'dart:io';

import 'package:jetleaf_env/env.dart';
import 'package:jetleaf_env/property.dart';
import 'package:jetleaf_lang/lang.dart';

import '../jet_application.dart';

/// {@template default_properties_property_source}
/// A specialized [MapPropertySource] representing a default set of properties
/// that can be added to or merged with an existing [Environment].
///
/// The source is always named `"defaultProperties"` and is often used as a
/// fallback or baseline configuration layer.
/// 
/// This property source supports convenient static utility methods for checking
/// names, conditionally creating sources, merging into existing sources, and
/// repositioning it within the property source list.
/// 
/// Example:
/// ```dart
/// final defaults = {
///   'app.name': 'JetLeaf',
///   'app.debug': false,
/// };
/// DefaultPropertiesPropertySource.ifNotEmpty(defaults, (p) {
///   environment.propertySources.addFirst(p);
/// });
/// ```
/// {@endtemplate}
class DefaultPropertiesPropertySource extends MapPropertySource {
  /// {@macro default_properties_property_source}
  DefaultPropertiesPropertySource(Map<String, Object> source) : super(NAME, source);

  /// {@template default_properties_property_source.name}
  /// The constant name `"defaultProperties"` used for this property source.
  /// {@endtemplate}
  static final String NAME = "defaultProperties";

  /// {@template default_properties_property_source.has_matching_name}
  /// Returns `true` if the given [propertySource] is named `"defaultProperties"`.
  ///
  /// This is a utility to quickly identify if a given property source matches
  /// the default properties naming convention.
  ///
  /// Returns `false` if [propertySource] is `null` or the name does not match.
  /// {@endtemplate}
  static bool hasMatchingName(PropertySource? propertySource) {
    return (propertySource != null) && propertySource.getName().equals(NAME);
  }

  /// {@template default_properties_property_source.if_not_empty}
  /// Invokes [action] with a new [DefaultPropertiesPropertySource] if the
  /// provided [source] map is not empty.
  ///
  /// Example:
  /// ```dart
  /// DefaultPropertiesPropertySource.ifNotEmpty(myMap, (p) {
  ///   env.propertySources.addLast(p);
  /// });
  /// ```
  ///
  /// Does nothing if [source] is empty or [action] is `null`.
  /// {@endtemplate}
  static void ifNotEmpty(Map<String, Object> source, Consumer<DefaultPropertiesPropertySource>? action) {
    if (source.isNotEmpty && action != null) {
      action.call(DefaultPropertiesPropertySource(source));
    }
  }

  /// {@template default_properties_property_source.add_or_merge}
  /// Adds a new [DefaultPropertiesPropertySource] to [sources] or merges the
  /// given [source] with an existing one named `"defaultProperties"`.
  ///
  /// This ensures that default properties can be updated without duplication.
  ///
  /// - If the named source exists, its values are merged.
  /// - If it does not exist, it is added as a new source.
  ///
  /// Example:
  /// ```dart
  /// DefaultPropertiesPropertySource.addOrMerge(defaults, env.propertySources);
  /// ```
  /// {@endtemplate}
  static void addOrMerge(Map<String, Object> source, MutablePropertySources sources) {
    if (source.isNotEmpty) {
      final resultingSource = <String, Object>{};
      final propertySource = DefaultPropertiesPropertySource(resultingSource);
      if (sources.containsName(NAME)) {
        mergeIfPossible(source, sources, resultingSource);
        sources.replace(NAME, propertySource);
      } else {
        resultingSource.addAll(source);
        sources.addLast(propertySource);
      }
    }
  }

  /// {@template default_properties_property_source.merge_if_possible}
  /// Internal helper that attempts to merge [source] into the existing
  /// `"defaultProperties"` property source inside [sources].
  ///
  /// The result is written into [resultingSource].
  /// {@endtemplate}
  static void mergeIfPossible(Map<String, Object> source, MutablePropertySources sources, Map<String, Object> resultingSource) {
    final existingSource = sources.get(NAME);
    if (existingSource != null) {
      final underlyingSource = existingSource.getSource();
      if (underlyingSource is Map) {
        resultingSource.addAll(underlyingSource as Map<String, Object>);
      }
      resultingSource.addAll(source);
    }
  }

  /// {@template default_properties_property_source.move_to_end}
  /// Moves the `"defaultProperties"` source to the end of the given [environment]'s
  /// property sources list.
  ///
  /// This allows user-defined or system-level property sources to override it.
  /// {@endtemplate}
  static void moveToEnd(ConfigurableEnvironment environment) {
    moveSourcesToEnd(environment.getPropertySources());
  }

  /// {@template default_properties_property_source.move_sources_to_end}
  /// Moves the `"defaultProperties"` source to the end of the [propertySources]
  /// collection, preserving its values but placing it last in resolution order.
  /// {@endtemplate}
  static void moveSourcesToEnd(MutablePropertySources propertySources) {
    final propertySource = propertySources.remove(NAME);
    if (propertySource != null) {
      propertySources.addLast(propertySource);
    }
  }
}

/// {@template application_info_property_source}
/// A [MapPropertySource] that exposes JetLeaf application metadata such as
/// version and process ID (`pid`) to the environment system.
///
/// This property source contributes:
/// - `jetleaf.application.version`: extracted from the Dart class's package metadata
/// - `jetleaf.application.pid`: the current process ID
///
/// This source is typically registered during JetLeaf application startup and is
/// useful for diagnostic or logging purposes.
///
/// ### Example usage:
/// ```dart
/// final source = ApplicationInfoPropertySource(MyApp);
/// print(source.getProperty('jetleaf.application.version'));
/// print(source.getProperty('jetleaf.application.pid'));
/// ```
///
/// This source is added under the name `applicationInfo` and can be reordered
/// using [moveToEnd] to change its resolution precedence.
///
/// {@endtemplate}
class ApplicationInfoPropertySource extends MapPropertySource {
  /// The default name under which this property source is registered.
  static final String NAME = "applicationInfo";

  /// {@macro application_info_property_source}
  ///
  /// Creates a new property source for the given application class.
  ///
  /// - [source]: the main Dart class (e.g., `MyApp`) whose package metadata
  ///   (version) will be used.
  ApplicationInfoPropertySource(Class<Object>? source) : super(NAME, _getProperties(_readVersion(source)));

  /// Builds the map of properties (`version`, `pid`) to be exposed.
  static Map<String, Object> _getProperties(String? applicationVersion) {
    Map<String, Object> result = {};
    if (applicationVersion != null && applicationVersion.isNotEmpty) {
      result.put(JetApplication.JETLEAF_APPLICATION_VERSION, applicationVersion);
    }

    result.put(JetApplication.JETLEAF_APPLICATION_PID, pid);

    return result;
  }

  /// Attempts to extract the version string from the provided Dart class.
  ///
  /// Returns `null` if the class or package has no version metadata.
  static String? _readVersion(Class<Object>? applicationClass) {
    Package? sourcePackage = (applicationClass != null) ? applicationClass.getPackage() : null;
    return (sourcePackage != null) ? sourcePackage.getVersion() : null;
  }

  /// {@template application_info_move_to_end}
  /// Moves the [ApplicationInfoPropertySource] to the end of the
  /// [ConfigurableEnvironment]'s property source list.
  ///
  /// This ensures it has the lowest priority during property resolution.
  ///
  /// Example:
  /// ```dart
  /// ApplicationInfoPropertySource.moveToEnd(environment);
  /// ```
  ///
  /// This is useful if you want system or user-defined sources to override
  /// application metadata.
  /// {@endtemplate}
  static void moveToEnd(ConfigurableEnvironment environment) {
    MutablePropertySources propertySources = environment.getPropertySources();
    PropertySource? propertySource = propertySources.remove(NAME);
    if (propertySource != null) {
      propertySources.addLast(propertySource);
    }
  }
}