import 'package:test/test.dart';
import 'package:jetleaf/jetleaf.dart';
import 'package:scanner_app/scanner_app.dart';

void main() {
  group('ScannerApp Tests (Zero AOT Registrar)', () {
    test('boots successfully via runScan fallback when no AOT registrar is provided', () async {
      final app = JetleafApplication(const ScannerApp());

      // Verify app.getSystem() is null before create()
      expect(app.getSystem(), isNull);

      // Explicitly run without an AOT registrar
      final context = await app.create(
        ['--jetleaf.application.type=cli'],
        null,
      );

      expect(context, isNotNull);
      // Verify app.getSystem() is populated after create()
      expect(app.getSystem(), isNotNull);

      final greeter = await context!.getPod<ScannerGreeterService>('scannerGreeterService');
      expect(greeter, isNotNull);
      expect(greeter.greet('Dart'), 'Hello from Scanner-discovered service, Dart!');

      final runner = await context.getPod<ScannerTaskRunner>('scannerTaskRunner');
      expect(runner, isNotNull);

      await context.close();
    });
  });
}