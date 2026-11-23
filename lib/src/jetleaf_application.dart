import 'dart:async';

import 'package:jetleaf_tools/jetleaf_tools.dart' show runScan, ensureDevelopmentRuntime, getBoundAotRegistrar, AotRegistrar, RuntimeScannerConfiguration, RuntimeBuildMode;
import 'package:jetleaf_core/convert.dart';
import 'package:jetleaf_core/core.dart';
import 'package:jetleaf_core/pod.dart';
import 'package:jetleaf_core/env.dart';
import 'package:jetleaf_core/property.dart';
import 'package:jetleaf_core/lang.dart';
import 'package:jetleaf_core/logging.dart';
import 'package:jetleaf_core/utils.dart';

import 'jetleaf_exception.dart';
import 'banner/banner.dart';
import 'banner/_banner.dart';
import 'pod_factory_post_processor/lazy_initialization_pod_factory_post_processor.dart';
import 'pod_factory_post_processor/property_source_ordering_pod_factory_post_processor.dart';
import 'context/bootstrap_context.dart';
import 'context/bootstrap_context_impl.dart';
import 'context/context_factory.dart';
import 'pod_factory_post_processor/runner.dart';
import 'context/default_context_factory.dart';
import 'exception_handler/application_exception_handler.dart';
import 'env/property_source.dart';
import 'exception_handler/exception_reporter_manager.dart';
import 'listener/run_listener.dart';
import 'listener/run_listeners.dart';
import 'listener/lifecycle_run_listener.dart';
import 'shutdown/application_shutdown_handler_hook.dart';
import 'shutdown/application_shutdown_handler.dart';
import 'logging/logging_listener.dart';
import 'logging/startup_logger.dart';
import 'exception_handler/exception_handler.dart';

part 'internal/_jetleaf_application_support.dart';
part 'internal/_jetleaf_application_lifecycle.dart';

/// {@template jetleaf_application}
/// Main entry point for Jetleaf framework applications.
///
/// The [JetleafApplication] class provides a convenient way to bootstrap and launch
/// Jetleaf applications from a main() method. It handles application context
/// creation, environment setup, banner display, and application lifecycle management.
///
/// ### Key Features:
/// - **Application Bootstrapping**: Creates and configures the application context
/// - **Environment Setup**: Configures property sources and profiles
/// - **Lifecycle Management**: Handles startup, shutdown, and event publishing
/// - **Banner Display**: Shows application banner during startup
/// - **Exception Handling**: Comprehensive exception reporting and handling
/// - **Profile Management**: Active profile detection and configuration
/// - **Command Line Support**: Command line argument parsing and integration
///
/// ### Basic Usage:
/// ```dart
/// void main(List<String> args) {
///   JetleafApplication.run(MyApplication, args);
/// }
///
/// @Configuration
/// @ComponentScan
/// class MyApplication {
///   // Application configuration
/// }
/// ```
///
/// ### Advanced Configuration:
/// ```dart
/// void main(List<String> args) async {
///   final app = JetleafApplication(MyApplication);
///   
///   // Custom configuration
///   app.setBannerMode(BannerMode.CONSOLE);
///   app.setAdditionalProfiles({'production'});
///   app.setAllowCircularReferences(true);
///   
///   // Add custom initializers
///   app.addInitializer((context) {
///     // Custom context initialization
///   });
///   
///   // Launch application
///   final context = await app.create(args, null);
/// }
/// ```
///
/// ### Application Lifecycle:
/// 1. **Detection**: Detect runtime environment and application type
/// 2. **Bootstrap**: Create bootstrap context and register components
/// 3. **Environment Setup**: Configure property sources and profiles
/// 4. **Context Creation**: Build and configure application context
/// 5. **Refresh**: Initialize pods and publish application events
/// 6. **Runners**: Execute application and command line runners
/// 7. **Ready**: Application is fully operational
///
/// ### Property Sources (in order of precedence):
/// 1. Command line arguments (`--name=value`)
/// 2. DVM system properties (`System.getProperty()`)
/// 3. OS environment variables
/// 4. Application-specific property files
/// 5. Default properties
///
/// See also:
/// - [ConfigurableApplicationContext] for the application context interface
/// - [ApplicationRunner] for custom application initialization logic
/// - [CommandLineRunner] for command line specific initialization
/// - [ApplicationEvent] for application lifecycle events
/// {@endtemplate}
final class JetleafApplication extends _JetleafApplicationLifecycle {
  /// {@template jetleaf_application.application_version_property}
  /// Property name used to override application version.
  ///
  /// Set this property to override the version detected from the application's
  /// pubspec.yaml file or build configuration.
  ///
  /// Example:
  /// ```dart
  /// --jetleaf.application.version=2.0.1
  /// ```
  /// {@endtemplate}
  static final String JETLEAF_APPLICATION_VERSION = "jetleaf.application.version";

