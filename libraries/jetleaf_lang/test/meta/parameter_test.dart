import 'package:jetleaf_lang/lang.dart';
import 'package:test/test.dart';

class TestClass {
  void method({
    int intDefault = 42,
    String stringDefault = 'hello',
    bool boolDefault = true,
    double doubleDefault = 3.14,
    List<String> listDefault = const ['a', 'b'],
  }) {}
}

class AnnotatedTestClass {
  void method(@Deprecated('old param') String param) {}
}

class MemberedTestClass {
  void method(String param) {}
}

class OrderedTestClass {
  void method(String a, int b, bool c) {}
}

class SignatureTestClass {
  void method(String param) {}
}

class MixedTestClass {
  void method(
    String required,
    String? optional,
    {String named = 'default'}
  ) {}
}

class ConstructorTestClass {
  final String field;
  ConstructorTestClass(this.field);
}

class SimpleTestClass {
  void method(String requiredParam) {}
}

class OptionalTestClass {
  void method([String? optionalParam]) {}
}

class NamedTestClass {
  void method({String namedParam = 'default'}) {}
}

class RequiredTestClass {
  void method({required String requiredNamed}) {}
}

class MultipleTestClass {
  void method1(String? nullable) {} // Nullable but required
  void method2([String? optional]) {} // Optional and nullable
  void method3({String? named}) {} // Named and nullable
}

class GenericTestClass<T> {
  void method(T genericParam) {}
}

