import 'package:jetleaf_core/core.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:test/test.dart';

void main() {
  group('ReadinessState', () {
    test('has ACCEPTING_TRAFFIC and REFUSING_TRAFFIC values', () {
      expect(ReadinessState.values, hasLength(2));
      expect(ReadinessState.ACCEPTING_TRAFFIC, isNotNull);
      expect(ReadinessState.REFUSING_TRAFFIC, isNotNull);
    });

    test('implements AvailabilityState', () {
      expect(ReadinessState.ACCEPTING_TRAFFIC, isA<AvailabilityState>());
    });
  });

  group('LivenessState', () {
    test('has BROKEN and ACTIVE values', () {
      expect(LivenessState.values, hasLength(2));
      expect(LivenessState.BROKEN, isNotNull);
      expect(LivenessState.ACTIVE, isNotNull);
    });

    test('implements AvailabilityState', () {
      expect(LivenessState.ACTIVE, isA<AvailabilityState>());
    });
  });

  group('AvailabilityEvent', () {
    test('stores availability state', () {
      final source = Object();
      final event = AvailabilityEvent(source, ReadinessState.ACCEPTING_TRAFFIC, DateTime.now());
      expect(event.availability, equals(ReadinessState.ACCEPTING_TRAFFIC));
    });

    test('getSource returns the source object', () {
      final source = Object();
      final event = AvailabilityEvent(source, LivenessState.ACTIVE, DateTime.now());
      expect(event.getSource(), equals(source));
    });

    test('getPackageName returns MAIN', () {
      final event = AvailabilityEvent(Object(), LivenessState.ACTIVE, DateTime.now());
      expect(event.getPackageName(), equals(PackageNames.MAIN));
    });

    test('equality based on source and timestamp', () {
      final source = Object();
      final ts = DateTime(2025, 1, 1);
      final e1 = AvailabilityEvent(source, ReadinessState.ACCEPTING_TRAFFIC, ts);
      final e2 = AvailabilityEvent(source, ReadinessState.REFUSING_TRAFFIC, ts);
      expect(e1, equals(e2));
    });
  });
}