  /// {@template jetleaf_application.application_pid_property}
  /// Property name used to override application PID.
  ///
  /// Set this property to specify a custom process ID for the application.
  ///
  /// Example:
  /// ```dart
  /// --jetleaf.application.pid=12345
  /// ```
  /// {@endtemplate}
  static final String JETLEAF_APPLICATION_PID = "jetleaf.application.pid";

  /// {@template jetleaf_application.application_type_property}
  /// Property name used to override application type.
  ///
  /// Set this property to explicitly specify the application type, overriding
  /// automatic detection.
  ///
  /// Valid values: "web", "none", "batch", "cli"
  ///
  /// Example:
  /// ```dart
  /// --jetleaf.application.type=web
  /// ```
  /// {@endtemplate}
  static final String JETLEAF_APPLICATION_TYPE = "jetleaf.application.type";

  /// {@template jetleaf_application.jetleaf_version_property}
  /// Property name used to override Jetleaf version.
  ///
  /// Set this property to override the detected Jetleaf framework version.
  ///
  /// Example:
  /// ```dart
  /// --jetleaf.version=1.5.0
  /// ```
  /// {@endtemplate}
  static final String JETLEAF_VERSION = "jetleaf.version";

  /// {@template jetleaf_application.banner_location_property}
  /// Property name used for banner location.
  ///
  /// Set this property to specify a custom banner file location.
  ///
  /// Example:
  /// ```dart
  /// --banner.location=classpath:custom-banner.txt
  /// ```
  /// {@endtemplate}
  static final String BANNER_LOCATION = "banner.location";

  /// {@template jetleaf_application.banner_text_property}
  /// Property name used for banner text.
  ///
  /// Set this property to specify custom banner text directly.
  ///
  /// Example:
  /// ```dart
  /// --banner.text="My Custom Application"
  /// ```
  /// {@endtemplate}
  static final String BANNER_TEXT = "banner.text";

  /// {@template jetleaf_application.lazy_initialization_property}
  /// Property name used to override lazy initialization.
  ///
  /// Set this property to specify whether the application should be initialized lazily.
  ///
  /// Example:
  /// ```dart
  /// --jetleaf.lazy-initialization=true
  /// ```
  /// {@endtemplate}
  static final String LAZY_INITIALIZATION = "jetleaf.lazy-initialization";

  /// {@template jetleaf_application.shutdown_hook}
  /// Global shutdown hook for graceful application termination.
  ///
  /// Registers with the runtime to handle SIGTERM, SIGINT, and other
  /// termination signals for graceful shutdown.
  /// {@endtemplate}
  static final ApplicationShutdownHandlerHook _shutdownHook = ApplicationShutdownHandlerHook();

  /// {@template jetleaf_application.application_hook}
  /// Thread-local storage for application hooks.
  ///
  /// Allows customization of application behavior through hooks that can
  /// be set per-thread or per-application instance.
  /// {@endtemplate}
  static final LocalThread<ApplicationHook> _applicationHook = LocalThread<ApplicationHook>();

  /// {@template jetleaf_application.logger}
  /// Logger instance for JetleafApplication operations.
  ///
  /// Used for logging framework operations, startup information,
  /// and error conditions.
  /// {@endtemplate}
  static final Log _logger = LogFactory.getLog(JetleafApplication);

  /// {@macro jetleaf_application}
  ///
  /// Creates a new JetleafApplication instance with the specified primary source.
  ///
  /// [primarySource] the primary source object, typically the main application class
  ///
  /// Example:
  /// ```dart
  /// final app = JetleafApplication(MyApp);
  /// ```
  JetleafApplication(super.primarySource) {
    _applicationContextFactory = DefaultApplicationContextFactory();
    _applicationStartup = DefaultApplicationStartup();
    _applicationHook.set(DefaultApplicationHook([], _applicationStartup));
  }

  // ================================================= CREATE =================================================

