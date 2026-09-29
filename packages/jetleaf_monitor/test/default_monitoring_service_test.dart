import 'package:jetleaf_monitor/jetleaf_monitor.dart';
import 'package:test/test.dart';

void main() {
  group('DefaultMonitoringService - Static Properties', () {
    test('should have correct POD_NAME', () {
      expect(DefaultMonitoringService.POD_NAME, equals('jetleaf.monitor.monitoringService'));
    });

    test('should have correct REQUEST_INTERVAL_PROPERTY_NAME', () {
      expect(DefaultMonitoringService.REQUEST_INTERVAL_PROPERTY_NAME, equals('jetleaf.monitor.interval'));
    });

    test('should have correct ANALYTICS_REQUEST_INTERVAL_PROPERTY_NAME', () {
      expect(DefaultMonitoringService.ANALYTICS_REQUEST_INTERVAL_PROPERTY_NAME, equals('jetleaf.monitor.interval.analytics'));
    });

    test('should have correct INIT_WINDOW_ANALYSIS_START_PROPERTY_NAME', () {
      expect(DefaultMonitoringService.INIT_WINDOW_ANALYSIS_START_PROPERTY_NAME, equals('jetleaf.monitor.init.window.analysis.start'));
    });

    test('should have correct INIT_WINDOW_ANALYSIS_END_PROPERTY_NAME', () {
      expect(DefaultMonitoringService.INIT_WINDOW_ANALYSIS_END_PROPERTY_NAME, equals('jetleaf.monitor.init.window.analysis.end'));
    });

    test('should have CLASS static field', () {
      expect(DefaultMonitoringService.CLASS, isNotNull);
    });
  });

  group('DefaultMonitoringService - Instance Behavior', () {
    late DefaultMonitoringService service;

    setUp(() {
      service = DefaultMonitoringService();
    });

    test('should create without environment', () {
      expect(service, isA<DefaultMonitoringService>());
      expect(service, isA<MonitoringService>());
    });

    test('should not be running initially', () {
      expect(service.isRunning(), isFalse);
    });

    test('should return null performance for nonexistent name', () {
      expect(service.getPerformance('nonexistent'), isNull);
    });

    test('should return empty performances initially', () {
      expect(service.getPerformances(), isEmpty);
    });

    test('should return empty memory history initially', () {
      expect(service.getMemoryHistory(), isEmpty);
    });

    test('should return memory reading stream', () {
      final stream = service.getMemoryReadingStream();
      expect(stream, isA<Stream>());
    });

    test('should return default analytics interval', () {
      expect(service.getAnalyticsInterval(), equals(Duration(hours: 1)));
    });

    test('should return default init window analysis start', () {
      expect(service.getInitWindowAnalysisStart(), equals(Duration(minutes: 3)));
    });

    test('should return default init window analysis end', () {
      expect(service.getInitWindowAnalysisEnd(), equals(Duration(minutes: 13)));
    });

    test('should return default interval', () {
      expect(service.getInterval(), equals(Duration(seconds: 5)));
    });

    test('should return null startup tracker initially', () {
      expect(service.getStartupTracker(), isNull);
    });

    test('should return logger', () {
      expect(service.getLogger(), isNotNull);
    });

    test('should get analytics with no readings', () {
      final analytics = service.getMemoryAnalytics();
      expect(analytics, isA<AbstractMemoryAnalytics>());
      expect(analytics.getReadings(), isEmpty);
    });

    test('should get analytics with custom duration', () {
      final analytics = service.getMemoryAnalytics(Duration(minutes: 5));
      expect(analytics.getTimeWindow(), equals(Duration(minutes: 5)));
    });

    test('should implement InstancePerformanceTracker', () {
      expect(service, isA<InstancePerformanceTracker>());
    });
  });

  group('DefaultMonitoringService - Configuration Defaults', () {
    test('default interval should be 5 seconds', () {
      final service = DefaultMonitoringService();
      expect(service.getInterval(), equals(Duration(seconds: 5)));
    });

    test('default analytics interval should be 1 hour', () {
      final service = DefaultMonitoringService();
      expect(service.getAnalyticsInterval(), equals(Duration(hours: 1)));
    });

    test('default init window start should be 3 minutes', () {
      final service = DefaultMonitoringService();
      expect(service.getInitWindowAnalysisStart(), equals(Duration(minutes: 3)));
    });

    test('default init window end should be 13 minutes', () {
      final service = DefaultMonitoringService();
      expect(service.getInitWindowAnalysisEnd(), equals(Duration(minutes: 13)));
    });
  });
}
