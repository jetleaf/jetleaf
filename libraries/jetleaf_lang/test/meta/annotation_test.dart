// ignore_for_file: deprecated_member_use_from_same_package

import 'package:jetleaf_lang/lang.dart' hide Version;
import 'package:test/test.dart';
import 'test_data.dart';

class ComplexAnnotation {
  final String name;
  final int count;
  final bool flag;
  const ComplexAnnotation(this.name, {this.count = 0, this.flag = true});
}

@ComplexAnnotation('test', count: 5, flag: false)
class ComplexClass {}

@Todo('task1')
@Todo('task2')
class MultiTodo {}

@Todo('custom task')
class CustomTodo {}

class DefaultAnnotation {
  final String field;
  const DefaultAnnotation([this.field = 'default']);
}

@DefaultAnnotation()
class WithDefault {}

@Todo('my task')
class MyTodo {}

@Todo('explicit task')
class ExplicitTodo {}

@Todo('complete task')
class CompleteTodo {}

class AnnotatedField {
  @Deprecated('old field')
  final String oldField = 'value';
}

class AnnotatedParam {
  void method(@Deprecated('old param') String param) {}
}

@Todo('task1')
@Version('1.0')
@Deprecated('Use new class')
class MultiAnnotated {}

@Todo('parent task')
class Parent {}

class Child extends Parent {}