  /// {@template jetleaf_application.create}
  /// Creates and initializes the application context.
  ///
  /// This is the main entry point for application creation and initialization.
  /// It handles runtime detection, bootstrap context creation, and application
  /// context building.
  ///
  /// ### Process Flow:
  /// 1. **Runtime Detection**: Detect AOT vs JIT compilation and validate runtime
  /// 2. **Bootstrap**: Create bootstrap context and register early components
  /// 3. **Listeners**: Collect and initialize application run listeners
  /// 4. **Context Building**: Create and configure the application context
  /// 5. **Startup**: Refresh context and execute application runners
  ///
  /// [args] command line arguments passed to the application
  /// [scanConfiguration] optional runtime scanner configuration to be applied to [runScan]
  ///
  /// Returns a [ConfigurableApplicationContext] representing the running application
  ///
  /// Throws:
  /// - [ApplicationContextException] if context creation fails
  /// - [IllegalStateException] if runtime requirements are not met
  /// - [MissingAotRegistrarException] if running in production/AOT mode without a registrar
  ///
  /// Example:
  /// ```dart
  /// final app = JetleafApplication(MyApp);
  /// final context = await app.create(args, null);
  /// ```
  /// {@endtemplate}
  Future<ConfigurableApplicationContext?> create(List<String> args, [RuntimeScannerConfiguration? scanConfiguration]) async {
    final system = _detector.detect(args);
    _system = system;

    return await runZonedGuarded<Future<ConfigurableApplicationContext?>>(() async {
      /// [Startup] is `Jetleaf`'s way of having control over the application's lifecycle as it pertains
      /// to the application startup process.
      ///
      /// It is to track the time taken to reach any point of the application startup process.
      _startup = StartupTracker.create();

      if (system.isDevelopmentMode() && !system.isRunningAot()) {
        await ensureDevelopmentRuntime(
          hasAotRegistrar: _aotRegistrar != null,
          isRunningFromDill: system.isRunningFromDill(),
          args: args,
        );

        _aotRegistrar ??= getBoundAotRegistrar();
      } else if (_aotRegistrar == null) {
        throw MissingAotRegistrarException();
      }

      if (_aotRegistrar case AotRegistrar registrar) {
        await registrar(null);
        Runtime.getAllClasses();
      }

      if (!Runtime.isPopulated || _aotRegistrar == null) {
        await runScan(
          args: args,
          config: scanConfiguration ?? _getConfig(),
          forceLoadLibraries: !system.isRunningFromDill() && !args.contains(Constant.JETLEAF_GENERATED_DIR_NAME),
        );
      }

      _mainApplicationClass = _primarySource is Class<Object>
        ? _primarySource
        : (_primarySource is Type ? Class.forType(_primarySource) : Class.forObject(_primarySource));

      /// We use the [JetleafApplicationShutdownHook] to register a shutdown hook with the system.
      ///
      /// This is to ensure that the application can be shut down gracefully when the user requests it.
      if (_registerShutdownHook) {
        _shutdownHook.enableShutdownHook();
      }

      _boostrapContext = await _createBootstrapContext();
      _boostrapContext.setApplicationClass(_mainApplicationClass);
      _applicationListeners = _getRunListeners(args);
      await _applicationListeners.onStarting(_boostrapContext, _mainApplicationClass);
      ConfigurableApplicationContext context = await _buildApplicationContext(args);

      try {
        if (context.isRunning()) {
          await _applicationListeners.onReady(context, _startup.getReady());
          StartupEvent.publish(context, _startup);
        }
      } on Throwable catch (e, st) {
        throw ExceptionHandler(
          _logger,
          _shutdownHook,
          _getExceptionReporters(context),
          _exitCodeExceptionHandlers,
        ).handleRunFailure(context, e, null, st);
      }

      return context;
    }, (Object error, StackTrace stack) {
      /// This is the uncaught exception handler for the entire Zone.
      ///
      /// We use this as a way to catch any exception which the application context might have missed.
      /// This is a last resort way of handling exceptions.
      ///
      /// We will try to handle the exception using the [ExceptionHandler].
      /// If it fails, we will log the exception using the [Log].
      ApplicationExceptionHandler.current.uncaughtException(error, stack);

      /// Also log it here if not handled by the custom handler's internal logic
      if (_logger.getIsErrorEnabled() && _loggingListener != null) {
        _logger.error("Uncaught exception in JetleafApplication run zone", error: error, stacktrace: stack);
      } else {
        System.err.println("Uncaught exception in JetleafApplication run zone: ${error.toString()}. $stack");
      }
    });
  }

  // ============================== RUN METHODS ==============================

