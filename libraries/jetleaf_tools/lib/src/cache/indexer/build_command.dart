import 'dart:io';

import 'package:path/path.dart' as p;

import '../manager/cacheable_manager.dart';
import '../jetleaf_paths.dart';
import '../scanner/cache_scanners.dart';
import '../../utils/constant.dart';
import '../../builder/reachability.dart';
import '../../builder/runtime_manifest.dart';
import '../../aot/aot_registrar_writer.dart';
import 'declaration_builder.dart';
import 'discovered_files.dart';
import 'file_discovery.dart';

/// One-shot build command — scans and writes cache, then exits.
Future<int> runBuild(List<String> args, {Directory? root}) async {
  final projectRoot = root ?? Directory.current;
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
  final treeShaking = !args.contains('--skip-tree-shaking');

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

  final reachability = treeShaking
      ? await ReachabilityAnalyzer(
          projectRoot: projectRoot,
          files: files,
        ).analyze(includeTests: forTests)
      : null;
  if (reachability != null) {
    await writeReachabilityReport(projectRoot, reachability);
  }

  // 3. Write cache (via scanner hierarchy)
  print('  Writing cache ...');
  final fingerprint = CacheManager.generateFingerprint(skipTests: !forTests);

  final componentsToWrite = forTests
      ? components
      : components
            .where((c) => !c.getLibrary().getUri().contains('/test/'))
            .toList();
  final filteredComponents =
      reachability == null || reachability.unresolvedImports.isNotEmpty
      ? componentsToWrite
      : componentsToWrite
            .where(
              (component) => _isReachableComponent(
                component,
                reachability,
                files,
                projectRoot,
              ),
            )
            .toList();

  final cacheWriter = CacheWriter(projectRoot);
  final summary = await cacheWriter.writeWithComponents(
    components: filteredComponents,
    fingerprint: fingerprint,
    forTests: forTests,
  );

  final manifest = RuntimeManifest.fromComponents(
    fingerprint: fingerprint,
    forTests: forTests,
    treeShakingEnabled: treeShaking,
    treeShakingApplied:
        reachability != null &&
        reachability.unresolvedImports.isEmpty &&
        filteredComponents.length != componentsToWrite.length,
    components: filteredComponents,
    packages: summary.packages,
    assets: summary.assets,
    subclassIndex: summary.subClassEntries,
    annotatedMethods: summary.annotatedMethodEntries,
    runtimeHints: summary.runtimeHintEntries,
    prunedPaths: reachability?.prunedPaths ?? const [],
    unresolvedImports: reachability?.unresolvedImports ?? const [],
  );
  await RuntimeManifestStore.write(projectRoot, manifest);

  // 5. Write compile-time AOT Pod Registrar (Pure Dart AOT)
  final aotWriter = AotRegistrarWriter(
    projectRoot: projectRoot,
    packageName: packageName,
  );
  await aotWriter.writeAotRegistrar(
    components: filteredComponents,
    forTests: forTests,
  );

  final libraryCount = filteredComponents
      .map((c) => c.getLibrary().getUri())
      .toSet()
      .length;

  print(
    'Done: ${summary.components.length} components, $libraryCount libraries, '
    '${summary.packages.length} packages, ${summary.assets.length} assets',
  );
  print(
    'Cache: ${forTests ? "${Constant.WORKSPACE_DIR_NAME}/${Constant.TEST_DIR_NAME}/" : "${Constant.WORKSPACE_DIR_NAME}/"} '
    '(fingerprint: $fingerprint)',
  );
  print('Manifest: ${JetleafPaths.runtimeManifest(projectRoot).path}');
  return 0;
}

bool _isReachableComponent(
  dynamic component,
  ReachabilityResult reachability,
  DiscoveredFiles files,
  Directory projectRoot,
) {
  final uri = component.getLibrary().getUri() as String;
  if (uri.startsWith('file:')) {
    try {
      return reachability.reachablePaths.contains(
        p.normalize(File.fromUri(Uri.parse(uri)).absolute.path),
      );
    } catch (_) {
      return true;
    }
  }
  if (uri.startsWith('package:')) {
    final parts = uri.substring('package:'.length).split('/');
    if (parts.isEmpty) return true;
    final root = files.packageUris[parts.first];
    if (root == null) return true;
    final rootPath = root.isAbsolute
        ? root.toFilePath()
        : p.join(projectRoot.path, root.path);
    var filePath = p.join(rootPath, 'lib');
    for (final part in parts.skip(1)) {
      filePath = p.join(filePath, part);
    }
    return reachability.reachablePaths.contains(
      p.normalize(File(filePath).absolute.path),
    );
  }
  return true;
}