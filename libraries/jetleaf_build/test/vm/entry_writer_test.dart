// ignore_for_file: invalid_use_of_protected_member
//
// Protected-member access below is intentional: [EntryWriter] is
// `abstract final` in the `jetleaf_vm` library, so tests drive stub
// generation through `JetleafVM.instance` (pure file I/O, no manager).

import 'dart:io';

import 'package:jetleaf_build/src/vm/jetleaf_vm.dart';
import 'package:test/test.dart';

void main() {
  group('EntryWriter', () {
    test('parked stub never completes and exposes ensure', () async {
      final dir = await Directory.systemTemp.createTemp('jl_stub');
      try {
        await JetleafVM.instance.writeParkedEntryStub(
          dir,
          'lib/main.dart',
          forTests: false,
        );
        final content = await File(
          '${dir.path}/.jetleaf/generated/entries/lib__main.dart',
        ).readAsString();
        // Regression: the resident isolate must keep an active timer and a
        // command socket alive between warm-up and the next run.
        expect(content, contains('Timer.periodic'));
        expect(content, contains('_jlCommandServer'));
        expect(content, contains('ServerSocket.bind'));
        expect(
          content.indexOf('AUTO-GENERATED entry stub'),
          lessThan(content.indexOf("import 'dart:async';")),
        );
        expect(
          content.indexOf("import 'dart:async';"),
          lessThan(content.indexOf("import 'dart:convert';")),
        );
        expect(content, contains('ensureJetleafRuntime'));
        expect(content, isNot(contains('as entry;')));
        // App entries ensure the production runtime.
      expect(content, contains('jl.runScan'));
      expect(content, contains('show RuntimeBuildMode, RuntimeScannerConfiguration;'));
      } finally {
        await dir.delete(recursive: true);
      }
    });

    test('test stub ensures the test runtime', () async {
      final dir = await Directory.systemTemp.createTemp('jl_stub');
      try {
        await JetleafVM.instance.writeParkedEntryStub(
          dir,
          'test/app_test.dart',
          forTests: true,
        );
        final content = await File(
          '${dir.path}/.jetleaf/generated/entries/test__app_test.dart',
        ).readAsString();
      expect(content, contains('jl.runTestScan'));
      expect(content, contains('show RuntimeBuildMode, RuntimeScannerConfiguration;'));
      } finally {
        await dir.delete(recursive: true);
      }
    });

    test('runner stub imports and invokes entry main with args', () async {
      final dir = await Directory.systemTemp.createTemp('jl_stub');
      try {
        await File(
          '${dir.path}/pubspec.yaml',
        ).writeAsString('name: demo_app\n');
        final lib = Directory('${dir.path}/lib')..createSync();
        final entry = File('${lib.path}/main.dart')
          ..writeAsString('void main(List<String> args) async {}\n');
        await JetleafVM.instance.writeRunnerEntryStub(
          dir,
          'lib/main.dart',
          entry,
          forTests: false,
        );
        final content = await File(
          '${dir.path}/.jetleaf/generated/entries/lib__main.dart',
        ).readAsString();
        expect(content, contains('package:demo_app/main.dart'));
        expect(content, contains('entry.main(args)'));
        expect(content, contains('ensureJetleafRuntime'));
        // Runner keeps the isolate alive after user main completes so
        // the VM survives for the next run.
        expect(content, contains('Timer.periodic'));
      } finally {
        await dir.delete(recursive: true);
      }
    });

    test('test runner stub drives the engine, not main()', () async {
      final dir = await Directory.systemTemp.createTemp('jl_stub');
      try {
        await File(
          '${dir.path}/pubspec.yaml',
        ).writeAsString('name: demo_app\n');
        final testDir = Directory('${dir.path}/test')..createSync();
        final entry = File('${testDir.path}/app_test.dart')
          ..writeAsString('void main() {}\n');
        await JetleafVM.instance.writeRunnerEntryStub(
          dir,
          'test/app_test.dart',
          entry,
          forTests: true,
        );
        final content = await File(
          '${dir.path}/.jetleaf/generated/entries/test__app_test.dart',
        ).readAsString();
        // Evaluating main() alone only registers tests; the driver runs
        // the engine and reports success. The VM persists (timer kept).
        expect(content, contains('runJetleafTests'));
        expect(content, contains('Declarer(isStandalone: true)'));
        expect(content, contains('Function.apply(entry.main'));
        expect(content, contains('ExpandedReporter'));
        expect(content, contains('Timer.periodic'));
        // The test runner is commanded through the resident VM socket, so it
        // only needs the returned pass flag, not the old polling state.
        expect(content, isNot(contains('_ensureJetleafRuntime')));
        expect(content, contains('_jlTestsPassed'));
        expect(content, contains('_jlTestsPassed = false'));
        expect(content, contains('Function.apply(entry.main, [args])'));
      } finally {
        await dir.delete(recursive: true);
      }
    });

    test('test driver handles async void entries', () async {
      final dir = await Directory.systemTemp.createTemp('jl_stub');
      try {
        await File(
          '${dir.path}/pubspec.yaml',
        ).writeAsString('name: demo_app\n');
        final testDir = Directory('${dir.path}/test')..createSync();
        final entry = File('${testDir.path}/async_test.dart')
          ..writeAsString('void main() async {}\n');
        await JetleafVM.instance.writeRunnerEntryStub(
          dir,
          'test/async_test.dart',
          entry,
          forTests: true,
        );
        final content = await File(
          '${dir.path}/.jetleaf/generated/entries/test__async_test.dart',
        ).readAsString();
        // Dynamic apply covers every main signature, sync or async.
        expect(content, contains('Function.apply(entry.main'));
        expect(content, contains('runJetleafTests'));
      } finally {
        await dir.delete(recursive: true);
      }
    });

    test('runner stub uses bare statement for sync void main', () async {
      final dir = await Directory.systemTemp.createTemp('jl_stub');
      try {
        await File(
          '${dir.path}/pubspec.yaml',
        ).writeAsString('name: demo_app\n');
        final lib = Directory('${dir.path}/lib')..createSync();
        final entry = File('${lib.path}/tool.dart')
          ..writeAsString('void main() {}\n');
        await JetleafVM.instance.writeRunnerEntryStub(
          dir,
          'lib/tool.dart',
          entry,
          forTests: false,
        );
        final content = await File(
          '${dir.path}/.jetleaf/generated/entries/lib__tool.dart',
        ).readAsString();
        // A `void` value can neither be `is`-checked nor awaited.
        expect(content, contains('entry.main();'));
        expect(content, isNot(contains('is Future')));
      } finally {
        await dir.delete(recursive: true);
      }
    });

    test('stubs carry the shared generated header', () async {
      final dir = await Directory.systemTemp.createTemp('jl_stub');
      try {
        await File(
          '${dir.path}/pubspec.yaml',
        ).writeAsString('name: demo_app\n');
        final lib = Directory('${dir.path}/lib')..createSync();
        final entry = File('${lib.path}/main.dart')
          ..writeAsString('void main(List<String> args) async {}\n');
        await JetleafVM.instance.writeRunnerEntryStub(
          dir,
          'lib/main.dart',
          entry,
          forTests: false,
        );
        final content = await File(
          '${dir.path}/.jetleaf/generated/entries/lib__main.dart',
        ).readAsString();
        expect(content, contains('AUTO-GENERATED entry stub'));
        expect(content, contains('Do not edit manually'));
        expect(content, contains('Copyright (c)'));
        expect(content, contains('ignore_for_file:'));
      } finally {
        await dir.delete(recursive: true);
      }
    });

    test('entry outside lib/ uses encoded file import', () async {
      final dir = await Directory.systemTemp.createTemp('jl_stub');
      try {
        await File(
          '${dir.path}/pubspec.yaml',
        ).writeAsString('name: demo_app\n');
        final bin = Directory('${dir.path}/bin')..createSync();
        final entry = File('${bin.path}/tool.dart')
          ..writeAsString('void main() {}\n');
        final uri = JetleafVM.instance.resolveEntryImport(dir, entry);
        // Percent-encoded file: URI — raw paths break compilation when
        // directories contain spaces (e.g. "Jetleaf Framework").
        expect(uri, Uri.file(entry.absolute.path).toString());
        expect(uri.contains(' '), isFalse);
      } finally {
        await dir.delete(recursive: true);
      }
    });

    test('prefixes stay lint-clean (no leading underscores)', () async {
      final dir = await Directory.systemTemp.createTemp('jl_stub');
      try {
        await File(
          '${dir.path}/pubspec.yaml',
        ).writeAsString('name: demo_app\n');
        final lib = Directory('${dir.path}/lib')..createSync();
        final entry = File('${lib.path}/main.dart')
          ..writeAsString('void main(List<String> args) async {}\n');
        await JetleafVM.instance.writeRunnerEntryStub(
          dir,
          'lib/main.dart',
          entry,
          forTests: false,
        );
        final content = await File(
          '${dir.path}/.jetleaf/generated/entries/lib__main.dart',
        ).readAsString();
        expect(content, contains('as jl;'));
        expect(content, contains('as entry;'));
        expect(content, isNot(contains('_user_entry')));
        expect(content, isNot(contains('as _jl;')));
      } finally {
        await dir.delete(recursive: true);
      }
    });
  });
}
