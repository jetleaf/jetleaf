import 'dart:io';

import 'package:path/path.dart' as p;

import 'jetleaf_paths.dart';
import 'json_document.dart';

/// {@template jetleaf_context_metadata}
/// Static Jetleaf Core facts extracted from application source.
///
/// This metadata is intentionally descriptive. Conditions and profiles remain
/// runtime concerns and are never evaluated or discarded here.
///
/// The model is an intermediate contract between source discovery and
/// `jetleaf_core`. It records declarations that can be known safely before an
/// application context exists, while preserving conditional declarations so
/// runtime configuration can make the final decision.
/// {@endtemplate}
final class JetleafContextMetadata {
  /// Name of the application starter class, when discovered.
  final String? applicationClass;

  /// Project-relative file containing the application starter.
  final String? applicationFile;

  /// Library URI for the application starter file.
  final String? applicationLibrary;

  /// Names of features enabled with `@Enable...` annotations.
  final List<String> enabledFeatures;

  /// Explicit package values found in component-scan annotations.
  final List<String> componentScanPackages;

  /// Classes carrying the `@Configuration` stereotype.
  final List<String> configurationClasses;

  /// Classes carrying the `@AutoConfiguration` stereotype.
  final List<String> autoConfigurations;

  /// Classes carrying the general `@Component` stereotype.
  final List<String> components;

  /// Classes carrying the `@Service` stereotype.
  final List<String> services;

  /// Classes carrying the `@Repository` stereotype.
  final List<String> repositories;

  /// Classes carrying the `@Controller` stereotype.
  final List<String> controllers;

  /// Source locations of methods carrying the `@Pod` annotation.
  final List<String> podMethods;

  /// Source locations of lifecycle and application-event methods.
  final List<String> lifecycleMethods;

  /// Source locations of conditional declarations retained for runtime use.
  final List<String> conditionalDeclarations;

  /// Creates a metadata snapshot.
  ///
  /// Each collection is sorted before it is produced by [fromSource]. Stable
  /// ordering makes generated JSON deterministic and avoids needless rebuilds
  /// when source traversal order changes.
  /// 
  /// {@macro jetleaf_context_metadata}
  const JetleafContextMetadata({
    this.applicationClass,
    this.applicationFile,
    this.applicationLibrary,
    this.enabledFeatures = const [],
    this.componentScanPackages = const [],
    this.configurationClasses = const [],
    this.autoConfigurations = const [],
    this.components = const [],
    this.services = const [],
    this.repositories = const [],
    this.controllers = const [],
    this.podMethods = const [],
    this.lifecycleMethods = const [],
    this.conditionalDeclarations = const [],
  });

