import 'dart:io';

import '../manager/cacheable_manager.dart';

/// Status command — checks cache validity and prints info.
void runStatus(List<String> args) {
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

  final prodFingerprint = CacheManager.generateFingerprint(skipTests: true);
  final testFingerprint = CacheManager.generateFingerprint(skipTests: false);

  final prodValid = CacheManager.isValid(projectRoot, configFingerprint: prodFingerprint);
  final testValid = CacheManager.isValid(projectRoot, configFingerprint: testFingerprint);

  final prodCache = CacheManager.load(projectRoot, configFingerprint: prodFingerprint);
  final testCache = CacheManager.load(projectRoot, configFingerprint: testFingerprint);

  print('Project: $packageName');
  print('Path: ${projectRoot.path}');
  print('');
  print('Production cache (.jetleaf/):');
  print('  Valid: $prodValid');
  print('  Fingerprint: $prodFingerprint');
  if (prodCache != null) {
    print('  Components: ${prodCache.components.length}');
    print('  Libraries: ${prodCache.libraries.length}');
    print('  Packages: ${prodCache.packages.length}');
    print('  Assets: ${prodCache.assets.length}');
    print('  Timestamp: ${prodCache.timestamp}');
  }
  print('');
  print('Test cache (.jetleaf/test/):');
  print('  Valid: $testValid');
  print('  Fingerprint: $testFingerprint');
  if (testCache != null) {
    print('  Components: ${testCache.components.length}');
    print('  Libraries: ${testCache.libraries.length}');
    print('  Packages: ${testCache.packages.length}');
    print('  Assets: ${testCache.assets.length}');
    print('  Timestamp: ${testCache.timestamp}');
  }
}