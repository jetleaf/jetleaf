import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:path/path.dart' as p;

import '../cache/indexer/discovered_files.dart';
import '../serialization/jetleaf_json.dart';

/// Result of conservative build-time library reachability analysis.
final class ReachabilityResult {
  final Set<String> reachablePaths;
  final List<String> roots;
  final List<String> unresolvedImports;
  final List<String> prunedPaths;

  const ReachabilityResult({
    required this.reachablePaths,
    required this.roots,
    required this.unresolvedImports,
    required this.prunedPaths,
  });

  Map<String, dynamic> toJson() => {
    'roots': roots,
    'reachable': reachablePaths.toList()..sort(),
    'pruned': prunedPaths,
    'unresolvedImports': unresolvedImports,
    'conservative': true,
  };
}

/// Follows Dart imports from annotated entry files.
///
/// Project `lib/` and `bin/` files remain roots because Jetleaf can discover
/// them from configuration. Dependency declarations are pruned only when
/// their source library is not reachable through the Dart import graph.
final class ReachabilityAnalyzer {
  final Directory projectRoot;
  final DiscoveredFiles files;

  const ReachabilityAnalyzer({required this.projectRoot, required this.files});

  Future<ReachabilityResult> analyze({required bool includeTests}) async {
    final all = files.getAnalyzableDartFiles();
    final byPath = <String, File>{
      for (final file in all) p.normalize(file.absolute.path): file,
    };
    final roots = <File>[];

    for (final file in all) {
      final relative = p.relative(file.path, from: projectRoot.path);
      if (!includeTests && relative.startsWith('test${p.separator}')) {
        continue;
      }
      final content = await file.readAsString();
      if (content.contains('@JetleafEntry') ||
          includeTests && content.contains('@JetleafTest')) {
        roots.add(file);
      }
    }

    // A library package often has no annotated executable. In that case its
    // public project sources remain roots and dependencies are left intact.
    if (roots.isEmpty) {
      return ReachabilityResult(
        reachablePaths: byPath.keys.toSet(),
        roots: const [],
        unresolvedImports: const [],
        prunedPaths: const [],
      );
    }

    final reachable = <String>{};
    final unresolved = <String>[];
    final pending = <File>[...roots];

    while (pending.isNotEmpty) {
      final file = pending.removeLast();
      final key = p.normalize(file.absolute.path);
      if (!reachable.add(key)) continue;

      CompilationUnit unit;
      try {
        unit = parseString(content: await file.readAsString()).unit;
      } catch (_) {
        continue;
      }

      for (final directive in unit.directives) {
        if (directive is! UriBasedDirective) continue;
        final value = directive.uri.stringValue;
        if (value == null || value.startsWith('dart:')) continue;
        final resolved = _resolve(file, value);
        if (resolved == null) {
          unresolved.add('${file.path}: $value');
        } else if (byPath.containsKey(p.normalize(resolved.absolute.path))) {
          pending.add(resolved);
        }
      }
    }

    // Configuration can name classes without importing them. Keep all local
    // project sources as dynamic roots; only dependency metadata is pruned.
    for (final file in all) {
      final relative = p.relative(file.path, from: projectRoot.path);
      if (relative.startsWith('lib${p.separator}') ||
          relative.startsWith('bin${p.separator}') ||
          includeTests && relative.startsWith('test${p.separator}')) {
        reachable.add(p.normalize(file.absolute.path));
      }
    }

    final pruned =
        byPath.keys.where((path) => !reachable.contains(path)).toList()..sort();
    return ReachabilityResult(
      reachablePaths: reachable,
      roots:
          roots.map((e) => p.relative(e.path, from: projectRoot.path)).toList()
            ..sort(),
      unresolvedImports: unresolved,
      prunedPaths: pruned,
    );
  }

  File? _resolve(File source, String uri) {
    if (uri.startsWith('package:')) {
      final parts = uri.substring('package:'.length).split('/');
      if (parts.isEmpty) return null;
      final root = files.packageUris[parts.first];
      if (root == null) return null;
      final rootPath = root.isAbsolute
          ? root.toFilePath()
          : p.join(projectRoot.path, root.path);
      var path = p.join(rootPath, 'lib');
      for (final part in parts.skip(1)) {
        path = p.join(path, part);
      }
      return File(path);
    }
    if (uri.startsWith('dart:')) return null;
    return File(p.normalize(p.join(source.parent.path, uri)));
  }
}

/// Writes the reachability report next to the runtime manifest.
Future<void> writeReachabilityReport(
  Directory projectRoot,
  ReachabilityResult result,
) async {
  final file = File(
    '${projectRoot.path}/.jetleaf/build/reachability_report.json',
  );
  await file.parent.create(recursive: true);
  await file.writeAsString(JetleafJson.encode(result.toJson()), flush: true);
}