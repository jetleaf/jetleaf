import 'package:jetleaf_core/context.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:test/test.dart';

void main() {
  group('EventObject', () {
    test('getSource returns the source', () {
      final source = Object();
      final event = _TestEvent(source);
      expect(event.getSource(), equals(source));
    });

    test('getTimestamp returns the timestamp', () {
      final ts = DateTime(2025, 1, 1);
      final event = _TestEvent(Object(), ts);
      expect(event.getTimestamp(), equals(ts));
    });

    test('getTimestamp defaults to DateTime.now when null', () {
      final before = DateTime.now();
      final event = _TestEvent(Object());
      final ts = event.getTimestamp();
      final after = DateTime.now();
      expect(ts.isAfter(before) || ts.isAtSameMomentAs(before), isTrue);
      expect(ts.isBefore(after) || ts.isAtSameMomentAs(after), isTrue);
    });

    test('equality based on source and timestamp', () {
      final source = Object();
      final ts = DateTime(2025, 1, 1);
      final e1 = _TestEvent(source, ts);
      final e2 = _TestEvent(source, ts);
      expect(e1, equals(e2));
    });

    test('inequality when sources differ', () {
      final ts = DateTime(2025, 1, 1);
      final e1 = _TestEvent(Object(), ts);
      final e2 = _TestEvent(Object(), ts);
      expect(e1, isNot(equals(e2)));
    });
  });

  group('ApplicationEvent', () {
    test('withClock uses the clock function', () {
      DateTime clock() => DateTime(2025, 6, 15);
      final event = _TestAppEvent.withClock(Object(), clock);
      expect(event.getTimestamp(), equals(DateTime(2025, 6, 15)));
    });
  });

  group('Context events', () {
    test('ContextClosedEvent has correct package name', () {
      final event = ContextClosedEvent(_FakeContext());
      expect(event.getPackageName(), equals(PackageNames.CORE));
    });

    test('ContextFailedEvent has correct package name', () {
      final event = ContextFailedEvent(_FakeContext());
      expect(event.getPackageName(), equals(PackageNames.CORE));
    });

    test('ContextReadyEvent has correct package name', () {
      final event = ContextReadyEvent(_FakeContext());
      expect(event.getPackageName(), equals(PackageNames.CORE));
    });

    test('ContextSetupEvent has correct package name', () {
      final event = ContextSetupEvent(_FakeContext());
      expect(event.getPackageName(), equals(PackageNames.CORE));
    });

    test('ContextRestartedEvent has correct package name', () {
      final event = ContextRestartedEvent(_FakeContext());
      expect(event.getPackageName(), equals(PackageNames.CORE));
    });

    test('ContextStartedEvent has correct package name', () {
      final event = ContextStartedEvent(_FakeContext());
      expect(event.getPackageName(), equals(PackageNames.CORE));
    });

    test('ContextStoppedEvent has correct package name', () {
      final event = ContextStoppedEvent(_FakeContext());
      expect(event.getPackageName(), equals(PackageNames.CORE));
    });

    test('CompletedInitializationEvent has correct package name', () {
      final event = CompletedInitializationEvent(_FakeContext());
      expect(event.getPackageName(), equals(PackageNames.CORE));
    });

    test('ContextClosedEvent.getSource returns ApplicationContext', () {
      final ctx = _FakeContext();
      final event = ContextClosedEvent(ctx);
      expect(event.getSource(), equals(ctx));
      expect(event.getApplicationContext(), equals(ctx));
    });
  });
}

class _TestEvent extends ApplicationEvent {
  _TestEvent(super.source, [super.timestamp]);

  @override
  String getPackageName() => 'test';
}

class _TestAppEvent extends ApplicationEvent {
  _TestAppEvent(super.source);
  _TestAppEvent.withClock(super.source, super.clock) : super.withClock();

  @override
  String getPackageName() => 'test';
}

class _FakeContext implements ApplicationContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}