import 'package:jetleaf_monitor/jetleaf_monitor.dart';
import 'package:test/test.dart';

void main() {
  group('Monitor Annotation', () {
    test('should create with no name', () {
      const monitor = Monitor();
      expect(monitor.name, isNull);
    });

    test('should create with a name', () {
      const monitor = Monitor('UserService.save');
      expect(monitor.name, equals('UserService.save'));
    });

    test('should return Monitor as annotationType', () {
      const monitor = Monitor('test');
      expect(monitor.annotationType, equals(Monitor));
    });

    test('should return Monitor as annotationType when no name', () {
      const monitor = Monitor();
      expect(monitor.annotationType, equals(Monitor));
    });

    test('should be a ReflectableAnnotation', () {
      const monitor = Monitor();
      // Monitor extends ReflectableAnnotation
      expect(monitor.annotationType, isNotNull);
    });

    test('should preserve name across instances', () {
      const m1 = Monitor('alpha');
      const m2 = Monitor('beta');
      const m3 = Monitor();

      expect(m1.name, equals('alpha'));
      expect(m2.name, equals('beta'));
      expect(m3.name, isNull);
    });

    test('should support long names', () {
      const monitor = Monitor('com.example.package.MyClass.myMethod');
      expect(monitor.name, equals('com.example.package.MyClass.myMethod'));
    });

    test('should support empty string name', () {
      const monitor = Monitor('');
      expect(monitor.name, equals(''));
    });
  });
}
