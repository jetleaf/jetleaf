import 'package:jetleaf_core/lang.dart';

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
/// and dynamic type casts required for reflection-free execution. [AotSubRegistrarWriter] ensures
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
///     // Write standardized header linked to root registry.g.dart
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

  /// Extracts the package name from a package URI
  /// (`package:pkg/lib/...` → `pkg`), or `null` for non-package URIs.
  static String? packageNameFromUri(String uri) {
    if (!uri.startsWith('package:')) return null;
    final rest = uri.substring('package:'.length);
    final slash = rest.indexOf('/');
    if (slash <= 0) return null;
    return rest.substring(0, slash);
  }

  /// Computes the set of package names declared as scan roots via
  /// `@ComponentScan(basePackages: [...])` or `(basePackageClasses: [...])`
  /// among [components].
  ///
  /// Returns `null` when there is no `@ComponentScan` or it declares no usable
  /// roots — in which case callers must not restrict registration.
  ///
  /// `basePackageClasses` are resolved against [components] by simple class
  /// name; an anchor whose package cannot be resolved is ignored.
  Set<String>? resolveComponentScanRoots(List<ClassDeclaration> components) {
    const scanName = 'ComponentScan';
    const anchorPattern = r'ClassType<\s*([A-Za-z_$][A-Za-z0-9_$]*)\s*>';
    final roots = <String>{};

    for (final component in components) {
      for (final annotation in component.getAnnotations()) {
        final name = annotation.getName();
        if (name != scanName && !name.endsWith('.$scanName')) continue;

        final values = annotation.getUserProvidedValues();

        final basePackages = values['basePackages'];
        if (basePackages is List) {
          for (final entry in basePackages) {
            final s = entry?.toString().trim() ?? '';
            if (s.isNotEmpty) roots.add(s);
          }
        }

        final basePackageClasses = values['basePackageClasses'];
        if (basePackageClasses is List) {
          for (final entry in basePackageClasses) {
            final source = entry?.toString() ?? '';
            final match = RegExp(anchorPattern).firstMatch(source);
            if (match == null) continue;
            final anchor = components
                .where((c) => c.getName() == match.group(1))
                .firstOrNull;
            if (anchor == null) continue;
            final pkg = packageNameFromUri(anchor.getLibrary().getUri());
            if (pkg != null) roots.add(pkg);
          }
        }
      }
    }

    if (roots.isEmpty) return null;

    // A scan filter whose declared roots match no known component can only
    // suppress the pods of the project being compiled — the closed-world AOT
    // registrar is the sole authority for what ships in the binary, and a
    // dangling @ComponentScan (e.g. pointing at a package that does not
    // exist) must not silently drop every pod. Only keep the restriction
    // when at least one declared component falls inside the declared roots.
    final matched = components.where(
      (c) => isComponentScanned(c, roots),
    );
    return matched.isEmpty ? null : roots;
  }

  /// Whether [component] is inside the declared [scanRoots].
  /// [scanRoots] must be non-null (use [resolveComponentScanRoots]).
  bool isComponentScanned(ClassDeclaration component, Set<String> scanRoots) {
    final pkg = packageNameFromUri(component.getLibrary().getUri());
    if (pkg == null) return true;
    return scanRoots.contains(pkg);
  }

  /// Escapes [value] for embedding inside a **single-quoted** Dart string
  /// literal in generated code.
  ///
  /// Handles the three characters that terminate or corrupt a single-quoted
  /// literal: `\`, `'`, and `$` (dollar starts interpolation — the source of
  /// the `$$JLInterfaced$$…` codegen breakage where proxy class names were
  /// emitted raw).
  ///
  /// Returns a *fragment* (no surrounding quotes) suitable for direct
  /// interpolation into `'…'` sections of emitted source.
  String escapeDartStringLiteral(String value) {
    return value
        .replaceAll('\\', '\\\\')
        .replaceAll("'", "\\'")
        .replaceAll('\$', r'\$');
  }

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

  /// Renders a generic collection type signature (such as `'List<CascadeType>'`
  /// or `'Map<String, User>'`) for [link] when it represents a parameterized
  /// `List`, `Set`, `Iterable`, or `Map` whose type arguments are concrete types
  /// (not unresolved class type parameters in [typeParamNames]).
  ///
  /// Returns `null` if [link] is not a parameterized collection or if its type
  /// arguments reference uninstantiated type parameters.
  String? renderCollectionTypeSignature(
    LinkDeclaration link, [
    Set<String> typeParamNames = const {},
  ]) {
    final name = link.getName();
    if (name != 'List' && name != 'Set' && name != 'Iterable' && name != 'Map') {
      return null;
    }
    final args = link.getTypeArguments();
    if (args.isEmpty) return null;
    if (_containsUnresolvedTypeParam(link, typeParamNames)) return null;
    final rendered = _formatLinkSignature(link);
    if (rendered == '$name<dynamic>') return null;
    return rendered;
  }

  bool _containsUnresolvedTypeParam(LinkDeclaration link, Set<String> typeParamNames) {
    final name = link.getName();
    if (typeParamNames.contains(name)) return true;
    for (final arg in link.getTypeArguments()) {
      if (_containsUnresolvedTypeParam(arg, typeParamNames)) return true;
    }
    return false;
  }

  String _formatLinkSignature(LinkDeclaration link) {
    final name = link.getName();
    final args = link.getTypeArguments();
    if (args.isEmpty) return name;
    return '$name<${args.map(_formatLinkSignature).join(', ')}>';
  }

  /// Writes the standard generated file header including the Jetleaf ASCII banner,
  /// licensing terms, documentation URLs, and global lint suppressions.
  ///
  /// When [partOf] is supplied, an additional `part of '<partOf>';` directive is appended.
  void writeGeneratedHeader(StringBuffer buffer, String targetDescription, {
    String? partOf,
  }) {
    final year = DateTime.now().year;
    buffer.writeln('''// ignore_for_file: type=lint, unused_import, unused_local_variable, unnecessary_cast, avoid_redundant_argument_values, depend_on_referenced_packages, implementation_imports, invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member, invalid_use_of_internal_member, deprecated_member_use, unnecessary_non_null_assertion, duplicate_import, prefer_final_fields, library_prefixes, unnecessary_underscores, unnecessary_import, lines_longer_than_80_chars, avoid_dynamic_calls, inference_failure_on_function_invocation, unnecessary_nullable_for_final_variable_declarations, non_constant_identifier_names, avoid_shadowing_type_parameters
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

  /// Writes a standardized `part of '../registry.g.dart';` header for a package-nested
  /// sub-registry file located in `lib/_jetleaf/<main|test>/<package>/`.
  void writeNestedPartHeader(StringBuffer buffer, [String description = 'AOT Package Sub-Registry']) {
    writeGeneratedHeader(
      buffer,
      description,
      partOf: '../${Constant.REGISTRY_FILE_NAME}',
    );
  }

  /// Writes a standardized `part of 'registry.g.dart';` header for a file located
  /// directly in `lib/_jetleaf/<main|test>/`.
  void writeRootPartHeader(StringBuffer buffer, [String description = 'AOT Root Registry']) {
    writeGeneratedHeader(
      buffer,
      description,
      partOf: Constant.REGISTRY_FILE_NAME,
    );
  }
}