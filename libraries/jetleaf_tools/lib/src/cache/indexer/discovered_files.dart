import 'dart:io';

import '../../utils/constant.dart';

/// Result of file discovery — all Dart files found in the project.
final class DiscoveredFiles {
  /// All Dart files found.
  final Set<File> dartFiles = {};

  /// Mapping of package name to root URI.
  final Map<String, Uri> packageUris = {};

  /// Mapping of file path to package name.
  final Map<String, String> packageNames = {};

  /// Gets files that can be scanned (not excluded).
  Set<File> getScannableDartFiles() {
    return dartFiles
        .where((f) => !f.path.contains('/.dart_tool/'))
        .where((f) => !f.path.contains('/build/'))
        .where((f) => !f.path.contains('/${Constant.JETLEAF_GENERATED_DIR_NAME}/'))
        .where((f) => !f.path.endsWith('.g.dart'))
        .toSet();
  }

  /// Gets files that can be analyzed (for analyzer-based scanning).
  Set<File> getAnalyzableDartFiles() {
    return dartFiles
        .where((f) => f.path.endsWith('.dart'))
        .where((f) => !f.path.contains('/.dart_tool/'))
        .where((f) => !f.path.contains('/build/'))
        .where((f) => !f.path.contains('/${Constant.JETLEAF_GENERATED_DIR_NAME}/'))
        .where((f) => !f.path.endsWith('.g.dart'))
        .toSet();
  }

  /// Adds a file to the discovery result.
  void add(File file, {String? packageName}) {
    dartFiles.add(file);
    if (packageName != null) {
      packageNames[file.path] = packageName;
    }
  }

  /// Merges another [DiscoveredFiles] into this one.
  void merge(DiscoveredFiles other) {
    dartFiles.addAll(other.dartFiles);
    packageUris.addAll(other.packageUris);
    packageNames.addAll(other.packageNames);
  }

  /// Number of discovered files.
  int get length => dartFiles.length;

  /// Whether no files were discovered.
  bool get isEmpty => dartFiles.isEmpty;

  /// Whether files were discovered.
  bool get isNotEmpty => dartFiles.isNotEmpty;
}