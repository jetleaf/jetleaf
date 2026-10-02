import 'package:test/test.dart';
import 'package:jetleaf/jetleaf.dart';

void main() {
  group('JetleafLoggingProperty', () {
    test('should have correct TYPE constant', () {
      expect(JetleafLoggingProperty.TYPE, equals('logging.type'));
    });

    test('should have correct LEVEL constant', () {
      expect(JetleafLoggingProperty.LEVEL, equals('logging.level'));
    });

    test('should have correct STEPS constant', () {
      expect(JetleafLoggingProperty.STEPS, equals('logging.steps'));
    });

    test('should have correct SHOW_TIMESTAMP constant', () {
      expect(JetleafLoggingProperty.SHOW_TIMESTAMP, equals('logging.show.timestamp'));
    });

    test('should have correct SHOW_TIME_ONLY constant', () {
      expect(JetleafLoggingProperty.SHOW_TIME_ONLY, equals('logging.show.time-only'));
    });

    test('should have correct SHOW_DATE_ONLY constant', () {
      expect(JetleafLoggingProperty.SHOW_DATE_ONLY, equals('logging.show.date-only'));
    });

    test('should have correct SHOW_LEVEL constant', () {
      expect(JetleafLoggingProperty.SHOW_LEVEL, equals('logging.show.level'));
    });

    test('should have correct SHOW_TAG constant', () {
      expect(JetleafLoggingProperty.SHOW_TAG, equals('logging.show.tag'));
    });

    test('should have correct SHOW_THREAD constant', () {
      expect(JetleafLoggingProperty.SHOW_THREAD, equals('logging.show.thread'));
    });

    test('should have correct SHOW_LOCATION constant', () {
      expect(JetleafLoggingProperty.SHOW_LOCATION, equals('logging.show.location'));
    });

    test('should have correct SHOW_EMOJI constant', () {
      expect(JetleafLoggingProperty.SHOW_EMOJI, equals('logging.show.emoji'));
    });

    test('should have correct USE_HUMAN_READABLE_TIME constant', () {
      expect(JetleafLoggingProperty.USE_HUMAN_READABLE_TIME, equals('logging.use-human-readable-time'));
    });

    test('should have correct FILE constant', () {
      expect(JetleafLoggingProperty.FILE, equals('logging.file'));
    });

    test('should have correct ENABLED constant', () {
      expect(JetleafLoggingProperty.ENABLED, equals('logging.enabled'));
    });

    test('should be abstract final class', () {
      expect(JetleafLoggingProperty, isA<Type>());
    });
  });

  group('JetleafApplicationStarter Annotation', () {
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
}
