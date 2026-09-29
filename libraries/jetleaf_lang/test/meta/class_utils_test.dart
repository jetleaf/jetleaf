import 'package:jetleaf_lang/lang.dart';
import 'package:test/test.dart';

@JetleafTest()
void main() {
  group('ClassUtils Tests', () {
    group('getClassHierarchy', () {
      test('should return hierarchy for basic class', () {
        final stringClass = Class.forType(String);
        final hierarchy = ClassUtils.getClassHierarchy(stringClass);
        
        expect(hierarchy, isNotEmpty);
        expect(hierarchy.first, equals(stringClass));
        expect(hierarchy.any((c) => c.getType() == Object), isTrue);
      });

      test('should handle Object class', () {
        final objectClass = Class.forType(Object);
        final hierarchy = ClassUtils.getClassHierarchy(objectClass);
        
        expect(hierarchy, isNotEmpty);
        expect(hierarchy.first, equals(objectClass));
      });

      test('should handle array types', () {
        final listClass = Class.forType(List);
        final hierarchy = ClassUtils.getClassHierarchy(listClass);
        
        expect(hierarchy, isNotEmpty);
        expect(hierarchy.first, equals(listClass));
      });

      test('should handle enum types', () {
        final enumClass = Class<Enum>();
        final hierarchy = ClassUtils.getClassHierarchy(enumClass);
        
        expect(hierarchy, isNotEmpty);
        expect(hierarchy.any((c) => c.getType() == Enum), isTrue);
        expect(hierarchy.any((c) => c.getType() == Object), isTrue);
      });

      test('should not add duplicate classes', () {
        final stringClass = Class.forType(String);
        final hierarchy = ClassUtils.getClassHierarchy(stringClass);
        
        final uniqueTypes = hierarchy.map((c) => c.getType()).toSet();
        expect(hierarchy.length, equals(uniqueTypes.length));
      });

      test('should handle null superclass gracefully', () {
        final objectClass = Class.forType(Object);
        final hierarchy = ClassUtils.getClassHierarchy(objectClass);
        
        expect(hierarchy, isNotEmpty);
        expect(() => ClassUtils.getClassHierarchy(objectClass), returnsNormally);
      });

      test('should include interfaces in hierarchy', () {
        final stringClass = Class.forType(String);
        final hierarchy = ClassUtils.getClassHierarchy(stringClass);
        
        // Should include Object and potentially other interfaces
        expect(hierarchy.length, greaterThan(1));
      });

      test('should handle complex inheritance chains', () {
        final intClass = Class.forType(int);
        final hierarchy = ClassUtils.getClassHierarchy(intClass);
        
        expect(hierarchy, isNotEmpty);
        expect(hierarchy.first, equals(intClass));
        expect(hierarchy.any((c) => c.getType() == Object), isTrue);
      });

      test('should handle generic list types', () {
        final listStringClass = Class.forType(List<String>);
        final hierarchy = ClassUtils.getClassHierarchy(listStringClass);
        
        expect(hierarchy, isNotEmpty);
        expect(hierarchy.any((c) => c.getType() == Object), isTrue);
      });

      test('should maintain proper ordering in hierarchy', () {
        final stringClass = Class.forType(String);
        final hierarchy = ClassUtils.getClassHierarchy(stringClass);
        print(hierarchy);
        
        expect(hierarchy.first, equals(stringClass));
        expect(hierarchy.last.getType(), equals(Object));
      });
    });

    group('Edge Cases', () {
      test('should handle very deep inheritance chains', () {
        final deepClass = Class.forType(String);
        expect(() => ClassUtils.getClassHierarchy(deepClass), returnsNormally);
      });

      test('should handle circular references safely', () {
        final testClass = Class.forType(Map);
        expect(() => ClassUtils.getClassHierarchy(testClass), returnsNormally);
      });

      test('should handle primitive types', () {
        final primitiveTypes = [int, double, bool, String];
        
        for (final type in primitiveTypes) {
          final clazz = Class.forType(type);
          final hierarchy = ClassUtils.getClassHierarchy(clazz);
          
          expect(hierarchy, isNotEmpty);
          expect(hierarchy.first.getType(), equals(type));
        }
      });

      test('should handle collection types', () {
        final collectionTypes = [List, Set, Map, Iterable];
        
        for (final type in collectionTypes) {
          final clazz = Class.forType(type);

          final hierarchy = ClassUtils.getClassHierarchy(clazz);
          
          expect(hierarchy, isNotEmpty);
          expect(hierarchy.first.getType(), equals(type));
        }
      });

      test('should handle function types', () {
        final functionClass = Class.forType(Function);
        final hierarchy = ClassUtils.getClassHierarchy(functionClass);
        
        expect(hierarchy, isNotEmpty);
        expect(hierarchy.first.getType(), equals(Function));
      });
    });
  });
}