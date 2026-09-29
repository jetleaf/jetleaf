import 'package:test/test.dart';
import 'package:jetleaf/jetleaf.dart';

void main() {
  group('ApplicationImportSelector', () {
    test('should create instance', () {
      final selector = ApplicationImportSelector();
      expect(selector, isNotNull);
    });

    test('should implement ImportSelector', () {
      final selector = ApplicationImportSelector();
      expect(selector, isA<ImportSelector>());
    });
  });

  group('ApplicationContextFactory', () {
    test('should be abstract class', () {
      expect(ApplicationContextFactory, isA<Type>());
    });
  });

  group('DefaultApplicationContextFactory', () {
    test('should create instance', () {
      final factory = DefaultApplicationContextFactory();
      expect(factory, isNotNull);
    });

    test('should implement ApplicationContextFactory', () {
      final factory = DefaultApplicationContextFactory();
      expect(factory, isA<ApplicationContextFactory>());
    });
  });
}
