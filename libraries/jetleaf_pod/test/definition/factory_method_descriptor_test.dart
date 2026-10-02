// test/factory_method_descriptor_test.dart
import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_pod/src/definition/commons.dart';
import 'package:test/test.dart';

void main() {
  group('FactoryMethodDescriptor', () {
    test('should create with required parameters', () {
      final descriptor = FactoryMethodDesign('podName', 'methodName');

      expect(descriptor.podName, equals('podName'));
      expect(descriptor.methodName, equals('methodName'));
    });

    test('equalsAndHashCode should work correctly', () {
      final descriptor1 = FactoryMethodDesign('podName', 'methodName');
      final descriptor2 = FactoryMethodDesign('podName', 'methodName');
      final descriptor3 = FactoryMethodDesign('different', 'methodName');
      final descriptor4 = FactoryMethodDesign('podName', 'different');

      expect(descriptor1.equals(descriptor2), isTrue);
      expect(descriptor1.equals(descriptor3), isFalse);
      expect(descriptor1.equals(descriptor4), isFalse);
      expect(descriptor1.hashCode, equals(descriptor2.hashCode));
    });

    test('toString should include properties', () {
      final descriptor = FactoryMethodDesign('podName', 'methodName');

      final str = descriptor.toString();
      expect(str, contains('podName'));
      expect(str, contains('methodName'));
    });

    test('should handle empty strings', () {
      final descriptor = FactoryMethodDesign('', '');

      expect(descriptor.podName, isEmpty);
      expect(descriptor.methodName, isEmpty);
    });

    test('should handle long names', () {
      final longPodName = 'a' * 1000;
      final longMethodName = 'b' * 1000;
      final descriptor = FactoryMethodDesign(longPodName, longMethodName);

      expect(descriptor.podName, hasLength(1000));
      expect(descriptor.methodName, hasLength(1000));
    });
  });
}