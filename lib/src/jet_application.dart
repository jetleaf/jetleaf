// ---------------------------------------------------------------------------
// 🍃 JetLeaf Framework - https://jetleaf.hapnium.com
//
// Copyright © 2025 Hapnium & JetLeaf Contributors. All rights reserved.
//
// This source file is part of the JetLeaf Framework and is protected
// under copyright law. You may not copy, modify, or distribute this file
// except in compliance with the JetLeaf license.
//
// For licensing terms, see the LICENSE file in the root of this project.
// ---------------------------------------------------------------------------
// 
// 🔧 Powered by Hapnium — the Dart backend engine 🍃

import 'dart:async';

import 'package:jetleaf_convert/convert.dart';
import 'package:jetleaf_core/context.dart';
import 'package:jetleaf_core/core.dart';
import 'package:jetleaf_pod/pod.dart';
import 'package:jetleaf_env/env.dart';
import 'package:jetleaf_env/property.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_logging/logging.dart';
import 'package:jetleaf_utils/utils.dart';

import 'banner/banner.dart';
import 'banner/_banner.dart';
import 'components/pod_factory_post_processors.dart';
import 'context/bootstrap_context.dart';
import 'context/bootstrap_context_impl.dart';
import 'context/context_factory.dart';
import 'components/runner.dart';
import 'context/default_context_factory.dart';
import 'exception_handler/application_exception_handler.dart';
import 'env/property_source.dart';
import 'exception_handler/exception_reporter_manager.dart';
import 'listener/run_listener.dart';
import 'listener/run_listeners.dart';
import 'shutdown/application_shutdown_handler_hook.dart';
import 'shutdown/application_shutdown_handler.dart';
import 'logging/logging_listener.dart';
import 'logging/startup_logger.dart';
import 'exception_handler/exception_handler.dart';

/// {@template jet_application}
/// Main entry point for JetLeaf framework applications.
///
/// The [JetApplication] class provides a convenient way to bootstrap and launch
/// JetLeaf applications from a main() method. It handles application context
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
///   JetApplication.run(MyApplication, args);
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
///   final app = JetApplication(MyApplication);
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
final class JetApplication {
  /// {@template jet_application.application_version_property}
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

  /// {@template jet_application.application_pid_property}
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

  /// {@template jet_application.application_type_property}
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

  /// {@template jet_application.jetleaf_version_property}
  /// Property name used to override JetLeaf version.
  ///
  /// Set this property to override the detected JetLeaf framework version.
  ///
  /// Example:
  /// ```dart
  /// --jetleaf.version=1.5.0
  /// ```
  /// {@endtemplate}
  static final String JETLEAF_VERSION = "jetleaf.version";

  /// {@template jet_application.banner_location_property}
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

  /// {@template jet_application.banner_text_property}
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

  /// {@template jet_application.lazy_initialization_property}
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

  /// {@template jet_application.primary_source}
  /// The primary source object for this application.
  ///
  /// Typically the main application class annotated with `@Configuration`
  /// or containing the main method.
  ///
  /// Used to determine the main application class and package scanning base.
  /// {@endtemplate}
  final Object _primarySource;
  
  /// {@template jet_application.shutdown_hook}
  /// Global shutdown hook for graceful application termination.
  ///
  /// Registers with the runtime to handle SIGTERM, SIGINT, and other
  /// termination signals for graceful shutdown.
  /// {@endtemplate}
  static final ApplicationShutdownHandlerHook _shutdownHook = ApplicationShutdownHandlerHook();

  /// {@template jet_application.application_hook}
  /// Thread-local storage for application hooks.
  ///
  /// Allows customization of application behavior through hooks that can
  /// be set per-thread or per-application instance.
  /// {@endtemplate}
  static final LocalThread<ApplicationHook> _applicationHook = LocalThread<ApplicationHook>();

  /// {@template jet_application.initializers}
  /// Application context initializers for custom context configuration.
  ///
  /// These initializers are called before the context is refreshed, allowing
  /// for custom configuration of the application context.
  /// {@endtemplate}
  List<ApplicationContextInitializer> _initializers = [];

  /// {@template jet_application.listeners}
  /// Application event listeners for lifecycle event handling.
  ///
  /// These listeners receive application events such as context refresh,
  /// startup completion, and shutdown initiation.
  /// {@endtemplate}
	List<ApplicationEventListener> _listeners = [];

  /// {@template jet_application.bootstrap_initializers}
  /// Bootstrap registry initializers for early component registration.
  ///
  /// These initializers are called during bootstrap context creation,
  /// allowing for registration of components before the main context is built.
  /// {@endtemplate}
	List<BootstrapRegistryInitializer> _bootstrapInitializers = [];

  /// {@template jet_application.exception_reporters}
  /// Exception reporters for handling and reporting application exceptions.
  ///
  /// These reporters are called when unhandled exceptions occur during
  /// application startup or operation.
  /// {@endtemplate}
  List<ExceptionReporter> _exceptionReporters = [];

  /// {@template jet_application.exit_code_exception_handlers}
  /// Exit code exception handlers for converting exceptions to exit codes.
  ///
  /// These handlers determine the appropriate exit code when the application
  /// terminates due to an exception.
  /// {@endtemplate}
  final List<ExitCodeExceptionHandler> _exitCodeExceptionHandlers = [];

  /// {@template jet_application.default_properties}
  /// Default properties applied to the environment.
  ///
  /// These properties have the lowest precedence and can be overridden by
  /// other property sources.
  /// {@endtemplate}
  Map<String, Object> _defaultProperties = {};

  /// {@template jet_application.additional_profiles}
  /// Additional active profiles for the application.
  ///
  /// These profiles are activated in addition to any profiles specified
  /// via command line or environment variables.
  /// {@endtemplate}
  Set<String> _additionalProfiles = {};

  /// {@template jet_application.startup_tracker}
  /// Tracks application startup timing and phases.
  ///
  /// Provides detailed timing information for different startup phases
  /// and can be used for performance monitoring and logging.
  /// {@endtemplate}
  late StartupTracker _startup;

  /// {@template jet_application.main_application_class}
  /// The main application class determined from the primary source.
  ///
  /// Used for package scanning, banner display, and various framework
  /// operations that require knowledge of the application class.
  /// {@endtemplate}
  late Class<Object> _mainApplicationClass;

  /// {@template jet_application.application_startup}
  /// Tracks application startup metrics and performance data.
  ///
  /// Provides detailed information about application initialization
  /// timing and can be used for monitoring and optimization.
  /// {@endtemplate}
  late ApplicationStartup _applicationStartup;

  /// {@template jet_application.bootstrap_context}
  /// Bootstrap context for early component registration and resolution.
  ///
  /// Used during the bootstrap phase to register components that are
  /// needed before the main application context is created.
  /// {@endtemplate}
  late ConfigurableBootstrapContext _boostrapContext;

  /// {@template jet_application.application_context_factory}
  /// Factory for creating application contexts based on application type.
  ///
  /// Determines the appropriate context implementation (web, standalone, etc.)
  /// based on the detected application type and configuration.
  /// {@endtemplate}
  late ApplicationContextFactory _applicationContextFactory;

  /// {@template jet_application.application_listeners}
  /// Manages application run listeners for lifecycle event publishing.
  ///
  /// Coordinates the calling of run listeners at various points in the
  /// application lifecycle.
  /// {@endtemplate}
  late ApplicationRunListeners _applicationListeners;

  /// {@template jet_application.conversion_service}
  /// Service for type conversion and formatting.
  ///
  /// Used by the framework for converting between different data types
  /// during configuration processing and property resolution.
  /// {@endtemplate}
  late ConfigurableConversionService _conversionService;

  /// {@template jet_application.runtime_provider}
  /// Runtime provider for environment detection and system interaction.
  ///
  /// Provides information about the runtime environment and handles
  /// system-level operations.
  /// {@endtemplate}
  RuntimeProvider? _runtimeProvider;

