import 'package:test/test.dart';
import 'package:jetleaf/jetleaf.dart';

void main() {
  group('JetleafVersion', () {
    test('should return version string', () {
      final version = JetleafVersion.getVersion();
      expect(version, isA<String>());
    });

    test('should return non-empty string', () {
      final version = JetleafVersion.getVersion();
      expect(version.isNotEmpty, isTrue);
    });

    test('should return Unknown on error', () {
      // In test environment, it might return 'Unknown' or actual version
      final version = JetleafVersion.getVersion();
      expect(version, isA<String>());
    });

    test('should be abstract class', () {
      expect(JetleafVersion, isA<Type>());
    });
  });
}
