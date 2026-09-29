import 'dart:convert';
import 'dart:io';

import 'discovered_files.dart';

/// Discovers ALL Dart files in the project.
///
/// Scans lib/, bin/, test/, dependencies, and dart SDK.
final class FileDiscovery {
  final Directory projectRoot;

  /// Creates a [FileDiscovery] for the given project root.
  const FileDiscovery(this.projectRoot);

  /// Finds ALL Dart files in the project.
  Future<DiscoveredFiles> discover({
    required bool skipTests,
    required List<String> packagesToExclude,
    required List<String> packagesToScan,
    required List<File> filesToExclude,
  }) async {
    final files = DiscoveredFiles();

    // 1. Local project files (lib/, bin/, test/)
    await _discoverLocalFiles(files, skipTests);

    // 2. Dependency files (from package_config.json)
    await _discoverDependencyFiles(
      files,
      packagesToExclude,
      packagesToScan,
    );

    // 3. Remove excluded files
    for (final excluded in filesToExclude) {
      files.dartFiles.removeWhere((f) => f.path == excluded.path);
    }

    return files;
  }

  /// Discovers local project files.
  Future<void> _discoverLocalFiles(
    DiscoveredFiles files,
    bool skipTests,
  ) async {
    // Scan lib/
    final libDir = Directory('${projectRoot.path}/lib');
    if (libDir.existsSync()) {
      await _scanDirectory(libDir, files);
    }

    // Scan bin/
    final binDir = Directory('${projectRoot.path}/bin');
    if (binDir.existsSync()) {
      await _scanDirectory(binDir, files);
    }

    // Scan test/ (if not skipped)
    if (!skipTests) {
      final testDir = Directory('${projectRoot.path}/test');
      if (testDir.existsSync()) {
        await _scanDirectory(testDir, files);
      }
    }
  }

  /// Discovers dependency files from package_config.json.
  Future<void> _discoverDependencyFiles(
    DiscoveredFiles files,
    List<String> packagesToExclude,
    List<String> packagesToScan,
  ) async {
    final configFile =
        File('${projectRoot.path}/.dart_tool/package_config.json');
    if (!configFile.existsSync()) return;

    try {
      final config = jsonDecode(await configFile.readAsString());
      if (config case {'packages': final List packages}) {
        for (final pkg in packages) {
          if (pkg is! Map<String, dynamic>) continue;

          final name = pkg['name'] as String?;
          final rootUri = pkg['rootUri'] as String?;
          if (name == null || rootUri == null) continue;

          // Check exclusions
          if (packagesToExclude.contains(name)) continue;

          // Check inclusions (if specified)
          if (packagesToScan.isNotEmpty && !packagesToScan.contains(name)) {
            continue;
          }

          // Resolve root URI
          final uri = Uri.parse(rootUri);
          final pkgDir =
              uri.isAbsolute ? Directory.fromUri(uri) : Directory(rootUri);
          if (!pkgDir.existsSync()) continue;

          // Scan package lib/ directory
          final libDir = Directory('${pkgDir.path}/lib');
          if (libDir.existsSync()) {
            await _scanDirectory(libDir, files, packageName: name);
          }

          // Store package URI
          files.packageUris[name] = uri;
        }
      }
    } catch (_) {
      // Ignore malformed package_config.json
    }
  }

  /// Recursively scans a directory for Dart files.
  Future<void> _scanDirectory(
    Directory dir,
    DiscoveredFiles files, {
    String? packageName,
  }) async {
    try {
      for (final entity in dir.listSync(recursive: true)) {
        if (entity is File && entity.path.endsWith('.dart')) {
          files.add(entity, packageName: packageName);
        }
      }
    } catch (_) {
      // Ignore permission errors or inaccessible directories
    }
  }
}