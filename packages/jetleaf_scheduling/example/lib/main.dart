// ignore_for_file: avoid_print

import 'dart:async';

import 'package:jetleaf_core/lang.dart';
import 'package:jetleaf_scheduling/jetleaf_scheduling.dart';

void main() async {
  print('========================================================');
  print('  🍃 Jetleaf Scheduling 2.0.0 Task Engine Showcase');
  print('========================================================\n');

  // 1. Cron Expression Evaluation
  print('[1] Cron Expression Evaluation:');
  final cron = CronExpression('0 0 12 * * *'); // Every day at 12:00:00 PM
  final cronTrigger = CronTrigger.fromExpression(cron, ZoneId.UTC);

  final executionContext = DefaultTaskExecutionContext();
  final nextRun = cronTrigger.nextExecutionTime(executionContext);
  print('Cron: "${cronTrigger.getExpression()}" in Zone "${cronTrigger.getZone()}"');
  print('Next Scheduled Execution: $nextRun\n');

  // 2. Concurrent Task Scheduler
  print('[2] ConcurrentTaskScheduler Execution:');
  final scheduler = ConcurrentTaskScheduler(maxConcurrency: 3);

  final completer = Completer<void>();
  var tickCount = 0;

  final task = await scheduler.scheduleAtFixedRate(
    () {
      tickCount++;
      print('  [Tick $tickCount] Scheduled job executed at: ${DateTime.now().toIso8601String()}');
      if (tickCount >= 3 && !completer.isCompleted) {
        completer.complete();
      }
    },
    const Duration(milliseconds: 100),
    'demoRecurringTask',
  );

  print('Scheduled Task ID: "${task.getName()}" (Initial Total: ${scheduler.getTotalTaskCount()})');
  await completer.future;

  // Cancel task and shutdown scheduler cleanly
  task.cancel();
  await scheduler.shutdown(true);
  print('Task cancelled and scheduler successfully shut down.');

  print('\n========================================================');
  print('  ✅ Jetleaf Scheduling Example executed successfully!');
  print('========================================================');
}
