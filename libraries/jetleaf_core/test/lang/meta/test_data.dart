// test_data.dart
import 'package:jetleaf_core/_jetleaf/test/registry.g.dart' show registerTestGeneratedArtifacts;

/// Registers the test-only AOT registry. Call at the start of tests that
/// rely on annotation materialisation; loading this library alone does not
/// force initialisation (library-level laziness), but `main()` should
/// `await ensureTestAotRegistered()` before exercising reflective paths.
Future<void> ensureTestAotRegistered() => registerTestGeneratedArtifacts();

/// Initialises the generated test registry synchronously.
///
/// `registerTestGeneratedArtifacts()` runs `_initRuntime()` before its first
/// suspension point, so calling it without `await` initialises the registry
/// immediately. Test files use this from a synchronous `main()` so that all
/// groups are declared before any test starts running.
void ensureTestAotRegisteredSync() {
  registerTestGeneratedArtifacts();
}


// For basic class tests
class TestUser {
  final String name;
  final int age;
  
  TestUser(this.name, this.age);
  
  TestUser.anonymous() : this('Anonymous', 0);
  
  factory TestUser.fromJson(Map<String, dynamic> json) => 
      TestUser(json['name'] as String, json['age'] as int);
  
  String greet() => 'Hello, I am $name';
  
  Future<String> greetAsync() async => 'Hello async, I am $name';
  
  // Getter and setter
  String get description => '$name ($age years)';
  set description(String value) => {}; // No-op for testing
  
  static String staticMethod() => 'Static method';
  
  @override
  String toString() => 'User(name: $name, age: $age)';
}

// For inheritance tests
class TestPerson {
  final String name;
  
  TestPerson(this.name);
}

class TestEmployee extends TestPerson {
  final String department;
  
  TestEmployee(super.name, this.department);
}

// For interface tests
abstract class TestComparable<T> {
  int compareTo(T other);
}

class TestProduct implements TestComparable<TestProduct> {
  final String id;
  final double price;
  
  TestProduct(this.id, this.price);
  
  @override
  int compareTo(TestProduct other) => price.compareTo(other.price);
}

// For enum tests
enum TestStatus {
  active,
  inactive,
  pending;
  
  String get description => name.toUpperCase();
}

// For mixin tests
mixin TestLogger {
  void log(String message) => print('LOG: $message');
}

mixin TestValidator {
  bool validate(String input) => input.isNotEmpty;
}

class TestService with TestLogger, TestValidator {
  void process(String input) {
    if (validate(input)) {
      log('Processing: $input');
    }
  }
}

// For annotation tests
class Todo {
  final String task;
  const Todo(this.task);
}

class Version {
  final String number;
  const Version(this.number);
}

@Todo('Refactor this class')
@Version('1.0.0')
class AnnotatedService {
  @Deprecated('Use newMethod instead')
  void oldMethod() {}
  
  void newMethod() {}
}

// For record-like structure (though records are different)
class Point {
  final double x;
  final double y;
  
  const Point(this.x, this.y);
}

// For field tests
class DataClass {
  final String id;
  String name;
  late String lateField;
  static String staticField = 'static';
  static const String constField = 'const';
  static final String me = "";
  
  DataClass(this.id, this.name);
  
  String get uppercaseName => name.toUpperCase();
  set uppercaseName(String value) => name = value.toLowerCase();
}

abstract class UserClassBase {}
abstract class FirstBase extends UserClassBase {}
abstract class SecondBase extends FirstBase {}
abstract class ThirdUnrelated extends SecondBase {}
abstract class Unrelated extends ThirdUnrelated {}