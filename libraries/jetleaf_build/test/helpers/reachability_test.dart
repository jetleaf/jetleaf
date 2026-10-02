import 'dart:io';

import 'package:jetleaf_build/src/cache/indexer/discovered_files.dart';
import 'package:jetleaf_build/src/helpers/reachability.dart';
import 'package:test/test.dart';

void main() {
  test(
    'keeps annotated roots and prunes unreachable dependency libraries',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'jetleaf_reachability_',
      );
      final app = Directory('${root.path}/lib')..createSync(recursive: true);
      final dependency = Directory('${root.path}/packages/dep/lib')
        ..createSync(recursive: true);
      addTearDown(() => root.delete(recursive: true));

      final main = File('${app.path}/main.dart')
        ..writeAsStringSync('''
import 'package:dep/used.dart';
@JetleafEntry()
void main() => used();
''');
      final used = File('${dependency.path}/used.dart')
        ..writeAsStringSync('void used() {}');
      final unused = File('${dependency.path}/unused.dart')
        ..writeAsStringSync('void unused() {}');

      final files = DiscoveredFiles()
        ..add(main)
        ..add(used, packageName: 'dep')
        ..add(unused, packageName: 'dep')
        ..packageUris['dep'] = Uri.directory('${root.path}/packages/dep');

      final result = await ReachabilityAnalyzer(
        projectRoot: root,
        files: files,
      ).analyze(includeTests: false);

      expect(result.roots, ['lib/main.dart']);
      expect(result.reachablePaths, contains(used.absolute.path));
      expect(result.prunedPaths, contains(unused.absolute.path));
      expect(result.unresolvedImports, isEmpty);

      await writeReachabilityReport(root, result);
      final report = File(
        '${root.path}/.jetleaf/build/reachability_report.json',
      ).readAsStringSync();
      expect(report, startsWith('{\n    "roots":'));
      expect(report, endsWith('\n'));
    },
  );
}