  /// {@template jet_application.pod_name_generator}
  /// Custom pod name generator for pod naming strategy.
  ///
  /// If specified, this generator is used to create names for registered
  /// pods instead of the default naming strategy.
  /// {@endtemplate}
  PodNameGenerator? _podNameGenerator;

  /// {@template jet_application.environment}
  /// The environment for this application.
  ///
  /// Manages property sources, profiles, and environment-specific
  /// configuration for the application.
  /// {@endtemplate}
  ConfigurableEnvironment? _environment;

  /// {@template jet_application.banner}
  /// The banner to be displayed at application startup.
  ///
  /// Can be customized to show application-specific information
  /// during startup.
  /// {@endtemplate}
  Banner? _banner;

  /// {@template jet_application.logging_listener}
  /// Global logging listener for framework logging events.
  ///
  /// Receives logging events from throughout the framework and
  /// can be used for custom logging integration.
  /// {@endtemplate}
  LoggingListener? _loggingListener;

  /// {@template jet_application.environment_prefix}
  /// Prefix for environment property resolution.
  ///
  /// Used when resolving properties from the environment to
  /// support namespaced configuration.
  /// {@endtemplate}
  String _environmentPrefix = "";

  /// {@template jet_application.banner_mode}
  /// The display mode of the application banner at startup.
  ///
  /// Controls how and where the application banner is displayed
  /// during startup.
  ///
  /// Defaults to [BannerMode.CONSOLE].
  /// {@endtemplate}
  BannerMode _bannerMode = BannerMode.CONSOLE;

  /// {@template jet_application.application_type}
  /// The type of application (e.g., [ApplicationType.WEB], [ApplicationType.NONE]).
  ///
  /// Determines the appropriate context implementation and configuration
  /// for the specific application type.
  ///
  /// Defaults to [ApplicationType.NONE].
  /// {@endtemplate}
  ApplicationType _applicationType = ApplicationType.NONE;

  /// {@template jet_application.register_shutdown_hook}
  /// Whether the application should register a shutdown hook with the runtime.
  ///
  /// When true, the application registers hooks for graceful shutdown
  /// on SIGTERM, SIGINT, and other termination signals.
  ///
  /// Defaults to `true`.
  /// {@endtemplate}
  bool _registerShutdownHook = true;

  /// {@template jet_application.allow_circular_references}
  /// Whether circular references between pods are allowed.
  ///
  /// When true, the framework attempts to resolve circular dependencies
  /// between pods using proxy objects or other strategies.
  ///
  /// Defaults to `false`.
  /// {@endtemplate}
  bool _allowCircularReferences = false;

  /// Tracks whether reporters have already been fetched from the application context.
  /// 
  /// Used to prevent repeatedly querying the context for reporters, since
  /// reporter lookup is typically an expensive or one-time initialization step.
  bool _reportersFetched = false;

  /// {@template jet_application.allow_definition_overriding}
  /// Whether a pod definition may be overridden.
  ///
  /// When true, later registrations of the same pod name will override
  /// earlier registrations.
  ///
  /// Defaults to `false`.
  /// {@endtemplate}
  bool _allowDefinitionOverriding = false;

  /// {@template jet_application.keep_alive}
  /// Whether the application should stay alive after startup.
  ///
  /// When true, the application will not exit automatically after
  /// startup completes, typically used for web applications or
  /// long-running services.
  ///
  /// Defaults to `false`.
  /// {@endtemplate}
  bool _keepAlive = false;

  /// {@template jet_application.lazy_initialization}
  /// Whether pods should be lazily initialized instead of eagerly.
  ///
  /// When true, pods are created on first access rather than during
  /// application startup.
  ///
  /// Defaults to `false`.
  /// {@endtemplate}
  bool _lazyInitialization = false;

  /// {@template jet_application.add_command_line_properties}
  /// Whether command line properties should be added to the environment.
  ///
  /// When true, command line arguments in the form `--name=value` are
  /// parsed and added to the environment as properties.
  ///
  /// Defaults to `true`.
  /// {@endtemplate}
  bool _addCommandLineProperties = true;

  /// {@template jet_application.add_conversion_service}
  /// Whether a conversion service should be added to the environment.
  ///
  /// When true, a default conversion service is registered for type
  /// conversion operations throughout the framework.
  ///
  /// Defaults to `true`.
  /// {@endtemplate}
  bool _addConversionService = true;

  /// {@template jet_application.log_startup_info}
  /// Whether startup information should be logged.
  ///
  /// When true, detailed startup information including active profiles
  /// and timing is logged during application initialization.
  ///
  /// Defaults to `true`.
  /// {@endtemplate}
  final bool _logStartupInfo = true;

  /// {@template configurable_pod_factory.expression_resolver}
  /// Holds the currently registered [PodExpressionResolver], if any.
  ///
  /// The resolver is responsible for evaluating pod expressions at runtime,
  /// such as those used in `@Value`, `@Conditional`, or other dynamic
  /// annotations within Jetleaf pods.
  ///
  /// - Can be null if no resolver is registered.
  /// - Provides the central mechanism for expression resolution across the pod factory.
  ///
  /// ### Example:
  /// ```dart
  /// if (_expressionResolver != null) {
  ///   final context = _expressionResolver!.createContext();
  ///   final value = context.evaluate('some.expression');
  /// }
  /// ```
  /// {@endtemplate}
  PodExpressionResolver? _expressionResolver;

  /// {@template jet_application.system_detector}
  /// Detector for system properties and runtime environment.
  ///
  /// Used to detect information about the runtime environment,
  /// including AOT vs JIT compilation mode.
  /// {@endtemplate}
  final SystemDetector _detector = StandardSystemDetector();

  /// {@template jet_application.logger}
  /// Logger instance for JetApplication operations.
  ///
  /// Used for logging framework operations, startup information,
  /// and error conditions.
  /// {@endtemplate}
  static final Log _logger = LogFactory.getLog(JetApplication);

  /// {@macro jet_application}
  ///
  /// Creates a new JetApplication instance with the specified primary source.
  ///
  /// [primarySource] the primary source object, typically the main application class
  /// [primarySources] additional primary sources for component scanning
  ///
  /// Example:
  /// ```dart
  /// final app = JetApplication(MyApp);
  /// // or with additional sources
  /// final app = JetApplication(MyApp, {Config1, Config2});
  /// ```
  JetApplication(this._primarySource) {
    _applicationContextFactory = DefaultApplicationContextFactory();
    _applicationStartup = DefaultApplicationStartup();
    _applicationHook.set(DefaultApplicationHook([], _applicationStartup));
  }

  // ================================================= CREATE =================================================
  
  /// {@template jet_application.create}
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
  /// [provider] optional runtime provider for environment detection
  ///
  /// Returns a [ConfigurableApplicationContext] representing the running application
  ///
  /// Throws:
  /// - [ApplicationContextException] if context creation fails
  /// - [IllegalStateException] if runtime requirements are not met
  ///
  /// Example:
  /// ```dart
  /// final app = JetApplication(MyApp);
  /// final context = await app.create(args, null);
  /// ```
  /// {@endtemplate}
  Future<ConfigurableApplicationContext?> create(List<String> args, RuntimeProvider? provider) async {
    final system = _detector.detect(args);
    _runtimeProvider = provider ?? GLOBAL_RUNTIME_PROVIDER;

    /// As at v1.0.0, we have two different ways of running the `JetLeaf` application.
    /// 
    /// 1. Running from a built application:
    ///    Here, the application has been built and contains all that it needs to run.
    ///    This is mostly seen when the developer is done building and wants to deploy the application.
    ///    At this point, Jetleaf enforces the check of AOT and RuntimeProvider since it is crucial to
    ///    providing the maximum experience the user needs.
    /// 
    /// 2. Running on development or JIT:
    ///    This does not require the RuntimeProvider to be present at the time of running the application,
    ///    because Jetleaf since has its authority over the application, it can automatically build
    ///    the application and run it.
    /// 
    /// We provide these two different ways to make the developer's experience swift and better.
    /// Since we cannot control how the run method executes from the user's IDE, we simulate such experience
    /// by detecting where the application is running from, in order to decide what to level with.

    if(system.isRunningAot() && _runtimeProvider == null) {
      /// Since the build pipeline failed, we can't proceed with the application startup.
      /// At this point, nothing has been initialized, so we will exit the application gracefully with
      /// just [System.out.println].
      System.out.printErr('''
        Application failed to start. Did you forget to bootstrap or build the application?

        For development, you need to use the `JetLeaf` cli command to run your application.
          - `jl dev`
            Bootstraps your application and runs it in development mode.

        For production, you need to use the `JetLeaf` cli command to build your application. Then,
        utilize the dart run command with the target file to run your application.
          - `jl build`
            Compiles your application to an executable file.
          - `dart run build/main.dill`
            Runs your application in production mode.
      ''');
      System.exit(1);
    }

    /// At this point, the application is presumed to have been fully bootstrapped by the developer,
    /// compiled and ready to execute fully functional .dill file, .dart file, .exe file.
    /// 
    /// So, we will just go ahead to create the [ConfigurableApplicationContext] and start the application.
    return _create(args);
  }

