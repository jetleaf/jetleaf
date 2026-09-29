import 'package:jetleaf_monitor/jetleaf_monitor.dart';
import 'package:test/test.dart';

void main() {
  ProcessInformation createProcessInfo({
    int currentRss = 1024,
    int freedMemory = 512,
    int maxRss = 2048,
  }) {
    return DefaultProcessInformation(currentRss, freedMemory, maxRss);
  }

  MemoryAnalytics createAnalytics({
    Duration timeWindow = const Duration(minutes: 5),
    double minMemoryMB = 100.0,
    double maxMemoryMB = 500.0,
    double avgMemoryMB = 300.0,
    double currentMemoryMB = 350.0,
  }) {
    return DefaultMemoryAnalytics(
      timeWindow: timeWindow,
      minMemoryMB: minMemoryMB,
      maxMemoryMB: maxMemoryMB,
      avgMemoryMB: avgMemoryMB,
      currentMemoryMB: currentMemoryMB,
    );
  }

  MonitoringReport createReport({
    ProcessInformation? information,
    DateTime? startTime,
    MemoryAnalytics? analytics,
    List<MemoryReading>? readings,
    Duration? uptime,
  }) {
    return DefaultMonitoringReport(
      information ?? createProcessInfo(),
      startTime ?? DateTime(2025, 1, 1),
      analytics ?? createAnalytics(),
      readings ?? [],
      uptime ?? const Duration(hours: 1),
    );
  }

  group('DefaultMonitoringReport', () {
    test('should create with all parameters', () {
      final info = createProcessInfo(currentRss: 2048);
      final start = DateTime(2025, 6, 15, 10, 0);
      final analytics = createAnalytics(minMemoryMB: 200.0);
      final readings = [
        DefaultMemoryReading(memoryMB: 200.0),
        DefaultMemoryReading(memoryMB: 250.0),
      ];
      final uptime = Duration(hours: 2);

      final report = createReport(
        information: info,
        startTime: start,
        analytics: analytics,
        readings: readings,
        uptime: uptime,
      );

      expect(report.getProcessInformation(), equals(info));
      expect(report.getAppStartTime(), equals(start));
      expect(report.getMemoryAnalytics(), equals(analytics));
      expect(report.getMemoryHistory().length, equals(2));
      expect(report.getTotalUptime(), equals(uptime));
    });

    test('should return app start time', () {
      final start = DateTime(2025, 1, 1, 12, 0);
      final report = createReport(startTime: start);
      expect(report.getAppStartTime(), equals(start));
    });

    test('should return total uptime', () {
      final report = createReport(uptime: Duration(hours: 3, minutes: 30));
      expect(report.getTotalUptime(), equals(Duration(hours: 3, minutes: 30)));
    });

    test('should return memory analytics', () {
      final analytics = createAnalytics(avgMemoryMB: 400.0);
      final report = createReport(analytics: analytics);
      expect(report.getMemoryAnalytics().getAverageMemoryInMegaByte().value, equals(400.0));
    });

    test('should return process information', () {
      final info = createProcessInfo(maxRss: 4096);
      final report = createReport(information: info);
      expect(report.getProcessInformation().getMaxResidentSetSizeMemory().value, equals(4096));
    });

    test('should return memory history as unmodifiable list', () {
      final readings = [DefaultMemoryReading(memoryMB: 100.0)];
      final report = createReport(readings: readings);
      final history = report.getMemoryHistory();
      expect(history.length, equals(1));
      expect(() => history.add(DefaultMemoryReading()), throwsA(isA<UnsupportedError>()));
    });

    test('should return empty memory history by default', () {
      final report = createReport();
      expect(report.getMemoryHistory(), isEmpty);
    });

    test('should serialize to JSON', () {
      final start = DateTime(2025, 1, 1);
      final report = createReport(
        startTime: start,
        uptime: Duration(hours: 1),
      );
      final json = report.toJson();
      expect(json['app.start.time'], equals(start));
      expect(json['uptime.in.milliseconds'], equals(3600000));
      expect(json['process.information'], isA<Map>());
      expect(json['memory.analytics'], isA<Map>());
      expect(json['memory.readings'], isA<List>());
    });

    test('should implement MonitoringReport interface', () {
      final report = createReport();
      expect(report, isA<MonitoringReport>());
    });

    test('should not be equal with different start times', () {
      final r1 = createReport(startTime: DateTime(2025));
      final r2 = createReport(startTime: DateTime(2026));
      expect(r1, isNot(equals(r2)));
    });

    test('should not be equal with different uptime', () {
      final r1 = createReport(uptime: Duration(hours: 1));
      final r2 = createReport(uptime: Duration(hours: 2));
      expect(r1, isNot(equals(r2)));
    });
  });
}
