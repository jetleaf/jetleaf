import 'dart:io';

import '../cache/indexer/declaration_builder.dart';
import '../cache/indexer/file_discovery.dart';
import '../cache/jetleaf_paths.dart';
import '../cache/manager/cacheable_manager.dart';
import '../cache/scanner/cache_scanners.dart';
import '../helpers/manifest.dart';
import '../helpers/reachability.dart';
import '../utils/constant.dart';
import 'jl_command.dart';

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
              (component) => _isReachableComponent(component, reachability),
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

bool _isReachableComponent(dynamic component, ReachabilityResult reachability) {
  final uri = component.getLibrary().getUri() as String;
  if (!uri.startsWith('file:')) return true;
  try {
    return reachability.reachablePaths.contains(
      File.fromUri(Uri.parse(uri)).absolute.path,
    );
  } catch (_) {
    return true;
  }
}

/// Builds declaration caches and the Jetleaf production runtime manifest.
final class BuildCommand extends JlCommand {
  const BuildCommand();

  @override
  String get name => 'build';

  @override
  String get description =>
      'Build Jetleaf caches and the production runtime manifest.';

  @override
  String get usage => '''
Usage: jl build [options]

Builds declaration metadata, indexes, runtime hints, and a production
runtime manifest under .jetleaf/build/.

Options:
  --root <dir>          Project root (default: current directory).
  --test                Include test declarations in the manifest.
  --skip-tree-shaking   Generate a complete manifest without optimization.
  -h, --help            Show this help.
''';

  @override
  Future<int> run(List<String> args) async {
    if (args.contains('-h') || args.contains('--help')) {
      print(usage);
      return 0;
    }
    final root = _flagValue(args, '--root') ?? Directory.current.path;
    final directory = Directory(root);
    if (!directory.existsSync()) {
      stderr.writeln('Error: root not found: $root');
      return 1;
    }
    try {
      return await runBuild(args, root: directory);
    } catch (error, stack) {
      stderr.writeln('Error: Jetleaf build failed: $error');
      stderr.writeln(stack);
      return 1;
    }
  }

  String? _flagValue(List<String> args, String flag) {
    for (var i = 0; i < args.length; i++) {
      if (args[i] == flag && i + 1 < args.length) {
        return args[i + 1];
      }
      if (args[i].startsWith('$flag=')) {
        return args[i].substring(flag.length + 1);
      }
    }
    return null;
  }
}