import 'package:jetleaf_cli/src/utils.dart';
import 'package:test/test.dart';

void main() {
  group('buildImportAlias', () {
    test('should create alias for package import', () {
      final alias = buildImportAlias('package:my_app/src/utils.dart');
      expect(alias, equals('pkg_my_app_utils'));
    });

    test('should create alias for dart import', () {
      final alias = buildImportAlias('dart:async');
      expect(alias, equals('dart_async'));
    });

    test('should create alias for relative import', () {
      final alias = buildImportAlias('../utils/helper.dart');
      expect(alias, contains('file'));
    });

    test('should handle package with hyphens', () {
      final alias = buildImportAlias('package:my-lib/src/foo.dart');
      expect(alias, equals('pkg_my_lib_foo'));
    });

    test('should handle deep package paths', () {
      final alias = buildImportAlias('package:my_app/lib/src/deep/path/file.dart');
      expect(alias, equals('pkg_my_app_file'));
    });

    test('should avoid collisions with used set', () {
      final used = <String>{};
      final alias1 = buildImportAlias('package:foo/bar.dart', used: used);
      final alias2 = buildImportAlias('package:foo/baz.dart', used: used);
      expect(alias1, isNot(equals(alias2)));
      expect(used.length, equals(2));
    });

    test('should append suffix on collision', () {
      final used = <String>{};
      final alias1 = buildImportAlias('dart:async', used: used);
      final alias2 = buildImportAlias('dart:async', used: used);
      expect(alias1, equals('dart_async'));
      expect(alias2, equals('dart_async_2'));
    });

    test('should handle dart:io import', () {
      final alias = buildImportAlias('dart:io');
      expect(alias, equals('dart_io'));
    });
  });

  group('aliasForUri', () {
    test('should create alias for package URI', () {
      final alias = aliasForUri(Uri.parse('package:my_app/src/main.dart'));
      expect(alias, startsWith('pkg_'));
      expect(alias, contains('my_app'));
    });

    test('should create alias for dart URI', () {
      final alias = aliasForUri(Uri.parse('dart:async'));
      expect(alias, startsWith('pkg_'));
      expect(alias, contains('async'));
    });

    test('should remove .dart extension', () {
      final alias = aliasForUri(Uri.parse('package:foo/bar.dart'));
      expect(alias, isNot(contains('.dart')));
    });

    test('should replace non-alphanumeric with underscores', () {
      final alias = aliasForUri(Uri.parse('package:my-app/src/some-file.dart'));
      expect(alias, isNot(contains('-')));
    });
  });

  group('sanitizePackageName', () {
    test('should convert simple name to PascalCase', () {
      expect(sanitizePackageName('myapp'), equals('Myapp'));
    });

    test('should handle hyphenated names', () {
      expect(sanitizePackageName('my-app'), equals('MyApp'));
    });

    test('should handle underscored names', () {
      expect(sanitizePackageName('my_app'), equals('MyApp'));
    });

    test('should handle mixed case', () {
      expect(sanitizePackageName('myApp'), equals('MyApp'));
    });

    test('should handle empty string', () {
      expect(sanitizePackageName(''), equals('UnnamedPackage'));
    });

    test('should handle special characters', () {
      expect(sanitizePackageName('my@app!'), equals('MyApp'));
    });
  });

  group('sanitizeFileName', () {
    test('should remove extension and convert to PascalCase', () {
      expect(sanitizeFileName('my_file.dart'), equals('MyFile'));
    });

    test('should handle hyphenated file names', () {
      expect(sanitizeFileName('my-file.dart'), equals('MyFile'));
    });

    test('should handle file without extension', () {
      expect(sanitizeFileName('myfile'), equals('Myfile'));
    });

    test('should handle empty file name', () {
      expect(sanitizeFileName(''), equals('UnnamedFile'));
    });

    test('should handle special characters', () {
      expect(sanitizeFileName('my-file_name.dart'), equals('MyFileName'));
    });
  });

  group('writeGeneratedHeader', () {
    test('should write header to buffer', () {
      final buffer = StringBuffer();
      writeGeneratedHeader(buffer, 'test_library');
      final output = buffer.toString();
      expect(output, contains('AUTO-GENERATED proxy for [test_library] package'));
      expect(output, contains('Do not edit manually'));
      expect(output, contains('Jetleaf Framework'));
      expect(output, contains('${DateTime.now().year}'));
    });

    test('should include ignore_for_file directives', () {
      final buffer = StringBuffer();
      writeGeneratedHeader(buffer, 'test');
      expect(buffer.toString(), contains('ignore_for_file'));
    });
  });

  group('writeGeneratedImports', () {
    test('should write dart imports first', () {
      final buffer = StringBuffer();
      writeGeneratedImports(buffer, {
        'dart:io': [],
        'package:test/test.dart': [],
      });
      final output = buffer.toString();
      final dartPos = output.indexOf("import 'dart:io'");
      final pkgPos = output.indexOf("import 'package:test/test.dart'");
      expect(dartPos, lessThan(pkgPos));
    });

    test('should add aliases when aliased is true', () {
      final buffer = StringBuffer();
      writeGeneratedImports(buffer, {
        'dart:async': [],
      }, aliased: true);
      expect(buffer.toString(), contains('as '));
    });

    test('should not add aliases when aliased is false', () {
      final buffer = StringBuffer();
      writeGeneratedImports(buffer, {
        'dart:async': [],
      }, aliased: false);
      expect(buffer.toString(), isNot(contains(' as ')));
    });

    test('should write show clause for symbols', () {
      final buffer = StringBuffer();
      writeGeneratedImports(buffer, {
        'dart:async': ['Future', 'Stream'],
      });
      expect(buffer.toString(), contains('show Future, Stream'));
    });

    test('should sort imports', () {
      final buffer = StringBuffer();
      writeGeneratedImports(buffer, {
        'package:z_app/main.dart': [],
        'package:a_app/main.dart': [],
      });
      final output = buffer.toString();
      final aPos = output.indexOf('a_app');
      final zPos = output.indexOf('z_app');
      expect(aPos, lessThan(zPos));
    });

    test('should separate dart and package imports with blank line', () {
      final buffer = StringBuffer();
      writeGeneratedImports(buffer, {
        'dart:io': [],
        'package:test/test.dart': [],
      });
      final output = buffer.toString();
      expect(output, contains("import 'dart:io'"));
      expect(output, contains("import 'package:test/test.dart'"));
    });
  });
}
