import 'package:jetleaf_lang/lang.dart';
import 'package:test/test.dart';
import 'test_data.dart';

class Service {
  ClassType<TestUser> getUserType() => ClassType<TestUser>();
}

@JetleafTest()
void main() {
  group('ClassType API', () {
    test('ClassType<T>() constructor', () {
      final classType = ClassType<String>();
      expect(classType, isA<ClassType<String>>());
    });
    
    test('ClassType.named() factory', () {
      final classType = ClassType.named('TestUser', 'test_data.dart');
      expect(classType.name, 'TestUser');
      expect(classType.package, 'test_data.dart');
    });
    
    test('ClassType.qualified() factory', () {
      final classType = ClassType.qualified('package:test/test_data.dart.TestUser');
      expect(classType.qualifiedName, 'package:test/test_data.dart.TestUser');
    });
    
    test('ClassType.declared() factory', () {
      final userClass = Class<TestUser>();
      final declaration = userClass.getClassDeclaration();
      final classType = ClassType.declared(declaration);
      
      expect(classType.declaration, declaration);
    });
    
    test('toClass() converts to Class instance', () {
      final classType = ClassType<TestUser>();
      final classApi = classType.toClass();
      
      expect(classApi, isA<Class<TestUser>>());
      expect(classApi.getSimpleName(), 'TestUser');
    });
    
    test('toClass() from named type', () {
      const classType = ClassType<TestUser>.named('TestUser', 'test_data.dart');
      final classApi = classType.toClass();
      
      expect(classApi, isA<Class<TestUser>>());
      expect(classApi.getSimpleName(), 'TestUser');
    });
    
    test('toClass() from declaration', () {
      final userClass = Class<TestUser>();
      final declaration = userClass.getClassDeclaration();
      final classType = ClassType.declared(declaration);
      final classApi = classType.toClass();
      
      expect(classApi.getSimpleName(), 'TestUser');
    });
    
    test('getType() returns runtime type', () {
      final classType = ClassType<TestUser>();
      expect(classType.getType(), TestUser);
    });
    
    test('Equality based on properties', () {
      final type1 = ClassType<TestUser>();
      final type2 = ClassType<TestUser>();
      final type3 = ClassType<String>();
      
      // Should be equal if same type
      expect(type1, equals(type2));
      expect(type1, isNot(equals(type3)));
    });
    
    test('ClassType with protection domain', () {
      final pd = ProtectionDomain.system();
      final classType = ClassType<TestUser>(null, null, pd);
      
      expect(classType.pd, pd);
      final classApi = classType.toClass();
      expect(classApi.getProtectionDomain(), pd);
    });
    
    test('ClassType for primitive types', () {
      final intType = ClassType<int>();
      final intClass = intType.toClass();
      
      expect(intClass.getSimpleName(), 'int');
      expect(intClass.isPrimitive(), isTrue);
    });
    
    test('ClassType for generic types', () {
      final listType = ClassType<List<String>>();
      final listClass = listType.toClass();
      
      expect(listClass.getSimpleName(), 'List<String>');
      expect(listClass.hasGenerics(), isTrue);
    });
    
    test('ClassType as method return type', () {      
      final service = Service();
      final classType = service.getUserType();
      final classApi = classType.toClass();
      
      expect(classApi.getSimpleName(), 'TestUser');
    });
    
    test('ClassType in collections', () {
      final types = <ClassType>[
        ClassType<String>(),
        ClassType<int>(),
        ClassType<TestUser>(),
      ];
      
      expect(types.length, 3);
      expect(types[0].getType(), String);
      expect(types[1].getType(), int);
      expect(types[2].getType(), TestUser);
    });
    
    test('ClassType with link declaration', () {
      final userClass = Class<TestUser>();
      final declaration = userClass.getClassDeclaration();
      
      // This would typically come from build system
      final classType = ClassType.declared(declaration);
      expect(classType.declaration, declaration);
    });
    
    test('ClassType toString representation', () {
      final classType = ClassType<TestUser>();
      final str = classType.toString();
      
      expect(str, contains('ClassType'));
      expect(str, contains('TestUser'));
    });
  });
}