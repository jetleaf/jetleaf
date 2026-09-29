import 'package:jetleaf_lang/lang.dart';
import 'package:test/test.dart';
import 'test_data.dart';

class WithPrivate {
  WithPrivate._private();
}

class MultiParam {
  MultiParam(String a, int b);
}

class NoArgClass {
  NoArgClass();
}

class WithArgClass {
  WithArgClass(String arg);
}

class NamedClass {
  NamedClass({required String a, int? b});
}

class AnnotatedConstructor {
  @Deprecated('Use other constructor')
  AnnotatedConstructor();
}

class ConstClass {
  final String value;
  const ConstClass(this.value);
}

class NullablePositionalClass {
  NullablePositionalClass(String a, [int? b]);
}

class PositionalClass {
  final String a;
  final int b;
  PositionalClass(this.a, this.b);
}

@JetleafTest()
void main() {
  group('Constructor API', () {
    test('getConstructors() returns all constructors', () {
      final userClass = Class<TestUser>();
      final constructors = userClass.getConstructors();
      
      expect(constructors.length, greaterThanOrEqualTo(3));
    });
    
    test('getDefaultConstructor() returns default constructor', () {
      final userClass = Class<TestUser>();
      final constructor = userClass.getDefaultConstructor();
      
      expect(constructor, isNotNull);
      expect(constructor!.getName(), isEmpty);
    });
    
    test('getConstructor() finds named constructor', () {
      final userClass = Class<TestUser>();
      final constructor = userClass.getConstructor('anonymous');
      
      expect(constructor, isNotNull);
      expect(constructor!.getName(), 'anonymous');
    });
    
    test('getConstructorBySignature() with parameters', () {      
      final classApi = Class<MultiParam>();
      final constructor = classApi.getConstructorBySignature([Class<String>(), Class<int>()]);
      
      expect(constructor, isNotNull);
    });
    
    test('getNoArgConstructor() finds no-arg constructor', () {      
      final noArgClass = Class<NoArgClass>();
      final withArgClass = Class<WithArgClass>();
      
      expect(noArgClass.getNoArgConstructor(), isNotNull);
      expect(withArgClass.getNoArgConstructor(), isNull);
    });
    
    test('isFactory() identifies factory constructors', () {
      final userClass = Class<TestUser>();
      final constructors = userClass.getConstructors();
      final factoryConstructor = constructors.firstWhere((c) => c.getName() == 'fromJson');
      
      expect(factoryConstructor.isFactory(), isTrue);
    });
    
    test('isConst() identifies const constructors', () {      
      final classApi = Class<ConstClass>();
      final constructor = classApi.getDefaultConstructor();
      
      expect(constructor, isNotNull);
      expect(constructor!.isConst(), isTrue);
    });
    
    test('getParameters() returns constructor parameters', () {
      final userClass = Class<TestUser>();
      final constructor = userClass.getDefaultConstructor();
      
      expect(constructor, isNotNull);
      final parameters = constructor!.getParameters();
      
      expect(parameters.length, 2);
      expect(parameters.elementAt(0).getName(), 'name');
      expect(parameters.elementAt(0).getType(), String);
      expect(parameters.elementAt(1).getName(), 'age');
      expect(parameters.elementAt(1).getType(), int);
    });
    
    test('getParameterCount() returns correct count', () {
      final userClass = Class<TestUser>();
      final constructor = userClass.getDefaultConstructor();
      
      expect(constructor, isNotNull);
      expect(constructor!.getParameterCount(), 2);
    });
    
    test('getParameter() finds parameter by name', () {
      final userClass = Class<TestUser>();
      final constructor = userClass.getDefaultConstructor();
      
      expect(constructor, isNotNull);
      final parameter = constructor!.getParameter('name');
      
      expect(parameter, isNotNull);
      expect(parameter!.getName(), 'name');
    });
    
    test('getParameterAt() returns parameter by index', () {
      final userClass = Class<TestUser>();
      final constructor = userClass.getDefaultConstructor();
      
      expect(constructor, isNotNull);
      final parameter = constructor!.getParameterAt(0);
      
      expect(parameter, isNotNull);
      expect(parameter!.getName(), 'name');
    });
    
    test('getParameterTypes() returns parameter types', () {
      final userClass = Class<TestUser>();
      final constructor = userClass.getDefaultConstructor();
      
      expect(constructor, isNotNull);
      final types = constructor!.getParameterTypes();
      
      expect(types.length, 2);
      expect(types.elementAt(0).getSimpleName(), 'String');
      expect(types.elementAt(1).getSimpleName(), 'int');
    });
    
    test('newInstance() creates instance', () {
      final userClass = Class<TestUser>();
      final constructor = userClass.getDefaultConstructor();
      
      expect(constructor, isNotNull);
      final instance = constructor!.newInstance<TestUser>({'name': 'Alice', 'age': 30});
      
      expect(instance, isA<TestUser>());
      expect(instance.name, 'Alice');
      expect(instance.age, 30);
    });
    
    test('newInstance() with positional arguments', () {      
      final classApi = Class<PositionalClass>();
      final constructor = classApi.getDefaultConstructor();
      
      expect(constructor, isNotNull);
      final instance = constructor!.newInstance<PositionalClass>(null, ['test', 42]);
      
      expect(instance, isA<PositionalClass>());
      expect(instance.a, 'test');
      expect(instance.b, 42);
    });
    
    test('newInstance() with factory constructor', () {
      final userClass = Class<TestUser>();
      final constructor = userClass.getConstructor('fromJson');
      
      expect(constructor, isNotNull);
      final instance = constructor!.newInstance<TestUser>({}, [{
        'name': 'Bob',
        'age': 25
      }]);
      
      expect(instance, isA<TestUser>());
      expect(instance.name, 'Bob');
      expect(instance.age, 25);
    });
    
    test('newInstance() with const constructor', () {
      final classApi = Class<ConstClass>();
      final constructor = classApi.getDefaultConstructor();
      
      expect(constructor, isNotNull);
      final instance = constructor!.newInstance<ConstClass>({'value': 'const'});
      
      expect(instance, isA<ConstClass>());
      expect(instance.value, 'const');
    });
    
    test('getDeclaringClass() returns owning class', () {
      final userClass = Class<TestUser>();
      final constructor = userClass.getDefaultConstructor();
      
      expect(constructor, isNotNull);
      final declaringClass = constructor!.getDeclaringClass<TestUser>();
      expect(declaringClass.getSimpleName(), 'TestUser');
    });
    
    test('getReturnClass() returns class type', () {
      final userClass = Class<TestUser>();
      final constructor = userClass.getDefaultConstructor();
      
      expect(constructor, isNotNull);
      final returnClass = constructor!.getReturnClass();
      expect(returnClass.getSimpleName(), 'TestUser');
    });
    
    test('getReturnType() returns runtime type', () {
      final userClass = Class<TestUser>();
      final constructor = userClass.getDefaultConstructor();
      
      expect(constructor, isNotNull);
      expect(constructor!.getReturnType(), TestUser);
    });
    
    test('canAcceptArguments() checks compatibility', () {
      final userClass = Class<TestUser>();
      final constructor = userClass.getDefaultConstructor();
      
      expect(constructor, isNotNull);
      expect(constructor!.canAcceptArguments({'name': 'Alice', 'age': 30}), isTrue);
      expect(constructor.canAcceptArguments({'name': 'Bob'}), isFalse); // Missing age
    });
    
    test('canAcceptPositionalArguments() checks compatibility', () {      
      final classApi = Class<NullablePositionalClass>();
      final constructor = classApi.getDefaultConstructor();
      
      expect(constructor, isNotNull);
      expect(constructor!.canAcceptPositionalArguments(['test']), isTrue);
      expect(constructor.canAcceptPositionalArguments(['test', 42]), isTrue);
      expect(constructor.canAcceptPositionalArguments([]), isFalse); // Missing required
    });
    
    test('canAcceptNamedArguments() checks compatibility', () {      
      final classApi = Class<NamedClass>();
      final constructor = classApi.getDefaultConstructor();
      
      expect(constructor, isNotNull);
      expect(constructor!.canAcceptNamedArguments({'a': 'test'}), isTrue);
      expect(constructor.canAcceptNamedArguments({'a': 'test', 'b': 42}), isTrue);
      expect(constructor.canAcceptNamedArguments({'b': 42}), isFalse); // Missing required
    });
    
    test('getSignature() returns constructor signature', () {
      final userClass = Class<TestUser>();
      final constructor = userClass.getDefaultConstructor();
      
      expect(constructor, isNotNull);
      final signature = constructor!.getSignature();
      expect(signature, contains('TestUser'));
      expect(signature, contains('name'));
      expect(signature, contains('age'));
    });
    
    test('Constructor with annotations', () {      
      final classApi = Class<AnnotatedConstructor>();
      final constructor = classApi.getDefaultConstructor();
      
      expect(constructor, isNotNull);
      final annotations = constructor!.getAllDirectAnnotations();
      expect(annotations.length, greaterThanOrEqualTo(1));
    });
    
    test('Private constructor access', () {
      final classApi = Class<WithPrivate>();
      final constructors = classApi.getConstructors();
      
      // Should be able to see private constructors
      expect(constructors.length, greaterThanOrEqualTo(1));
    });
  });
}