@JetleafTest()
void main() {
  group('Annotation API', () {
    test('getAnnotation() finds annotation', () {
      final serviceClass = Class<AnnotatedService>();
      final annotation = serviceClass.getAnnotation<Todo>();
      
      expect(annotation, isNotNull);
    });
    
    test('getAnnotations() finds all of type', () {
      final classApi = Class<MultiTodo>();
      final annotations = classApi.getAnnotations<Todo>();
      
      expect(annotations.length, greaterThanOrEqualTo(2));
    });
    
    test('getAllAnnotations() returns all annotations', () {
      final serviceClass = Class<AnnotatedService>();
      final annotations = serviceClass.getAllAnnotations();
      
      expect(annotations.length, greaterThanOrEqualTo(2));
    });
    
    test('hasAnnotation() checks presence', () {
      final serviceClass = Class<AnnotatedService>();
      
      expect(serviceClass.hasAnnotation<Todo>(), isTrue);
      expect(serviceClass.hasAnnotation<Version>(), isTrue);
    });
    
    test('getType() returns annotation type', () {
      final serviceClass = Class<AnnotatedService>();
      final annotation = serviceClass.getAnnotation<Todo>();
      
      expect(annotation, isNotNull);
      expect(annotation.runtimeType, Todo);
    });
    
    test('getClass() returns Class instance', () {
      final serviceClass = Class<AnnotatedService>();
      final annotation = serviceClass.getAnnotation<Todo>();
      
      expect(annotation, isNotNull);
      final annotationClass = annotation!.getClass();
      expect(annotationClass.getSimpleName(), 'Todo');
    });
    
    test('matches() type checking', () {
      final serviceClass = Class<AnnotatedService>();
      final annotation = serviceClass.getAllAnnotations();
      print(serviceClass.getAllAnnotations());
      
      expect(annotation, isNotNull);
      expect(annotation.any((ann) => ann.matches<Todo>()), isTrue);
      expect(annotation.any((ann) => ann.matches<Version>()), isTrue);
      expect(annotation.any((ann) => ann.matches<DefaultAnnotation>()), isFalse);
    });
    
    test('getFieldNames() returns field names', () {
      final serviceClass = Class<AnnotatedService>();
      final annotation = serviceClass.getAllAnnotations().firstWhereOrNull((ann) => ann.matches<Todo>());
      
      expect(annotation, isNotNull);
      final fieldNames = annotation!.getFieldNames();
      expect(fieldNames, contains('task'));
    });
    
    test('getFieldValue() returns field value', () {
      final serviceClass = Class<AnnotatedService>();
      final annotation = serviceClass.getAllAnnotations().firstWhereOrNull((ann) => ann.matches<Todo>());
      
      expect(annotation, isNotNull);
      final value = annotation!.getFieldValue('task');
      expect(value, 'Refactor this class');
    });
    
    test('getFieldValueAs() typed access', () {
      final serviceClass = Class<AnnotatedService>();
      final annotation = serviceClass.getAllAnnotations().firstWhereOrNull((ann) => ann.matches<Todo>());
      
      expect(annotation, isNotNull);
      final value = annotation!.getFieldValueAs<String>('task');
      expect(value, 'Refactor this class');
    });
    
    test('hasField() checks field existence', () {
      final serviceClass = Class<AnnotatedService>();
      final annotation = serviceClass.getAllAnnotations().firstWhereOrNull((ann) => ann.matches<Todo>());
      
      expect(annotation, isNotNull);
      expect(annotation!.hasField('task'), isTrue);
      expect(annotation.hasField('nonExistent'), isFalse);
    });
    
    test('hasUserProvidedValue() vs hasDefaultValue()', () {
      final classApi = Class<CustomTodo>();
      final annotation = classApi.getAllAnnotations().firstWhereOrNull((ann) => ann.matches<Todo>());
      
      expect(annotation, isNotNull);
      // 'task' field was user-provided
      expect(annotation!.hasUserProvidedValue('task'), isTrue);
    });
    
    test('getDefaultValue() returns default', () {      
      final classApi = Class<WithDefault>();
      final annotation = classApi.getAllAnnotations().firstWhereOrNull((ann) => ann.matches<DefaultAnnotation>());
      
      expect(annotation, isNotNull);
      expect(annotation!.getDefaultValue('field'), 'default');
    });
    
    test('getUserProvidedValue() returns explicit value', () {      
      final classApi = Class<ExplicitTodo>();
      final annotation = classApi.getAllAnnotations().firstWhereOrNull((ann) => ann.matches<Todo>());
      
      expect(annotation, isNotNull);
      expect(annotation!.getUserProvidedValue('task'), 'explicit task');
    });
    
    test('getUserProvidedValues() returns map', () {
      final classApi = Class<MyTodo>();
      final annotation = classApi.getAllAnnotations().firstWhereOrNull((ann) => ann.matches<Todo>());
      
      expect(annotation, isNotNull);
      final values = annotation!.getUserProvidedValues();
      expect(values['task'], 'my task');
    });
    
    test('getAllFieldValues() returns complete map', () {      
      final classApi = Class<CompleteTodo>();
      final annotation = classApi.getAllAnnotations().firstWhereOrNull((ann) => ann.matches<Todo>());
      
      expect(annotation, isNotNull);
      final allValues = annotation!.getAllFieldValues();
      expect(allValues['task'], 'complete task');
    });
    
    test('getInstance() returns annotation instance', () {
      final serviceClass = Class<AnnotatedService>();
      final annotation = serviceClass.getAllAnnotations().firstWhereOrNull((ann) => ann.matches<Todo>());
      
      expect(annotation, isNotNull);
      final instance = annotation!.getInstance<Todo>();
      expect(instance, isA<Todo>());
      expect(instance.task, 'Refactor this class');
    });
    
    test('getSignature() returns annotation signature', () {
      final serviceClass = Class<AnnotatedService>();
      final annotation = serviceClass.getAllAnnotations().firstWhereOrNull((ann) => ann.matches<Todo>());
      
      expect(annotation, isNotNull);
      final signature = annotation!.getSignature();
      expect(signature, contains('Todo'));
      expect(signature, contains('Refactor this class'));
    });
    
    test('Annotation on methods', () {
      final serviceClass = Class<AnnotatedService>();
      final method = serviceClass.getMethod('oldMethod');
      
      expect(method, isNotNull);
      final annotation = method!.getAllDirectAnnotations().firstWhereOrNull((ann) => ann.matches<Deprecated>());
      
      expect(annotation, isNotNull);
      expect(annotation!.getFieldValue('message'), 'Use newMethod instead');
    });
    
    test('Annotation on fields', () {      
      final classApi = Class<AnnotatedField>();
      final field = classApi.getField('oldField');
      
      expect(field, isNotNull);
      final annotations = field!.getAllDirectAnnotations();
      expect(annotations.length, greaterThanOrEqualTo(1));
    });
    
    test('Annotation on parameters', () {      
      final classApi = Class<AnnotatedParam>();
      final method = classApi.getMethod('method');
      
      expect(method, isNotNull);
      final parameters = method!.getParameters();
      final param = parameters.elementAt(0);
      
      final annotations = param.getAllDirectAnnotations();
      expect(annotations.length, greaterThanOrEqualTo(1));
    });
    
    test('Multiple annotations', () {      
      final classApi = Class<MultiAnnotated>();
      final annotations = classApi.getAllAnnotations();
      
      expect(annotations.length, greaterThanOrEqualTo(3));
    });
    
    test('Annotation inheritance', () {      
      final childClass = Class<Child>();
      final annotations = childClass.getAllAnnotations();
      
      // Should inherit parent annotations
      expect(annotations.length, greaterThanOrEqualTo(1));
    });
    
    test('Custom annotation with multiple fields', () {      
      final classApi = Class<ComplexClass>();
      final annotation = classApi.getAllAnnotations().firstWhereOrNull((ann) => ann.matches<ComplexAnnotation>());
      
      expect(annotation, isNotNull);
      expect(annotation!.getFieldValue('name'), 'test');
      expect(annotation.getFieldValue('count'), 5);
      expect(annotation.getFieldValue('flag'), false);
    });
  });
}