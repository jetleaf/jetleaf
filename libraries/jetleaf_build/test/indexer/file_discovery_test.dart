import 'dart:convert';
import 'dart:io';

import 'package:jetleaf_build/src/cache/indexer/file_discovery.dart';
import 'package:test/test.dart';

void main() {
  group('FileDiscovery', () {
    late Directory tempDir;
    late FileDiscovery discovery;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('file_discovery_test_');

      // Create project structure
      final libDir = Directory('${tempDir.path}/lib');
      final testDir = Directory('${tempDir.path}/test');
      final binDir = Directory('${tempDir.path}/bin');
      libDir.createSync();
      testDir.createSync();
      binDir.createSync();

      File('${libDir.path}/main.dart').writeAsStringSync('void main() {}');
      File('${libDir.path}/utils.dart').writeAsStringSync('void util() {}');
      File('${testDir.path}/main_test.dart').writeAsStringSync('void test() {}');
      File('${binDir.path}/app.dart').writeAsStringSync('void app() {}');

      discovery = FileDiscovery(tempDir);
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('discovers all dart files', () async {
      final files = await discovery.discover(
        skipTests: false,
        packagesToExclude: [],
        packagesToScan: [],
        filesToExclude: [],
      );

      expect(files.dartFiles.length, equals(4));
    });

    test('skips tests when requested', () async {
      final files = await discovery.discover(
        skipTests: true,
        packagesToExclude: [],
        packagesToScan: [],
        filesToExclude: [],
      );

      expect(files.dartFiles.length, equals(3));
      expect(
        files.dartFiles.every((f) => !f.path.contains('/test/')),
        isTrue,
      );
    });

    test('returns scannable dart files', () async {
      final files = await discovery.discover(
        skipTests: false,
        packagesToExclude: [],
        packagesToScan: [],
        filesToExclude: [],
      );

      final scannable = files.getScannableDartFiles();
      expect(scannable, isNotEmpty);
    });

    test('discovers configured dependency files with their package owner', () async {
      final dependencyRoot = Directory('${tempDir.path}/packages/dependency')
        ..createSync(recursive: true);
      final dependencyLib = Directory('${dependencyRoot.path}/lib')
        ..createSync();
      final dependencyFile = File('${dependencyLib.path}/service.dart')
        ..writeAsStringSync('class DependencyService {}');
      final packageConfig = Directory('${tempDir.path}/.dart_tool')
        ..createSync();
      File('${packageConfig.path}/package_config.json').writeAsStringSync(
        jsonEncode({
          'configVersion': 2,
          'packages': [
            {
              'name': 'test',
              'rootUri': Uri.directory(tempDir.path).toString(),
              'packageUri': 'lib/',
              'languageVersion': '3.9',
            },
            {
              'name': 'dependency',
              'rootUri': Uri.directory(dependencyRoot.path).toString(),
              'packageUri': 'lib/',
              'languageVersion': '3.9',
            },
          ],
        }),
      );

      final files = await discovery.discover(
        skipTests: true,
        packagesToExclude: [],
        packagesToScan: [],
        filesToExclude: [],
      );

      expect(files.dartFiles.map((file) => file.path), contains(dependencyFile.path));
      expect(files.packageNames[dependencyFile.path], 'dependency');
    });
  });
}
