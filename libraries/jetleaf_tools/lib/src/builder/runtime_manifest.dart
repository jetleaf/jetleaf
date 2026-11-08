import 'dart:convert';
import 'dart:io';

import '../cache/jetleaf_paths.dart';
import '../cache/scanner/cache_models.dart';
import '../runtime/declaration/declaration.dart';
import '../serialization/jetleaf_json.dart';

/// Build-time runtime metadata for a production Jetleaf launcher.
///
/// This is deliberately a manifest, not a source-code tree shaker. Jetleaf
/// supports configuration and string-based discovery, so source deletion must
/// wait until all dynamic roots have been proven reachable.
final class RuntimeManifest {
  static const int currentSchemaVersion = 1;

  final String fingerprint;
  final bool forTests;
  final bool treeShakingEnabled;
  final bool treeShakingApplied;
  final DateTime generatedAt;
  final List<String> componentQualifiedNames;
  final List<String> libraryUris;
  final List<String> packageNames;
  final List<String> assetPaths;
  final List<SubClassEntry> subclassIndex;
  final List<AnnotatedMethodEntry> annotatedMethods;
  final List<RuntimeHintEntry> runtimeHints;
  final List<String> prunedPaths;
  final List<String> unresolvedImports;

  const RuntimeManifest({
    required this.fingerprint,
    required this.forTests,
    required this.treeShakingEnabled,
    this.treeShakingApplied = false,
    required this.generatedAt,
    required this.componentQualifiedNames,
    required this.libraryUris,
    required this.packageNames,
    required this.assetPaths,
    required this.subclassIndex,
    required this.annotatedMethods,
    required this.runtimeHints,
    this.prunedPaths = const [],
    this.unresolvedImports = const [],
  });

  /// Creates a manifest from the declarations written to the cache.
  factory RuntimeManifest.fromComponents({
    required String fingerprint,
    required bool forTests,
    required bool treeShakingEnabled,
    bool treeShakingApplied = false,
    required List<ClassDeclaration> components,
    required List<Package> packages,
    required List<Asset> assets,
    required List<SubClassEntry> subclassIndex,
    required List<AnnotatedMethodEntry> annotatedMethods,
    required List<RuntimeHintEntry> runtimeHints,
    List<String> prunedPaths = const [],
    List<String> unresolvedImports = const [],
  }) {
    return RuntimeManifest(
      fingerprint: fingerprint,
      forTests: forTests,
      treeShakingEnabled: treeShakingEnabled,
      treeShakingApplied: treeShakingApplied,
      generatedAt: DateTime.now().toUtc(),
      componentQualifiedNames:
          components.map((e) => e.getQualifiedName()).toList()..sort(),
      libraryUris:
          components.map((e) => e.getLibrary().getUri()).toSet().toList()
            ..sort(),
      packageNames: packages.map((e) => e.getName()).toSet().toList()..sort(),
      assetPaths:
          assets.map((e) => e.getFilePath()).whereType<String>().toList()
            ..sort(),
      subclassIndex: subclassIndex,
      annotatedMethods: annotatedMethods,
      runtimeHints: runtimeHints,
      prunedPaths: prunedPaths,
      unresolvedImports: unresolvedImports,
    );
  }

  Map<String, dynamic> toJson() => {
    'schemaVersion': currentSchemaVersion,
    'fingerprint': fingerprint,
    'forTests': forTests,
    'treeShakingEnabled': treeShakingEnabled,
    'treeShakingApplied': treeShakingApplied,
    'generatedAt': generatedAt.toIso8601String(),
    'counts': {
      'components': componentQualifiedNames.length,
      'libraries': libraryUris.length,
      'packages': packageNames.length,
      'assets': assetPaths.length,
      'runtimeHints': runtimeHints.length,
    },
    'components': componentQualifiedNames,
    'libraries': libraryUris,
    'packages': packageNames,
    'assets': assetPaths,
    'subclasses': subclassIndex.map((e) => e.toJson()).toList(),
    'annotatedMethods': annotatedMethods.map((e) => e.toJson()).toList(),
    'runtimeHints': runtimeHints.map((e) => e.toJson()).toList(),
    'prunedPaths': prunedPaths,
    'unresolvedImports': unresolvedImports,
  };

