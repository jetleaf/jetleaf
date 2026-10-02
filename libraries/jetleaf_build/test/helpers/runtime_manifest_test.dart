import 'dart:io';

import 'package:jetleaf_build/src/cache/jetleaf_paths.dart';
import 'package:jetleaf_build/src/helpers/manifest.dart';
import 'package:test/test.dart';

void main() {
  test('writes and reloads a versioned production manifest', () async {
    final root = await Directory.systemTemp.createTemp('jetleaf_manifest_');
    addTearDown(() => root.delete(recursive: true));

    final manifest = RuntimeManifest(
      fingerprint: 'abc123',
      forTests: false,
      treeShakingEnabled: true,
      generatedAt: DateTime.parse('2000-01-01T00:00:00.000Z'),
      componentQualifiedNames: ['package:demo/demo.dart.Demo'],
      libraryUris: ['package:demo/demo.dart'],
      packageNames: ['demo'],
      assetPaths: [],
      subclassIndex: [],
      annotatedMethods: [],
      runtimeHints: [],
    );

    await RuntimeManifestStore.write(root, manifest);
    final loaded = RuntimeManifestStore.load(root, fingerprint: 'abc123');

    expect(
      loaded?.componentQualifiedNames,
      contains('package:demo/demo.dart.Demo'),
    );
    expect(loaded?.treeShakingEnabled, isTrue);
    expect(
      JetleafPaths.runtimeRegistry(root).readAsStringSync(),
      contains('abc123'),
    );
    expect(RuntimeManifestStore.load(root, fingerprint: 'stale'), isNull);
  });

  test('writes registry collections as readable multiline Dart lists', () async {
    final root = await Directory.systemTemp.createTemp('jetleaf_registry_');
    addTearDown(() => root.delete(recursive: true));

    final manifest = RuntimeManifest(
      fingerprint: 'registry-test',
      forTests: false,
      treeShakingEnabled: false,
      generatedAt: DateTime.parse('2000-01-01T00:00:00.000Z'),
      componentQualifiedNames: [
        'package:demo/demo.dart.Demo',
        'package:demo/other.dart.Other',
        'package:demo/special.dart.Special\$Value',
      ],
      libraryUris: [
        'package:demo/demo.dart',
        'package:demo/other.dart',
      ],
      packageNames: ['demo'],
      assetPaths: [],
      subclassIndex: [],
      annotatedMethods: [],
      runtimeHints: [],
    );

    await RuntimeManifestStore.write(root, manifest);
    final source = JetleafPaths.runtimeRegistry(root).readAsStringSync();

    expect(
      source,
      contains(
        'const jetleafRuntimeComponents = [\n'
        '  "package:demo/demo.dart.Demo",\n',
      ),
    );
    expect(
      source,
      contains(
        'const jetleafRuntimeLibraries = [\n'
        '  "package:demo/demo.dart",\n',
      ),
    );
    expect(source, contains(r'Special\$Value'));
  });
}
