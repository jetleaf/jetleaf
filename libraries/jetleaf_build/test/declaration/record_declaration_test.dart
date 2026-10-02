import 'package:test/test.dart';
import 'package:jetleaf_build/jetleaf_build.dart';

// Simple record types
typedef SimpleRecord = (String, int);
typedef NamedRecord = ({String name, int age});
typedef MixedRecord = (String, int, {bool isActive});

// Generic record types
typedef GenericRecord<T> = (T value, String label);

// Record as function return type
typedef ResultRecord<T> = ({T? value, String? error, bool success});

// Record with default values in extension
extension RecordExtensions on (String, int) {
  String get description => 'Record(${$1}, ${$2})';
  bool get isPositive => $2 > 0;
}

extension NamedRecordExtensions on ({String name, int age}) {
  bool get isAdult => age >= 18;
  String get greeting => 'Hello, $name!';
}

// Classes using records
class RecordUser {
  final SimpleRecord data;
  
  RecordUser(this.data);
  
  String get description => 'RecordUser with ${data.$1} and ${data.$2}';
}

class GenericRecordProcessor<T> {
  final GenericRecord<T> record;
  
  GenericRecordProcessor(this.record);
  
  String process() => '${record.$2}: ${record.$1}';
}

// Functions using records
SimpleRecord createSimpleRecord(String text, int number) {
  return (text, number);
}

NamedRecord createNamedRecord(String name, int age) {
  return (name: name, age: age);
}

({T? value, String? error}) safeParse<T>(T Function(String) parser, String input) {
  try {
    return (value: parser(input), error: null);
  } catch (e) {
    return (value: null, error: e.toString());
  }
}

// Pattern matching with records
String describeRecord(dynamic record) {
  return switch (record) {
    (String name, int age) => 'Tuple: $name is $age years old',
    (: String name, : int age) => 'Named: $name is $age years old',
    _ => 'Unknown record type',
  };
}

// Record with private field (in extension)
extension PrivateRecordExtension on (String, int) {
  String _privateFormat() => '[${$1}:${$2}]';
  String publicFormat() => _privateFormat().toUpperCase();
}

@JetleafTest()
void main() async {
  group('RecordDeclaration Basic Properties', () {
    test('should find RecordUser class in runtime', () {
      final recordUserClass = Runtime.findClass<RecordUser>();
      expect(recordUserClass, isNotNull);
      expect(recordUserClass.getName(), equals('RecordUser'));
    });

    test('should find GenericRecordProcessor class in runtime', () {
      final processorClass = Runtime.findClass<GenericRecordProcessor>();
      expect(processorClass, isNotNull);
    });
  });

  group('RecordDeclaration Usage', () {
    test('should demonstrate record creation and access', () {
      final simple = ('hello', 42);
      expect(simple.$1, equals('hello'));
      expect(simple.$2, equals(42));
      
      final named = (name: 'Alice', age: 30);
      expect(named.name, equals('Alice'));
      expect(named.age, equals(30));
      
      final mixed = ('Bob', 25, isActive: true);
      expect(mixed.$1, equals('Bob'));
      expect(mixed.$2, equals(25));
      expect(mixed.isActive, equals(true));
    });

    test('should demonstrate pattern matching with records', () {
      final simple = ('Charlie', 40);
      final description = describeRecord(simple);
      expect(description, contains('Tuple'));
      expect(description, contains('Charlie'));
      expect(description, contains('40'));
      
      final named = (name: 'Diana', age: 35);
      final namedDescription = describeRecord(named);
      expect(namedDescription, contains('Named'));
      expect(namedDescription, contains('Diana'));
    });

    test('should demonstrate records in function returns', () {
      final result = safeParse<int>(int.parse, '42');
      expect(result.value, equals(42));
      expect(result.error, isNull);
      
      final errorResult = safeParse<int>(int.parse, 'not a number');
      expect(errorResult.value, isNull);
      expect(errorResult.error, isNotNull);
    });

    test('should create simple record via function', () {
      final record = createSimpleRecord('test', 10);
      expect(record.$1, equals('test'));
      expect(record.$2, equals(10));
    });

    test('should create named record via function', () {
      final record = createNamedRecord('Eve', 20);
      expect(record.name, equals('Eve'));
      expect(record.age, equals(20));
    });
  });

  group('RecordDeclaration Extensions', () {
    test('should demonstrate record extensions', () {
      final record = ('test', 10);
      expect(record.description, equals('Record(test, 10)'));
      expect(record.isPositive, isTrue);
      
      final named = (name: 'Eve', age: 20);
      expect(named.isAdult, isTrue);
      expect(named.greeting, equals('Hello, Eve!'));
    });

    test('should handle private members in record extensions', () {
      final record = ('private', 99);
      expect(record.publicFormat(), equals('[PRIVATE:99]'));
    });
  });

  group('RecordDeclaration Complex Records', () {
    test('should handle nested records', () {
      final simple = ('basic', 1);
      final named = (name: 'person', age: 2);
      final nested = (simple, named);
      
      expect(nested.$1.$1, equals('basic'));
      expect(nested.$1.$2, equals(1));
      expect(nested.$2.name, equals('person'));
      expect(nested.$2.age, equals(2));
    });

    test('should handle generic records', () {
      final generic = GenericRecordProcessor<int>((42, 'answer'));
      expect(generic.process(), equals('answer: 42'));
      
      final stringProcessor = GenericRecordProcessor<String>(('hello', 'greeting'));
      expect(stringProcessor.process(), equals('greeting: hello'));
    });

    test('should handle mixed positional and named fields', () {
      final mixed = ('hello', 42, isActive: true);
      expect(mixed.$1, equals('hello'));
      expect(mixed.$2, equals(42));
      expect(mixed.isActive, isTrue);
    });
  });
}