  /// {@template jetleaf_application.run}
  /// Convenience method for running an application with a single primary source.
  ///
  /// This is the simplest way to launch a Jetleaf application from a main method.
  ///
  /// ### Usage:
  /// ```dart
  /// void main(List<String> args) {
  ///   JetleafApplication.run(MyApplication, args);
  /// }
  /// ```
  ///
  /// [primarySource] the primary source (typically main application class)
  /// [args] command line arguments
  /// [scanConfiguration] optional runtime scanner configuration to be applied to [runScan]
  /// [aotRegistrar] optional compile-time generated AOT registrar
  ///
  /// Returns the created application context
  /// {@endtemplate}
  static Future<ConfigurableApplicationContext?> run(
    Object primarySource,
    List<String> args, {
    RuntimeScannerConfiguration? scanConfiguration,
    AotRegistrar? aotRegistrar,
  }) {
    final app = JetleafApplication(primarySource);
    if (aotRegistrar != null) {
      app.setAotRegistrar(aotRegistrar);
    }
    return app.create(args, scanConfiguration);
  }

  // ============================== HOOKS ==============================

  /// {@template jetleaf_application.use_hook}
  /// Executes an action with a specific application hook.
  ///
  /// Application hooks allow customization of framework behavior during
  /// application creation and execution.
  ///
  /// ### Usage:
  /// ```dart
  /// JetleafApplication.useHook(MyApplicationHook(), () {
  ///   JetleafApplication.run(MyApplication, args);
  /// });
  /// ```
  ///
  /// [hook] the application hook to use
  /// [action] the action to execute with the hook active
  /// {@endtemplate}
  static void useHook(ApplicationHook hook, Runnable action) {
    useThrowableHook(hook, () {
      action.run();
      return null;
    });
  }

  /// {@template jetleaf_application.use_throwable_hook}
  /// Executes a throwable action with a specific application hook.
  ///
  /// Similar to [useHook] but supports actions that can throw exceptions
  /// and return values.
  ///
  /// [hook] the application hook to use
  /// [action] the throwable action to execute
  ///
  /// Returns the result of the action
  /// {@endtemplate}
  static T useThrowableHook<T>(ApplicationHook hook, ThrowingSupplier<T> action) {
    _applicationHook.set(hook);
    try {
      return action.get();
    } finally {
      _applicationHook.remove();
    }
  }

  // ============================== EXIT AND CLOSE ==============================

  /// {@template jetleaf_application.exit}
  /// Gracefully exits the application with the appropriate exit code.
  ///
  /// This method:
  /// 1. Collects exit code from all registered exit code generators
  /// 2. Publishes an exit code event
  /// 3. Closes the application context
  /// 4. Returns the determined exit code
  ///
  /// [context] the application context to close
  /// [exitCodeGenerators] additional exit code generators
  ///
  /// Returns the exit code for the application
  /// {@endtemplate}
  static Future<int> exit(ApplicationContext context, List<ExitCodeGenerator> exitCodeGenerators) async {
    int exitCode = 0;
    final cls = Class<ExitCodeGenerator>(null, PackageNames.MAIN);

    try {
      try {
        final generators = ExitCodeGenerators();
        final result = await context.getPodsOf<ExitCodeGenerator>(cls);

        final pods = result.values.toList();
        generators.addAllGenerators(exitCodeGenerators);
        generators.addAllGenerators(pods);

        exitCode = generators.getExitCode();

        if (exitCode != 0) {
          context.publishEvent(ExitCodeEvent(context, exitCode));
        }
      } finally {
        await close(context);
      }
    } on Exception catch (ex) {
      ex.printStackTrace();
      exitCode = (exitCode != 0) ? exitCode : 1;
    }

    return exitCode;
  }

  /// {@template jetleaf_application.close}
  /// Closes the application context and releases resources.
  ///
  /// This method should be called when the application is being shut down
  /// to ensure proper cleanup of resources.
  ///
  /// [context] the application context to close
  /// {@endtemplate}
  static Future<void> close(ApplicationContext context) async {
    if (context is ConfigurableApplicationContext) {
      await context.close();
    }
  }

  // ============================== SHUTDOWN HANDLERS ==============================

  /// {@template jetleaf_application.get_shutdown_handler}
  /// Gets the global application shutdown handler.
  ///
  /// The shutdown handler manages graceful application termination and
  /// can be used to register custom shutdown hooks.
  ///
  /// Returns the global [ApplicationShutdownHandler] instance
  /// {@endtemplate}
  static ApplicationShutdownHandler getShutdownHandler() => _shutdownHook.handler;
}