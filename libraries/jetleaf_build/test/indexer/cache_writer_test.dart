import 'dart:io';

import 'package:jetleaf_build/cache.dart';
import 'package:test/test.dart';

void main() {
  group('CacheWriter', () {
    late Directory tempDir;
    late CacheableWriter writer;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('cache_writer_test_');
      writer = CacheWriter(tempDir);
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('writes cache files', () async {
      await writer.writeWithComponents(
        components: [],
        fingerprint: 'test-fingerprint',
        forTests: false,
      );

      final cacheDir = Directory('${tempDir.path}/.jetleaf');
      expect(cacheDir.existsSync(), isTrue);
    });

    test('reads fingerprint from ScanCacheManager', () async {
      await writer.writeWithComponents(
        components: [],
        fingerprint: 'test-fingerprint',
        forTests: false,
      );

      final result = CacheManager.load(
        tempDir,
        configFingerprint: 'test-fingerprint',
      );
      expect(result, isNotNull);
    });

    test('validates cache with ScanCacheManager', () async {
      await writer.writeWithComponents(
        components: [],
        fingerprint: 'test-fingerprint',
        forTests: false,
      );

      expect(
        CacheManager.isValid(tempDir, configFingerprint: 'test-fingerprint'),
        isTrue,
      );
      expect(
        CacheManager.isValid(tempDir, configFingerprint: 'other'),
        isFalse,
      );
    });
  });
}