  /// {@template jet_application._create}
  /// Internal method for application creation with proper error handling.
  ///
  /// Wraps the creation process in a guarded zone to ensure proper exception
  /// handling and resource cleanup.
  ///
  /// [args] command line arguments
  ///
  /// Returns the created application context
  /// {@endtemplate}
  Future<ConfigurableApplicationContext?> _create(List<String> args) async {
    return await runZonedGuarded<Future<ConfigurableApplicationContext?>>(() async {
      /// [Startup] is `JetLeaf`'s way of having control over the application's lifecycle as it pertains
      /// to the application startup process.
      /// 
      /// It is to track the time taken to reach any point of the application startup process.
      _startup = StartupTracker.create();

      // Runtime is mostly null when the application did not run through the jetleaf's cli command
      RuntimeProvider? runtime = _runtimeProvider;
      if(runtime == null) {
        final result = await runScan(forceLoadLibraries: !args.contains(Constant.JETLEAF_GENERATED_DIR_NAME));
        runtime = result;
      }
      
      _runtimeProvider = runtime;
      GLOBAL_RUNTIME_PROVIDER = runtime;
      Runtime.register(runtime);
      _mainApplicationClass = Class.forObject(_primarySource);

      /// We use the [JetApplicationShutdownHook] to register a shutdown hook with the system.
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
      if(_logger.getIsErrorEnabled() && _loggingListener != null) {
        _logger.error("Uncaught exception in JetApplication run zone", error: error, stacktrace: stack);
      } else {
        System.err.println("Uncaught exception in JetApplication run zone: ${error.toString()}. $stack");
      }
    });
  }

  // ============================================== BOOTSTRAPPING ==============================================
  
  /// {@template jet_application._create_bootstrap_context}
  /// Creates the bootstrap context for early component registration.
  ///
  /// The bootstrap context allows registration of components that are needed
  /// before the main application context is created. This is useful for
  /// infrastructure components, custom factories, or other early-stage
  /// dependencies.
  ///
  /// Returns a configured [DefaultBootstrapContext]
  ///
  /// Example of bootstrap initializer:
  /// ```dart
  /// class MyBootstrapInitializer implements BootstrapRegistryInitializer {
  ///   @override
  ///   Future<void> initialize(BootstrapContext context) async {
  ///     context.register(MyEarlyService, () => MyEarlyService());
  ///   }
  /// }
  /// ```
  /// {@endtemplate}
  Future<DefaultBootstrapContext> _createBootstrapContext() async {
    DefaultBootstrapContext bootstrapContext = DefaultBootstrapContext();

    for (var bri in _bootstrapInitializers) {
      await bri.initialize(bootstrapContext);
    }

    /// Add the main instance of the application to the bootstrap context, should the developer want it.
    bootstrapContext.register(_mainApplicationClass, BootstrapInstanceSupplier.of(_primarySource));

    return bootstrapContext;
  }

  // ============================================== RUN LISTENERS ========================================== 
  
  /// {@template jet_application._get_run_listeners}
  /// Discovers and initializes application run listeners.
  ///
  /// Run listeners are called at various points in the application lifecycle
  /// and can be used to customize startup behavior, add monitoring, or
  /// integrate with external systems.
  ///
  /// Listeners are discovered through:
  /// 1. Classpath scanning for [ApplicationRunListener] implementations
  /// 2. Application hooks registered via [useHook]
  ///
  /// [args] command line arguments for listener configuration
  ///
  /// Returns an [ApplicationRunListeners] instance managing all discovered listeners
  /// {@endtemplate}
  ApplicationRunListeners _getRunListeners(List<String> args) {
		final listeners = <ApplicationRunListener>[];

    final classes = Class<ApplicationRunListener>(null, PackageNames.MAIN).getSubClasses();
    if(classes.isNotEmpty) {
      for(final cls in classes) {
        // Skip ApplicationRunListeners
        if(cls == Class<ApplicationRunListeners>(null, PackageNames.MAIN)) {
          continue;
        }

        try {
          final listener = ExecutableInstantiator.of(cls).newInstance();
          if (listener is ApplicationRunListener) {
            listeners.add(listener);
          } else if(_logger.getIsWarnEnabled()) {
            _logger.warn("ApplicationRunListener ${cls.getName()} was not instantiated because it was not a no-arg constructor or not of listener type");
          }
        } catch (_) {
          // No-op
        }
      }
    }

    final hook = _applicationHook.get();
		final hookListener = (hook != null) ? hook.getRunListener(this) : null;
		if (hookListener != null) {
			listeners.add(hookListener);
		}

		return ApplicationRunListeners(listeners, _applicationStartup);
	}

  // ============================================= APPLICATION CONTEXT ========================================

  /// {@template jet_application._build_application_context}
  /// Builds and configures the main application context.
  ///
  /// This method orchestrates the complete context creation process:
  /// 1. Environment setup and configuration
  /// 2. Banner display
  /// 3. Application type detection
  /// 4. Context creation and configuration
  /// 5. Context refresh and pod initialization
  /// 6. Runner execution
  ///
  /// [args] command line arguments for context configuration
  ///
  /// Returns the fully configured and refreshed application context
  ///
  /// Throws:
  /// - [RuntimeException] if context creation fails
  /// - [PodDefinitionException] if pod configuration is invalid
  /// {@endtemplate}
  Future<ConfigurableApplicationContext> _buildApplicationContext(List<String> args) async {
    ConfigurableApplicationContext? context;

    try {
      ApplicationArguments aargs = DefaultApplicationArguments(args);
      _applicationType = _detectApplicationType();
      context = _applicationContextFactory.create(_applicationType);

      ConfigurableEnvironment environment = await _setupEnvironment(aargs, context.getSupportingEnvironment());

      final listener = _boostrapContext.get(
        Class<LoggingListener>(null, PackageNames.LOGGING),
        orElse: ApplicationLoggingListener(_mainApplicationClass, environment)
      );

      if(_loggingListener == null) {
        setLoggingListener(listener);
      }
      
      _banner = _printBanner(environment);


      if(_logger.getIsInfoEnabled()) {
        _logger.info("Launching ${_mainApplicationClass.getName()} with application type: ${_applicationType.getEmoji()} ${_applicationType.getName()}");
      }

      context.setApplicationStartup(_applicationStartup);
      context.setMainApplicationClass(_mainApplicationClass);
      
      // At this point, [Environment] must have been set, so we can proceed with caution.
      context.setEnvironment(_environment!);

      await _setupApplicationContext(context, aargs);
      
      if (_registerShutdownHook) {
        _shutdownHook.registerApplicationContext(context);
      }

       await context.setup();
      _startup.started();
      StartupEvent.publish(context, _startup);

      if (_logStartupInfo) {
        _startupLogger.logStarted(_logger, _startup);
      }

      await _applicationListeners.onStarted(context, _startup.getTimeTakenToStarted());
      StartupEvent.publish(context, _startup);
      await _callRunners(context, aargs);

      if (context.getPodExpressionResolver() != null && _expressionResolver == null) {
        _expressionResolver = context.getPodExpressionResolver();
      }

      await _refreshConversionService(context);

      return context;
    } on Throwable catch (e, st) {
      throw ExceptionHandler(
        _logger,
        _shutdownHook,
        _getExceptionReporters(context),
        _exitCodeExceptionHandlers,
      ).handleRunFailure(context, e, null, st);
    }
  }

