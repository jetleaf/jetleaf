import 'package:jetleaf_core/context.dart';
import 'package:jetleaf_core/core.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_logging/logging.dart';

/// {@template exception_reporter_manager}
/// Discovers, instantiates, and manages all available implementations of
/// [ExceptionReporter] within the application's classpath.
///
/// This class acts as the **central registry and factory** for exception-reporting
/// components. It uses JetLeaf's reflection system to:
///
/// 1. Locate all non-abstract subclasses of [ExceptionReporter]  
/// 2. Automatically construct each instance using:
///    - A no-argument constructor, **or**
///    - The “best” constructor that accepts an [ApplicationContext]
/// 3. Inject dependencies using [ExecutableArgumentResolver]  
/// 4. Log discovery and instantiation steps for visibility
///
/// This allows application modules or extensions to contribute exception reporters
/// simply by defining subclasses—no manual registration required.
///
/// ### Discovery Behavior
/// - Only concrete (non-abstract) subclasses of [ExceptionReporter] are instantiated  
/// - If a class has **no usable constructor**, it is skipped with a warning  
/// - Constructor resolution follows this priority:
///   1. No-argument constructor  
///   2. Constructor compatible with `[ApplicationContext]`  
///
/// ### Example
/// ```dart
/// final manager = ExceptionReporterManager(context);
/// final reporters = manager.getReporters();
///
/// for (final reporter in reporters) {
///   reporter.reportException(Exception("Test"));
/// }
/// ```
///
/// ### Logging
/// - **INFO**: When attempting to instantiate an individual reporter  
/// - **WARN**: When a reporter lacks a usable constructor  
/// - Errors during instantiation are swallowed silently (intentionally),
///   allowing the discovery process to continue without failing the application.
///
/// {@endtemplate}
final class ExceptionReporterManager {
  /// The application context used for dependency injection during reporter instantiation.
  final ConfigurableApplicationContext? _context;

  /// Logger instance for discovery and instantiation visibility.
  final Log _logger = LogFactory.getLog(ExceptionReporterManager);

  /// {@macro exception_reporter_manager}
  ExceptionReporterManager(this._context);

  /// Discovers and instantiates all available [ExceptionReporter] implementations.
  ///
  /// This method:
  /// - Scans the classpath for subclasses of [ExceptionReporter]  
  /// - Filters out abstract classes  
  /// - Attempts to construct each reporter using the best available constructor  
  /// - Applies argument resolution and dependency injection  
  ///
  /// Returns a list of successfully instantiated reporters.
  ///
  /// Any errors during instantiation are safely ignored so that one faulty
  /// reporter does not prevent others from loading.
  List<ExceptionReporter> getReporters() {
    // Root reflective class representing ExceptionReporter
    final cac = Class<ExceptionReporter>(null, PackageNames.CORE);

    final sources = <ExceptionReporter>[];

    // Get all non-abstract subclasses
    final classes = cac.getSubClasses().where((cl) => !cl.isAbstract());

    for(final cls in classes) {
      if(_logger.getIsInfoEnabled()) {
        _logger.info("Attempting to instantiate the exception reporter ${cls.getName()}");
      }

      final source = ExecutableInstantiator.of(cls)
        .withSelector(ExecutableSelector().and(Class<ApplicationContext>()))
        .withArgumentResolver(ExecutableArgumentResolver().and(Class<ApplicationContext>(), _context))
        .newInstance();
      
      if (source is ExceptionReporter) {
        sources.add(source);
      }
    }

    return sources;
  }
}