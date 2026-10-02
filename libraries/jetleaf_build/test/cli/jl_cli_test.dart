import 'dart:io';

import 'package:jetleaf_build/src/cli/jl_cli.dart';
import 'package:jetleaf_build/src/utils/utils.dart';
import 'package:test/test.dart';

void main() {
  group('RuntimeUtils.isJetLeafBuildProject', () {
    test('accepts pubspec with jetleaf_build dep', () async {
      final dir = await Directory.systemTemp.createTemp('jl_test');
      try {
        await File('${dir.path}/pubspec.yaml').writeAsString('''
name: my_app
dependencies:
  jetleaf_build: any
''');
        expect(RuntimeUtils.isJetLeafBuildProject(dir), isTrue);
      } finally {
        await dir.delete(recursive: true);
      }
    });

    test('accepts own jetleaf_build package (self-hosting)', () async {
      final dir = await Directory.systemTemp.createTemp('jl_test');
      try {
        await File('${dir.path}/pubspec.yaml').writeAsString('''
name: jetleaf_build
version: 1.0.0
''');
        expect(RuntimeUtils.isJetLeafBuildProject(dir), isTrue);
      } finally {
        await dir.delete(recursive: true);
      }
    });

    test('rejects plain dart project', () async {
      final dir = await Directory.systemTemp.createTemp('jl_test');
      try {
        await File('${dir.path}/pubspec.yaml').writeAsString('''
name: my_app
dependencies:
  path: any
''');
        expect(RuntimeUtils.isJetLeafBuildProject(dir), isFalse);
      } finally {
        await dir.delete(recursive: true);
      }
    });

    test('accepts package_config with jetleaf_build', () async {
      final dir = await Directory.systemTemp.createTemp('jl_test');
      try {
        await File('${dir.path}/pubspec.yaml').writeAsString('name: my_app\n');
        final toolDir = Directory('${dir.path}/.dart_tool')..createSync();
        await File('${toolDir.path}/package_config.json')
            .writeAsString('{"packages":[{"name": "jetleaf_build"}]}');
        expect(RuntimeUtils.isJetLeafBuildProject(dir), isTrue);
      } finally {
        await dir.delete(recursive: true);
      }
    });
  });

  group('JlCli', () {
    test('unknown command exits 1', () async {
      expect(await JlCli().run(['bogus']), 1);
    });

    test('dev rejects non-jetleaf root', () async {
      final dir = await Directory.systemTemp.createTemp('jl_test');
      try {
        await File('${dir.path}/pubspec.yaml').writeAsString('name: plain\n');
        expect(await JlCli().run(['dev', '--once', '--root', dir.path]), 1);
      } finally {
        await dir.delete(recursive: true);
      }
    });

    test('dev --once warms a jetleaf project and writes cache', () async {
      final dir = await Directory.systemTemp.createTemp('jl_test');
      try {
        await File('${dir.path}/pubspec.yaml').writeAsString(
            'name: warm_app\ndependencies:\n  jetleaf_build: any\n');
        final lib = Directory('${dir.path}/lib')..createSync();
        await File('${lib.path}/a.dart').writeAsString(
            'class Alpha {\n  String greet() => "hi";\n}\n');

        expect(await JlCli().run(['dev', '--once', '--root', dir.path]), 0);
        expect(File('${dir.path}/.jetleaf/cache/main/cache_38e880ef.bin').existsSync(),
            isTrue);
        expect(
            Directory('${dir.path}/.jetleaf/cache/test').existsSync(), isTrue);

        // Second run is idempotent.
        expect(await JlCli().run(['dev', '--once', '--root', dir.path]), 0);
      } finally {
        await dir.delete(recursive: true);
      }
    });
  });
}