  /// {@template jet_application._startup_logger}
  /// Gets the startup logger for application initialization logging.
  ///
  /// The startup logger provides specialized logging for application
  /// startup phases, including timing information and status updates.
  ///
  /// Returns a [StartupLogger] instance configured for this application
  ///
  /// Throws:
  /// - [IllegalArgumentException] if environment is not set
  /// {@endtemplate}
  StartupLogger get _startupLogger {
    if(_environment == null) {
      throw IllegalArgumentException("Environment cannot be null when accessing startup logger");
    }

    return StartupLogger(_mainApplicationClass, _environment!);
  }

  /// {@template jet_application._get_conversion_service}
  /// Gets the conversion service for type conversion operations.
  ///
  /// Returns the configured conversion service or a default implementation
  /// if none is configured.
  ///
  /// Returns a [ConfigurableConversionService] instance
  /// {@endtemplate}
  ConfigurableConversionService _getConversionService() {
    try {
      return _conversionService;
    } catch (_) {
      _conversionService = ApplicationConversionService();
      return _conversionService;
    }
  }

  // ============================================= ENVIRONMENT HANDLING ========================================
  
  /// {@template jet_application._setup_environment}
  /// Sets up and configures the application environment.
  ///
  /// Configures property sources in order of precedence:
  /// 1. Command line properties
  /// 2. System properties
  /// 3. Environment variables
  /// 4. Default properties
  ///
  /// Also handles profile activation and conversion service setup.
  ///
  /// [args] application arguments for command line property source
  ///
  /// Returns the configured [ConfigurableEnvironment]
  /// {@endtemplate}
  Future<ConfigurableEnvironment> _setupEnvironment(ApplicationArguments args, ConfigurableEnvironment environment) async {
    ConfigurableEnvironment env = _environment ?? environment;
    
    if (_addConversionService) {
      env.setConversionService(_getConversionService());
    }

    _configurePropertySources(env, args.getSourceArgs());
    
    if(_additionalProfiles.isNotEmpty) {
      env.setActiveProfiles(_additionalProfiles.toList());
    }

    ConfigurationPropertySource.attach(env);
    await _applicationListeners.onEnvironmentPrepared(_boostrapContext, env);

    ApplicationInfoPropertySource.moveToEnd(env);
    DefaultPropertiesPropertySource.moveSourcesToEnd(env.getPropertySources());
    ConfigurationPropertySource.attach(env); // Attach again after everything

    _environment = env;

    // Set lazy initialization from environment
    final lazyInit = env.getPropertyAs(LAZY_INITIALIZATION, Class<bool>(null, PackageNames.DART));
    _lazyInitialization = lazyInit ?? _lazyInitialization;

    return env;
  }

  /// {@template jet_application._configure_property_sources}
  /// Configures property sources in the given environment.
  ///
  /// Adds default properties and command line properties (if enabled) to the environment.
  /// Also handles profile activation and conversion service setup.
  ///
  /// [environment] the environment to configure
  /// [args] application arguments for command line property source
  /// {@endtemplate}
  void _configurePropertySources(ConfigurableEnvironment environment, List<String> args) {
    final sources = environment.getPropertySources();
    if (_defaultProperties.isNotEmpty) {
      DefaultPropertiesPropertySource.addOrMerge(_defaultProperties, sources);
    }

    if (_addCommandLineProperties && args.isNotEmpty) {
      final name = CommandLinePropertySource.COMMAND_LINE_PROPERTY_SOURCE_NAME;
      if (sources.containsName(name)) {
        final source = sources.get(name);

        if(source != null) {
          final composite = CompositePropertySource(name);
          composite.addPropertySource(SimpleCommandLinePropertySource.named(CommandLinePropertySource.JETLEAF_COMMAND_LINE_PROPERTY_SOURCE_NAME, args));
          composite.addPropertySource(source);
          sources.replace(name, composite);
        }
      } else {
        sources.addFirst(SimpleCommandLinePropertySource(args));
      }
    }

    sources.addLast(ApplicationInfoPropertySource(_mainApplicationClass));
  }

  // =============================================== BANNER ================================================
  
  /// {@template jet_application._print_banner}
  /// Prints the application banner based on configuration.
  ///
  /// The banner can be customized through:
  /// - Banner mode (console, log, off)
  /// - Custom banner implementation
  /// - Property-based configuration
  ///
  /// [environment] the environment for banner configuration
  ///
  /// Returns the [Banner] instance used, or null if banner is disabled
  /// {@endtemplate}
  Banner? _printBanner(ConfigurableEnvironment environment) {
    if (_bannerMode == BannerMode.OFF) {
      return null;
    }

    // Assuming DefaultBanner is available and implements Banner interface
    final banner = _banner ?? DefaultBanner(JetLeafBanner());
    final stream = ConsolePrintStream(System.out);
    banner.printBanner(environment, _mainApplicationClass, stream);

    if (_bannerMode == BannerMode.CONSOLE) {
      stream.flush();
    }

    return banner;
  }

  // =============================================== APPLICATION TYPE ========================================

  /// {@template jet_application._detect_application_type}
  /// Detects the application type based on configuration and dependencies.
  ///
  /// Detection order:
  /// 1. Explicit configuration via property or API
  /// 2. Presence of web dependencies
  /// 3. Default to [ApplicationType.NONE]
  ///
  /// Returns the detected [ApplicationType]
  /// {@endtemplate}
  ApplicationType _detectApplicationType() {
    // 1. We will check from environment
    final envType = _environment?.getProperty(JETLEAF_APPLICATION_TYPE);
    if(envType != null) {
      return ApplicationType.fromString(envType);
    }

    // 2. We will auto detect from the [_mainApplicationClass] for [@EnableWebServer()]
    final hasWebServer = Runtime.getAllPackages().find((p) => p.getName() == PackageNames.WEB) != null;
    if(hasWebServer) {
      return ApplicationType.WEB;
    }

    // 3. If none of the above, we will return [ApplicationType.NONE]
    return ApplicationType.NONE;
  }

  // ============================================== CONTEXT HANDLING =========================================

