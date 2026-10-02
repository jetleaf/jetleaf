import 'dart:io';

import 'package:jetleaf_build/cache.dart';
import 'package:test/test.dart';

void main() {
  group('Asset scanning via CacheWriter', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('asset_scan_test_');
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('excludes Dart files from assets', () async {
      final libDir = Directory('${tempDir.path}/lib');
      libDir.createSync(recursive: true);
      File('${libDir.path}/main.dart').writeAsStringSync('void main() {}');
      File('${libDir.path}/config.json').writeAsStringSync('{}');

      final writer = CacheWriter(tempDir);
      final summary = await writer.writeWithComponents(
        components: [],
        fingerprint: 'test-fingerprint',
        forTests: false,
      );

      expect(summary.assets.every((a) => !a.getFilePath().endsWith('.dart')), isTrue);
    });

    test('scans lib/ for non-Dart asset files', () async {
      final libDir = Directory('${tempDir.path}/lib');
      libDir.createSync(recursive: true);
      File('${libDir.path}/config.json').writeAsStringSync('{}');
      File('${libDir.path}/data.yaml').writeAsStringSync('key: value');

      final writer = CacheWriter(tempDir);
      final summary = await writer.writeWithComponents(
        components: [],
        fingerprint: 'test-fingerprint',
        forTests: false,
      );

      expect(summary.assets.length, greaterThanOrEqualTo(2));
    });

    test('scans bin/ for non-Dart asset files', () async {
      final binDir = Directory('${tempDir.path}/bin');
      binDir.createSync(recursive: true);
      File('${binDir.path}/config.json').writeAsStringSync('{}');

      final writer = CacheWriter(tempDir);
      final summary = await writer.writeWithComponents(
        components: [],
        fingerprint: 'test-fingerprint',
        forTests: false,
      );

      expect(summary.assets.any((a) => a.getFilePath().contains('/bin/')), isTrue);
    });
  });
}
