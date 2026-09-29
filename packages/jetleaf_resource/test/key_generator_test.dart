import 'package:test/test.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_resource/jetleaf_resource.dart';
import 'package:jetleaf_resource/src/key_generator/simple_key.dart';

void main() {
  group('SimpleKeyGenerator', () {
    late SimpleKeyGenerator generator;

    setUp(() {
      generator = SimpleKeyGenerator();
    });

    test('should have equalizedProperties with runtimeType', () {
      final props = generator.equalizedProperties();
      expect(props, equals([SimpleKeyGenerator]));
    });

    test('should implement KeyGenerator interface', () {
      expect(generator, isA<KeyGenerator>());
    });
  });

  group('SimpleKey', () {
    test('EMPTY should be a singleton', () {
      expect(identical(SimpleKey.EMPTY, SimpleKey.EMPTY), isTrue);
    });

    test('EMPTY should have correct toString', () {
      expect(SimpleKey.EMPTY.toString(), equals('SimpleKey'));
    });

    test('should create with arguments', () {
      final args = ExecutableArgument.unmodified({'flag': true}, [42, 'hello']);
      final key = SimpleKey(args);
      final str = key.toString();
      expect(str, contains('SimpleKey('));
      expect(str, contains('42'));
      expect(str, contains('hello'));
      expect(str, contains('flag'));
    });

    test('should create without arguments', () {
      final key = SimpleKey();
      expect(key.toString(), equals('SimpleKey'));
    });

    test('should not equal EMPTY when has arguments', () {
      final args = ExecutableArgument.unmodified({}, [42]);
      final key = SimpleKey(args);
      expect(key, isNot(equals(SimpleKey.EMPTY)));
    });

    test('should have equalizedProperties', () {
      final args = ExecutableArgument.unmodified({}, [42]);
      final key = SimpleKey(args);
      final props = key.equalizedProperties();
      expect(props, contains(args));
      expect(props, contains(SimpleKey));
    });

    test('should have equalizedProperties for EMPTY', () {
      final props = SimpleKey.EMPTY.equalizedProperties();
      expect(props, contains(SimpleKey));
    });
  });

  group('ExecutableArgument', () {
    test('none should create empty argument', () {
      final args = ExecutableArgument.none();
      expect(args.getPositionalArguments(), isEmpty);
      expect(args.getNamedArguments(), isEmpty);
      expect(args.getSymbolizedNamedArguments(), isEmpty);
    });

    test('unmodified should create argument with positional and named', () {
      final args = ExecutableArgument.unmodified({'key': 'value'}, [1, 2]);
      expect(args.getPositionalArguments(), equals([1, 2]));
      expect(args.getNamedArguments(), equals({'key': 'value'}));
    });

    test('positional should create argument with only positional', () {
      final args = ExecutableArgument.positional([1, 2, 3]);
      expect(args.getPositionalArguments(), equals([1, 2, 3]));
      expect(args.getNamedArguments(), isEmpty);
    });

    test('named should create argument with only named', () {
      final args = ExecutableArgument.named({'a': 1, 'b': 2});
      expect(args.getPositionalArguments(), isEmpty);
      expect(args.getNamedArguments(), equals({'a': 1, 'b': 2}));
    });

    test('optional should default to none', () {
      final args = ExecutableArgument.optional();
      expect(args.getPositionalArguments(), isEmpty);
      expect(args.getNamedArguments(), isEmpty);
    });

    test('getArgument should retrieve positional by index', () {
      final args = ExecutableArgument.positional([10, 20, 30]);
      expect(args.getArgument(0, false), equals(10));
      expect(args.getArgument(1, false), equals(20));
      expect(args.getArgument(2, false), equals(30));
    });

    test('getArgument should retrieve named by key', () {
      final args = ExecutableArgument.named({'x': 42, 'y': 99});
      expect(args.getArgument('x', true), equals(42));
      expect(args.getArgument('y', true), equals(99));
    });
  });
}
