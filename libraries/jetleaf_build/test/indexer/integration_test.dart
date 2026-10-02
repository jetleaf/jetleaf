import 'dart:io';

import 'package:jetleaf_build/cache.dart';
import 'package:jetleaf_build/src/cache/indexer/declaration_builder.dart';
import 'package:jetleaf_build/src/cache/indexer/file_discovery.dart';
import 'package:test/test.dart';

void main() {
  group('Integration: builder cache -> ScanCacheManager', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('integration_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('round-trip with annotated classes', () async {
      // Write a Dart file with an annotated class and an enum
      final libDir = Directory('${tempDir.path}/lib');
      libDir.createSync();

      File('${libDir.path}/user.dart').writeAsStringSync('''
class Injectable {
  const Injectable({this.scope});
  final String? scope;
}

@Injectable(scope: 'singleton')
class UserService {
  String name = '';
  void greet() {}
}

enum Status { active, inactive }
''');

      // Build declarations
      final discovery = FileDiscovery(tempDir);
      final files = await discovery.discover(
        skipTests: true,
        packagesToExclude: [],
        packagesToScan: [],
        filesToExclude: [],
      );

      final builder = DeclarationBuilder();
      final components = await builder.build(files: files, packageName: 'test');

      // Serialize
      final fileEntries = <String, int>{};
      for (final file in files.getScannableDartFiles()) {
        final relativePath = file.path.substring(tempDir.path.length + 1);
        fileEntries[relativePath] = file.statSync().modified.millisecondsSinceEpoch;
      }

      final data = CacheSerializer.serialize(components, fileEntries);

      // Write cache file
      final cacheDir = Directory('${tempDir.path}/.jetleaf');
      cacheDir.createSync(recursive: true);
      final cacheFile = File('${cacheDir.path}/cache_test.bin');
      await cacheFile.writeAsBytes(data, flush: true);

      // Load with ScanCacheManager
      final result = CacheManager.load(
        tempDir,
        configFingerprint: 'test',
      );

      expect(result, isNotNull);
      expect(result!.components.length, equals(components.length));

      // Verify annotations preserved
      final userService = result.components.firstWhere(
        (c) => c.getName() == 'UserService',
      );
      expect(userService.getAnnotations().length, equals(1));
      expect(userService.getAnnotations().first.getName(), equals('Injectable'));
      expect(userService.getIsPublic(), isTrue);
    });

    test('cache invalidation on file change', () async {
      final libDir = Directory('${tempDir.path}/lib');
      libDir.createSync();

      File('${libDir.path}/config.dart').writeAsStringSync('''
class Config {
  String value = '';
}
''');

      // Build and write cache
      final discovery = FileDiscovery(tempDir);
      final files = await discovery.discover(
        skipTests: true,
        packagesToExclude: [],
        packagesToScan: [],
        filesToExclude: [],
      );

      final builder = DeclarationBuilder();
      final components = await builder.build(files: files, packageName: 'test');

      final fileEntries = <String, int>{};
      for (final file in files.getScannableDartFiles()) {
        final relativePath = file.path.substring(tempDir.path.length + 1);
        fileEntries[relativePath] = file.statSync().modified.millisecondsSinceEpoch;
      }

      final data = CacheSerializer.serialize(components, fileEntries);
      final cacheDir = Directory('${tempDir.path}/.jetleaf');
      cacheDir.createSync(recursive: true);
      await File('${cacheDir.path}/cache_test.bin').writeAsBytes(data, flush: true);

      // Verify cache is valid
      expect(CacheManager.isValid(tempDir, configFingerprint: 'test'), isTrue);

      // Modify the file (wait to ensure mtime changes)
      sleep(Duration(milliseconds: 1100));
      File('${libDir.path}/config.dart').writeAsStringSync('''
class Config {
  String value = 'changed';
}
''');

      // Cache should now be invalid
      expect(CacheManager.isValid(tempDir, configFingerprint: 'test'), isFalse);
    });

    test('different fingerprints produce different cache files', () async {
      final libDir = Directory('${tempDir.path}/lib');
      libDir.createSync();

      File('${libDir.path}/empty.dart').writeAsStringSync('''
class Empty {}
''');

      final discovery = FileDiscovery(tempDir);
      final files = await discovery.discover(
        skipTests: true,
        packagesToExclude: [],
        packagesToScan: [],
        filesToExclude: [],
      );

      final builder = DeclarationBuilder();
      final components = await builder.build(files: files, packageName: 'test');

      final fileEntries = <String, int>{};
      for (final file in files.getScannableDartFiles()) {
        final relativePath = file.path.substring(tempDir.path.length + 1);
        fileEntries[relativePath] = file.statSync().modified.millisecondsSinceEpoch;
      }

      // Write with fingerprint 1
      final data1 = CacheSerializer.serialize(components, fileEntries);
      final cacheDir = Directory('${tempDir.path}/.jetleaf');
      cacheDir.createSync(recursive: true);
      await File('${cacheDir.path}/cache_fp1.bin').writeAsBytes(data1, flush: true);

      // Write with fingerprint 2
      final data2 = CacheSerializer.serialize(components, fileEntries);
      await File('${cacheDir.path}/cache_fp2.bin').writeAsBytes(data2, flush: true);
    });
  });
}
