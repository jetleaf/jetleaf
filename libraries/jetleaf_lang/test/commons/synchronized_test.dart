import 'dart:async';

import 'package:jetleaf_lang/lang.dart';
import 'package:test/test.dart';

/// A custom exception for user-defined errors, used for testing propagation.
class MyUserException implements Exception {
  final String message;
  MyUserException(this.message);
  @override
  String toString() => 'MyUserException: $message';
}

void main() {
  group('${Constant.ICON} Jetleaf SynchronizedLock', () {
    test('only one async block runs at a time (mutual exclusion)', () async {
      final monitor = Object();
      final log = <String>[];
      Future<void> task(String label, int delay) async {
        await synchronizedAsync(monitor, () async {
          log.add('start $label');
          await Thread.sleep(Duration(milliseconds: delay)); // Use Thread.sleep
          log.add('end $label');
        });
      }

      await Future.wait([
        task('A', 100),
        task('B', 50),
        task('C', 10),
      ]);

      expect(log, [
        'start A',
        'end A',
        'start B',
        'end B',
        'start C',
        'end C',
      ]);
    });

    test('synchronous lock works without async gaps', () {
      final monitor = Object();
      final log = <String>[];
      synchronized(monitor, () => log.add('first'));
      synchronized(monitor, () => log.add('second'));
      expect(log, ['first', 'second']);
    });

    test('reentrant lock (same zone) executes immediately (async)', () async {
      final monitor = Object();
      final log = <String>[];
      await synchronizedAsync(monitor, () async {
        log.add('outer');
        await synchronizedAsync(monitor, () async {
          log.add('inner');
        });
      });
      expect(log, ['outer', 'inner']);
    });

    test('reentrant lock (same zone) executes immediately (sync)', () {
      final monitor = Object();
      final log = <String>[];
      synchronized(monitor, () {
        log.add('outer sync');
        synchronized(monitor, () {
          log.add('inner sync');
        });
      });
      expect(log, ['outer sync', 'inner sync']);
    });

    test('synchronous lock throws if held by another zone', () async {
      final monitor = Object();
      final completer = Completer<void>();

      // Acquire the lock asynchronously in a different "context" (though same zone)
      // This simulates the lock being held by an async operation.
      synchronizedAsync(monitor, () async {
        completer.complete(); // Signal that the lock is acquired
        await Thread.sleep(Duration(milliseconds: 100)); // Keep lock held
      });

      await completer.future; // Wait for the async lock to be acquired

      // Attempt to acquire synchronously from the same zone, but while async is holding it
      expect(
        () => synchronized(monitor, () => print('This should not run')),
        throwsA(isA<ReentrantSynchronizedException>().having(
          (e) => e.message,
          'message',
          contains('Synchronized lock is held by another zone. Cannot acquire synchronously.'),
        )),
      );
    });

    test('synchronous lock rethrows user-thrown MyUserException', () {
      final monitor = Object();
      expect(
        () => synchronized(monitor, () {
          throw MyUserException('custom error');
        }),
        throwsA(isA<MyUserException>()), // Expect original MyUserException
      );
    });

    test('synchronizedAsync propagates user-thrown InvalidArgumentException properly', () async {
      final monitor = Object();
      expect(
        () => synchronizedAsync(monitor, () async {
          throw InvalidArgumentException('invalid!');
        }),
        throwsA(isA<InvalidArgumentException>()), // Expect original InvalidArgumentException
      );
    });

    test('synchronizedAsync propagates user-thrown MyUserException properly', () async {
      final monitor = Object();
      expect(
        () => synchronizedAsync(monitor, () async {
          throw MyUserException('async custom error');
        }),
        throwsA(isA<MyUserException>()), // Expect original MyUserException
      );
    });

    test('independent monitors are isolated', () async {
      final monitor1 = Object();
      final monitor2 = Object();
      final log = <String>[];

      Future<void> task(Object mon, String id) async {
        await synchronizedAsync(mon, () async {
          log.add('start $id');
          await Thread.sleep(Duration(milliseconds: 50));
          log.add('end $id');
        });
      }

      // Run tasks on different monitors concurrently
      await Future.wait([
        task(monitor1, 'A'),
        task(monitor2, 'B'),
      ]);

      // Interleaved execution means they are not locked together
      expect(log.length, 4);
      expect(log, contains('start A'));
      expect(log, contains('end A'));
      expect(log, contains('start B'));
      expect(log, contains('end B'));
    });

    // New test: synchronizedAsync queues when lock is held by another task
    test('synchronizedAsync queues when lock is held by another task', () async {
      final monitor = Object();
      final log = <String>[];
      final completer1 = Completer<void>();

      // Task A acquires the lock and holds it
      synchronizedAsync(monitor, () async {
        log.add('start A');
        completer1.complete(); // Signal that A has started
        await Thread.sleep(Duration(milliseconds: 100)); // Hold the lock
        log.add('end A');
      });

      await completer1.future; // Wait for Task A to start and acquire lock

      // Task B attempts to acquire the lock while A holds it
      final completer2 = Completer<void>();
      synchronizedAsync(monitor, () async {
        log.add('start B');
        await Thread.sleep(Duration(milliseconds: 50));
        log.add('end B');
        completer2.complete();
      });

      // Task B should be queued, so 'start B' should not appear yet.
      expect(log, ['start A']);

      await completer2.future; // Wait for Task B to complete

      // Now, the log should show A finishing, then B starting and finishing.
      expect(log, ['start A', 'end A', 'start B', 'end B']);
    });
  });
}