  /// {@template jet_application._setup_application_context}
  /// Performs final setup and configuration of the application context.
  ///
  /// This method:
  /// - Applies context initializers
  /// - Configures the pod factory
  /// - Registers core framework components
  /// - Sets up lifecycle management
  ///
  /// [context] the application context to configure
  /// [args] application arguments for context configuration
  /// {@endtemplate}
  Future<void> _setupApplicationContext(ConfigurableApplicationContext context, ApplicationArguments args) async {
    for (final initializer in _initializers) {
      initializer.initialize(context);
    }
  
    await _applicationListeners.onContextPrepared(context);
    _boostrapContext.close(context);

    if (_logStartupInfo) {
      if(context.getParent() == null) {
        _startupLogger.logStarting(_logger);
      }

      if (_logger.getIsInfoEnabled()) {
        final activeProfiles = context.getEnvironment().getActiveProfiles().toList();
        final defaultProfiles = context.getEnvironment().getDefaultProfiles().toList();

        if (activeProfiles.isEmpty) {
          final profileWord = defaultProfiles.length == 1 ? "profile" : "profiles";
          final profilesList = StringUtils.collectionToDelimitedString(defaultProfiles, ", ");
          _logger.info("⚠️  No active profile set → using $profileWord: [$profilesList]");
        } else {
          final profileWord = activeProfiles.length == 1 ? "profile" : "profiles";
          final profilesList = StringUtils.collectionToDelimitedString(activeProfiles, ", ");
          _logger.info("✅ Application started with $profileWord: [$profilesList]");
        }
      }
    }

    final podFactory = context.getPodFactory();

    if (_podNameGenerator != null && !podFactory.containsSingleton(AbstractApplicationContext.POD_NAME_GENERATOR_POD_NAME)) {
      final gen = _podNameGenerator!;
      final genClass = gen.getClass();

      podFactory.registerSingleton(
        AbstractApplicationContext.POD_NAME_GENERATOR_POD_NAME,
        genClass,
        object: ObjectHolder(gen, packageName: gen.getPackageName(), qualifiedName: genClass.getQualifiedName())
      );
    }

    if (_addConversionService) {
      context.setConversionService(_getConversionService());
      podFactory.setConversionService(_getConversionService());
    }

    if (!podFactory.containsSingleton(AbstractApplicationContext.JETLEAF_ARGUMENT_POD_NAME)) {
      final argsClass = args.getClass();

      podFactory.registerSingleton(
        AbstractApplicationContext.JETLEAF_ARGUMENT_POD_NAME,
        argsClass,
        object: ObjectHolder(args, packageName: args.getPackageName(), qualifiedName: argsClass.getQualifiedName())
      );
    }

    if(_banner != null && !podFactory.containsSingleton(AbstractApplicationContext.BANNER_POD_NAME)) {
      final bann = _banner!;
      final bannerClass = bann.getClass();

      podFactory.registerSingleton(
        AbstractApplicationContext.BANNER_POD_NAME,
        bannerClass,
        object: ObjectHolder(bann, packageName: bann.getPackageName(), qualifiedName: bannerClass.getQualifiedName())
      );
    }

    podFactory.setAllowCircularReferences(_allowCircularReferences);
    podFactory.setAllowDefinitionOverriding(_allowDefinitionOverriding);

    if (_lazyInitialization) {
      context.addPodFactoryPostProcessor(LazyInitializationPodFactoryPostProcessor());
    }

    if (_keepAlive) {
      context.addApplicationListener(KeepAlive());
    }

    if (_expressionResolver != null) {
      context.setPodExpressionResolver(_expressionResolver);
    }

    context.addPodFactoryPostProcessor(PropertySourceOrderingPodFactoryPostProcessor(context));
    await _applicationListeners.onContextLoaded(context);
  }

  /// {@template jet_application._call_runners}
  /// Discovers and executes application and command line runners.
  ///
  /// Runners are executed after the context is refreshed and can be used
  /// for application-specific initialization logic.
  ///
  /// [context] the application context for pod lookup
  /// [args] application arguments for runner execution
  /// {@endtemplate}
  Future<void> _callRunners(ConfigurableApplicationContext context, ApplicationArguments args) async {
    final podFactory = context.getPodFactory();
    final podNames = await podFactory.getPodNames(Class<Runner>(null, PackageNames.MAIN));

    final runners = <Runner>{};
    for (String podName in podNames) {
      final instance = await podFactory.getPod(podName);
      runners.add(instance);
    }

    final sorted = runners.toList();
    sorted.sort(OrderComparator().compare);
  
    for (var runner in sorted) {
      _callRunner(runner, args);
    }
  }

  /// {@template jet_application._call_runner}
  /// Executes a single runner instance.
  ///
  /// This method handles both [ApplicationRunner] and [CommandLineRunner]
  /// types, executing them with appropriate arguments.
  ///
  /// [runner] the runner instance to execute
  /// [args] application arguments for runner execution
  /// {@endtemplate}
  void _callRunner(Runner runner, ApplicationArguments args) {
    if (runner is ApplicationRunner) {
      _callRunnerInternal<ApplicationRunner>(runner, (applicationRunner) => applicationRunner.run(args));
    } else if (runner is CommandLineRunner) {
      _callRunnerInternal<CommandLineRunner>(runner, (commandLineRunner) => commandLineRunner.run(args.getSourceArgs()));
    }
  }

  /// Returns the list of all available [ExceptionReporter] instances.
  ///
  /// The returned list includes:
  ///  - Reporters explicitly registered via `_exceptionReporters`
  ///  - Reporters discovered dynamically from the application context
  ///
  /// Discovery from the context happens only **once**:
  ///  - The first call with a non-null [context] triggers reporter discovery
  ///    through the [ExceptionReporterManager].
  ///  - Subsequent calls return cached reporters and do not re-query the context.
  ///
  /// This behavior ensures:
  ///  - Reporter collection is deterministic
  ///  - Performance is improved by avoiding repeated environment scanning
  ///  - User-provided reporters take precedence (added first)
  ///
  /// If [context] is `null`, only explicitly registered reporters are returned.
  ///
  /// ### Parameters
  /// - [context] – the application context used to discover additional reporters
  ///
  /// ### Returns
  /// A combined list of registered and discovered reporters.
  List<ExceptionReporter> _getExceptionReporters(ConfigurableApplicationContext? context) {
    final reporters = List<ExceptionReporter>.from(_exceptionReporters);
    
    if (_reportersFetched) {
      return reporters;
    }

    final fetched = ExceptionReporterManager(context);
    reporters.addAll(fetched.getReporters());
    _reportersFetched = true;

    return _exceptionReporters = reporters;
  }

  /// {@template jet_application._call_runner_internal}
  /// Executes a runner instance with safe execution.
  ///
  /// This method safely executes a runner instance, handling any exceptions
  /// and logging appropriate error messages.
  ///
  /// [runner] the runner instance to execute
  /// [call] the execution callback
  /// {@endtemplate}
  void _callRunnerInternal<R extends Runner>(R runner, ThrowingConsumer<R> call) {
    call.callSafely(runner, message: () => "Failed to execute $R");
  }

  /// Refreshes and rebinds the active [ConversionService] within the application context.
  ///
  /// This method ensures that the JetLeaf runtime uses the most up-to-date
  /// `ApplicationConversionService` when no user-defined conversion service
  /// is provided.
  ///
  /// The method performs the following steps:
  /// 1. Verifies that the current conversion service is the default
  ///    [ApplicationConversionService].
  /// 2. Retrieves the configured conversion service pod from the
  ///    [ConfigurableApplicationContext].
  /// 3. Rebinds it as the active conversion service for:
  ///    - The [ApplicationContext]
  ///    - The [PodFactory]
  ///    - The [Environment], if configurable
  ///
  /// This allows dynamic type conversions (e.g., for configuration properties,
  /// validation, or request binding) to remain consistent across the framework.
  ///
  /// Example:
  /// ```dart
  /// await _refreshConversionService(context);
  /// ```
  ///
  /// See also:
  /// - [ApplicationConversionService]
  /// - [ConfigurableApplicationContext]
  /// - [ConfigurableEnvironment]
  Future<void> _refreshConversionService(ConfigurableApplicationContext context) async {
    // Only do this when the user did not provide a default conversion service
    if (_conversionService is ApplicationConversionService) {
      final podFactory = context.getPodFactory();

      if (podFactory.containsDefinition(AbstractApplicationContext.JETLEAF_CONVERSION_SERVICE_POD_NAME)) {
        final conversionService = await podFactory.getPod<ApplicationConversionService>(AbstractApplicationContext.JETLEAF_CONVERSION_SERVICE_POD_NAME);

        if (_addConversionService) {
          context.setConversionService(conversionService);
          podFactory.setConversionService(conversionService);
        }

        final env = context.getEnvironment();

        if (env is ConfigurableEnvironment) {
          env.setConversionService(conversionService);
        }

        context.setEnvironment(env);
        _conversionService = conversionService;
      }
    }
  }

  // ============================== RUN METHODS ============================== 

  /// {@template jet_application.run}
  /// Convenience method for running an application with a single primary source.
  ///
  /// This is the simplest way to launch a JetLeaf application from a main method.
  ///
  /// ### Usage:
  /// ```dart
  /// void main(List<String> args) {
  ///   JetApplication.run(MyApplication, args);
  /// }
  /// ```
  ///
  /// [primarySource] the primary source (typically main application class)
  /// [args] command line arguments
  /// [provider] optional runtime provider
  ///
  /// Returns the created application context
  /// {@endtemplate}
  static Future<ConfigurableApplicationContext?> run(Object primarySource, List<String> args, [RuntimeProvider? provider]) {
    return JetApplication(primarySource).create(args, provider);
  }

