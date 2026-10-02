import 'package:jetleaf_cli/src/common/spinner.dart';
import 'package:test/test.dart';

void main() {
  group('Spinner', () {
    test('should create with message', () {
      final spinner = Spinner('Loading...');
      expect(spinner.message, equals('Loading...'));
    });

    test('should start without error', () {
      final spinner = Spinner('Processing...');
      spinner.start();
      spinner.stop();
    });

    test('should stop without error', () {
      final spinner = Spinner('Processing...');
      spinner.stop();
    });

    test('should stop with success message', () {
      final spinner = Spinner('Processing...');
      spinner.start();
      spinner.stop(successMessage: 'Done!');
    });

    test('should stop without having started', () {
      final spinner = Spinner('Processing...');
      spinner.stop();
    });

    test('should not start twice', () {
      final spinner = Spinner('Processing...');
      spinner.start();
      spinner.start(); // Should not throw
      spinner.stop();
    });

    test('should stop without having started (no-op)', () {
      final spinner = Spinner('Processing...');
      spinner.stop(); // Should not throw
    });
  });
}
