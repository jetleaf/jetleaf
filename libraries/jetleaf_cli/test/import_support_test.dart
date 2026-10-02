import 'package:jetleaf_cli/src/support/support.dart';
import 'package:test/test.dart';

class TestImportSupport extends ImportSupport {
  const TestImportSupport();

  String testBuildEntryAlias(String packageName) => buildEntryAlias(packageName);
  String testBuildImportAlias(String importPath, {Set<String>? used}) => buildImportAlias(importPath, used: used);
}

void main() {
  const support = TestImportSupport();

  group('ImportSupport', () {
    group('buildEntryAlias', () {
      test('should create entry alias from package name', () {
        expect(support.testBuildEntryAlias('my_package'), equals('my_package_entry_library'));
      });

      test('should handle simple package name', () {
        expect(support.testBuildEntryAlias('app'), equals('app_entry_library'));
      });

      test('should handle hyphenated package name', () {
        expect(support.testBuildEntryAlias('my-app'), equals('my-app_entry_library'));
      });
    });

    group('buildImportAlias', () {
      test('should create alias for package import', () {
        final alias = support.testBuildImportAlias('package:my_app/src/utils.dart');
        expect(alias, equals('pkg_my_app_utils'));
      });

      test('should create alias for dart import', () {
        final alias = support.testBuildImportAlias('dart:async');
        expect(alias, equals('dart_async'));
      });

      test('should create alias for relative import', () {
        final alias = support.testBuildImportAlias('../utils/helper.dart');
        expect(alias, isA<String>());
        expect(alias.isNotEmpty, isTrue);
      });

      test('should handle package with hyphens', () {
        final alias = support.testBuildImportAlias('package:my-lib/src/foo.dart');
        expect(alias, equals('pkg_my_lib_foo'));
      });

      test('should avoid collisions with used set', () {
        final used = <String>{};
        final alias1 = support.testBuildImportAlias('package:foo/bar.dart', used: used);
        final alias2 = support.testBuildImportAlias('package:foo/baz.dart', used: used);
        expect(alias1, isNot(equals(alias2)));
      });

      test('should append suffix on collision', () {
        final used = <String>{};
        final alias1 = support.testBuildImportAlias('dart:async', used: used);
        final alias2 = support.testBuildImportAlias('dart:async', used: used);
        expect(alias1, equals('dart_async'));
        expect(alias2, equals('dart_async_2'));
      });
    });
  });
}
