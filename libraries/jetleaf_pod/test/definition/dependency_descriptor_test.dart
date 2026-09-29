// test/dependency_descriptor_test.dart
import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_pod/src/definition/commons.dart';
import 'package:test/test.dart';

void main() {
  group('DependencyDescriptor', () {
    test('should create with required parameters', () {
      final descriptor = DependencyDesign(name: 'depName');

      expect(descriptor.name, equals('depName'));
      expect(descriptor.prototypeInSingleton, isFalse);
    });

    test('should create with all parameters', () {
      final descriptor = DependencyDesign(name: 'depName', prototypeInSingleton: true);

      expect(descriptor.name, equals('depName'));
      expect(descriptor.prototypeInSingleton, isTrue);
    });

    test('equalsAndHashCode should work correctly', () {
      final descriptor1 = DependencyDesign(name: 'depName');
      final descriptor2 = DependencyDesign(name: 'depName');
      final descriptor3 = DependencyDesign(name: 'different');
      final descriptor4 = DependencyDesign(name: 'depName');

      expect(descriptor1.equals(descriptor2), isTrue);
      expect(descriptor1.equals(descriptor3), isFalse);
      expect(descriptor1.equals(descriptor4), isTrue);
      expect(descriptor1.hashCode, equals(descriptor2.hashCode));
    });

    test('toString should include properties', () {
      final descriptor = DependencyDesign(name: 'depName', prototypeInSingleton: true);

      final str = descriptor.toString();
      expect(str, contains('depName'));
      expect(str, contains('prototypeInSingleton: true'));
    });

    test('should handle edge cases', () {
      final emptyName = DependencyDesign(name: '');
      final longName = DependencyDesign(name: 'a' * 1000);
      final specialChars = DependencyDesign(name: 'dep-name_with.special@chars');

      expect(emptyName.name, isEmpty);
      expect(longName.name, hasLength(1000));
      expect(specialChars.name, equals('dep-name_with.special@chars'));
    });
  });
}