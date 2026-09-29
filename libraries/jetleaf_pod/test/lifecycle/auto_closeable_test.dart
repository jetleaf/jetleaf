// test/auto_closeable_test.dart
import 'package:jetleaf_lang/lang.dart';
import 'package:test/test.dart';

class TestAutoCloseable implements Closeable {
  bool closed = false;
  
  @override
  void close() {
    closed = true;
  }
}

class TestAsyncAutoCloseable implements Closeable {
  bool closed = false;
  
  @override
  Future<void> close() async {
    await Future.delayed(Duration(milliseconds: 10));
    closed = true;
  }
}

void main() {
  group('Closeable', () {
    test('should be an abstract class', () {
      final closeable = TestAutoCloseable();
      expect(closeable, isA<Closeable>());
    });
    
    test('should have close method', () {
      final closeable = TestAutoCloseable();
      expect(() => closeable.close(), returnsNormally);
    });
    
    test('close method should work synchronously', () {
      final closeable = TestAutoCloseable();
      expect(closeable.closed, isFalse);
      closeable.close();
      expect(closeable.closed, isTrue);
    });
    
    test('close method should work asynchronously', () async {
      final closeable = TestAsyncAutoCloseable();
      expect(closeable.closed, isFalse);
      await closeable.close();
      expect(closeable.closed, isTrue);
    });
    
    test('should be constructible', () {
      expect(() => TestAutoCloseable(), returnsNormally);
    });
  });
}