  // ============================== HOOKS ============================== 

  /// {@template jet_application.use_hook}
  /// Executes an action with a specific application hook.
  ///
  /// Application hooks allow customization of framework behavior during
  /// application creation and execution.
  ///
  /// ### Usage:
  /// ```dart
  /// JetApplication.useHook(MyApplicationHook(), () {
  ///   JetApplication.run(MyApplication, args);
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

  /// {@template jet_application.use_throwable_hook}
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

  /// {@template jet_application.exit}
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
				close(context);
			}
		} on Exception catch (ex) {
			ex.printStackTrace();
			exitCode = (exitCode != 0) ? exitCode : 1;
		}

		return exitCode;
  }

  /// {@template jet_application.close}
  /// Closes the application context and releases resources.
  ///
  /// This method should be called when the application is being shut down
  /// to ensure proper cleanup of resources.
  ///
  /// [context] the application context to close
  /// {@endtemplate}
  static void close(ApplicationContext context) {
		if (context is ConfigurableApplicationContext) {
			context.close();
		}
	}

  // ============================== SHUTDOWN HANDLERS ============================== 

  /// {@template jet_application.get_shutdown_handler}
  /// Gets the global application shutdown handler.
  ///
  /// The shutdown handler manages graceful application termination and
  /// can be used to register custom shutdown hooks.
  ///
  /// Returns the global [ApplicationShutdownHandler] instance
  /// {@endtemplate}
  static ApplicationShutdownHandler getShutdownHandler() => _shutdownHook.handler;

  // ============================== MAIN APPLICATION CLASS ============================== 

  /// {@template jet_application.get_main_class}
  /// Gets the main application class.
  ///
  /// Returns the [Class] representing the main application class
  /// {@endtemplate}
  Class<Object> getMainClass() => _mainApplicationClass;

  // ============================== WEB APPLICATION TYPE ============================== 

  /// {@template jet_application.get_application_type}
  /// Gets the application type.
  ///
  /// Returns the detected or configured [ApplicationType]
  /// {@endtemplate}
  ApplicationType getApplicationType() => _applicationType;

  /// {@template jet_application.set_application_type}
  /// Sets the application type explicitly.
  ///
  /// Overrides automatic application type detection.
  ///
  /// [webApplicationType] the application type to set
  /// {@endtemplate}
  void setApplicationType(ApplicationType webApplicationType) {
    _applicationType = webApplicationType;
  }

  // ============================== ALLOW POD DEFINITION OVERRIDING ============================== 

  /// {@template jet_application.get_allow_pod_definition_overriding}
  /// Gets whether pod definition overriding is allowed.
  ///
  /// Returns `true` if pod definition overriding is allowed
  /// {@endtemplate}
  bool getAllowPodDefinitionOverriding() => _allowDefinitionOverriding;

  /// {@template jet_application.set_allow_pod_definition_overriding}
  /// Sets whether pod definition overriding is allowed.
  ///
  /// [allowDefinitionOverriding] whether to allow pod definition overriding
  /// {@endtemplate}
  void setAllowPodDefinitionOverriding(bool allowDefinitionOverriding) {
    _allowDefinitionOverriding = allowDefinitionOverriding;
  }

  // ============================== ALLOW CIRCULAR REFERENCES ============================== 

  /// {@template jet_application.get_allow_circular_references}
  /// Gets whether circular references are allowed.
  ///
  /// Returns `true` if circular references are allowed
  /// {@endtemplate}
  bool getAllowCircularReferences() => _allowCircularReferences;

  /// {@template jet_application.set_allow_circular_references}
  /// Sets whether circular references are allowed.
  ///
  /// [allowCircularReferences] whether to allow circular references
  /// {@endtemplate}
  void setAllowCircularReferences(bool allowCircularReferences) {
    _allowCircularReferences = allowCircularReferences;
  }

  // ============================== BANNER MODE ============================== 

  /// {@template jet_application.get_banner_mode}
  /// Gets the banner display mode.
  ///
  /// Returns the configured [BannerMode]
  /// {@endtemplate}
  BannerMode getBannerMode() => _bannerMode;

  /// {@template jet_application.set_banner_mode}
  /// Sets the banner display mode.
  ///
  /// [bannerMode] the banner mode to set
  /// {@endtemplate}
  void setBannerMode(BannerMode bannerMode) {
    _bannerMode = bannerMode;
  }

  // ============================== KEEP ALIVE ============================== 

  /// {@template jet_application.get_keep_alive}
  /// Gets whether the application should stay alive after startup.
  ///
  /// Returns `true` if the application should stay alive
  /// {@endtemplate}
  bool getKeepAlive() => _keepAlive;

  /// {@template jet_application.set_keep_alive}
  /// Sets whether the application should stay alive after startup.
  ///
  /// [keepAlive] whether the application should stay alive
  /// {@endtemplate}
  void setKeepAlive(bool keepAlive) {
    _keepAlive = keepAlive;
  }

  // ============================== LAZY INITIALIZATION ============================== 

  /// {@template jet_application.get_lazy_initialization}
  /// Gets whether lazy initialization is enabled.
  ///
  /// Returns `true` if lazy initialization is enabled
  /// {@endtemplate}
  bool getLazyInitialization() => _lazyInitialization;

  /// {@template jet_application.set_lazy_initialization}
  /// Sets whether lazy initialization is enabled.
  ///
  /// [lazyInitialization] whether to enable lazy initialization
  /// {@endtemplate}
  void setLazyInitialization(bool lazyInitialization) {
    _lazyInitialization = lazyInitialization;
  }

  // ============================== POD EXPRESSION RESOLVER ============================== 

  /// {@template configurable_pod_factory.get_expression_resolver}
  /// Returns the currently registered [PodExpressionResolver], or `null` if none.
  ///
  /// The resolver evaluates pod expressions such as `@Value` and `@Conditional`
  /// within the Jetleaf container.
  /// {@endtemplate}
  PodExpressionResolver? getPodExpressionResolver() => _expressionResolver;

  /// {@template configurable_pod_factory.set_expression_resolver}
  /// Registers or updates the [PodExpressionResolver] used by this pod factory.
  ///
  /// Setting this resolver ensures that all expression evaluations within
  /// pod definitions use the provided resolver instance. Passing `null` will
  /// clear the current resolver.
  ///
  /// ### Example:
  /// ```dart
  /// setPodExpressionResolver(resolver);
  /// ```
  /// {@endtemplate}
  void setPodExpressionResolver(PodExpressionResolver? valueResolver) {
    _expressionResolver = valueResolver;
  }

  // ============================== LOG STARTUP INFO ============================== 

  /// {@template jet_application.get_log_startup_info}
  /// Gets whether startup information logging is enabled.
  ///
  /// Returns `true` if startup information logging is enabled
  /// {@endtemplate}
  bool getLogStartupInfo() => _logStartupInfo;

  /// {@template jet_application.set_log_startup_info}
  /// Sets whether startup information logging is enabled.
  ///
  /// [logStartupInfo] whether to enable startup information logging
  /// {@endtemplate}
  void setLogStartupInfo(bool logStartupInfo) {
    logStartupInfo = logStartupInfo;
  }

  // ============================== REGISTER SHUTDOWN HOOK ============================== 

  /// {@template jet_application.get_register_shutdown_hook}
  /// Gets whether shutdown hook registration is enabled.
  ///
  /// Returns `true` if shutdown hook registration is enabled
  /// {@endtemplate}
  bool getRegisterShutdownHook() => _registerShutdownHook;

  /// {@template jet_application.set_register_shutdown_hook}
  /// Sets whether shutdown hook registration is enabled.
  ///
  /// [registerShutdownHook] whether to enable shutdown hook registration
  /// {@endtemplate}
  void setRegisterShutdownHook(bool registerShutdownHook) {
    _registerShutdownHook = registerShutdownHook;
  }

  // ============================== ADD COMMAND LINE PROPERTIES ============================== 

  /// {@template jet_application.get_add_command_line_properties}
  /// Gets whether command line property parsing is enabled.
  ///
  /// Returns `true` if command line property parsing is enabled
  /// {@endtemplate}
  bool getAddCommandLineProperties() => _addCommandLineProperties;

  /// {@template jet_application.set_add_command_line_properties}
  /// Sets whether command line property parsing is enabled.
  ///
  /// [addCommandLineProperties] whether to enable command line property parsing
  /// {@endtemplate}
  void setAddCommandLineProperties(bool addCommandLineProperties) {
    _addCommandLineProperties = addCommandLineProperties;
  }

  // ============================== ADD CONVERSION SERVICE ============================== 

  /// {@template jet_application.get_add_conversion_service}
  /// Gets whether conversion service registration is enabled.
  ///
  /// Returns `true` if conversion service registration is enabled
  /// {@endtemplate}
  bool getAddConversionService() => _addConversionService;

  /// {@template jet_application.add_conversion_service}
  /// Sets whether conversion service registration is enabled.
  ///
  /// [addConversionService] whether to enable conversion service registration
  /// {@endtemplate}
  void addConversionService(bool addConversionService) {
    _addConversionService = addConversionService;
  }

  /// {@template jet_application.get_conversion_service}
  /// Gets the conversion service.
  ///
  /// Returns the configured [ConfigurableConversionService]
  /// {@endtemplate}
  ConfigurableConversionService getConversionService() => _getConversionService();

  /// {@template jet_application.set_conversion_service}
  /// Sets the conversion service.
  ///
  /// [conversionService] the conversion service to set
  /// {@endtemplate}
  void setConversionService(ConfigurableConversionService conversionService) {
    _conversionService = conversionService;
  }

  // ============================== BOOTSTRAP REGISTRY INITIALIZERS ============================== 

  /// {@template jet_application.get_bootstrap_registry_initializers}
  /// Gets the bootstrap registry initializers.
  ///
  /// Returns an unmodifiable list of bootstrap registry initializers
  /// {@endtemplate}
  List<BootstrapRegistryInitializer> getBootstrapRegistryInitializers() => List.unmodifiable(_bootstrapInitializers);

  /// {@template jet_application.add_bootstrap_registry_initializers}
  /// Adds multiple bootstrap registry initializers.
  ///
  /// [initializers] the bootstrap registry initializers to add
  /// {@endtemplate}
  void addBootstrapRegistryInitializers(List<BootstrapRegistryInitializer> initializers) {
    _bootstrapInitializers.addAll(initializers);
  }

  /// {@template jet_application.add_bootstrap_registry_initializer}
  /// Adds a single bootstrap registry initializer.
  ///
  /// [initializer] the bootstrap registry initializer to add
  /// {@endtemplate}
  void addBootstrapRegistryInitializer(BootstrapRegistryInitializer initializer) {
    _bootstrapInitializers.add(initializer);
  }

  /// {@template jet_application.set_bootstrap_registry_initializers}
  /// Sets the bootstrap registry initializers.
  ///
  /// [initializers] the bootstrap registry initializers to set
  /// {@endtemplate}
  void setBootstrapRegistryInitializers(List<BootstrapRegistryInitializer> initializers) {
    _bootstrapInitializers = initializers;
  }

  // ============================== CONTEXT INITIALIZERS ============================== 

  /// {@template jet_application.get_initializers}
  /// Gets the application context initializers.
  ///
  /// Returns an unmodifiable list of application context initializers
  /// {@endtemplate}
  List<ApplicationContextInitializer> getInitializers() => List.unmodifiable(_initializers);

  /// {@template jet_application.add_initializers}
  /// Adds multiple application context initializers.
  ///
  /// [initializers] the application context initializers to add
  /// {@endtemplate}
  void addInitializers(List<ApplicationContextInitializer> initializers) {
    _initializers.addAll(initializers);
  }

  /// {@template jet_application.set_initializers}
  /// Sets the application context initializers.
  ///
  /// [initializers] the application context initializers to set
  /// {@endtemplate}
  void setInitializers(List<ApplicationContextInitializer> initializers) {
    _initializers = initializers;
  }

  /// {@template jet_application.add_initializer}
  /// Adds a single application context initializer.
  ///
  /// [initializer] the application context initializer to add
  /// {@endtemplate}
  void addInitializer(ApplicationContextInitializer initializer) {
    _initializers.add(initializer);
  }

  // ============================== LISTENERS ============================== 

  /// {@template jet_application.get_listeners}
  /// Gets the application event listeners.
  ///
  /// Returns an unmodifiable list of application event listeners
  /// {@endtemplate}
  List<ApplicationEventListener<ApplicationEvent>> getListeners() => List.unmodifiable(_listeners);

  /// {@template jet_application.set_listeners}
  /// Sets the application event listeners.
  ///
  /// [listeners] the application event listeners to set
  /// {@endtemplate}
  void setListeners(List<ApplicationEventListener<ApplicationEvent>> listeners) {
    _listeners = listeners;
  }

  /// {@template jet_application.add_listeners}
  /// Adds multiple application event listeners.
  ///
  /// [listeners] the application event listeners to add
  /// {@endtemplate}
  void addListeners(List<ApplicationEventListener<ApplicationEvent>> listeners) {
    _listeners.addAll(listeners);
  }

  // ============================== ADDITIONAL PROFILES ============================== 

  /// {@template jet_application.get_additional_profiles}
  /// Gets the additional active profiles.
  ///
  /// Returns an unmodifiable set of additional active profiles
  /// {@endtemplate}
  Set<String> getAdditionalProfiles() => Set.unmodifiable(_additionalProfiles);

  /// {@template jet_application.set_additional_profiles}
  /// Sets the additional active profiles.
  ///
  /// [profiles] the additional active profiles to set
  /// {@endtemplate}
  void setAdditionalProfiles(Set<String> profiles) {
    _additionalProfiles = profiles;
  }

  // ============================== DEFAULT PROPERTIES ============================== 

  /// {@template jet_application.get_default_properties}
  /// Gets the default properties.
  ///
  /// Returns an unmodifiable map of default properties
  /// {@endtemplate}
  Map<String, Object> getDefaultProperties() => Map.unmodifiable(_defaultProperties);

  /// {@template jet_application.set_default_properties}
  /// Sets the default properties.
  ///
  /// [defaultProperties] the default properties to set
  /// {@endtemplate}
  void setDefaultProperties(Map<String, String> defaultProperties) {
    _defaultProperties = defaultProperties;
  }

  // ============================== APPLICATION STARTUP ==============================

  /// {@template jet_application.get_startup}
  /// Gets the application startup tracker.
  ///
  /// Returns the [ApplicationStartup] instance
  /// {@endtemplate}
  ApplicationStartup getStartup() => _applicationStartup;

  /// {@template jet_application.set_application_startup}
  /// Sets the application startup tracker.
  ///
  /// [applicationStartup] the application startup tracker to set
  /// {@endtemplate}
  void setApplicationStartup(ApplicationStartup? applicationStartup) {
		if (applicationStartup != null) {
			_applicationStartup = applicationStartup;
		}
	}

  // ============================== ENVIRONMENT PREFIX ============================== 

  /// {@template jet_application.get_environment_prefix}
  /// Gets the environment property prefix.
  ///
  /// Returns the environment property prefix
  /// {@endtemplate}
  String getEnvironmentPrefix() => _environmentPrefix;

  /// {@template jet_application.set_environment_prefix}
  /// Sets the environment property prefix.
  ///
  /// [environmentPrefix] the environment property prefix to set
  /// {@endtemplate}
  void setEnvironmentPrefix(String environmentPrefix) {
		_environmentPrefix = environmentPrefix;
	}

  // ============================== POD NAME GENERATOR ============================== 

  /// {@template jet_application.get_pod_name_generator}
  /// Gets the pod name generator.
  ///
  /// Returns the configured [PodNameGenerator], or null if not set
  /// {@endtemplate}
  PodNameGenerator? getPodNameGenerator() => _podNameGenerator;

  /// {@template jet_application.set_pod_name_generator}
  /// Sets the pod name generator.
  ///
  /// [podNameGenerator] the pod name generator to set
  /// {@endtemplate}
  void setPodNameGenerator(PodNameGenerator? podNameGenerator) {
		_podNameGenerator = podNameGenerator;
	}

  // =============================================== EXCEPTION REPORTERS ========================================
  //
  // This is where we find all the [ExceptionReporter]s and return them as a [ExceptionReporters]

  /// Adds an exception reporter to the list of exception reporters.
  /// 
  /// Exception reporters are used to report exceptions to the user.
  /// 
  /// ### Example
  /// ```dart
  /// final app = JetApplication();
  /// app.addExceptionReporter(ExceptionReporter());
  /// ```
  void addExceptionReporter(ExceptionReporter reporter) {
    _exceptionReporters.add(reporter);
  }

  /// Returns the list of exception reporters.
  /// 
  /// ### Example
  /// ```dart
  /// final app = JetApplication();
  /// app.addExceptionReporter(ExceptionReporter());
  /// final reporters = app.getExceptionReporters();
  /// ```
  List<ExceptionReporter> getExceptionReporters() => List.unmodifiable(_exceptionReporters);

  // =============================================== EXIT CODE EXCEPTION HANDLERS ========================================
  //
  // This is where we find all the [ExitCodeExceptionHandler]s and return them as a [ExitCodeExceptionHandlers]

  /// Adds an exit code exception handler to the list of exit code exception handlers.
  /// 
  /// Exit code exception handlers are used to handle exceptions and return an exit code.
  /// 
  /// ### Example
  /// ```dart
  /// final app = JetApplication();
  /// app.addExitCodeExceptionHandler(ExitCodeExceptionHandler());
  /// ```
  void addExitCodeExceptionHandler(ExitCodeExceptionHandler handler) {
    _exitCodeExceptionHandlers.add(handler);
  }

  /// Returns the list of exit code exception handlers.
  /// 
  /// ### Example
  /// ```dart
  /// final app = JetApplication();
  /// app.addExitCodeExceptionHandler(ExitCodeExceptionHandler());
  /// final handlers = app.getExitCodeExceptionHandlers();
  /// ```
  List<ExitCodeExceptionHandler> getExitCodeExceptionHandlers() => List.unmodifiable(_exitCodeExceptionHandlers);

  // =============================================== LOGGING LISTENER ========================================
  //
  // This is where we find all the [LoggingListener]s and return them as a [LoggingListeners]

  /// Adds a logging listener to the list of logging listeners.
  /// 
  /// Logging listeners are used to listen to logging events.
  /// 
  /// ### Example
  /// ```dart
  /// final app = JetApplication();
  /// app.setLoggingListener(LoggingListener());
  /// ```
  void setLoggingListener(LoggingListener listener) {
    _loggingListener = listener;
    LogFactory.setGlobalLoggingListener(listener);
  }

  /// Returns the logging listener.
  /// 
  /// ### Example
  /// ```dart
  /// final app = JetApplication();
  /// app.setLoggingListener(LoggingListener());
  /// final listener = app.getLoggingListener();
  /// ```
  LoggingListener? getLoggingListener() => _loggingListener;
}

