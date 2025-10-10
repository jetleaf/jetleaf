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

import 'package:jetleaf_core/annotation.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:meta/meta_meta.dart';

import 'entry/application_import_selector.dart';
import 'entry/application_type_filter.dart';

/// {@template jetleaf_class_JetLeafApplication}
/// A **meta-annotation** in Jetleaf used to bootstrap and configure the
/// root application class.
///
/// When applied to a class, this annotation signals Jetleaf to:
/// - Perform component scanning via [ComponentScan].
/// - Apply the [Configuration] with identifier `jetleaf_application`.
/// - Import additional selectors, such as [ApplicationImportSelector].
///
/// This annotation plays a central role in defining the application entry point
/// and enabling auto-configuration features.
///
/// ### Properties
/// - [ENABLE_AUTO_CONFIGURATION_PROPERTY]: Toggle to enable auto-configuration.
/// - [DISABLE_AUTO_CONFIGURATION_PROPERTY]: Toggle to disable auto-configuration.
///
/// ### Example
/// ```dart
/// @JetLeafApplication()
/// class MyApplication {
///   static void main() {
///     // Launch the application
///     JetLeaf.run(MyApplication);
///   }
/// }
/// ```
/// {@endtemplate}
@EnableAutoConfiguration()
@Target({TargetKind.classType})
@Configuration("jetleaf_application")
@Import([ClassType<ApplicationImportSelector>(package: PackageNames.MAIN)])
@ComponentScan(
  includeFilters: [ComponentScanFilter(type: FilterType.CUSTOM, typeFilter: ApplicationTypeFilter())]
)
class JetLeafApplication extends ReflectableAnnotation {
  /// {@template jetleaf_app_enable_auto_config}
  /// Property key used to enable auto-configuration.
  ///
  /// When set to `true`, Jetleaf will attempt to auto-detect and register
  /// components and modules during startup.
  /// {@endtemplate}
  static const String ENABLE_AUTO_CONFIGURATION_PROPERTY = "jetleaf.enableautoconfiguration";

  /// {@template jetleaf_app_disable_auto_config}
  /// Property key used to disable auto-configuration.
  ///
  /// When set to `true`, Jetleaf will skip auto-configuration, allowing
  /// for full manual configuration of the application.
  /// {@endtemplate}
  static const String DISABLE_AUTO_CONFIGURATION_PROPERTY = "jetleaf.disableautoconfiguration";

  /// {@macro jetleafEntry}
  const JetLeafApplication();

  /// {@template jetleaf_app_annotation_type}
  /// Returns the runtime [Type] of this annotation, allowing Jetleaf's
  /// reflection system to recognize and process it.
  /// {@endtemplate}
  @override
  Type get annotationType => JetLeafApplication;
}

/// {@template enableAutoConfiguration}
/// Core framework annotations for Jet
/// 
/// These annotations provide the foundation for dependency injection,
/// configuration, and application lifecycle management.
///
/// EnableAutoConfiguration annotation for enabling auto-configuration
/// 
/// This annotation enables Jet's auto-configuration mechanism.
/// 
/// Example Usage:
/// ```dart
/// @Configuration()
/// @EnableAutoConfiguration(exclude: [ClassType<DataSourceAutoConfiguration>()])
/// class AppConfig {
///   // Configuration pods
/// }
/// ```
/// 
/// {@endtemplate}
@Target({TargetKind.classType})
class EnableAutoConfiguration extends ReflectableAnnotation {
  /// Auto-configuration classes to exclude
  /// 
  /// ### Example:
  /// ```dart
  /// @Configuration()
  /// @EnableAutoConfiguration(exclude: [DataSourceAutoConfiguration])
  /// class AppConfig {
  ///   // Configuration pods
  /// }
  /// ```
  final List<ClassType> exclude;
  
  /// Auto-configuration class names to exclude
  /// 
  /// ### Example:
  /// ```dart
  /// @Configuration()
  /// @EnableAutoConfiguration(excludeName: ['dataSourceAutoConfiguration'])
  /// class AppConfig {
  ///   // Configuration pods
  /// }
  /// ```
  final List<String> excludeName;
  
  /// {@macro enableAutoConfiguration}
  const EnableAutoConfiguration({
    this.exclude = const [],
    this.excludeName = const [],
  });
  
  @override
  String toString() => 'EnableAutoConfiguration(exclude: $exclude, excludeName: $excludeName)';

  @override
  Type get annotationType => EnableAutoConfiguration;
}