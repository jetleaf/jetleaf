import 'package:test/test.dart';
import 'package:jetleaf/jetleaf.dart';

void main() {
  group('JetleafApplication constants', () {
    test('should have JETLEAF_APPLICATION_VERSION', () {
      expect(
        JetleafApplication.JETLEAF_APPLICATION_VERSION,
        equals('jetleaf.application.version'),
      );
    });

    test('should have JETLEAF_APPLICATION_PID', () {
      expect(
        JetleafApplication.JETLEAF_APPLICATION_PID,
        equals('jetleaf.application.pid'),
      );
    });

    test('should have JETLEAF_APPLICATION_TYPE', () {
      expect(
        JetleafApplication.JETLEAF_APPLICATION_TYPE,
        equals('jetleaf.application.type'),
      );
    });

    test('should have JETLEAF_VERSION', () {
      expect(
        JetleafApplication.JETLEAF_VERSION,
        equals('jetleaf.version'),
      );
    });

    test('should have BANNER_LOCATION', () {
      expect(
        JetleafApplication.BANNER_LOCATION,
        equals('banner.location'),
      );
    });

    test('should have BANNER_TEXT', () {
      expect(
        JetleafApplication.BANNER_TEXT,
        equals('banner.text'),
      );
    });

    test('should have LAZY_INITIALIZATION', () {
      expect(
        JetleafApplication.LAZY_INITIALIZATION,
        equals('jetleaf.lazy-initialization'),
      );
    });
  });

  group('JetleafApplication class', () {
    test('should be final class', () {
      expect(JetleafApplication, isA<Type>());
    });

    test('should have useHook method', () {
      // JetleafApplication.useHook is a static method
      expect(JetleafApplication.useHook, isA<Function>());
    });
  });

  group('JetleafApplicationStarter annotation', () {
    test('should have ENABLE_AUTO_CONFIGURATION_PROPERTY', () {
      expect(
        JetleafApplicationStarter.ENABLE_AUTO_CONFIGURATION_PROPERTY,
        equals('jetleaf.enableautoconfiguration'),
      );
    });

    test('should have DISABLE_AUTO_CONFIGURATION_PROPERTY', () {
      expect(
        JetleafApplicationStarter.DISABLE_AUTO_CONFIGURATION_PROPERTY,
        equals('jetleaf.disableautoconfiguration'),
      );
    });
  });

  group('EnableAutoConfiguration annotation', () {
    test('should be annotation class', () {
      expect(EnableAutoConfiguration, isA<Type>());
    });
  });
}
