import 'package:jetleaf_lang/lang.dart';
import 'package:test/test.dart';
import 'test_data.dart';

class WithNullable {
  String? nullableMethod() => null;
  String nonNullableMethod() => '';
}

class DynamicReturn {
  dynamic getValue() => null;
}

class WithParams {
  void method(String param1, int param2) {}
}

class WithNullableParams {
  void method(String name, {int? age}) {}
}

class WithParamsAgain {
  void method(String a, int b, bool c) {}
}

class Calculator {
  int add(int a, int b) => a + b;
}

class Parent {
  void method() {}
}

class Child extends Parent {
  @override
  void method() {}
}

@JetleafTest()
void main() {
  group('Method API', () {
    test('getMethod() finds method by name', () {
      final userClass = Class<TestUser>();
      final method = userClass.getMethod('greet');
      
      expect(method, isNotNull);
      expect(method!.getName(), 'greet');
    });
    
    test('getMethodBySignature() with parameters', () {
      final userClass = Class<TestUser>();
      final method = userClass.getMethodBySignature(
        'greet',
        [] // No parameters
      );
      
      expect(method, isNotNull);
      expect(method!.getName(), 'greet');
    });
    
    test('getMethods() returns all methods', () {
      final userClass = Class<TestUser>();
      final methods = userClass.getMethods();
      
      expect(methods.length, greaterThanOrEqualTo(6));
      expect(methods.any((m) => m.getName() == 'greet'), isTrue);
      expect(methods.any((m) => m.getName() == 'greetAsync'), isTrue);
      expect(methods.any((m) => m.getName() == 'toString'), isTrue);
    });
    
    test('isStatic() identifies static methods', () {
      final userClass = Class<TestUser>();
      final method = userClass.getMethod('staticMethod');
      
      expect(method, isNotNull);
      expect(method!.isStatic(), isTrue);
    });
    
    test('isGetter() and isSetter() identify properties', () {
      final userClass = Class<TestUser>();
      final getter = userClass.getMethod('description');
      final setter = userClass.getMethod('description=');
      
      expect(getter, isNotNull);
      expect(getter!.isGetter(), isTrue);
      
      expect(setter, isNotNull);
      expect(setter!.isSetter(), isTrue);
    });
    
    test('isAbstract() for abstract methods', () {
      final comparableClass = Class<TestComparable>();
      final methods = comparableClass.getMethods();
      final compareMethod = methods.firstWhere((m) => m.getName() == 'compareTo');
      
      expect(compareMethod.isAbstract(), isTrue);
    });
    
    test('isVoid() identifies void methods', () {
      final serviceClass = Class<TestService>();
      final method = serviceClass.getMethod('process');
      print(method);
      
      expect(method, isNotNull);
      expect(method!.isVoid(), isTrue);
    });
    
    test('isAsync() identifies async methods', () {
      final userClass = Class<TestUser>();
      final method = userClass.getMethod('greetAsync');
      
      expect(method, isNotNull);
      expect(method!.isAsync(), isTrue);
    });
    
    test('isDynamic() for dynamic return types', () {
      final classApi = Class<DynamicReturn>();
      final method = classApi.getMethod('getValue');
      
      expect(method, isNotNull);
      expect(method!.isDynamic(), isTrue);
    });
    
    test('getReturnType() returns correct type', () {
      final userClass = Class<TestUser>();
      final method = userClass.getMethod('greet');
      
      expect(method, isNotNull);
      expect(method!.getReturnType(), String);
    });
    
    test('getReturnClass() returns Class instance', () {
      final userClass = Class<TestUser>();
      final method = userClass.getMethod('greet');
      
      expect(method, isNotNull);
      final returnClass = method!.getReturnClass();
      expect(returnClass.getSimpleName(), 'String');
    });
    
    test('getParameters() returns method parameters', () {
      final classApi = Class<WithParams>();
      final method = classApi.getMethod('method');
      
      expect(method, isNotNull);
      final params = method!.getParameters();
      expect(params.length, 2);
      expect(params.elementAt(0).getName(), 'param1');
      expect(params.elementAt(0).getType(), String);
      expect(params.elementAt(1).getName(), 'param2');
      expect(params.elementAt(1).getType(), int);
    });
    
    test('getParameterCount() returns correct count', () {
      final classApi = Class<WithParamsAgain>();
      final method = classApi.getMethod('method');
      
      expect(method, isNotNull);
      expect(method!.getParameterCount(), 3);
    });
    
    test('invoke() calls method with named arguments', () {
      final user = TestUser('Alice', 30);
      final userClass = Class<TestUser>();
      final method = userClass.getMethod('greet');
      
      expect(method, isNotNull);
      final result = method!.invoke(user);
      expect(result, 'Hello, I am Alice');
    });
    
    test('invoke() with positional arguments', () {
      final calc = Calculator();
      final classApi = Class<Calculator>();
      final method = classApi.getMethod('add');
      
      expect(method, isNotNull);
      final result = method!.invoke(calc, null, [5, 3]);
      expect(result, 8);
    });
    
    test('invoke() async method', () async {
      final user = TestUser('Bob', 25);
      final userClass = Class<TestUser>();
      final method = userClass.getMethod('greetAsync');
      
      expect(method, isNotNull);
      final result = method!.invoke(user);
      expect(result, isA<Future>());
      expect(await result, 'Hello async, I am Bob');
    });
    
    test('isOverride() detects overridden methods', () {
      final childClass = Class<Child>();
      final method = childClass.getMethod('method');
      
      expect(method, isNotNull);
      expect(method!.isOverride(), isTrue);
    });
    
    test('getOverriddenMethod() returns super method', () {
      final childClass = Class<Child>();
      final method = childClass.getMethod('method');
      
      expect(method, isNotNull);
      final overridden = method!.getOverriddenMethod();
      expect(overridden, isNotNull);
    });
    
    test('canAcceptArguments() checks parameter compatibility', () {
      final classApi = Class<WithNullableParams>();
      final method = classApi.getMethod('method');
      
      expect(method, isNotNull);
      expect(method!.canAcceptArguments({'name': 'Alice'}), isTrue);
      expect(method.canAcceptArguments({'name': 'Bob', 'age': 30}), isTrue);
      expect(method.canAcceptArguments({'age': 30}), isFalse); // Missing required
    });
    
    test('getSignature() returns method signature', () {
      final userClass = Class<TestUser>();
      final method = userClass.getMethod('greet');
      
      expect(method, isNotNull);
      final signature = method!.getSignature();
      expect(signature, contains('greet'));
      expect(signature, contains('String'));
    });
    
    test('hasNullableReturn() checks return nullability', () {
      final classApi = Class<WithNullable>();
      final nullableMethod = classApi.getMethod('nullableMethod');
      final nonNullableMethod = classApi.getMethod('nonNullableMethod');
      
      expect(nullableMethod, isNotNull);
      expect(nullableMethod!.hasNullableReturn(), isTrue);
      
      expect(nonNullableMethod, isNotNull);
      expect(nonNullableMethod!.hasNullableReturn(), isFalse);
    });
    
    test('getDeclaringClass() returns owning class', () {
      final userClass = Class<TestUser>();
      final method = userClass.getMethod('greet');
      
      expect(method, isNotNull);
      final declaringClass = method!.getDeclaringClass<TestUser>();
      expect(declaringClass.getSimpleName(), 'TestUser');
    });
  });
}