import 'dart:io';

import '../manager/cacheable_manager.dart';
import '../scanner/cache_scanners.dart';
import 'declaration_builder.dart';
import 'file_discovery.dart';

/// One-shot build command — scans and writes cache, then exits.
Future<void> runBuild(List<String> args) async {
  final projectRoot = Directory.current;
  final pubspecFile = File('${projectRoot.path}/pubspec.yaml');
  var packageName = 'unknown';

  if (pubspecFile.existsSync()) {
    final content = pubspecFile.readAsStringSync();
    for (final line in content.split('\n')) {
      if (line.trimLeft().startsWith('name:')) {
        packageName = line.split(':').last.trim();
        break;
      }
    }
  }

  final forTests = args.contains('--test');

  print('Scanning $packageName ...');

  // 1. Discovery
  print('  Discovery ...');
  final discovery = FileDiscovery(projectRoot);
  final files = await discovery.discover(
    skipTests: false,
    packagesToExclude: [],
    packagesToScan: [],
    filesToExclude: [],
  );
  print('  Found ${files.dartFiles.length} files');

  // 2. Analysis
  print('  Analysis ...');
  final declarationBuilder = DeclarationBuilder();
  final components = await declarationBuilder.build(
    files: files,
    packageName: packageName,
  );

  // 3. Write cache (via scanner hierarchy)
  print('  Writing cache ...');
  final fingerprint = CacheManager.generateFingerprint(
    skipTests: !forTests,
  );

  final componentsToWrite = forTests
      ? components
      : components.where((c) => !c.getLibrary().getUri().contains('/test/')).toList();

  final cacheWriter = CacheWriter(projectRoot);
  final summary = await cacheWriter.writeWithComponents(
    components: componentsToWrite,
    fingerprint: fingerprint,
    forTests: forTests,
  );

  final libraryCount = componentsToWrite.map((c) => c.getLibrary().getUri()).toSet().length;

  print('Done: ${summary.components.length} components, $libraryCount libraries, '
      '${summary.packages.length} packages, ${summary.assets.length} assets');
  print('Cache: ${forTests ? ".jetleaf/test/" : ".jetleaf/"} '
      '(fingerprint: $fingerprint)');
}
