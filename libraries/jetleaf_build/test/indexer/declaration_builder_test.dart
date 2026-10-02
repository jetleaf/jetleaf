import 'dart:convert';
import 'dart:io';

import 'package:jetleaf_build/cache.dart';
import 'package:jetleaf_build/src/cache/indexer/declaration_builder.dart';
import 'package:jetleaf_build/src/cache/indexer/file_discovery.dart';
import 'package:jetleaf_build/src/runtime/declaration/declaration.dart';
import 'package:test/test.dart';

void main() {
  group('DeclarationBuilder', () {
    late Directory tempDir;
    late Directory libDir;
    late DeclarationBuilder builder;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('declaration_builder_test_');
      libDir = Directory('${tempDir.path}/lib');
      libDir.createSync();
      builder = DeclarationBuilder();
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('builds class declarations', () async {
      File('${libDir.path}/user.dart').writeAsStringSync('''
class User {
  String name = '';
  int age = 0;
  User();
  void greet() {}
}
''');

      final discovery = FileDiscovery(tempDir);
      final files = await discovery.discover(
        skipTests: true,
        packagesToExclude: [],
        packagesToScan: [],
        filesToExclude: [],
      );

      final components = await builder.build(files: files, packageName: 'test');

      expect(components, isNotEmpty);
      final userClass = components.firstWhere((c) => c.getName() == 'User');
      expect(userClass.getName(), equals('User'));
      expect(userClass.getFields().length, equals(2));
      expect(userClass.getConstructors().length, equals(1));
      expect(userClass.getMethods().length, equals(1));
    });

    test('extracts annotations', () async {
      File('${libDir.path}/user.dart').writeAsStringSync('''
class User {
  @override
  String toString() => 'User';
}
''');

      final discovery = FileDiscovery(tempDir);
      final files = await discovery.discover(
        skipTests: true,
        packagesToExclude: [],
        packagesToScan: [],
        filesToExclude: [],
      );

      final components = await builder.build(files: files, packageName: 'test');
      final userClass = components.firstWhere((c) => c.getName() == 'User');
      final methods = userClass.getMethods();

      expect(methods.length, equals(1));
      expect(methods.single.getAnnotations(), hasLength(1));
      expect(methods.single.getAnnotations().single.getName(), 'override');
    });

    test('preserves annotations on methods for the cache index', () async {
      File('${libDir.path}/cache.dart').writeAsStringSync('''
class User {
  @Cacheable()
  String load() => 'value';
}
''');

      final discovery = FileDiscovery(tempDir);
      final files = await discovery.discover(
        skipTests: true,
        packagesToExclude: [],
        packagesToScan: [],
        filesToExclude: [],
      );

      final components = await builder.build(files: files, packageName: 'test');
      final userClass = components.firstWhere((c) => c.getName() == 'User');

      expect(userClass.getMethods().single.getAnnotations(), hasLength(1));
      expect(
        userClass.getMethods().single.getAnnotations().single.getName(),
        'Cacheable',
      );

      await CacheWriter(tempDir).writeWithComponents(
        components: components,
        fingerprint: 'annotated-method-test',
        forTests: false,
      );
      final index = jsonDecode(
        JetleafPaths.annotatedMethodsJson(tempDir).readAsStringSync(),
      ) as Map<String, dynamic>;

      expect(index['Cacheable'], hasLength(1));
      expect(index['Cacheable'].single['class'], 'User');
      expect(index['Cacheable'].single['method'], 'load');
    });

    test('handles abstract classes', () async {
      File('${libDir.path}/base.dart').writeAsStringSync('''
abstract class Base {
  void method();
}
class Concrete extends Base {
  void method() {}
}
''');

      final discovery = FileDiscovery(tempDir);
      final files = await discovery.discover(
        skipTests: true,
        packagesToExclude: [],
        packagesToScan: [],
        filesToExclude: [],
      );

      final components = await builder.build(files: files, packageName: 'test');

      expect(components.length, equals(2));
      final baseClass = components.firstWhere((c) => c.getName() == 'Base');
      expect(baseClass.getIsAbstract(), isTrue);
    });

    test('handles enums', () async {
      File('${libDir.path}/status.dart').writeAsStringSync('''
enum Status { active, inactive }
''');

      final discovery = FileDiscovery(tempDir);
      final files = await discovery.discover(
        skipTests: true,
        packagesToExclude: [],
        packagesToScan: [],
        filesToExclude: [],
      );

      final components = await builder.build(files: files, packageName: 'test');

      expect(components.length, equals(1));
      expect(components.first, isA<EnumDeclaration>());
    });

    test('handles mixins', () async {
      File('${libDir.path}/loggable.dart').writeAsStringSync('''
mixin Loggable {
  void log() {}
}
class UserService with Loggable {
  int get methodCount => 1;
}
''');

      final discovery = FileDiscovery(tempDir);
      final files = await discovery.discover(
        skipTests: true,
        packagesToExclude: [],
        packagesToScan: [],
        filesToExclude: [],
      );

      final components = await builder.build(files: files, packageName: 'test');

      expect(components.length, equals(2));
      final loggable = components.firstWhere((c) => c.getName() == 'Loggable');
      expect(loggable.getIsMixin(), isTrue);
    });
  });
}
