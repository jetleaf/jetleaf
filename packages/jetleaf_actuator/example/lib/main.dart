// ignore_for_file: avoid_print

import 'dart:io';

import 'package:jetleaf_actuator/jetleaf_actuator.dart';
import 'package:jetson/jetson.dart';

void main() {
  print('========================================================');
  print('  🍃 Jetleaf Actuator 1.0.0 Actuator Showcase');
  print('========================================================\n');

  final startTime = DateTime.now().subtract(const Duration(minutes: 15));
  final uptime = DateTime.now().difference(startTime);

  // 1. Process Information
  print('[1] Capturing Process & Host Information:');
  final currentRss = ProcessInfo.currentRss;
  final maxRss = ProcessInfo.maxRss;
  final processInfo = DefaultProcessInformation(currentRss, 0, maxRss);

  print('Operating System : ${processInfo.getOperatingSystem()} (${processInfo.getOperatingSystemVersion()})');
  print('Host Name        : ${processInfo.getLocalHostName()}');
  print('Processors (CPUs): ${processInfo.getNumberOfProcessors()}');
  print('Dart Version     : ${processInfo.getDartVersion()}');
  print('Current RSS (MB) : ${(currentRss / (1024 * 1024)).toStringAsFixed(2)} MB');
  print('Max RSS (MB)     : ${(maxRss / (1024 * 1024)).toStringAsFixed(2)} MB\n');

  // 2. Memory Readings
  print('[2] Capturing Chronological Memory Readings:');
  final readings = <MemoryReading>[
    DefaultMemoryReading(
      timestamp: startTime.add(const Duration(minutes: 5)),
      memoryMB: 32.4,
      uptime: const Duration(minutes: 5),
    ),
    DefaultMemoryReading(
      timestamp: startTime.add(const Duration(minutes: 10)),
      memoryMB: 48.6,
      uptime: const Duration(minutes: 10),
    ),
    DefaultMemoryReading(
      timestamp: DateTime.now(),
      memoryMB: (currentRss / (1024 * 1024)),
      uptime: uptime,
    ),
  ];

  for (final (index, reading) in readings.indexed) {
    print('  Snapshot #${index + 1}: ${reading.getMemoryInMegaByte().value.toStringAsFixed(2)} MB at uptime ${reading.getUptime().inMinutes}m');
  }

  // 3. Memory Analytics
  print('\n[3] Computing Memory Trend Analytics:');
  final analytics = DefaultMemoryAnalytics(
    timeWindow: const Duration(minutes: 15),
    minMemoryMB: 32.4,
    maxMemoryMB: 48.6,
    avgMemoryMB: 40.5,
    currentMemoryMB: currentRss / (1024 * 1024),
    readings: readings,
  );

  print('Observation Window : ${analytics.getTimeWindow().inMinutes} minutes');
  print('Min Memory         : ${analytics.getMinimumMemoryInMegaByte().value.toStringAsFixed(2)} MB');
  print('Max Memory         : ${analytics.getMaximumMemoryInMegaByte().value.toStringAsFixed(2)} MB');
  print('Average Memory     : ${analytics.getAverageMemoryInMegaByte().value.toStringAsFixed(2)} MB');
  print('Current Memory     : ${analytics.getCurrentMemoryInMegaByte().value.toStringAsFixed(2)} MB\n');

  // 4. Compiling Full Diagnostic Report
  print('[4] Generating System Diagnostic Snapshot:');
  final report = DefaultMonitoringReport(
    processInfo,
    startTime,
    analytics,
    readings,
    uptime,
  );

  print('App Start Time     : ${report.getAppStartTime().toIso8601String()}');
  print('Total Uptime       : ${report.getTotalUptime().inSeconds}s');
  print('Readings Recorded  : ${report.getMemoryHistory().length}');

  // 5. JSON Serialization via Jetson
  print('\n[5] Serializing Health & Actuator Report to JSON:');
  final mapper = ObjectMapper();
  final jsonReport = mapper.writeValueAsString(report.toJson());
  print(jsonReport);

  print('\n========================================================');
  print('  ✅ Jetleaf Monitor Example executed successfully!');
  print('========================================================');
}