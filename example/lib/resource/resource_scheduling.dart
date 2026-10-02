import 'package:example/core/stereotype_examples.dart';
import 'package:jetleaf/jetleaf.dart';
import 'package:jetleaf_scheduling/jetleaf_scheduling.dart';

@Component()
@RequiredAll()
class ScheduledTasks {
  final AsyncConfig config;
  final ValidationError error;

  const ScheduledTasks(this.config, this.error);

  // ─────────────────────────────────────────────────────────────
  // Execute every 10 seconds
  // ─────────────────────────────────────────────────────────────
  
  @Scheduled(fixedRate: Duration(seconds: 10))
  Future<void> every10Seconds() async {
    // final result = await config.getValidation();
    // final gen = await config.getGeneric();

    // print('⏰ Running scheduled task: every10Seconds() - $result - $gen');
    // try {
    //   print('✅ Completed scheduled task: every10Seconds()');
    // } catch (e, st) {
    //   print('❌ Error in scheduled task: every10Seconds() - $e - $st');
    // }
  }

  // ─────────────────────────────────────────────────────────────
  // Execute every 30 seconds
  // ─────────────────────────────────────────────────────────────
  @Scheduled(fixedRate: Duration(seconds: 30))
  Future<void> every30Seconds() async {
    // print('⏰ Running scheduled task: every30Seconds()');
    // try {
    //   // Add your logic here
    //   print('✅ Completed scheduled task: every30Seconds()');
    // } catch (e, st) {
    //   print('❌ Error in scheduled task: every30Seconds() - $e - $st');
    // }
  }

  // ─────────────────────────────────────────────────────────────
  // Execute every minute - Clear all cache
  // ─────────────────────────────────────────────────────────────
  @Scheduled(type: CronType.EVERY_MINUTE)
  Future<void> everyMinute() async {
    // print('⏰ Running scheduled task: everyMinute() (clear cache)');
    // try {
    //   print('✅ Completed scheduled task: everyMinute()');
    // } catch (e, st) {
    //   print('❌ Error in scheduled task: everyMinute() - $e - $st');
    // }
  }

  // ─────────────────────────────────────────────────────────────
  // Execute every 45 seconds
  // ─────────────────────────────────────────────────────────────
  @Scheduled(fixedRate: Duration(seconds: 45))
  Future<void> every45Seconds() async {
    // print('⏰ Running scheduled task: every45Seconds()');
    // try {
    //   print('✅ Completed scheduled task: every45Seconds()');
    // } catch (e, st) {
    //   print('❌ Error in scheduled task: every45Seconds() - $e - $st');
    // }
  }

  // ─────────────────────────────────────────────────────────────
  // Execute with fixed delay - Async operations
  // ─────────────────────────────────────────────────────────────
  @Scheduled(fixedDelay: Duration(seconds: 15))
  Future<void> fixedDelay() async {
    // print('⏰ Running scheduled task: fixedDelay()');
    // try {
    //   print('✅ Completed scheduled task: fixedDelay()');
    // } catch (e, st) {
    //   print('❌ Error in scheduled task: fixedDelay() - $e - $st');
    // }
  }
}