  /// Parses and validates a manifest from JSON.
  factory RuntimeManifest.fromJson(Map<String, dynamic> json) {
    if (json['schemaVersion'] != currentSchemaVersion) {
      throw const FormatException(
        'Unsupported Jetleaf runtime manifest schema.',
      );
    }
    return RuntimeManifest(
      fingerprint: json['fingerprint'] as String,
      forTests: json['forTests'] as bool? ?? false,
      treeShakingEnabled: json['treeShakingEnabled'] as bool? ?? false,
      treeShakingApplied: json['treeShakingApplied'] as bool? ?? false,
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      componentQualifiedNames: _strings(json['components']),
      libraryUris: _strings(json['libraries']),
      packageNames: _strings(json['packages']),
      assetPaths: _strings(json['assets']),
      subclassIndex: (json['subclasses'] as List<dynamic>? ?? [])
          .map(
            (e) => SubClassEntry.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
      annotatedMethods: (json['annotatedMethods'] as List<dynamic>? ?? [])
          .map(
            (e) => AnnotatedMethodEntry.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
      runtimeHints: (json['runtimeHints'] as List<dynamic>? ?? [])
          .map(
            (e) =>
                RuntimeHintEntry.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
      prunedPaths: _strings(json['prunedPaths']),
      unresolvedImports: _strings(json['unresolvedImports']),
    );
  }

  static List<String> _strings(Object? value) =>
      (value as List<dynamic>? ?? []).whereType<String>().toList();
}

/// Reads and writes the production manifest for a project.
abstract final class RuntimeManifestStore {
  RuntimeManifestStore._();

  /// Writes the manifest and a small generated registry sidecar.
  static Future<void> write(
    Directory projectRoot,
    RuntimeManifest manifest,
  ) async {
    final dir = JetleafPaths.buildDir(projectRoot);
    await dir.create(recursive: true);
    await JetleafPaths.runtimeManifest(projectRoot).parent.create(recursive: true);
    await JetleafPaths.runtimeRegistry(projectRoot).parent.create(recursive: true);
    final json = JetleafJson.encode(manifest.toJson());
    await JetleafPaths.runtimeManifest(
      projectRoot,
    ).writeAsString(json, flush: true);
    await JetleafPaths.runtimeRegistry(
      projectRoot,
    ).writeAsString(_registrySource(manifest), flush: true);
  }

  /// Loads a manifest only when its schema and optional identity match.
  static RuntimeManifest? load(
    Directory projectRoot, {
    String? fingerprint,
    bool? forTests,
  }) {
    final file = JetleafPaths.runtimeManifest(projectRoot);
    if (!file.existsSync()) return null;
    try {
      final manifest = RuntimeManifest.fromJson(
        jsonDecode(file.readAsStringSync()) as Map<String, dynamic>,
      );
      if (fingerprint != null && manifest.fingerprint != fingerprint) {
        return null;
      }
      if (forTests != null && manifest.forTests != forTests) {
        return null;
      }
      return manifest;
    } catch (_) {
      return null;
    }
  }

  static String _registrySource(RuntimeManifest manifest) {
    final buffer = StringBuffer()
      ..writeln('// GENERATED FILE. Do not edit.')
      ..writeln('// Generated by `jl build`; consumed by production launchers.')
      ..writeln(
        "const jetleafRuntimeManifestFingerprint = '${manifest.fingerprint}';",
      )
      ..writeln(
        'const jetleafRuntimeTreeShakingApplied = ${manifest.treeShakingApplied};',
      )
      ..writeln(
        'const jetleafRuntimePrunedPathCount = ${manifest.prunedPaths.length};',
      )
      ..writeln(
        'const jetleafRuntimeComponentCount = ${manifest.componentQualifiedNames.length};',
      )
      ..writeln(
        'const jetleafRuntimeLibraryCount = ${manifest.libraryUris.length};',
      )
      ..writeln(
        'const jetleafRuntimeComponents = ${_dartStrings(manifest.componentQualifiedNames)};',
      )
      ..writeln(
        'const jetleafRuntimeLibraries = ${_dartStrings(manifest.libraryUris)};',
      )
      ..writeln(
        'const jetleafRuntimePackages = ${_dartStrings(manifest.packageNames)};',
      )
      ..writeln(
        'const jetleafRuntimeHints = ${_dartStrings(manifest.runtimeHints.map((e) => e.qualifiedName).toList())};',
      );
    return buffer.toString();
  }

  /// Encodes strings as a readable Dart list for generated registry source.
  ///
  /// Registry files are Dart source rather than persisted JSON. The previous
  /// inline join made large registries unreadable and caused the generated
  /// file to differ from the established multiline registry format. JSON
  /// string encoding is still used for each value so quotes, backslashes,
  /// newlines, and dollar signs remain safe in Dart source.
  static String _dartStrings(List<String> values) {
    if (values.isEmpty) return '[]';
    final encoded = const JsonEncoder.withIndent('  ').convert(values);

    // JSON escapes quotes, backslashes, and control characters, but it does
    // not escape `$`. A registry is Dart source, where an unescaped dollar
    // starts interpolation inside a double-quoted string.
    return encoded.replaceAll(r'$', r'\$');
  }
}