/// {@template throwing_consumer}
/// A consumer function that can throw exceptions.
///
/// Used for operations that may fail and need to propagate exceptions.
///
/// ### Type Parameters:
/// - [T]: The type of value being consumed
///
/// ### Example:
/// ```dart
/// ThrowingConsumer<String> consumer = (value) {
///   if (value.isEmpty) {
///     throw ArgumentError('Value cannot be empty');
///   }
///   print(value);
/// };
/// ```
/// {@endtemplate}
typedef ThrowingConsumer<T> = void Function(T value);

/// {@template throwing_consumer_extension}
/// Extension methods for [ThrowingConsumer] providing safe execution.
///
/// Adds exception handling capabilities to throwing consumers.
/// {@endtemplate}
extension ThrowingConsumerX<T> on ThrowingConsumer<T> {
  /// {@template throwing_consumer.call_safely}
  /// Executes the consumer with exception handling and custom error messaging.
  ///
  /// Wraps the consumer execution in a try-catch block and provides
  /// meaningful error messages when exceptions occur.
  ///
  /// [value] the value to pass to the consumer
  /// [message] optional function to generate custom error messages
  ///
  /// Throws:
  /// - [IllegalStateException] if the consumer throws an exception
  ///
  /// Example:
  /// ```dart
  /// consumer.callSafely('test', message: () => 'Failed to process value');
  /// ```
  /// {@endtemplate}
  void callSafely(T value, {String Function()? message}) {
    try {
      this(value);
    } catch (ex) {
      throw IllegalStateException(
        message?.call() ?? "Execution of ${T.runtimeType} failed",
        cause: ex,
      );
    }
  }
}

