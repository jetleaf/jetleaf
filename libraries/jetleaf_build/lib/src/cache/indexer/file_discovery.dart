import 'dart:io';

import 'package:path/path.dart' as p;

import '../../file_utility/file_utility.dart';
import '../../runtime/scanner/runtime_scanner_configuration.dart';
import 'discovered_files.dart';

/// Adapts Jetleaf's canonical runtime file discovery to the cache indexer.
///
/// The runtime scanners use [FileUtility] to discover the application and all
/// resolved dependency packages. Cache warming must consume that same result;
/// maintaining a second package walker causes the warm cache and the runtime
/// scanner to observe different source trees.
final class FileDiscovery {
  /// Project directory used as the root for runtime discovery.
  final Directory projectRoot;

  /// Creates a discovery adapter for [projectRoot].
  const FileDiscovery(this.projectRoot);

  /// Finds project and dependency Dart files using the runtime scanner rules.
  ///
  /// The returned model remains compatible with the analyzer cache pipeline,
  /// while package ownership is retained for correct package URI generation.
  Future<DiscoveredFiles> discover({
    required bool skipTests,
    required List<String> packagesToExclude,
    required List<String> packagesToScan,
    required List<File> filesToExclude,
  }) async {
    final files = DiscoveredFiles();
    final utility = FileUtility(
      (_, _) {},
      (_, _) {},
      (_, _) {},
      RuntimeScannerConfiguration(
        skipTests: skipTests,
        packagesToScan: packagesToScan,
        packagesToExclude: packagesToExclude,
        filesToExclude: filesToExclude,
      ),
      (_, _) => true,
    );

    final located = await utility.findDartFiles(projectRoot);
    final discovered = <String, File>{};
    for (final file in [
      ...located.getScannableDartFiles(),
      ...located.getAnalyzeableDartFiles(),
    ]) {
      discovered[p.normalize(file.absolute.path)] = file;
    }

    for (final file in discovered.values) {
      final normalized = p.normalize(file.absolute.path);
      if (normalized.contains('${p.separator}.dart_tool${p.separator}') ||
          normalized.contains('${p.separator}build${p.separator}')) {
        continue;
      }

      files.add(file, packageName: _packageNameFor(file, utility));
    }

    for (final entry in utility.packageConfig) {
      files.packageUris[entry.name] = entry.rootUri;
    }

    return files;
  }

  /// Resolves the owning package using the longest matching package root.
  ///
  /// Longest-match ordering matters for nested package roots and ensures a
  /// dependency is not accidentally attributed to its containing project.
  String? _packageNameFor(File file, FileUtility utility) {
    final path = p.normalize(file.absolute.path);
    final candidates = utility.packageConfig
        .where((entry) => p.isWithin(entry.absoluteRootPath, path))
        .toList()
      ..sort(
        (left, right) => right.absoluteRootPath.length.compareTo(
          left.absoluteRootPath.length,
        ),
      );
    return candidates.firstOrNull?.name;
  }
}
