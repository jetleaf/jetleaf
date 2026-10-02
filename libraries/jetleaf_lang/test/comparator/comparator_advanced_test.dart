import 'package:test/test.dart';
import 'package:jetleaf_lang/lang.dart';

class Person implements Comparable<Person> {
  final String name;
  final int age;

  Person(this.name, this.age);

  @override
  int compareTo(Person other) => name.compareTo(other.name);

  @override
  String toString() => 'Person(name: $name, age: $age)';
}

void main() {
  final people = [
    Person('Alice', 30),
    Person('Bob', 25),
    Person('Charlie', 35),
    Person('David', 25),
    Person('Eve', 30),
  ];

  test('Sort by natural order (name)', () {
    final sorted = List<Person>.from(people)..sort(Comparator.naturalOrder().compare);
    expect(sorted.map((p) => p.name), ['Alice', 'Bob', 'Charlie', 'David', 'Eve']);
  });

  test('Sort by reverse natural order (name)', () {
    final sorted = List<Person>.from(people)..sort(Comparator.reverseOrder().compare);
    expect(sorted.map((p) => p.name), ['Eve', 'David', 'Charlie', 'Bob', 'Alice']);
  });

  test('Sort by age', () {
    final sorted = List<Person>.from(people)
      ..sort(Comparator.comparing<Person, Integer>((p) => Integer(p.age)).compare);
    expect(sorted.map((p) => p.age), [25, 25, 30, 30, 35]);
  });

  test('Sort by age (reversed)', () {
    final sorted = List<Person>.from(people)
      ..sort(Comparator.comparing<Person, Integer>((p) => Integer(p.age)).reversed().compare);
    expect(sorted.map((p) => p.age), [35, 30, 30, 25, 25]);
  });

  test('Sort by age, then by name', () {
    final sorted = List<Person>.from(people)
      ..sort(Comparator.comparing<Person, Integer>((p) => Integer(p.age))
          .thenComparing(Comparator.naturalOrder())
          .compare);
    expect(sorted.map((p) => p.name), ['Bob', 'David', 'Alice', 'Eve', 'Charlie']);
  });

  test('Sort by age (reversed), then by name', () {
    final sorted = List<Person>.from(people)
      ..sort(Comparator.comparing<Person, Integer>((p) => Integer(p.age))
          .reversed()
          .thenComparing(Comparator.naturalOrder())
          .compare);
    expect(sorted.map((p) => p.name), ['Charlie', 'Alice', 'Eve', 'Bob', 'David']);
  });

  test('Sort by name length, then name alphabetically', () {
    final sorted = List<Person>.from(people)
      ..sort(Comparator.comparing<Person, Integer>((p) => Integer(p.name.length))
          .thenComparing(Comparator.naturalOrder())
          .compare);
    expect(sorted.map((p) => p.name), ['Bob', 'Eve', 'Alice', 'David', 'Charlie']);
  });
}