/// {@template default_application_hook}
/// Default implementation of [ApplicationHook] in JetLeaf.
///
/// This hook serves as the central point for managing **application lifecycle events**
/// and orchestrating the execution of run listeners. It is typically used internally
/// by the JetLeaf framework but can also be extended or replaced if custom behavior
/// is required during application startup or shutdown.
///
/// The primary responsibilities of this hook include:
///
/// 1. **Listener Management**
///    - Maintains a collection of [ApplicationRunListener] instances.
///    - Ensures that each listener is invoked in order during application lifecycle events.
///
/// 2. **Startup Tracking**
///    - Tracks the startup sequence via [ApplicationStartup], which can measure
///      duration, report progress, or emit diagnostic information.
///
/// 3. **Lifecycle Coordination**
///    - Delegates lifecycle events (startup, ready, shutdown) to all registered listeners.
///    - Provides a consistent and predictable execution order for application hooks.
///
/// ### How It Works
///
/// During the application bootstrap:
///
/// 1. The JetLeaf framework initializes the [DefaultApplicationHook] with a list
///    of listeners and a startup tracker.
/// 2. When the application is started, [getRunListener] is called with the active
///    [JetApplication] instance.
/// 3. [ApplicationRunListeners], a composite listener, wraps all individual listeners
///    and ensures that lifecycle events are forwarded correctly.
///
/// This pattern allows multiple independent modules to register listeners without
/// interfering with each other. Each listener can react to startup, ready, or shutdown
/// events independently while the hook guarantees correct ordering.
///
/// ### Example Usage
///
/// ```dart
/// final startupTracker = ApplicationStartup();
/// final listeners = [LoggingRunListener(), MetricsRunListener()];
///
/// final hook = DefaultApplicationHook(listeners, startupTracker);
/// final runListener = hook.getRunListener(myJetApplication);
///
/// runListener.onApplicationStarting();
/// runListener.onApplicationReady();
/// runListener.onApplicationStopping();
/// ```
///
/// ### Extending or Customizing
///
/// If you need custom behavior, you can subclass [DefaultApplicationHook] and override
/// [getRunListener] to provide your own composite or decorated run listeners:
///
/// ```dart
/// class CustomApplicationHook extends DefaultApplicationHook {
///   CustomApplicationHook(List<ApplicationRunListener> listeners, ApplicationStartup startup)
///     : super(listeners, startup);
///
///   @override
///   ApplicationRunListener getRunListener(JetApplication jetApplication) {
///     final original = super.getRunListener(jetApplication);
///     return LoggingDecorator(original); // add logging around all events
///   }
/// }
/// ```
///
/// This ensures your custom logic is seamlessly integrated with JetLeaf’s lifecycle.
/// {@endtemplate}
final class DefaultApplicationHook implements ApplicationHook {
  /// The list of listeners that will be invoked for lifecycle events.
  final List<ApplicationRunListener> _listeners;

  /// Tracks the application startup lifecycle and duration.
  final ApplicationStartup _applicationStartup;

  /// Creates a new [DefaultApplicationHook] with the provided run listeners
  /// and startup tracker.
  /// 
  /// {@macro default_application_hook}
  DefaultApplicationHook(this._listeners, this._applicationStartup);

  @override
  ApplicationRunListener getRunListener(JetApplication jetApplication) {
    // Returns a composite listener that delegates events to all registered listeners.
    return ApplicationRunListeners(_listeners, _applicationStartup);
  }
}