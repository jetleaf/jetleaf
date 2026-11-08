import 'package:jetleaf_monitor/jetleaf_monitor.dart';
import 'package:test/test.dart';

void main() {
  ConfigurablePerformance createPerformance({
    String name = 'TestOperation',
    String location = 'TestClass.testMethod',
    DateTime? startTime,
    DateTime? endTime,
    bool isRunning = true,
    String? ipAddress,
  }) {
    return ConfigurablePerformance(
      name: name,
      location: location,
      startTime: startTime,
      endTime: endTime,
      isRunning: isRunning,
      ipAddress: ipAddress,
    );
  }

  group('ConfigurablePerformance', () {
    test('should create with required parameters', () {
      final perf = createPerformance();
      expect(perf.getName(), equals('TestOperation'));
      expect(perf.getLocation(), equals('TestClass.testMethod'));
      expect(perf.isRunning(), isTrue);
      expect(perf.getStartTime(), isA<DateTime>());
      expect(perf.getEndTime(), isA<DateTime>());
    });

    test('should create with optional parameters', () {
      final start = DateTime(2025, 1, 1);
      final end = DateTime(2025, 1, 1, 0, 0, 5);
      final perf = createPerformance(
        startTime: start,
        endTime: end,
        isRunning: false,
        ipAddress: '192.168.1.1',
      );
      expect(perf.getStartTime(), equals(start));
      expect(perf.getIpAddress(), equals('192.168.1.1'));
      expect(perf.isRunning(), isFalse);
    });

    test('should return end time as DateTime.now() when running', () {
      final before = DateTime.now();
      final perf = createPerformance(isRunning: true);
      final endTime = perf.getEndTime();
      final after = DateTime.now();
      expect(endTime.isAfter(before) || endTime.isAtSameMomentAs(before), isTrue);
      expect(endTime.isBefore(after) || endTime.isAtSameMomentAs(after), isTrue);
    });

    test('should return stored end time when not running', () {
      final end = DateTime(2025, 6, 15, 12, 0);
      final perf = createPerformance(endTime: end, isRunning: false);
      expect(perf.getEndTime(), equals(end));
    });

    test('should compute run period from start to end', () {
      final start = DateTime(2025, 1, 1, 0, 0, 0);
      final end = DateTime(2025, 1, 1, 0, 0, 10);
      final perf = createPerformance(
        startTime: start,
        endTime: end,
        isRunning: false,
      );
      expect(perf.getRunPeriod(), equals(Duration(seconds: 10)));
    });

    test('should return null memory analytics by default', () {
      final perf = createPerformance();
      expect(perf.getMemoryAnalytics(), isNull);
    });

    test('should return empty error type counts by default', () {
      final perf = createPerformance();
      expect(perf.getErrorTypeCounts(), isEmpty);
    });

    test('should return empty error counts by default', () {
      final perf = createPerformance();
      expect(perf.getErrorCounts(), isEmpty);
    });

    test('should set start time', () {
      final perf = createPerformance();
      final newStart = DateTime(2025, 6, 15);
      perf.setStartTime(newStart);
      expect(perf.getStartTime(), equals(newStart));
    });

    test('should set end time and mark as not running', () {
      final perf = createPerformance(isRunning: true);
      final newEnd = DateTime(2025, 6, 15, 12, 0);
      perf.setEndTime(newEnd);
      expect(perf.getEndTime(), equals(newEnd));
      expect(perf.isRunning(), isFalse);
    });

    test('should set is running to false and update end time', () {
      final perf = createPerformance(isRunning: true);
      final before = DateTime.now();
      perf.setIsRunning(false);
      final after = DateTime.now();
      expect(perf.isRunning(), isFalse);
      expect(perf.getEndTime().isAfter(before) || perf.getEndTime().isAtSameMomentAs(before), isTrue);
      expect(perf.getEndTime().isBefore(after) || perf.getEndTime().isAtSameMomentAs(after), isTrue);
    });

    test('should set is running to true', () {
      final perf = createPerformance(isRunning: false);
      perf.setIsRunning(true);
      expect(perf.isRunning(), isTrue);
    });

    test('should set IP address', () {
      final perf = createPerformance();
      perf.setIpAddress('10.0.0.1');
      expect(perf.getIpAddress(), equals('10.0.0.1'));
    });

    test('should set IP address to null', () {
      final perf = createPerformance(ipAddress: '10.0.0.1');
      perf.setIpAddress(null);
      expect(perf.getIpAddress(), isNull);
    });

    test('should set memory analytics', () {
      final perf = createPerformance();
      final analytics = DefaultMemoryAnalytics(
        timeWindow: Duration(minutes: 1),
        minMemoryMB: 100.0,
        maxMemoryMB: 200.0,
        avgMemoryMB: 150.0,
        currentMemoryMB: 180.0,
      );
      perf.setMemoryAnalytics(analytics);
      expect(perf.getMemoryAnalytics(), equals(analytics));
      expect(perf.getMemoryAnalytics()!.getMinimumMemoryInMegaByte().value, equals(100.0));
    });

    test('should add error type count', () {
      final perf = createPerformance();
      perf.addErrorTypeCount('TimeoutException');
      expect(perf.getErrorTypeCounts()['TimeoutException'], equals(1));
      perf.addErrorTypeCount('TimeoutException');
      expect(perf.getErrorTypeCounts()['TimeoutException'], equals(2));
      perf.addErrorTypeCount('StateError');
      expect(perf.getErrorTypeCounts()['StateError'], equals(1));
      expect(perf.getErrorTypeCounts().length, equals(2));
    });

    test('should add error count', () {
      final perf = createPerformance();
      perf.addErrorCount('Connection timed out');
      expect(perf.getErrorCounts()['Connection timed out'], equals(1));
      perf.addErrorCount('Connection timed out');
      expect(perf.getErrorCounts()['Connection timed out'], equals(2));
      perf.addErrorCount('Different error');
      expect(perf.getErrorCounts().length, equals(2));
    });

    test('should return unmodifiable error type counts', () {
      final perf = createPerformance();
      perf.addErrorTypeCount('Error');
      final counts = perf.getErrorTypeCounts();
      expect(() => counts['NewError'] = 1, throwsA(isA<UnsupportedError>()));
    });

    test('should return unmodifiable error counts', () {
      final perf = createPerformance();
      perf.addErrorCount('Error');
      final counts = perf.getErrorCounts();
      expect(() => counts['NewError'] = 1, throwsA(isA<UnsupportedError>()));
    });

    test('should set uptime', () {
      final perf = createPerformance();
      perf.setUptime(Duration(seconds: 42));
      expect(perf.getRunPeriod(), equals(Duration(seconds: 42)));
    });

    test('should serialize to JSON', () {
      final start = DateTime(2025, 1, 1, 0, 0, 0);
      final end = DateTime(2025, 1, 1, 0, 0, 10);
      final perf = createPerformance(
        startTime: start,
        endTime: end,
        isRunning: false,
        ipAddress: '10.0.0.1',
      );
      perf.addErrorTypeCount('TimeoutException');
      perf.addErrorCount('timeout');

      final json = perf.toJson();
      expect(json['name'], equals('TestOperation'));
      expect(json['start_time'], equals(start));
      expect(json['end_time'], equals(end));
      expect(json['run_period_in_milliseconds'], equals(10000));
      expect(json['is_running'], isFalse);
      expect(json['ip_address'], equals('10.0.0.1'));
      expect(json['error_type_counts'], equals({'TimeoutException': 1}));
      expect(json['error_counts'], equals({'timeout': 1}));
    });

    test('should serialize to JSON without optional fields', () {
      final perf = createPerformance(isRunning: true);
      final json = perf.toJson();
      expect(json.containsKey('ip_address'), isFalse);
      expect(json.containsKey('error_type_counts'), isFalse);
      expect(json.containsKey('error_counts'), isFalse);
      expect(json.containsKey('memory_analytics'), isFalse);
    });

    test('should serialize to JSON with memory analytics', () {
      final perf = createPerformance();
      perf.setMemoryAnalytics(DefaultMemoryAnalytics(
        timeWindow: Duration(minutes: 1),
        minMemoryMB: 100.0,
        maxMemoryMB: 200.0,
        avgMemoryMB: 150.0,
        currentMemoryMB: 180.0,
      ));
      final json = perf.toJson();
      expect(json.containsKey('memory_analytics'), isTrue);
    });

    test('should implement Performance interface', () {
      final perf = createPerformance();
      expect(perf, isA<Performance>());
    });

    test('should implement AbstractPerformance', () {
      final perf = createPerformance();
      expect(perf, isA<AbstractPerformance>());
    });
  });

  group('Performance.freeze()', () {
    test('should return a frozen performance', () {
      final perf = createPerformance();
      final frozen = perf.freeze();
      expect(frozen, isA<Performance>());
      expect(frozen, isNot(isA<ConfigurablePerformance>()));
    });

    test('should delegate getName to source', () {
      final perf = createPerformance(name: 'MyMethod');
      final frozen = perf.freeze();
      expect(frozen.getName(), equals('MyMethod'));
    });

    test('should delegate getStartTime to source', () {
      final start = DateTime(2025, 6, 15);
      final perf = createPerformance(startTime: start);
      final frozen = perf.freeze();
      expect(frozen.getStartTime(), equals(start));
    });

    test('should delegate getEndTime to source', () {
      final end = DateTime(2025, 6, 15, 12, 0);
      final perf = createPerformance(endTime: end, isRunning: false);
      final frozen = perf.freeze();
      expect(frozen.getEndTime(), equals(end));
    });

    test('should delegate isRunning to source', () {
      final perf = createPerformance(isRunning: false);
      final frozen = perf.freeze();
      expect(frozen.isRunning(), isFalse);
    });

    test('should delegate getIpAddress to source', () {
      final perf = createPerformance(ipAddress: '10.0.0.1');
      final frozen = perf.freeze();
      expect(frozen.getIpAddress(), equals('10.0.0.1'));
    });

    test('should delegate getMemoryAnalytics to source', () {
      final perf = createPerformance();
      final analytics = DefaultMemoryAnalytics(minMemoryMB: 50.0);
      perf.setMemoryAnalytics(analytics);
      final frozen = perf.freeze();
      expect(frozen.getMemoryAnalytics(), equals(analytics));
    });

    test('should delegate getErrorTypeCounts to source', () {
      final perf = createPerformance();
      perf.addErrorTypeCount('StateError');
      final frozen = perf.freeze();
      expect(frozen.getErrorTypeCounts()['StateError'], equals(1));
    });

    test('should delegate getErrorCounts to source', () {
      final perf = createPerformance();
      perf.addErrorCount('oops');
      final frozen = perf.freeze();
      expect(frozen.getErrorCounts()['oops'], equals(1));
    });

    test('should delegate getLocation to source', () {
      final perf = createPerformance(location: 'com.example.MyClass');
      final frozen = perf.freeze();
      expect(frozen.getLocation(), equals('com.example.MyClass'));
    });

    test('should delegate toJson to source', () {
      final perf = createPerformance(name: 'Test');
      final frozen = perf.freeze();
      expect(frozen.toJson()['name'], equals('Test'));
    });

    test('should delegate getRunPeriod to source', () {
      final perf = createPerformance();
      perf.setUptime(Duration(seconds: 30));
      final frozen = perf.freeze();
      expect(frozen.getRunPeriod(), equals(Duration(seconds: 30)));
    });
  });
}
