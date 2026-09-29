import 'dart:async';
import 'dart:isolate';

import 'package:test/test.dart';
import 'package:jetleaf_lang/lang.dart';

import '../dependencies/exceptions.dart';

void main() {
  group('Thread', () {
    test('start and join basic isolate execution', () async {
      void isolateMain(ThreadMessage msg) {
        msg.replyPort.send('done');
      }

      final thread = Thread(isolateMain, debugName: 'test-thread-1');
      await thread.start();
      await thread.join();

      expect(thread.isAlive, isFalse);
    });

    test('throws if join called before start', () {
      void isolateMain(ThreadMessage msg) {
        msg.replyPort.send('done');
      }

      final thread = Thread(isolateMain);
      expect(() => thread.join(), throwsInvalidArgumentException);
    });

    test('throws if start is called more than once', () async {
      void isolateMain(ThreadMessage msg) {
        msg.replyPort.send('done');
      }

      final thread = Thread(isolateMain);
      await thread.start();
      expect(() => thread.start(), throwsInvalidArgumentException);
      await thread.join();
    });

    test('interrupt terminates isolate', () async {
      void isolateMain(ThreadMessage msg) async {
        await Future.delayed(Duration(seconds: 5));
        msg.replyPort.send('done');
      }

      final thread = Thread(isolateMain);
      await thread.start();
      thread.interrupt();

      expect(thread.isAlive, isFalse);
      expect(() => thread.join(), throwsA(isA<ThreadInterruptedException>()));
    });

    test('currentThreadName returns isolate debug name', () async {
      void isolateMain(ThreadMessage msg) {
        final name = Thread.currentThreadName;
        msg.replyPort.send(name);
      }

      final completer = Completer<String>();

      final port = ReceivePort();
      port.listen((msg) {
        if (msg is String) {
          completer.complete(msg);
          port.close();
        }
      });

      await Isolate.spawn<ThreadMessage>(
        isolateMain,
        ThreadMessage(port.sendPort, null),
        debugName: 'named-thread',
      );

      final name = await completer.future;
      expect(name, 'named-thread');
    });

    test('sleep delays execution', () async {
      final stopwatch = Stopwatch()..start();
      await Thread.sleep(Duration(milliseconds: 300));
      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(290));
    });

    test('initial message is received in isolate', () async {
      final completer = Completer<String>();
      final testReceivePort = ReceivePort(); // This is the port the test will listen to

      void isolateMain(ThreadMessage msg) {
        // msg.data is expected to be a List: [initial message string, SendPort to test]
        final List<dynamic> initialData = msg.data as List<dynamic>;
        final String initialMsg = initialData[0] as String;
        final SendPort testReplyPort = initialData[1] as SendPort;

        testReplyPort.send(initialMsg); // Send the initial message back to the test
        msg.replyPort.send('done'); // Signal completion to the Thread instance
      }

      // Pass the actual initial message AND the test's SendPort as initialMessage
      final thread = Thread(isolateMain, initialMessage: ['hello', testReceivePort.sendPort]);
      await thread.start();

      testReceivePort.listen((message) {
        if (message is String) {
          completer.complete(message);
          testReceivePort.close();
        }
      });

      final receivedMessage = await completer.future; // Wait for the message from the isolate
      expect(receivedMessage, 'hello');

      await thread.join(); // Wait for the thread to fully complete its lifecycle
    });
  });
}