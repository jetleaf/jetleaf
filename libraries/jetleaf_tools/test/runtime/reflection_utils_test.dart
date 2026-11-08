import 'package:jetleaf_tools/src/utils/reflection_utils.dart';
import 'package:test/test.dart';

/// A dummy class used for testing reflection.
class User {
  final String name;
  User(this.name);
}

/// Another dummy class to verify multiple types.
class Admin extends User {
  Admin(super.name);
}

/// A function for testing.
void testFunction(int x, String y) {}

/// Another function for testing.
int anotherFunction(double d) => d.toInt();

void main() {
  group('ReflectionUtils', () {
    test('findQualifiedName returns a fully qualified name for an instance', () {
      final user = User('Alice');
      final qualifiedName = ReflectionUtils.findQualifiedName(user);

      expect(qualifiedName, contains('User'));
    });

    test('findQualifiedNameFromType returns a fully qualified name for a Type', () {
      final qualifiedName = ReflectionUtils.findQualifiedNameFromType(Admin);

      expect(qualifiedName, contains('Admin'));
    });

    test('isThisARecord detects record types', () {
      final record = (1, 'hello');
      expect(ReflectionUtils.isThisARecord(record), isTrue);

      final namedRecord = (id: 42, label: 'test');
      expect(ReflectionUtils.isThisARecord(namedRecord), isTrue);

      expect(ReflectionUtils.isThisARecord('not a record'), isFalse);
      expect(ReflectionUtils.isThisARecord(123), isFalse);
      expect(ReflectionUtils.isThisARecord(User('Bob')), isFalse);
    });

    test('isThisAFunction detects functions and closures', () {
      expect(ReflectionUtils.isThisAFunction(testFunction), isTrue);
      expect(ReflectionUtils.isThisAFunction(anotherFunction), isTrue);
      expect(ReflectionUtils.isThisAFunction((int a) => a + 1), isTrue);

      expect(ReflectionUtils.isThisAFunction('string'), isFalse);
      expect(ReflectionUtils.isThisAFunction(123), isFalse);
      expect(ReflectionUtils.isThisAFunction(User('Charlie')), isFalse);
    });

    test('buildQualifiedName builds canonical dot-separated qualified names', () {
      final name = ReflectionUtils.buildQualifiedName('MyClass', 'package:my_app/my_class.dart');
      expect(name, equals('package:my_app/my_class.dart.MyClass'));
    });

    test('extractClassName extracts the class name from qualified name', () {
      expect(ReflectionUtils.extractClassName('package:my_app/models/user.dart.User'), equals('User'));
      expect(ReflectionUtils.extractClassName('dart:core.String'), equals('String'));
      expect(ReflectionUtils.extractClassName('BareName'), equals('BareName'));
    });

    test('extractLibraryUri extracts library URI from qualified name', () {
      expect(
        ReflectionUtils.extractLibraryUri('package:my_app/models/user.dart.User'),
        equals('package:my_app/models/user.dart'),
      );
      expect(ReflectionUtils.extractLibraryUri('dart:core.String'), equals('dart:core'));
      expect(ReflectionUtils.extractLibraryUri('BareName'), equals('BareName'));
    });
  });
}