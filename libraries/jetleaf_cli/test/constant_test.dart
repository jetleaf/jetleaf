import 'package:jetleaf_cli/src/common/constant.dart';
import 'package:test/test.dart';

void main() {
  group('CliConstant', () {
    test('should have correct DEV_FLAG', () {
      expect(CliConstant.DEV_FLAG, equals('--jetleaf-dev'));
    });

    test('should have correct DEV_HOT_RELOAD_FLAG', () {
      expect(CliConstant.DEV_HOT_RELOAD_FLAG, equals('--watch'));
    });

    test('should have correct DEV_HOT_RELOAD_FLAG_NEGATION', () {
      expect(CliConstant.DEV_HOT_RELOAD_FLAG_NEGATION, equals('--no-watch'));
    });
  });
}
