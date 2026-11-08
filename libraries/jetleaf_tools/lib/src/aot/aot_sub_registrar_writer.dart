import '../utils/constant.dart';

/// {@template aot_sub_registrar_writer}
/// 🛠️ **Base AOT Registry Code Generator**
///
/// An abstract foundational writer that provides shared code generation primitives,
/// identifier validation, naming sanitization, and standardized header generation
/// for all Ahead-Of-Time (AOT) sub-registry generators in the Jetleaf build pipeline.
///
/// Subclasses specialize in generating distinct segments of the AOT runtime reflection
/// infrastructure:
/// - Constructors ([AotConstructorRegistryWriter])
/// - Methods ([AotMethodRegistryWriter])
/// - Fields ([AotFieldRegistryWriter])
/// - Types ([AotTypeRegistryWriter])
/// - Pod Definitions ([AotPodRegistryWriter])
/// - Annotations ([AotAnnotationRegistryWriter])
///
/// ## 🛡️ Lint Suppression Architecture
///
/// Generated AOT artifacts contain complex synthetic identifiers, deep generic instantiations,
/// and dynamic type casts required for mirrorless execution. [AotSubRegistrarWriter] ensures
/// every generated file begins with comprehensive lint suppression directives (`// ignore_for_file: ...`),
/// preventing compiler warnings or IDE errors from surfacing in user workspaces regardless of
/// the user's local `analysis_options.yaml` configuration:
///
/// ```dart
/// // ignore_for_file: type=lint, unused_import, unused_local_variable, unnecessary_cast, ...
/// ```
///
/// ## 🎯 Usage Example
///
/// ```dart
/// class MyCustomAotWriter extends AotSubRegistrarWriter {
///   const MyCustomAotWriter();
///
///   void generate(StringBuffer buffer) {
///     // Write standardized header linked to root aot_registry.g.dart
///     writeNestedPartHeader(buffer, 'Custom Sub-Registry');
///
///     final safeName = sanitizePackageIdentifier('my-package.core');
///     buffer.writeln('void _registerCustom_$safeName() { ... }');
///   }
/// }
/// ```
/// {@endtemplate}
abstract class AotSubRegistrarWriter {
  /// {@macro aot_sub_registrar_writer}
  const AotSubRegistrarWriter();

  /// Members on `Object` that should not be registered as custom field or method accessors.
  ///
  /// Prevents shadowing or generating redundant reflective dispatchers for universal
  /// Dart root members: `toString`, `hashCode`, `noSuchMethod`, `runtimeType`, and `==`.
  static const Set<String> skippedMemberNames = {
    'toString',
    'hashCode',
    'noSuchMethod',
    'runtimeType',
    '==',
  };

  /// Validates whether [name] is a syntactically legal Dart identifier.
  ///
  /// Rejects operator names (`[]`, `+`, `*`), symbols, whitespace, and private/empty tokens
  /// that cannot be directly referenced as symbol dispatch targets.
  ///
  /// Returns `true` if [name] conforms to `^[a-zA-Z_$][a-zA-Z0-9_$]*$`.
  bool isValidDartIdentifier(String name) {
    return RegExp(r'^[a-zA-Z_$][a-zA-Z0-9_$]*$').hasMatch(name);
  }

  /// Sanitizes an arbitrary Dart package name into a safe, valid Dart identifier suffix.
  ///
  /// Converts hyphens, dots, and non-alphanumeric characters into underscores:
  /// ```dart
  /// sanitizePackageIdentifier('jetleaf-core.v2'); // 'jetleaf_core_v2'
  /// ```
  String sanitizePackageIdentifier(String packageName) {
    return packageName.replaceAll(RegExp(r'[^a-zA-Z0-9_$]'), '_');
  }

  /// Converts a `PascalCase` class or type identifier to `camelCase`.
  ///
  /// Used for generating standard default pod names and method invoker identifiers:
  /// ```dart
  /// camelCase('UserService'); // 'userService'
  /// camelCase('HTTPClient');  // 'hTTPClient'
  /// ```
  String camelCase(String input) {
    if (input.isEmpty) return input;
    return input[0].toLowerCase() + input.substring(1);
  }

  /// Determines whether [typeName] represents a standard Dart primitive or collection.
  ///
  /// Primitives are treated as scalar values during code generation and do not participate
  /// in custom IoC pod dependency resolution.
  bool isPrimitiveType(String typeName) {
    return const {
      'int',
      'double',
      'num',
      'String',
      'bool',
      'List',
      'Map',
      'Set',
      'Iterable',
      'dynamic',
      'Object',
      'void',
      'Function',
    }.contains(typeName);
  }

  /// Writes the standard generated file header including the Jetleaf ASCII banner,
  /// licensing terms, documentation URLs, and global lint suppressions.
  ///
  /// When [partOf] is supplied, an additional `part of '<partOf>';` directive is appended.
  void writeGeneratedHeader(StringBuffer buffer, String targetDescription, {
    String? partOf,
  }) {
    final year = DateTime.now().year;
    buffer.writeln('''// ignore_for_file: type=lint, unused_import, unused_local_variable, unnecessary_cast, avoid_redundant_argument_values, depend_on_referenced_packages, implementation_imports, invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member, deprecated_member_use, unnecessary_non_null_assertion, duplicate_import, prefer_final_fields, library_prefixes, unnecessary_underscores, unnecessary_import, lines_longer_than_80_chars, avoid_dynamic_calls, inference_failure_on_function_invocation, unnecessary_nullable_for_final_variable_declarations, non_constant_identifier_names, avoid_shadowing_type_parameters
//
${Constant.BANNER_ART.trim()}
//
// AUTO-GENERATED: $targetDescription
// Do not edit manually.
//
// ---------------------------------------------------------------------------
// Jetleaf Framework
//
// Copyright (c) $year Hapnium & Jetleaf Contributors
//
// Licensed under the MIT License. See LICENSE file in the root of the jetleaf project
//
// This file is part of the Jetleaf Framework, a modern, modular backend
// framework for Dart.
//
// For documentation and usage, visit:
// https://jetleaf.hapnium.com/docs
// ---------------------------------------------------------------------------''');
    if (partOf != null) {
      buffer.writeln();
      buffer.writeln("part of '$partOf';");
    }
    buffer.writeln();
  }

  /// Writes a standardized `part of '../aot_registry.g.dart';` header for a package-nested
  /// sub-registry file located in `lib/_jetleaf/<package>/`.
  void writeNestedPartHeader(StringBuffer buffer, [String description = 'AOT Package Sub-Registry']) {
    writeGeneratedHeader(
      buffer,
      description,
      partOf: '../${Constant.AOT_REGISTRY_FILE_NAME}',
    );
  }

  /// Writes a standardized `part of 'aot_registry.g.dart';` header for a root-level
  /// sub-registry file located directly in `lib/_jetleaf/`.
  void writeRootPartHeader(StringBuffer buffer, [String description = 'AOT Root Registry']) {
    writeGeneratedHeader(
      buffer,
      description,
      partOf: Constant.AOT_REGISTRY_FILE_NAME,
    );
  }
}
