import 'package:jetleaf_lang/jetleaf_lang.dart';
import 'package:test/test.dart';
import 'test_data.dart';

class Parent {
  String parentField = 'parent';
}

class Child extends Parent {
  String childField = 'child';
}

class NullableFields {
  String? nullable;
  String nonNullable = '';
}

class AnnotatedFields {
  @Deprecated('Use newField instead')
  final String oldField = 'old';
}

@JetleafTest()
void main() {
  group('Field API', () {
    test('getField() finds field by name', () {
      final dataClass = Class<DataClass>();
      final field = dataClass.getField('id');
      
      expect(field, isNotNull);
      expect(field!.getName(), 'id');
    });
    
    test('getFields() returns all fields', () {
      final dataClass = Class<DataClass>();
      final fields = dataClass.getFields();
      
      expect(fields.length, greaterThanOrEqualTo(4));
      expect(fields.any((f) => f.getName() == 'id'), isTrue);
      expect(fields.any((f) => f.getName() == 'name'), isTrue);
      expect(fields.any((f) => f.getName() == 'lateField'), isTrue);
    });
    
    test('isFinal() identifies final fields', () {
      final dataClass = Class<DataClass>();
      final field = dataClass.getField('id');
      
      expect(field, isNotNull);
      expect(field!.isFinal(), isTrue);
    });
    
    test('isStatic() identifies static fields', () {
      final dataClass = Class<DataClass>();
      final field = dataClass.getField('staticField');
      
      expect(field, isNotNull);
      expect(field!.isStatic(), isTrue);
    });
    
    test('isLate() identifies late fields', () {
      final dataClass = Class<DataClass>();
      final field = dataClass.getField('lateField');
      
      expect(field, isNotNull);
      expect(field!.isLate(), isTrue);
    });
    
    test('isConst() identifies const fields', () {
      final dataClass = Class<DataClass>();
      final field = dataClass.getField('constField');
      
      expect(field, isNotNull);
      expect(field!.isConst(), isTrue);
    });
    
    test('isNullable() checks nullability', () {      
      final classApi = Class<NullableFields>();
      final nullableField = classApi.getField('nullable');
      final nonNullableField = classApi.getField('nonNullable');
      
      expect(nullableField, isNotNull);
      expect(nullableField!.isNullable(), isTrue);
      
      expect(nonNullableField, isNotNull);
      expect(nonNullableField!.isNullable(), isFalse);
    });
    
    test('getType() returns field type', () {
      final dataClass = Class<DataClass>();
      final field = dataClass.getField('id');
      
      expect(field, isNotNull);
      expect(field!.getType(), String);
    });
    
    test('getClass() returns field type as Class', () {
      final dataClass = Class<DataClass>();
      final field = dataClass.getField('id');
      
      expect(field, isNotNull);
      final typeClass = field!.getReturnClass();
      expect(typeClass.getSimpleName(), 'String');
    });
    
    test('getValue() reads field value', () {
      final instance = DataClass('123', 'Test');
      final dataClass = Class<DataClass>();
      final field = dataClass.getField('id');
      
      expect(field, isNotNull);
      expect(field!.getValue(instance), '123');
    });
    
    test('getValue() for static fields', () {
      final dataClass = Class<DataClass>();
      final field = dataClass.getField('staticField');
      
      expect(field, isNotNull);
      expect(field!.getValue(null), 'static');
      expect(field.getValue(DataClass), 'static');
    });
    
    test('setValue() modifies field value', () {
      final instance = DataClass('123', 'Test');
      final dataClass = Class<DataClass>();
      final field = dataClass.getField('name');
      
      expect(field, isNotNull);
      expect(field!.isWritable(), isTrue);
      
      field.setValue(instance, 'New Name');
      expect(instance.name, 'New Name');
    });
    
    test('setValue() for static fields', () {
      final dataClass = Class<DataClass>();
      final field = dataClass.getField('staticField');
      
      expect(field, isNotNull);
      field!.setValue(null, 'new static');
      field.setValue(DataClass, 'new static');
      expect(DataClass.staticField, 'new static');
    });
    
    test('getValueAs() returns typed value', () {
      final instance = DataClass('123', 'Test');
      final dataClass = Class<DataClass>();
      final field = dataClass.getField('id');
      
      expect(field, isNotNull);
      final value = field!.getValueAs<String>(instance);
      expect(value, '123');
    });
    
    test('isReadable() checks readability', () {
      final dataClass = Class<DataClass>();
      final idField = dataClass.getField('id');
      final nameField = dataClass.getField('name');
      final staticField = dataClass.getField('staticField');
      
      expect(idField, isNotNull);
      expect(idField!.isReadable(), isTrue);
      
      expect(nameField, isNotNull);
      expect(nameField!.isReadable(), isTrue);
      
      expect(staticField, isNotNull);
      expect(staticField!.isReadable(), isTrue);
    });
    
    test('isWritable() checks writability', () {
      final dataClass = Class<DataClass>();
      final idField = dataClass.getField('id');
      final nameField = dataClass.getField('name');
      final constField = dataClass.getField('constField');
      
      expect(idField, isNotNull);
      expect(idField!.isWritable(), isFalse); // Final field
      
      expect(nameField, isNotNull);
      expect(nameField!.isWritable(), isTrue); // Mutable field
      
      expect(constField, isNotNull);
      expect(constField!.isWritable(), isFalse); // Const field
    });
    
    test('getDeclaringClass() returns owning class', () {
      final dataClass = Class<DataClass>();
      final field = dataClass.getField('id');
      
      expect(field, isNotNull);
      final declaringClass = field!.getDeclaringClass<DataClass>();
      expect(declaringClass.getSimpleName(), 'DataClass');
    });
    
    test('getParent() returns parent declaration', () {
      final dataClass = Class<DataClass>();
      final field = dataClass.getField('id');
      
      expect(field, isNotNull);
      final parent = field!.getParent();
      expect(parent, isNotNull);
    });
    
    test('getSignature() returns field signature', () {
      final dataClass = Class<DataClass>();
      final field = dataClass.getField('id');
      
      expect(field, isNotNull);
      final signature = field!.getSignature();
      expect(signature, contains('id'));
      expect(signature, contains('String'));
    });
    
    test('Enum field properties', () {
      final statusClass = Class<TestStatus>();
      final field = statusClass.getField('active');
      
      expect(field, isNotNull);
      expect(field!.isEnumField(), isTrue);
      expect(field.getValue(), TestStatus.active);
    });
    
    test('Late field initialization', () {
      final instance = DataClass('123', 'Test');
      final dataClass = Class<DataClass>();
      final field = dataClass.getField('lateField');
      
      expect(field, isNotNull);
      expect(field!.isLate(), isTrue);
      
      // Late fields can be set even if not initialized
      field.setValue(instance, 'late value');
      expect(instance.lateField, 'late value');
    });
    
    test('Field with annotations', () {
      final classApi = Class<AnnotatedFields>();
      final field = classApi.getField('oldField');
      
      expect(field, isNotNull);
      final annotations = field!.getAllDirectAnnotations();
      expect(annotations.length, greaterThanOrEqualTo(1));
    });
    
    test('Field inheritance', () {      
      final childClass = Class<Child>();
      final fields = childClass.getFields();
      
      // Should include both parent and child fields
      expect(fields.any((f) => f.getName() == 'parentField'), isTrue);
      expect(fields.any((f) => f.getName() == 'childField'), isTrue);
    });
  });
}