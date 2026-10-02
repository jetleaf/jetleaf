import 'package:jetleaf_lang/lang.dart';
import 'package:test/test.dart';

import 'dart:async';

// Convenience helper to collect events until `count` is reached or timeout.
Future<List<ObsEvent>> collectEvents(
  StreamSubscription<ObsEvent> Function(void Function(ObsEvent) onData) subscribeFactory,
  int count, {
  Duration timeout = const Duration(seconds: 1),
}) {
  final completer = Completer<List<ObsEvent>>();
  final events = <ObsEvent>[];
  final sub = subscribeFactory((e) {
    events.add(e);
    if (events.length >= count && !completer.isCompleted) {
      completer.complete(List<ObsEvent>.from(events));
    }
  });

  // Cancel subscription when done/timeout
  return completer.future
      .timeout(timeout)
      .whenComplete(() async {
        await sub.cancel();
      });
}

void main() {
  group('Obs - Value', () {
    test('emits ValueChanged when value set', () async {
      final obs = Obs<int>(0);
      final events = <ObsEvent>[];
      final sub = obs.listen((e) => events.add(e));

      obs.set(1);
      // Wait a microtask to allow async broadcast to deliver
      await Future.delayed(Duration(milliseconds: 10));

      expect(events, hasLength(1));
      expect(events[0], isA<ValueChanged<int>>());
      final vc = events[0] as ValueChanged<int>;
      expect(vc.oldValue, equals(0));
      expect(vc.newValue, equals(1));

      await sub.cancel();
    });

    test('dispose prevents further events', () async {
      final obs = Obs<int>(42);
      final events = <ObsEvent>[];
      final sub = obs.listen((e) => events.add(e));
      await obs.dispose();

      obs.set(100);
      await Future.delayed(Duration(milliseconds: 10));
      expect(events, isEmpty);

      await sub.cancel();
    });
  });

  group('Obs - List helpers', () {
    test('add emits ListChange.add', () async {
      final obs = Obs<List<int>>([]);
      final events = <ObsEvent>[];
      final sub = obs.listen((e) => events.add(e));

      obs.add<int>(1);
      await Future.delayed(Duration(milliseconds: 10));
      expect(events.length, 1);
      expect(events[0], isA<ListChange<int>>());
      final lc = events[0] as ListChange<int>;
      expect(lc.type, equals(ListChangeType.add));
      expect(lc.index, equals(0));
      expect(lc.newValue, equals(1));

      await sub.cancel();
    });

    test('addAll emits BulkChange with multiple add events', () async {
      final obs = Obs<List<String>>([]);
      final events = <ObsEvent>[];
      final sub = obs.listen((e) => events.add(e));

      obs.addAll<String>(['a', 'b', 'c']);
      await Future.delayed(Duration(milliseconds: 10));
      expect(events.length, 1);
      expect(events[0], isA<BulkChange>());
      final bulk = events[0] as BulkChange;
      expect(bulk.changes, hasLength(3));
      expect(bulk.changes.every((c) => c is ListChange<String>), isTrue);

      await sub.cancel();
    });

    test('removeFromList removes and emits remove event', () async {
      final obs = Obs<List<int>>([1, 2, 3]);
      final events = <ObsEvent>[];
      final sub = obs.listen((e) => events.add(e));

      final removed = obs.removeFromList<int>(2);
      await Future.delayed(Duration(milliseconds: 10));
      expect(removed, isTrue);
      expect(events.length, 1);
      expect(events[0], isA<ListChange<int>>());
      final lc = events[0] as ListChange<int>;
      expect(lc.type, equals(ListChangeType.remove));
      expect(lc.oldValue, equals(2));

      await sub.cancel();
    });

    test('transaction batches events into a single BulkChange', () async {
      final obs = Obs<List<int>>([]);
      final events = <ObsEvent>[];
      final sub = obs.listen((e) => events.add(e));

      obs.transaction(() {
        obs.add<int>(1);
        obs.add<int>(2);
        obs.add<int>(3);
      });

      await Future.delayed(Duration(milliseconds: 10));
      expect(events.length, 1);
      expect(events[0], isA<BulkChange>());
      final bulk = events[0] as BulkChange;
      expect(bulk.changes, hasLength(3));
      expect(bulk.changes.every((c) => c is ListChange<int>), isTrue);

      await sub.cancel();
    });

    test('replaceAllInList emits BulkChange remove/add pairs', () async {
      final obs = Obs<List<String>>(['a', 'b', 'c']);
      final events = <ObsEvent>[];
      final sub = obs.listen((e) => events.add(e));

      obs.replaceAllInList<String>(['x', 'y']);
      await Future.delayed(Duration(milliseconds: 10));
      expect(events.length, 1);
      expect(events[0], isA<BulkChange>());
      final bulk = events[0] as BulkChange;
      // removed 3 items, added 2 => total 5 internal changes
      expect(bulk.changes.length, equals(5));

      await sub.cancel();
    });
  });

  group('Obs - Map helpers', () {
    test('put emits MapChange.put', () async {
      final obs = Obs<Map<String, String>>({});
      final events = <ObsEvent>[];
      final sub = obs.listen((e) => events.add(e));

      obs.put<String, String>('k', 'v');
      await Future.delayed(Duration(milliseconds: 10));
      expect(events.length, 1);
      expect(events[0], isA<MapChange<String, String>>());
      final mc = events[0] as MapChange<String, String>;
      expect(mc.type, equals(MapChangeType.put));
      expect(mc.key, equals('k'));
      expect(mc.newValue, equals('v'));

      await sub.cancel();
    });

    test('putAll emits BulkChange with put events', () async {
      final obs = Obs<Map<String, int>>({});
      final events = <ObsEvent>[];
      final sub = obs.listen((e) => events.add(e));

      obs.putAll<String, int>({'a': 1, 'b': 2});
      await Future.delayed(Duration(milliseconds: 10));
      expect(events.length, 1);
      expect(events[0], isA<BulkChange>());
      final bulk = events[0] as BulkChange;
      expect(bulk.changes.length, equals(2));
      expect(bulk.changes.every((c) => c is MapChange<String, int>), isTrue);

      await sub.cancel();
    });

    test('removeKey and clearMap behavior', () async {
      final obs = Obs<Map<String, String>>({'a': '1', 'b': '2'});
      final events = <ObsEvent>[];
      final sub = obs.listen((e) => events.add(e));

      final removed = obs.removeKey<String, String>('a');
      expect(removed, equals('1'));
      // wait delivery
      await Future.delayed(Duration(milliseconds: 10));
      expect(events.isNotEmpty, isTrue);
      final last = events.last;
      expect(last, isA<MapChange<String, String>>());
      final mc = last as MapChange<String, String>;
      expect(mc.type, equals(MapChangeType.remove));

      // clearMap
      events.clear();
      obs.clearMap<String, String>();
      await Future.delayed(Duration(milliseconds: 10));
      expect(events.length, 1);
      expect(events[0], isA<BulkChange>());

      await sub.cancel();
    });

    test('put on non-map throws IllegalStateException', () {
      final obs = Obs<int>(5);
      expect(() => obs.put<String, String>('k', 'v'), throwsA(isA<IllegalStateException>()));
    });
  });

  group('Misc', () {
    test('dispose closes and further operations do not emit', () async {
      final obs = Obs<List<int>>([]);
      final events = <ObsEvent>[];
      final sub = obs.listen((e) => events.add(e));
      await obs.dispose();

      // these operations should not add events
      obs.add<int>(1);
      await Future.delayed(Duration(milliseconds: 10));
      expect(events, isEmpty);

      await sub.cancel();
    });
  });
}