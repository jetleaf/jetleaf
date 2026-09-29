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
  });
}
