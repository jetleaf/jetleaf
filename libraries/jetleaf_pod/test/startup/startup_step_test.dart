// test/startup_step_test.dart
import 'package:jetleaf_pod/src/startup/startup.dart';
import 'package:test/test.dart';

void main() {
  group('StartupStep', () {
    test('DefaultStartupStep should have default values', () {
      final step = DefaultStartupStep();
      
      expect(step.name, equals('default'));
      expect(step.id, equals(0));
      expect(step.parentId, isNull);
      expect(step.tags, isA<StartupStepTags>());
    });

    test('DefaultStartupStep tag methods should return this', () {
      final step = DefaultStartupStep();
      
      final tagged = step.tag('key', value: 'value');
      expect(tagged, equals(step));
      
      final taggedWithSupplier = step.tag('key', supplied: () => 'value');
      expect(taggedWithSupplier, equals(step));
    });

    test('DefaultStartupStep end() should not throw', () {
      final step = DefaultStartupStep();
      expect(() => step.end(), returnsNormally);
    });

    test('DefaultStartupStep tags should be empty', () {
      final step = DefaultStartupStep();
      final tags = step.tags;
      
      expect(tags.isEmpty, isTrue);
      expect(tags.iterator.moveNext(), isFalse);
    });

    test('should handle multiple tag calls', () {
      final step = DefaultStartupStep();
      
      // Multiple calls should all return this and not affect state
      final step1 = step.tag('key1', value: 'value1');
      final step2 = step.tag('key2', value: 'value2');
      final step3 = step.tag('key3', supplied: () => 'value3');
      
      expect(step1, equals(step));
      expect(step2, equals(step));
      expect(step3, equals(step));
      expect(step.tags.isEmpty, isTrue);
    });

    test('should handle null and empty tag values', () {
      final step = DefaultStartupStep();
      
      final result1 = step.tag('', value: 'value');
      final result2 = step.tag('key', value: '');
      final result3 = step.tag('key', supplied: () => '');
      
      expect(result1, equals(step));
      expect(result2, equals(step));
      expect(result3, equals(step));
    });

    test('should handle multiple end() calls', () {
      final step = DefaultStartupStep();
      
      step.end();
      step.end();
      step.end();
      
      // Should not throw on multiple calls
      expect(() => step.end(), returnsNormally);
    });

    test('should work with iterator', () {
      final step = DefaultStartupStep();
      final tags = step.tags;
      
      int count = 0;
      for (final _ in tags) {
        count++;
      }
      
      expect(count, equals(0));
    });

    test('should handle toString', () {
      final step = DefaultStartupStep();
      
      expect(step.toString(), contains('DefaultStartupStep'));
      expect(step.toString(), contains('default'));
    });
  });
}