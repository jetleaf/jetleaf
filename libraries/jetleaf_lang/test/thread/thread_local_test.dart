import 'dart:isolate';

import 'package:test/test.dart';
import 'package:jetleaf_lang/lang.dart';

void main() {
  group('ThreadLocal (Isolate-based)', () {
    late LocalThread<String> threadLocal;

    setUp(() {
      threadLocal = LocalThread<String>();
    });

    test('get returns null when unset', () {
      expect(threadLocal.get(), isNull);
    });

    test('set and get work in main isolate', () {
      threadLocal.set('hello');
      expect(threadLocal.get(), 'hello');
    });

    test('remove clears the value', () {
      threadLocal.set('value');
      threadLocal.remove();
      expect(threadLocal.get(), isNull);
    });

    test('values are isolate-local', () async {
      threadLocal.set('main');

      final receivePort = ReceivePort();
      await Isolate.spawn((SendPort sendPort) {
        final threadLocal = LocalThread<String>();
        threadLocal.set('child');
        sendPort.send(threadLocal.get());
      }, receivePort.sendPort);

      final result = await receivePort.first;
      expect(result, 'child');
      expect(threadLocal.get(), 'main');
    });
  });
}