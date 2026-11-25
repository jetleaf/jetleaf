part of '../jetleaf_application.dart';

/// {@template jetleaf_application_lifecycle}
/// Internal lifecycle orchestration support for [JetleafApplication].
///
/// Encapsulates bootstrapping, run listener discovery, environment setup,
/// banner rendering, application type detection, context building, runner
/// execution, exception reporting, and conversion service refreshing.
/// {@endtemplate}
abstract base class _JetleafApplicationLifecycle extends _JetleafApplicationSupport {
  /// {@macro jetleaf_application_lifecycle}
  _JetleafApplicationLifecycle(super.primarySource);

  /// {@template jetleaf_application._get_config}
  /// Returns the default [RuntimeScannerConfiguration] when an AOT registrar
  /// is available.
  ///
  /// When [_aotRegistrar] is non-null, returns a compatibility-mode
  /// configuration (`reload: false`, `buildMode: RuntimeBuildMode.compatibility`,
  /// `skipTests: true`) so [runScan] reuses the existing cache and generated
  /// artifacts without forcing a full reload. Returns `null` when no AOT
  /// registrar is configured, allowing [runScan] to use its default
  /// configuration.
  /// {@endtemplate}
  RuntimeScannerConfiguration? _getConfig() {
    if (_aotRegistrar != null) {
      return const RuntimeScannerConfiguration(
        reload: false,
        buildMode: RuntimeBuildMode.compatibility,
        skipTests: true,
      );
    }

    return null;
  }

  // ============================================== BOOTSTRAPPING ==============================================

  /// {@template jetleaf_application._create_bootstrap_context}
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

  /// {@template jetleaf_application._get_run_listeners}
  /// Discovers and initializes application run listeners.
  ///
  /// Run listeners are called at various points in the application lifecycle
  /// and can be used to customize startup behavior, add monitoring, or
  /// integrate with external systems.
  ///
  /// Listeners are discovered through:
  /// 1. Classpath scanning for [ApplicationRunListener] implementations
  /// 2. Application hooks registered via [JetleafApplication.useHook]
  ///
  /// [args] command line arguments for listener configuration
  ///
  /// Returns an [ApplicationRunListeners] instance managing all discovered listeners
  /// {@endtemplate}
  ApplicationRunListeners _getRunListeners(List<String> args) {
    final listeners = <ApplicationRunListener>[
      LifecycleRunListener(),
    ];

    final classes = Class<ApplicationRunListener>(null, PackageNames.MAIN).getSubClasses();
    if (classes.isNotEmpty) {
      for (final cls in classes) {
        // Skip ApplicationRunListeners
        if (cls == Class<ApplicationRunListeners>(null, PackageNames.MAIN)) {
          continue;
        }

        try {
          final listener = ExecutableInstantiator.of(cls).newInstance();
          if (listener is ApplicationRunListener) {
            listeners.add(listener);
          } else if (JetleafApplication._logger.getIsWarnEnabled()) {
            JetleafApplication._logger.warn("ApplicationRunListener ${cls.getName()} was not instantiated because it was not a no-arg constructor or not of listener type");
          }
        } catch (_) {
          // No-op
        }
      }
    }

    final hook = JetleafApplication._applicationHook.get();
    final hookListener = (hook != null && this is JetleafApplication)
        ? hook.getRunListener(this as JetleafApplication)
        : null;
    if (hookListener != null) {
      listeners.add(hookListener);
    }

    return ApplicationRunListeners(listeners, _applicationStartup);
  }

  // ============================================= APPLICATION CONTEXT ========================================

  /// {@template jetleaf_application._build_application_context}
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
      final aargs = DefaultApplicationArguments(args);
      _applicationType = _detectApplicationType(aargs);
      context = _applicationContextFactory.create(_applicationType);

      if (!context.supports(_applicationType)) {
        throw IllegalStateException(
          'The application context \'${context.getDisplayName()}\' does not support application type '
          '${_applicationType.getName()}. For web applications, run with `jl run`/`jl dev` or the generated '
          'registry (`lib/_jetleaf/main.dart`, passing `registerGeneratedArtifacts` to '
          '`JetleafApplication.run(...)`). Set `-Djetleaf.application.type=none` to boot as a non-web application.',
        );
      }

      final environment = await _setupEnvironment(aargs, context.getSupportingEnvironment());

      final listener = _boostrapContext.get(
        Class<LoggingListener>(null, PackageNames.LOGGING),
        orElse: ApplicationLoggingListener(_mainApplicationClass, environment)
      );

      if (_loggingListener == null) {
        setLoggingListener(listener);
      }

      _banner = _printBanner(environment);

      if (JetleafApplication._logger.getIsInfoEnabled()) {
        JetleafApplication._logger.info("Launching ${_mainApplicationClass.getName()} with application type: ${_applicationType.getEmoji()} ${_applicationType.getName()}");
      }

      context.setApplicationStartup(_applicationStartup);
      context.setMainApplicationClass(_mainApplicationClass);

      // At this point, [Environment] must have been set, so we can proceed with caution.
      context.setEnvironment(environment);

      await _setupApplicationContext(context, aargs);

      if (_registerShutdownHook) {
        JetleafApplication._shutdownHook.registerApplicationContext(context);
      }

      await context.setup();
      _startup.started();
      StartupEvent.publish(context, _startup);

      if (_logStartupInfo) {
        _startupLogger.logStarted(JetleafApplication._logger, _startup);
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
        JetleafApplication._logger,
        JetleafApplication._shutdownHook,
        _getExceptionReporters(context),
        _exitCodeExceptionHandlers,
      ).handleRunFailure(context, e, null, st);
    }
  }

  /// {@template jetleaf_application._startup_logger}
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
    if (_environment == null) {
      throw IllegalArgumentException("Environment cannot be null when accessing startup logger");
    }

    return StartupLogger(_mainApplicationClass, _environment!);
  }

  // ============================================= ENVIRONMENT HANDLING ========================================

  /// {@template jetleaf_application._setup_environment}
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

    if (_additionalProfiles.isNotEmpty) {
      env.setActiveProfiles(_additionalProfiles.toList());
    }

    ConfigurationPropertySource.attach(env);
    await _applicationListeners.onEnvironmentPrepared(_boostrapContext, env);

    ApplicationInfoPropertySource.moveToEnd(env);
    DefaultPropertiesPropertySource.moveSourcesToEnd(env.getPropertySources());
    ConfigurationPropertySource.attach(env); // Attach again after everything

    _environment = env;

    // Set lazy initialization from environment
    final lazyInit = env.getPropertyAs(JetleafApplication.LAZY_INITIALIZATION, Class<bool>(null, PackageNames.DART));
    _lazyInitialization = lazyInit ?? _lazyInitialization;

    return env;
  }

  /// {@template jetleaf_application._configure_property_sources}
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

        if (source != null) {
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

  /// {@template jetleaf_application._print_banner}
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
    final banner = _banner ?? DefaultBanner(JetleafBanner());
    final stream = ConsolePrintStream(System.out);
    banner.printBanner(environment, _mainApplicationClass, stream);

    if (_bannerMode == BannerMode.CONSOLE) {
      stream.flush();
    }

    return banner;
  }

  // =============================================== APPLICATION TYPE ========================================

  /// {@template jetleaf_application._detect_application_type}
  /// Detects the application type based on configuration and dependencies.
  ///
  /// Detection order:
  /// 1. Explicit configuration via property or API
  /// 2. Presence of web dependencies
  /// 3. Default to [ApplicationType.NONE]
  ///
  /// Returns the detected [ApplicationType]
  /// {@endtemplate}
  ApplicationType _detectApplicationType([ApplicationArguments? args]) {
    if (_isApplicationTypeSet) {
      return _applicationType;
    }

    // 1. Explicit command-line configuration (takes priority) — the switch is
    // honoured even without a pre-built environment since the environment is
    // assembled from the same CLI arguments only after detection.
    final cliConfig = args?.getOptionValues(JetleafApplication.JETLEAF_APPLICATION_TYPE);
    if (cliConfig != null && cliConfig.isNotEmpty && cliConfig.first.isNotEmpty) {
      return ApplicationType.fromString(cliConfig.first);
    }

    // 2. We will check from environment
    final envType = _environment?.getProperty(JetleafApplication.JETLEAF_APPLICATION_TYPE);
    if (envType != null) {
      return ApplicationType.fromString(envType);
    }

    // 2. We will auto detect from the [_mainApplicationClass] for [@EnableWebServer()]
    final hasWebServer = Runtime.getAllPackages().find((p) => p.getName() == PackageNames.WEB) != null;
    if (hasWebServer) {
      return ApplicationType.WEB;
    }

    // 3. If none of the above, we will return [ApplicationType.NONE]
    return ApplicationType.NONE;
  }

  // ============================================== CONTEXT HANDLING =========================================

  /// {@template jetleaf_application._setup_application_context}
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
      if (context.getParent() == null) {
        _startupLogger.logStarting(JetleafApplication._logger);
      }

      if (JetleafApplication._logger.getIsInfoEnabled()) {
        final activeProfiles = context.getEnvironment().getActiveProfiles().toList();
        final defaultProfiles = context.getEnvironment().getDefaultProfiles().toList();

        if (activeProfiles.isEmpty) {
          final profileWord = defaultProfiles.length == 1 ? "profile" : "profiles";
          final profilesList = StringUtils.collectionToDelimitedString(defaultProfiles, ", ");
          JetleafApplication._logger.info("⚠️  No active profile set → using $profileWord: [$profilesList]");
        } else {
          final profileWord = activeProfiles.length == 1 ? "profile" : "profiles";
          final profilesList = StringUtils.collectionToDelimitedString(activeProfiles, ", ");
          JetleafApplication._logger.info("✅ Application started with $profileWord: [$profilesList]");
        }
      }
    }

    final podFactory = context.getPodFactory();

    if (_aotRegistrar case AotRegistrar registrar when podFactory is DefaultListablePodFactory) {
      await registrar(podFactory);
    }

    if (_primarySource is! Type && _primarySource is! Class) {
      final name = StringUtils.uncapitalize(_mainApplicationClass.getSimpleName());
      if (!podFactory.containsSingleton(name)) {
        await podFactory.registerSingleton(
          name,
          _mainApplicationClass,
          object: ObjectHolder(
            _primarySource,
            packageName: _mainApplicationClass.getPackage().getName(),
            qualifiedName: _mainApplicationClass.getQualifiedName(),
          ),
        );
      }

      if (_primarySource is PodFactoryCustomizer) {
        await _primarySource.customize(podFactory, context.getEnvironment());
      }
    }

    if (_podNameGenerator != null && !podFactory.containsSingleton(AbstractApplicationContext.POD_NAME_GENERATOR_POD_NAME)) {
      final gen = _podNameGenerator!;
      final genClass = gen.getClass();

      await podFactory.registerSingleton(
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

      await podFactory.registerSingleton(
        AbstractApplicationContext.JETLEAF_ARGUMENT_POD_NAME,
        argsClass,
        object: ObjectHolder(args, packageName: args.getPackageName(), qualifiedName: argsClass.getQualifiedName())
      );
    }

    if (_banner != null && !podFactory.containsSingleton(AbstractApplicationContext.BANNER_POD_NAME)) {
      final bann = _banner!;
      final bannerClass = bann.getClass();

      await podFactory.registerSingleton(
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

  /// {@template jetleaf_application._call_runners}
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
    final runnerClass = Class<Runner>(null, PackageNames.MAIN);
    final podNames = await podFactory.getPodNames(runnerClass);

    final runners = <Runner>{};
    for (String podName in podNames) {
      final instance = await podFactory.getPod(podName);
      runners.add(instance);
    }

    final sorted = runners.toList();
    sorted.sort(OrderComparator().compare);

    for (var runner in sorted) {
      await _callRunner(runner, args);
    }
  }

  /// {@template jetleaf_application._call_runner}
  /// Executes a single runner instance.
  ///
  /// This method handles both [ApplicationRunner] and [CommandLineRunner]
  /// types, executing them with appropriate arguments.
  ///
  /// [runner] the runner instance to execute
  /// [args] application arguments for runner execution
  /// {@endtemplate}
  Future<void> _callRunner(Runner runner, ApplicationArguments args) async {
    if (runner is ApplicationRunner) {
      await _callRunnerInternal<ApplicationRunner>(runner, (applicationRunner) => applicationRunner.run(args));
    } else if (runner is CommandLineRunner) {
      await _callRunnerInternal<CommandLineRunner>(runner, (commandLineRunner) => commandLineRunner.run(args.getSourceArgs()));
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

  /// {@template jetleaf_application._call_runner_internal}
  /// Executes a runner instance with safe execution.
  ///
  /// This method safely executes a runner instance, handling any exceptions
  /// and logging appropriate error messages.
  ///
  /// [runner] the runner instance to execute
  /// [call] the execution callback
  /// {@endtemplate}
  Future<void> _callRunnerInternal<R extends Runner>(R runner, ThrowingConsumer<R> call) async {
    await call.callSafelyAsync(runner, message: () => "Failed to execute $R");
  }

  /// Refreshes and rebinds the active [ConversionService] within the application context.
  ///
  /// This method ensures that the Jetleaf runtime uses the most up-to-date
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
typedef ThrowingConsumer<T> = FutureOr<void> Function(T value);

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

  /// Executes the consumer asynchronously with safe exception handling.
  Future<void> callSafelyAsync(T value, {String Function()? message}) async {
    try {
      await this(value);
    } catch (ex) {
      throw IllegalStateException(
        message?.call() ?? "Execution of ${T.runtimeType} failed",
        cause: ex,
      );
    }
  }
}

/// {@template default_application_hook}
/// Default implementation of [ApplicationHook] in Jetleaf.
///
/// This hook serves as the central point for managing **application lifecycle events**
/// and orchestrating the execution of run listeners. It is typically used internally
/// by the Jetleaf framework but can also be extended or replaced if custom behavior
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
/// 1. The Jetleaf framework initializes the [DefaultApplicationHook] with a list
///    of listeners and a startup tracker.
/// 2. When the application is started, [getRunListener] is called with the active
///    [JetleafApplication] instance.
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
/// final runListener = hook.getRunListener(myJetleafApplication);
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
///   ApplicationRunListener getRunListener(JetleafApplication jetleafApplication) {
///     final original = super.getRunListener(jetleafApplication);
///     return LoggingDecorator(original); // add logging around all events
///   }
/// }
/// ```
///
/// This ensures your custom logic is seamlessly integrated with Jetleaf’s lifecycle.
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
  ApplicationRunListener getRunListener(JetleafApplication jetleafApplication) {
    // Returns a composite listener that delegates events to all registered listeners.
    return ApplicationRunListeners(_listeners, _applicationStartup);
  }
}