@JetleafTest()
void main() {
  group('Parameter API', () {
    test('Parameter properties for required positional', () {      
      final classApi = Class<SimpleTestClass>();
      final method = classApi.getMethod('method');
      
      expect(method, isNotNull);
      final parameters = method!.getParameters();
      expect(parameters.length, 1);
      
      final param = parameters.elementAt(0);
      expect(param.getName(), 'requiredParam');
      expect(param.getType(), String);
      expect(param.getReturnClass().getSimpleName(), 'String');
      expect(param.getIndex(), 0);
      expect(param.isRequired(), isTrue);
      expect(param.isOptional(), isFalse);
      expect(param.isNamed(), isFalse);
      expect(param.isPositional(), isTrue);
      expect(param.isNullable(), isFalse);
      expect(param.hasDefaultValue(), isFalse);
    });
    
    test('Parameter properties for optional positional', () {      
      final classApi = Class<OptionalTestClass>();
      final method = classApi.getMethod('method');
      
      expect(method, isNotNull);
      final parameters = method!.getParameters();
      expect(parameters.length, 1);
      
      final param = parameters.elementAt(0);
      expect(param.getName(), 'optionalParam');
      expect(param.getType(), String);
      expect(param.isRequired(), isFalse);
      expect(param.isOptional(), isTrue);
      expect(param.isNamed(), isFalse);
      expect(param.isPositional(), isTrue);
      expect(param.isNullable(), isTrue);
      expect(param.hasDefaultValue(), isFalse);
    });
    
    test('Parameter properties for named parameter', () {      
      final classApi = Class<NamedTestClass>();
      final method = classApi.getMethod('method');
      
      expect(method, isNotNull);
      final parameters = method!.getParameters();
      expect(parameters.length, 1);
      
      final param = parameters.elementAt(0);
      expect(param.getName(), 'namedParam');
      expect(param.getType(), String);
      expect(param.isRequired(), isFalse);
      expect(param.isOptional(), isTrue);
      expect(param.isNamed(), isTrue);
      expect(param.isPositional(), isFalse);
      expect(param.isNullable(), isFalse);
      expect(param.hasDefaultValue(), isTrue);
      expect(param.getDefaultValue(), 'default');
    });
    
    test('Parameter properties for required named parameter', () {      
      final classApi = Class<RequiredTestClass>();
      final method = classApi.getMethod('method');
      
      expect(method, isNotNull);
      final parameters = method!.getParameters();
      expect(parameters.length, 1);
      
      final param = parameters.elementAt(0);
      expect(param.getName(), 'requiredNamed');
      expect(param.getType(), String);
      expect(param.isRequired(), isTrue);
      expect(param.isOptional(), isFalse);
      expect(param.isNamed(), isTrue);
      expect(param.isPositional(), isFalse);
      expect(param.isNullable(), isFalse);
      expect(param.hasDefaultValue(), isFalse);
    });
    
    test('getMember() returns owning method', () {      
      final classApi = Class<MemberedTestClass>();
      final method = classApi.getMethod('method');
      
      expect(method, isNotNull);
      final parameters = method!.getParameters();
      final param = parameters.elementAt(0);
      
      expect(param.getMember(), method);
    });
    
    test('Parameter with annotations', () {      
      final classApi = Class<AnnotatedTestClass>();
      final method = classApi.getMethod('method');
      
      expect(method, isNotNull);
      final parameters = method!.getParameters();
      final param = parameters.elementAt(0);
      
      final annotations = param.getAllDirectAnnotations();
      expect(annotations.length, greaterThanOrEqualTo(1));
    });
    
    test('getSignature() returns parameter signature', () {      
      final classApi = Class<SignatureTestClass>();
      final method = classApi.getMethod('method');
      
      expect(method, isNotNull);
      final parameters = method!.getParameters();
      final param = parameters.elementAt(0);
      
      final signature = param.getSignature();
      expect(signature, contains('param'));
      expect(signature, contains('String'));
    });
    
    test('Parameter ordering', () {      
      final classApi = Class<OrderedTestClass>();
      final method = classApi.getMethod('method');
      
      expect(method, isNotNull);
      final parameters = method!.getParameters();
      
      expect(parameters.length, 3);
      expect(parameters.elementAt(0).getName(), 'a');
      expect(parameters.elementAt(0).getIndex(), 0);
      expect(parameters.elementAt(1).getName(), 'b');
      expect(parameters.elementAt(1).getIndex(), 1);
      expect(parameters.elementAt(2).getName(), 'c');
      expect(parameters.elementAt(2).getIndex(), 2);
    });
    
    test('Mixed parameter types', () {      
      final classApi = Class<MixedTestClass>();
      final method = classApi.getMethod('method');
      
      expect(method, isNotNull);
      final parameters = method!.getParameters();
      
      expect(parameters.length, 3);
      
      final requiredParam = parameters.elementAt(0);
      expect(requiredParam.getName(), 'required');
      expect(requiredParam.isPositional(), isTrue);
      expect(requiredParam.isNamed(), isFalse);
      
      final optionalParam = parameters.elementAt(1);
      expect(optionalParam.getName(), 'optional');
      expect(optionalParam.isPositional(), isTrue);
      expect(optionalParam.isNamed(), isFalse);
      
      final namedParam = parameters.elementAt(2);
      expect(namedParam.getName(), 'named');
      expect(namedParam.isPositional(), isFalse);
      expect(namedParam.isNamed(), isTrue);
    });
    
    test('Constructor parameters', () {      
      final classApi = Class<ConstructorTestClass>();
      final constructor = classApi.getDefaultConstructor();
      
      expect(constructor, isNotNull);
      final parameters = constructor!.getParameters();
      
      expect(parameters.length, 1);
      final param = parameters.elementAt(0);
      expect(param.getName(), 'field');
      expect(param.getType(), String);
      expect(param.getMember(), constructor);
    });
    
    test('Generic type parameters', () {      
      final classApi = Class<GenericTestClass<String>>();
      final method = classApi.getMethod('method');
      
      expect(method, isNotNull);
      final parameters = method!.getParameters();
      
      expect(parameters.length, 1);
      final param = parameters.elementAt(0);
      expect(param.getName(), 'genericParam');
      // Type should be resolved to String
    });
    
    test('Nullable vs optional distinction', () {      
      final classApi = Class<MultipleTestClass>();
      
      final method1 = classApi.getMethod('method1');
      expect(method1, isNotNull);
      final param1 = method1!.getParameters().elementAt(0);
      expect(param1.isNullable(), isTrue);
      expect(param1.isOptional(), isFalse);
      
      final method2 = classApi.getMethod('method2');
      expect(method2, isNotNull);
      final param2 = method2!.getParameters().elementAt(0);
      expect(param2.isNullable(), isTrue);
      expect(param2.isOptional(), isTrue);
      
      final method3 = classApi.getMethod('method3');
      expect(method3, isNotNull);
      final param3 = method3!.getParameters().elementAt(0);
      expect(param3.isNullable(), isTrue);
      expect(param3.isOptional(), isTrue);
    });
    
    test('Default value types', () {      
      final classApi = Class<TestClass>();
      final method = classApi.getMethod('method');
      
      expect(method, isNotNull);
      final parameters = method!.getParameters();
      
      for (final param in parameters) {
        expect(param.hasDefaultValue(), isTrue);
        expect(param.getDefaultValue(), isNotNull);
      }
    });
  });
}