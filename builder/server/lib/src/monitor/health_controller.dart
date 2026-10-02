import 'package:jetleaf/core.dart';
import 'package:jetleaf_monitor/jetleaf_monitor.dart';
import 'package:jetleaf_web/jetleaf_web.dart';

/// {@template application_readiness}
/// Global application state tracking for health checks.
///
/// This class manages global flags that represent the readiness,
/// liveness, and shutdown state of the application. These flags are
/// typically referenced by health endpoints to determine how the system
/// should report its current status.
///
/// ### Usage
/// ```dart
/// ApplicationReadiness.markReady();
/// if (ApplicationReadiness.isHealthy) {
///   // proceed
/// }
/// ```
///
/// ### States
/// - **isReady**: Indicates whether the application is fully initialized
///   and ready to accept traffic.
/// - **isHealthy**: Indicates whether the application is currently healthy.
/// - **isShuttingDown**: Indicates whether the application is terminating
///   gracefully.
///
/// These values are static and intended to be updated by lifecycle hooks,
/// initialization routines, or shutdown signals.
/// {@endtemplate}
class ApplicationReadiness {
  /// Whether the application is fully started and ready to accept requests.
  static bool isReady = false;

  /// Whether the application is currently healthy.
  static bool isHealthy = true;

  /// Whether the application is performing a graceful shutdown.
  static bool isShuttingDown = false;

  /// {@macro application_readiness}
  ApplicationReadiness._();

  /// Marks the application as fully initialized and ready.
  static void markReady() {
    isReady = true;
    isHealthy = true;
  }

  /// Marks the application as unhealthy.
  ///
  /// An optional [reason] can be provided for logging purposes.
  static void markUnhealthy([String? reason]) {
    isHealthy = false;
    // Log the reason if provided.
  }

  /// Marks the application as shutting down gracefully.
  ///
  /// Also clears the readiness flag, since the application should not
  /// accept new traffic during shutdown.
  static void markShuttingDown() {
    isShuttingDown = true;
    isReady = false;
  }
}

@Monitor()
@RestController("/health")
class HealthController extends ApplicationEventListener<AvailabilityEvent<ReadinessState>> {
  const HealthController();

  @override
  Future<void> onApplicationEvent(AvailabilityEvent<ReadinessState> event) async {
    if (event.availability == ReadinessState.ACCEPTING_TRAFFIC) {
      ApplicationReadiness.markReady();
    } else {
      ApplicationReadiness.markUnhealthy();
    }
  }

  @GetMapping()
  Future<ResponseBody<Map<String, Object>>> getHealth() async {
    if (ApplicationReadiness.isHealthy && ApplicationReadiness.isReady) {
      return ResponseBody.ok({"active": true});
    }

    return ResponseBody.of(HttpStatus.SERVICE_UNAVAILABLE, {"active": false});
  }
}