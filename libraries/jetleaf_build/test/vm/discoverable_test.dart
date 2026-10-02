// ignore_for_file: invalid_use_of_protected_member
//
// Protected-member access below is intentional: [Discoverable] is
// `abstract final` in the `jetleaf_vm` library, so tests drive discovery
// through `JetleafVM.instance` (pure analyzer I/O, no running manager).

import 'dart:io';

import 'package:jetleaf_build/src/vm/jetleaf_vm.dart';
import 'package:test/test.dart';

void main() {
  group('discoverEntries', () {
    test('finds @JetleafEntry and @JetleafTest on void main() only',
        () async {
      final dir = await Directory.systemTemp.createTemp('jl_entry');
      try {
        final lib = Directory('${dir.path}/lib')..createSync();
        await File('${lib.path}/main.dart').writeAsString('''
import 'package:jetleaf_build/jetleaf_build.dart';

@JetleafEntry()
void main(List<String> args) {}
''');
        await File('${lib.path}/helper.dart').writeAsString('''
import 'package:jetleaf_build/jetleaf_build.dart';

@JetleafEntry()
class NotAMain {}

void main() {}
''');
        final testDir = Directory('${dir.path}/test')..createSync();
        await File('${testDir.path}/app_test.dart').writeAsString('''
import 'package:jetleaf_build/jetleaf_build.dart';
import 'package:test/test.dart';

@JetleafTest(timeoutSeconds: 30)
void main() {
  test('works', () {});
}
''');

        final warnings = <String>[];
        final registry = await JetleafVM.instance
            .discoverEntries(dir, onWarning: warnings.add);

        expect(registry.entries, hasLength(2));
        expect(registry.appCount, 1);
        expect(registry.testCount, 1);

        final app = registry.entries
            .firstWhere((e) => e.kind == EntryKind.entry);
        expect(app.file, 'lib/main.dart');

        final test = registry.entries
            .firstWhere((e) => e.kind == EntryKind.test);
        expect(test.file, 'test/app_test.dart');
        expect(test.timeoutSeconds, 30);
        expect(test.forTests, isTrue);

        // helper.dart must not produce an entry (annotation not on main,
        // bare main ignored) — and should warn.
        expect(
            registry.entries.any((e) => e.file == 'lib/helper.dart'),
            isFalse);
        expect(warnings.any((w) => w.contains('lib/helper.dart')), isTrue);
      } finally {
        await dir.delete(recursive: true);
      }
    });

    test('empty project yields empty registry', () async {
      final dir = await Directory.systemTemp.createTemp('jl_entry');
      try {
        final lib = Directory('${dir.path}/lib')..createSync();
        await File('${lib.path}/a.dart')
            .writeAsString('void main() {}\n');
        final registry =
            await JetleafVM.instance.discoverEntries(dir);
        expect(registry.isEmpty, isTrue);
      } finally {
        await dir.delete(recursive: true);
      }
    });

    test('finds the standard Jetleaf starter application', () async {
      final dir = await Directory.systemTemp.createTemp('jl_starter');
      try {
        final lib = Directory('${dir.path}/lib')..createSync();
        await File('${lib.path}/main.dart').writeAsString('''
import 'package:jetleaf/jetleaf.dart';

Future<void> main(List<String> args) async {
  await JetleafApplication.run(Application(), args);
}

@JetleafApplicationStarter()
class Application {}
''');
        final registry = await JetleafVM.instance.discoverEntries(dir);
        expect(registry.appCount, 1);
        expect(registry.entries.single.file, 'lib/main.dart');
      } finally {
        await dir.delete(recursive: true);
      }
    });

    test('only allowlist scopes discovery to given files', () async {
      final dir = await Directory.systemTemp.createTemp('jl_entry');
      try {
        final lib = Directory('${dir.path}/lib')..createSync();
        await File('${lib.path}/a.dart').writeAsString('''
import 'package:jetleaf_build/jetleaf_build.dart';

@JetleafEntry()
void main() {}
''');
        final testDir = Directory('${dir.path}/test')..createSync();
        await File('${testDir.path}/b_test.dart').writeAsString('''
import 'package:jetleaf_build/jetleaf_build.dart';

@JetleafTest()
void main() {}
''');
        final scoped = await JetleafVM.instance
            .discoverEntries(dir, only: ['lib/a.dart']);
        expect(scoped.entries, hasLength(1));
        expect(scoped.entries.single.file, 'lib/a.dart');

        final missing = await JetleafVM.instance.discoverEntries(dir,
            only: ['lib/nope.dart'], onWarning: (_) {});
        expect(missing.isEmpty, isTrue);
      } finally {
        await dir.delete(recursive: true);
      }
    });
  });
}