  /// Extracts framework metadata from [files] below [root].
  ///
  /// **Parameters:**
  /// - [root]: project root used to create stable relative source locations.
  /// - [files]: Dart source files participating in metadata discovery.
  /// - [applicationFile]: optional application entry path.
  /// - [applicationLibrary]: optional application library URI.
  ///
  /// Annotation extraction is intentionally conservative. It records names
  /// and declaration locations but does not instantiate classes, evaluate
  /// conditions, or remove declarations based on the current environment.
  factory JetleafContextMetadata.fromSource({
    required Directory root,
    required List<File> files,
    String? applicationFile,
    String? applicationLibrary,
  }) {
    final enabled = <String>{};
    final scans = <String>{};
    final configurations = <String>{};
    final autoConfigurations = <String>{};
    final components = <String>{};
    final services = <String>{};
    final repositories = <String>{};
    final controllers = <String>{};
    final pods = <String>{};
    final lifecycle = <String>{};
    final conditionals = <String>{};
    String? applicationClass;

    // Each file contributes independently to the metadata sets. Sets remove
    // duplicate declarations while the final sorting step makes the document
    // deterministic regardless of file-system traversal order.
    for (final file in files) {
      final content = file.readAsStringSync();
      final relative = p.relative(file.path, from: root.path);
      
      for (final match in RegExp(r'@Enable([A-Z]\w*)').allMatches(content)) {
        enabled.add(match.group(1)!);
      }
      
      for (final match in RegExp(r'@ComponentScan\s*\(([^)]*)\)', dotAll: true).allMatches(content)) {
        final value = match.group(1)!;
        for (final package in RegExp(r'''['"]([^'"]+)['"]''').allMatches(value)) {
          scans.add(package.group(1)!);
        }
      }
      
      if (content.contains('@JetleafApplicationStarter')) {
        final starters = _classesForAnnotation(content, 'JetleafApplicationStarter');
        if (starters.isNotEmpty) applicationClass ??= starters.first;
      }
      
      configurations.addAll(_classesForAnnotation(content, 'Configuration'));
      autoConfigurations.addAll(_classesForAnnotation(content, 'AutoConfiguration'));
      components.addAll(_classesForAnnotation(content, 'Component'));
      services.addAll(_classesForAnnotation(content, 'Service'));
      repositories.addAll(_classesForAnnotation(content, 'Repository'));
      controllers.addAll(_classesForAnnotation(content, 'Controller'));
      
      for (final match in RegExp(r'@Pod(?:\s*\([^)]*\))?\s*[\w<>?, ]+\s+(\w+)\s*\(').allMatches(content)) {
        pods.add('$relative:${match.group(1)}');
      }
      
      for (final match in RegExp(r'@(OnApplication\w+|EventListener|PostConstruct|PreDestroy)[^\n]*\s*[\w<>?, ]+\s+(\w+)\s*\(').allMatches(content)) {
        lifecycle.add('$relative:${match.group(2)}');
      }
      
      for (final match in RegExp(r'@(Conditional\w*|Profile|If\w+|Unless\w+)').allMatches(content)) {
        conditionals.add('$relative:${match.group(1)}');
      }
    }

    List<String> sorted(Set<String> values) => values.toList()..sort();
    
    return JetleafContextMetadata(
      applicationClass: applicationClass,
      applicationFile: applicationFile,
      applicationLibrary: applicationLibrary,
      enabledFeatures: sorted(enabled),
      componentScanPackages: sorted(scans),
      configurationClasses: sorted(configurations),
      autoConfigurations: sorted(autoConfigurations),
      components: sorted(components),
      services: sorted(services),
      repositories: sorted(repositories),
      controllers: sorted(controllers),
      podMethods: sorted(pods),
      lifecycleMethods: sorted(lifecycle),
      conditionalDeclarations: sorted(conditionals),
    );
  }

  /// Serializes the metadata using the stable context schema.
  Map<String, Object?> toJson() => {
    'applicationClass': applicationClass,
    'applicationFile': applicationFile,
    'applicationLibrary': applicationLibrary,
    'enabledFeatures': enabledFeatures,
    'componentScanPackages': componentScanPackages,
    'configurationClasses': configurationClasses,
    'autoConfigurations': autoConfigurations,
    'components': components,
    'services': services,
    'repositories': repositories,
    'controllers': controllers,
    'podMethods': podMethods,
    'lifecycleMethods': lifecycleMethods,
    'conditionalDeclarations': conditionalDeclarations,
  };

  /// Writes `context.json` below the canonical project metadata directory.
  Future<void> write(JetleafProjectPaths paths) => JetleafJsonWriter().write(
    paths.projectFile('context.json').path,
    toJson(),
  );
}

/// Finds class declarations carrying [annotation] in source text.
///
/// This helper intentionally returns declaration names only. It is used during
/// the lightweight CLI metadata phase and must not be mistaken for the full
/// analyzer-backed runtime scanner.
Iterable<String> _classesForAnnotation(String content, String annotation) sync* {
  final expression = RegExp(
    '@$annotation(?:\\s*\\([^)]*\\))?(?:\\s*@\\w+(?:\\s*\\([^)]*\\))?)*\\s*(?:abstract\\s+)?class\\s+(\\w+)',
    dotAll: true,
  );
  
  for (final match in expression.allMatches(content)) {
    final name = match.group(1);
    if (name != null) yield name;
  }
}
