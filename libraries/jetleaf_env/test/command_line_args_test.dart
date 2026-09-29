import 'package:jetleaf_env/src/core/command_line_args.dart';
import 'package:test/test.dart';

void main() {
  group('CommandLineArgs', () {
    late CommandLineArgs args;

    setUp(() {
      args = CommandLineArgs();
    });

    test('add and retrieve option arguments', () {
      args.addOptionArg('foo', 'bar');
      args.addOptionArg('foo', 'baz');
      args.addOptionArg('alpha', 'beta');

      expect(args.containsOption('foo'), isTrue);
      expect(args.containsOption('alpha'), isTrue);
      expect(args.containsOption('none'), isFalse);

      expect(args.getOptionNames(), containsAll(['foo', 'alpha']));
      expect(args.getOptionValues('foo'), equals(['bar', 'baz']));
      expect(args.getOptionValues('alpha'), equals(['beta']));
    });

    test('add null option value', () {
      args.addOptionArg('key', null);

      expect(args.containsOption('key'), isTrue);
      expect(args.getOptionValues('key'), isEmpty);
    });

    test('add and retrieve non-option args', () {
      args.addNonOptionArg('input.txt');
      args.addNonOptionArg('config.json');

      final nonOpts = args.getNonOptionArgs();
      expect(nonOpts, equals(['input.txt', 'config.json']));
    });

    test('getNonOptionArgs is unmodifiable', () {
      args.addNonOptionArg('file.txt');
      final list = args.getNonOptionArgs();
      expect(() => list.add('fail.txt'), throwsUnsupportedError);
    });
  });
}