import 'package:test/test.dart';
import 'package:jetleaf_lang/lang.dart';

void main() {
  group('Stream', () {
    test('stream creates GenericStream from iterable', () {
      final stream = StreamSupport.stream([1, 2, 3]);
      expect(stream.toList(), [1, 2, 3]);
    });

    test('intStream creates IntStream from iterable', () {
      final stream = StreamSupport.intStream([4, 5, 6]);
      expect(stream.toList(), [4, 5, 6]);
    });

    test('doubleStream creates DoubleStream from iterable', () {
      final stream = StreamSupport.doubleStream([1.1, 2.2]);
      expect(stream.toList(), [1.1, 2.2]);
    });

    test('empty returns empty GenericStream', () {
      final stream = StreamSupport.empty<String>();
      expect(stream.toList(), isEmpty);
    });

    test('emptyIntStream returns empty IntStream', () {
      final stream = StreamSupport.emptyIntStream();
      expect(stream.toList(), isEmpty);
    });

    test('emptyDoubleStream returns empty DoubleStream', () {
      final stream = StreamSupport.emptyDoubleStream();
      expect(stream.toList(), isEmpty);
    });

    test('ofSingle returns stream with one item', () {
      final stream = StreamSupport.ofSingle('OnlyOne');
      expect(stream.toList(), ['OnlyOne']);
    });

    test('generate creates infinite stream with limit', () {
      int i = 0;
      final stream = StreamSupport.generate(() => ++i).limit(3);
      expect(stream.toList(), [1, 2, 3]);
    });

    test('iterate applies function repeatedly', () {
      final stream = StreamSupport.iterate(1, (n) => n * 2).limit(4);
      expect(stream.toList(), [1, 2, 4, 8]);
    });

    test('concat combines two streams', () {
      final a = GenericStream.of([1, 2]);
      final b = GenericStream.of([3, 4]);
      final stream = StreamSupport.concat(a, b);
      expect(stream.toList(), [1, 2, 3, 4]);
    });

    test('of creates stream from up to 5 values', () {
      final stream = StreamSupport.of('a', 'b', 'c');
      expect(stream.toList(), ['a', 'b', 'c']);
    });

    test('ofAll creates stream from list', () {
      final stream = StreamSupport.ofAll([10, 20, 30]);
      expect(stream.toList(), [10, 20, 30]);
    });

    test('builder creates stream via StreamBuilder', () {
      final stream = StreamSupport.builder<String>()
        ..add('one')
        ..add('two');
      final built = stream.build();
      expect(built.toList(), ['one', 'two']);
    });
  });
}