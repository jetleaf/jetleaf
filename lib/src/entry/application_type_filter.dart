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
import 'package:jetleaf_core/context.dart';
import 'package:jetleaf_lang/lang.dart';

import '../jet_leaf_application.dart';

/// The globally registered entry-point application type.
/// 
/// This value is assigned when Jetleaf initializes its context and
/// is used by the [ApplicationTypeFilter] to determine which
/// classes are eligible for auto-configuration scanning.
Class<Object>? _entryApplication;

/// {@template application_type_filter}
/// A Jetleaf-specific [TypeFilter] implementation that determines
/// whether a given class qualifies as an **auto-configuration candidate**.
///
/// The [ApplicationTypeFilter] plays a central role in Jetleaf’s
/// component scanning process. It consults the entry-point
/// application (annotated with [`@EnableAutoConfiguration`]) and
/// filters out classes that should **not** be auto-configured
/// according to exclusion rules defined in the annotation.
///
/// ### Responsibilities
/// - Tracks the root Jetleaf application type (set via [setEntryApplication]).
/// - Evaluates `@EnableAutoConfiguration` metadata for exclusions.
/// - Verifies that a class carries the [`@AutoConfiguration`] annotation.
/// - Filters out excluded types and names from the auto-configuration scan.
///
/// ### Example
/// ```dart
/// @EnableAutoConfiguration(exclude: [SomeExcludedConfig])
/// class MyApp {}
///
/// void main() {
///   final appClass = Class.forType(MyApp);
///   final filter = ApplicationTypeFilter();
///
///   filter.setEntryApplication(appClass);
///
///   final candidate = Class.forType(DatabaseConfig);
///   final isIncluded = filter.matches(candidate);
///
///   print(isIncluded ? "Config included" : "Config excluded");
/// }
/// ```
/// {@endtemplate}
final class ApplicationTypeFilter implements TypeFilter {
  /// {@macro annotation_type_filter}
  const ApplicationTypeFilter();

  @override
  void setEntryApplication(Class<Object> entryApplication) {
    _entryApplication = entryApplication;
  }

  @override
  bool matches(Class cls) {
    if(_entryApplication == null) {
      return false;
    }

    if (_entryApplication!.hasDirectAnnotation<EnableAutoConfiguration>()) {
      final config = _entryApplication!.getDirectAnnotation<EnableAutoConfiguration>();
      final excludeClasses = config?.exclude.map((c) => c.toClass()).toList() ?? [];
      final excludeNames = config?.excludeName ?? [];

      return hasAuto(cls) && excludeClasses.none((c) => c.getQualifiedName().equals(cls.getQualifiedName()) || c == cls) && excludeNames.none((n) => n.equalsIgnoreCase(cls.getName()));
    } else if (_entryApplication!.hasDirectAnnotation<JetLeafApplication>()) {
      final jl = _entryApplication!.getAllDirectAnnotations().find((a) => a.getDeclaringClass() == Class<JetLeafApplication>(null, PackageNames.MAIN))?.getDeclaringClass();
      final config = jl?.getDirectAnnotation<EnableAutoConfiguration>();
      final excludeClasses = config?.exclude.map((c) => c.toClass()).toList() ?? [];
      final excludeNames = config?.excludeName ?? [];

      return hasAuto(cls) && excludeClasses.none((c) => c.getQualifiedName().equals(cls.getQualifiedName()) || c == cls) && excludeNames.none((n) => n.equalsIgnoreCase(cls.getName()));
    }

    return false;
  }

  /// {@template application_type_filter.has_auto}
  /// Returns `true` if the provided [cls] is annotated with
  /// [`@AutoConfiguration`] from the Jetleaf core package.
  ///
  /// This is used internally by [matches] to determine whether
  /// a class represents an auto-configuration candidate.
  /// {@endtemplate}
  bool hasAuto(Class cls) => cls.getAllAnnotations().any((a) => a.getDeclaringClass() == Class<AutoConfiguration>(null, PackageNames.CORE));
}