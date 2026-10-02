import 'package:jetleaf_env/env.dart';
import 'package:test/test.dart';

void main() {
  group('DefaultApplicationArguments', () {
    test('getSourceArgs returns raw args', () {
      final args = DefaultApplicationArguments(['--name=test', 'value']);
      expect(args.getSourceArgs(), equals(['--name=test', 'value']));
    });

    test('getOptionNames returns option names', () {
      final args = DefaultApplicationArguments(['--name=test', '--verbose']);
      final optionNames = args.getOptionNames();
      expect(optionNames, contains('name'));
      expect(optionNames, contains('verbose'));
    });

    test('containsOption returns true for existing option', () {
      final args = DefaultApplicationArguments(['--name=test']);
      expect(args.containsOption('name'), isTrue);
      expect(args.containsOption('other'), isFalse);
    });

    test('getOptionValues returns values for option', () {
      final args = DefaultApplicationArguments(['--name=test', '--name=again']);
      final values = args.getOptionValues('name');
      expect(values, equals(['test', 'again']));
    });

    test('getNonOptionArgs returns non-option arguments', () {
      final args = DefaultApplicationArguments(['--name=test', 'value1', 'value2']);
      final nonOptions = args.getNonOptionArgs();
      expect(nonOptions, contains('value1'));
      expect(nonOptions, contains('value2'));
    });
  });
}