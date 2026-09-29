// ignore_for_file: deprecated_member_use_from_same_package

import 'package:jetleaf_lang/lang.dart' hide Version;
import 'package:test/test.dart';
import 'test_data.dart';

final class FinalTestClass {}

@JetleafTest()
void main() {
  group('Class API', () {
    test('Class<T>() constructor', () {
      final stringClass = Class<String>();
      expect(stringClass, isA<Class<String>>());
      expect(stringClass.getSimpleName(), 'String');
    });
    
    test('Class.forType<T>() factory', () {
      final intClass = Class.forType<int>(0);
      expect(intClass, isA<Class<int>>());
      expect(intClass.isPrimitive(), isTrue);
    });
    
    test('Class.forObject() with object', () {
      final obj = 'test string';
      final classApi = Class.forObject(obj);
      expect(classApi.getSimpleName(), 'String');
      expect(classApi.isInstance(obj), isTrue);
    });
    
    test('Class.forName() with primitive', () {
      final doubleClass = Class.forName<double>('double');
      expect(doubleClass.getSimpleName(), 'double');
      expect(doubleClass.isPrimitive(), isTrue);
    });
    
    test('Class.forName() with custom class', () {
      final userClass = Class.forName<TestUser>('TestUser');
      expect(userClass.getSimpleName(), 'TestUser');
      expect(userClass.isClass(), isTrue);
    });
    
    test('getSimpleName() returns simple name', () {
      expect(Class<TestUser>().getSimpleName(), 'TestUser');
      expect(Class<List<String>>().getSimpleName(), 'List<String>');
    });
    
    test('getCanonicalName() includes generic info', () {
      final listClass = Class<List<String>>();
      final canonicalName = listClass.getCanonicalName();
      expect(canonicalName, contains('List'));
      // May or may not include generic params depending on implementation
    });
    
    test('getPackageUri() for core types', () {
      expect(Class<String>().getPackageUri(), 'dart:core/string.dart');
    });
    
    test('getType() returns runtime Type', () {
      expect(Class<TestUser>().getType(), TestUser);
      expect(Class<int>().getType(), int);
    });
    
    test('isClass() for regular classes', () {
      expect(Class<TestUser>().isClass(), isTrue);
      expect(Class<TestService>().isClass(), isTrue);
    });
    
    test('isMixin() identifies mixins', () {
      expect(Class<TestLogger>().isMixin(), isTrue);
      expect(Class<TestValidator>().isMixin(), isTrue);
      expect(Class<TestUser>().isMixin(), isFalse);
    });
    
    test('isEnum() identifies enums', () {
      expect(Class<TestStatus>().isEnum(), isTrue);
      expect(Class<TestUser>().isEnum(), isFalse);
    });
    
    test('isAbstract() for abstract classes', () {
      expect(Class<TestComparable>().isAbstract(), isTrue);
      expect(Class<TestUser>().isAbstract(), isFalse);
    });
    
    test('isFinal() for final classes', () {
      final finalClass = Class<FinalTestClass>();
      expect(finalClass.isFinal(), isTrue);
    });
    
    test('isPrimitive() for primitive types', () {
      expect(Class<int>().isPrimitive(), isTrue);
      expect(Class<String>().isPrimitive(), isTrue);
      expect(Class<bool>().isPrimitive(), isTrue);
      expect(Class<double>().isPrimitive(), isTrue);
      expect(Class<TestUser>().isPrimitive(), isFalse);
    });
    
    test('isInstance() checks object type', () {
      final userClass = Class<TestUser>();
      final user = TestUser('Alice', 30);
      
      expect(userClass.isInstance(user), isTrue);
      expect(userClass.isInstance('not a user'), isFalse);
      expect(userClass.isInstance(null), isFalse);
    });
    
    test('isAssignableFrom() type compatibility', () {
      final objectClass = Class<Object>();
      final stringClass = Class<String>();
      final userClass = Class<TestUser>();
      
      expect(objectClass.isAssignableFrom(stringClass), isTrue);
      expect(objectClass.isAssignableFrom(userClass), isTrue);
      expect(stringClass.isAssignableFrom(objectClass), isFalse);
    });
    
    test('isAssignableTo() type compatibility', () {
      final objectClass = Class<Object>();
      final stringClass = Class<String>();
      
      expect(stringClass.isAssignableTo(objectClass), isTrue);
      expect(objectClass.isAssignableTo(stringClass), isFalse);
    });
    
    test('isSubclassOf() hierarchy check', () {
      final personClass = Class<TestPerson>();
      final employeeClass = Class<TestEmployee>();
      
      expect(employeeClass.isSubclassOf(personClass), isTrue);
      expect(personClass.isSubclassOf(employeeClass), isFalse);
    });
    
    test('getSuperClass() returns superclass', () {
      final employeeClass = Class<TestEmployee>();
      final superClass = employeeClass.getSuperClass<TestPerson>();
      
      expect(superClass, isNotNull);
      expect(superClass!.getSimpleName(), 'TestPerson');
    });
    
    test('getInterfaces() returns implemented interfaces', () {
      final productClass = Class<TestProduct>();
      final interfaces = productClass.getInterfaces<TestComparable>();
      
      expect(interfaces, isNotEmpty);
      expect(interfaces.first.getSimpleName(), 'TestComparable');
    });
    
    test('getAllInterfaces() includes all interfaces', () {
      final productClass = Class<TestProduct>();
      final allInterfaces = productClass.getAllInterfaces();
      
      expect(allInterfaces.length, greaterThanOrEqualTo(1));
    });
    
    test('getMixins() returns applied mixins', () {
      final serviceClass = Class<TestService>();
      final mixins = serviceClass.getMixins<TestLogger>();
      
      expect(mixins, isNotEmpty);
      expect(mixins.first.getSimpleName(), 'TestLogger');
    });
    
    test('getAllMixins() includes all mixins', () {
      final serviceClass = Class<TestService>();
      final allMixins = serviceClass.getAllMixins();
      
      expect(allMixins.length, greaterThanOrEqualTo(2));
      expect(allMixins.any((m) => m.getSimpleName() == 'TestLogger'), isTrue);
      expect(allMixins.any((m) => m.getSimpleName() == 'TestValidator'), isTrue);
    });
    
    test('getConstructors() returns all constructors', () {
      final userClass = Class<TestUser>();
      final constructors = userClass.getConstructors();
      
      expect(constructors.length, greaterThanOrEqualTo(3));
      expect(constructors.any((c) => c.getName().isEmpty), isTrue); // Default
      expect(constructors.any((c) => c.getName() == 'anonymous'), isTrue);
      expect(constructors.any((c) => c.getName() == 'fromJson'), isTrue);
    });
    
    test('getMethods() returns all methods', () {
      final userClass = Class<TestUser>();
      final methods = userClass.getMethods();
      
      expect(methods.length, greaterThanOrEqualTo(5));
      expect(methods.any((m) => m.getName() == 'greet'), isTrue);
      expect(methods.any((m) => m.getName() == 'greetAsync'), isTrue);
      expect(methods.any((m) => m.getName() == 'toString'), isTrue);
    });
    
    test('getFields() returns all fields', () {
      final dataClass = Class<DataClass>();
      final fields = dataClass.getFields();
      
      expect(fields.length, greaterThanOrEqualTo(4));
      expect(fields.any((f) => f.getName() == 'id'), isTrue);
      expect(fields.any((f) => f.getName() == 'name'), isTrue);
      expect(fields.any((f) => f.getName() == 'lateField'), isTrue);
    });
    
    test('getEnumValues() for enum classes', () {
      final statusClass = Class<TestStatus>();
      final values = statusClass.getEnumValues();
      
      expect(values.length, 3);
      expect(values.any((f) => f.getName() == 'active'), isTrue);
      expect(values.any((f) => f.getName() == 'inactive'), isTrue);
      expect(values.any((f) => f.getName() == 'pending'), isTrue);
    });

    test('getEnumValuesAsFields() for enum classes', () {
      final statusClass = Class<TestStatus>();
      final values = statusClass.getFields();
      
      expect(values.length, 5);
      expect(values.any((f) => f.getName() == 'active'), isTrue);
      expect(values.any((f) => f.getName() == 'inactive'), isTrue);
      expect(values.any((f) => f.getName() == 'pending'), isTrue);
    });
    
    test('newInstance() creates instances', () {
      final userClass = Class<TestUser>();
      final user = userClass.newInstance({'name': 'Bob', 'age': 25});
      
      expect(user, isA<TestUser>());
      expect(user.name, 'Bob');
      expect(user.age, 25);
    });
    
    test('newInstance() with named constructor', () {
      final userClass = Class<TestUser>();
      final user = userClass.newInstance({}, 'anonymous');
      
      expect(user, isA<TestUser>());
      expect(user.name, 'Anonymous');
      expect(user.age, 0);
    });
    
    test('ClassExtension.getClass() on objects', () {
      final user = TestUser('Charlie', 40);
      final userClass = user.getClass();
      
      expect(userClass.getSimpleName(), 'TestUser');
      expect(userClass.isInstance(user), isTrue);
    });
    
    test('getAnnotation() finds annotations', () {
      final serviceClass = Class<AnnotatedService>();
      final todoAnnotation = serviceClass.getAnnotation<Todo>();
      
      expect(todoAnnotation, isNotNull);
    });
    
    test('hasAnnotation() checks annotation presence', () {
      final serviceClass = Class<AnnotatedService>();
      
      expect(serviceClass.hasAnnotation<Todo>(), isTrue);
      expect(serviceClass.hasAnnotation<Version>(), isTrue);
    });
    
    test('getAllAnnotations() returns all annotations', () {
      final serviceClass = Class<AnnotatedService>();
      final annotations = serviceClass.getAllAnnotations();
      
      expect(annotations.length, greaterThanOrEqualTo(2));
    });
    
    test('hasGenerics() detects generic types', () {
      expect(Class<List<String>>().hasGenerics(), isTrue);
      expect(Class<Map<String, int>>().hasGenerics(), isTrue);
      expect(Class<TestUser>().hasGenerics(), isFalse);
    });
    
    test('isArray() for List types', () {
      expect(Class<List>().isArray(), isTrue);
      expect(Class<List<String>>().isArray(), isTrue);
      expect(Class<TestUser>().isArray(), isFalse);
    });
    
    test('isKeyValuePaired() for Map types', () {
      expect(Class<Map>().isKeyValuePaired(), isTrue);
      expect(Class<Map<String, int>>().isKeyValuePaired(), isTrue);
      expect(Class<TestUser>().isKeyValuePaired(), isFalse);
    });
    
    test('componentType() for generic collections', () {
      final listClass = Class<List<String>>();
      final component = listClass.componentType<String>();
      
      expect(component, isNotNull);
      expect(component!.getSimpleName(), 'String');
    });
    
    test('keyType() and componentType() for Maps', () {
      final mapClass = Class<Map<String, int>>();
      final keyType = mapClass.keyType<String>();
      final valueType = mapClass.componentType<int>();
      
      expect(keyType, isNotNull);
      expect(keyType!.getSimpleName(), 'String');
      
      expect(valueType, isNotNull);
      expect(valueType!.getSimpleName(), 'int');

      final keyedType = mapClass.keyType();
      final valuedType = mapClass.componentType();
      
      expect(keyedType, isNotNull);
      expect(keyedType!.getType(), String);
      
      expect(valuedType, isNotNull);
      expect(valuedType!.getType(), int);
    });
  });

  group("IsInstance in a List", () {
    test("Check list data", () {
      final result = ["1", "2", "3", "4"];
      final list = Class<List>();

      print(list.isInstance(result));
    });
  });

  group('Diagnostic: Subclass lookup', () {
    test('check Runtime.getSubClasses vs manual DFS', () {
      final baseClass = Class<UserClassBase>();
      final subClassesViaAPI = baseClass.getSubClasses().toList();

      print('Subclasses returned by Class API for UserClassBase:');
      for (var c in subClassesViaAPI) {
        print('- ${c.getQualifiedName()}');
      }

      // At least 4 (FirstBase, SecondBase, ThirdUnrelated, Unrelated);
      // more may appear when running via all_tests.dart with a shared cache.
      expect(subClassesViaAPI.length, greaterThanOrEqualTo(4));
    });

    test('check Runtime.getSubClasses vs manual DFS', () {
      final baseClass = Class<Closeable>();
      final subClassesViaAPI = baseClass.getSubClasses().toList();

      print('Subclasses returned by Class API for Closeable:');
      for (var c in subClassesViaAPI) {
        print('- ${c.getQualifiedName()}');
      }
    });

    test('check Runtime.getSubClasses vs manual DFS', () {
      final baseClass = Class<InputStream>();
      final subClassesViaAPI = baseClass.getSubClasses().toList();

      print('Subclasses returned by Class API for InputStream:');
      for (var c in subClassesViaAPI) {
        print('- ${c.getQualifiedName()}');
      }
    });

    test('check Runtime.getSubClasses vs manual DFS', () {
      final baseClass = Class<String>();
      final subClassesViaAPI = baseClass.getSubClasses().toList();

      print('Subclasses returned by Class API for String:');
      for (var c in subClassesViaAPI) {
        print('- ${c.getQualifiedName()}');
      }
    });
  });
}