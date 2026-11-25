part of '../jetleaf_application.dart';

/// {@template jetleaf_application_support}
/// Internal base state and configuration holder for [JetleafApplication].
///
/// Stores all configurable properties, lifecycle initializers, listeners,
/// exception reporters, and runtime state fields along with their public
/// getters and setters.
/// {@endtemplate}
abstract base class _JetleafApplicationSupport {
  /// {@template jetleaf_application.primary_source}
  /// The primary source object for this application.
  ///
  /// Typically the main application class annotated with `@Configuration`
  /// or containing the main method.
  ///
  /// Used to determine the main application class and package scanning base.
  /// {@endtemplate}
  final Object _primarySource;

  /// {@template jetleaf_application.initializers}
  /// Application context initializers for custom context configuration.
  ///
  /// These initializers are called before the context is refreshed, allowing
  /// for custom configuration of the application context.
  /// {@endtemplate}
  List<ApplicationContextInitializer> _initializers = [];

  /// {@template jetleaf_application.listeners}
  /// Application event listeners for lifecycle event handling.
  ///
  /// These listeners receive application events such as context refresh,
  /// startup completion, and shutdown initiation.
  /// {@endtemplate}
  List<ApplicationEventListener> _listeners = [];

  /// {@template jetleaf_application.bootstrap_initializers}
  /// Bootstrap registry initializers for early component registration.
  ///
  /// These initializers are called during bootstrap context creation,
  /// allowing for registration of components before the main context is built.
  /// {@endtemplate}
  List<BootstrapRegistryInitializer> _bootstrapInitializers = [];

  /// {@template jetleaf_application.exception_reporters}
  /// Exception reporters for handling and reporting application exceptions.
  ///
  /// These reporters are called when unhandled exceptions occur during
  /// application startup or operation.
  /// {@endtemplate}
  List<ExceptionReporter> _exceptionReporters = [];

  /// {@template jetleaf_application.exit_code_exception_handlers}
  /// Exit code exception handlers for converting exceptions to exit codes.
  ///
  /// These handlers determine the appropriate exit code when the application
  /// terminates due to an exception.
  /// {@endtemplate}
  final List<ExitCodeExceptionHandler> _exitCodeExceptionHandlers = [];

  /// {@template jetleaf_application.default_properties}
  /// Default properties applied to the environment.
  ///
  /// These properties have the lowest precedence and can be overridden by
  /// other property sources.
  /// {@endtemplate}
  Map<String, Object> _defaultProperties = {};

  /// {@template jetleaf_application.additional_profiles}
  /// Additional active profiles for the application.
  ///
  /// These profiles are activated in addition to any profiles specified
  /// via command line or environment variables.
  /// {@endtemplate}
  Set<String> _additionalProfiles = {};

  /// {@template jetleaf_application.startup_tracker}
  /// Tracks application startup timing and phases.
  ///
  /// Provides detailed timing information for different startup phases
  /// and can be used for performance monitoring and logging.
  /// {@endtemplate}
  late StartupTracker _startup;

  /// {@template jetleaf_application.main_application_class}
  /// The main application class determined from the primary source.
  ///
  /// Used for package scanning, banner display, and various framework
  /// operations that require knowledge of the application class.
  /// {@endtemplate}
  late Class<Object> _mainApplicationClass;

  /// {@template jetleaf_application.application_startup}
  /// Tracks application startup metrics and performance data.
  ///
  /// Provides detailed information about application initialization
  /// timing and can be used for monitoring and optimization.
  /// {@endtemplate}
  late ApplicationStartup _applicationStartup;

  /// {@template jetleaf_application.bootstrap_context}
  /// Bootstrap context for early component registration and resolution.
  ///
  /// Used during the bootstrap phase to register components that are
  /// needed before the main application context is created.
  /// {@endtemplate}
  late ConfigurableBootstrapContext _boostrapContext;

  /// {@template jetleaf_application.application_context_factory}
  /// Factory for creating application contexts based on application type.
  ///
  /// Determines the appropriate context implementation (web, standalone, etc.)
  /// based on the detected application type and configuration.
  /// {@endtemplate}
  late ApplicationContextFactory _applicationContextFactory;

  /// {@template jetleaf_application.application_listeners}
  /// Manages application run listeners for lifecycle event publishing.
  ///
  /// Coordinates the calling of run listeners at various points in the
  /// application lifecycle.
  /// {@endtemplate}
  late ApplicationRunListeners _applicationListeners;

  /// {@template jetleaf_application.conversion_service}
  /// Service for type conversion and formatting.
  ///
  /// Used by the framework for converting between different data types
  /// during configuration processing and property resolution.
  /// {@endtemplate}
  late ConfigurableConversionService _conversionService;

  /// {@template jetleaf_application.pod_name_generator}
  /// Custom pod name generator for pod naming strategy.
  ///
  /// If specified, this generator is used to create names for registered
  /// pods instead of the default naming strategy.
  /// {@endtemplate}
  PodNameGenerator? _podNameGenerator;

  /// {@template jetleaf_application.environment}
  /// The environment for this application.
  ///
  /// Manages property sources, profiles, and environment-specific
  /// configuration for the application.
  /// {@endtemplate}
  ConfigurableEnvironment? _environment;

  /// {@template jetleaf_application.banner}
  /// The banner to be displayed at application startup.
  ///
  /// Can be customized to show application-specific information
  /// during startup.
  /// {@endtemplate}
  Banner? _banner;

  /// {@template jetleaf_application.logging_listener}
  /// Global logging listener for framework logging events.
  ///
  /// Receives logging events from throughout the framework and
  /// can be used for custom logging integration.
  /// {@endtemplate}
  LoggingListener? _loggingListener;

  /// {@template jetleaf_application.environment_prefix}
  /// Prefix for environment property resolution.
  ///
  /// Used when resolving properties from the environment to
  /// support namespaced configuration.
  /// {@endtemplate}
  String _environmentPrefix = "";

  /// {@template jetleaf_application.aot_registrar}
  /// Optional compile-time generated AOT registrar.
  /// When provided, types, members, annotations, and pods are registered directly
  /// with zero runtime reflection.
  /// {@endtemplate}
  AotRegistrar? _aotRegistrar;

  /// {@template jetleaf_application.banner_mode}
  /// The display mode of the application banner at startup.
  ///
  /// Controls how and where the application banner is displayed
  /// during startup.
  ///
  /// Defaults to [BannerMode.CONSOLE].
  /// {@endtemplate}
  BannerMode _bannerMode = BannerMode.CONSOLE;

  /// {@template jetleaf_application.application_type}
  /// The type of application (e.g., [ApplicationType.WEB], [ApplicationType.NONE]).
  ///
  /// Determines the appropriate context implementation and configuration
  /// for the specific application type.
  ///
  /// Defaults to [ApplicationType.NONE].
  /// {@endtemplate}
  ApplicationType _applicationType = ApplicationType.NONE;

  /// {@template jetleaf_application.is_application_type_set}
  /// Whether the application type was explicitly configured via [setApplicationType].
  ///
  /// When `true`, [_detectApplicationType] returns [_applicationType] directly
  /// without inspecting CLI arguments, environment properties, or classpath
  /// web dependencies.
  ///
  /// Defaults to `false`.
  /// {@endtemplate}
  bool _isApplicationTypeSet = false;

  /// {@template jetleaf_application.register_shutdown_hook}
  /// Whether the application should register a shutdown hook with the runtime.
  ///
  /// When true, the application registers hooks for graceful shutdown
  /// on SIGTERM, SIGINT, and other termination signals.
  ///
  /// Defaults to `true`.
  /// {@endtemplate}
  bool _registerShutdownHook = true;

  /// {@template jetleaf_application.allow_circular_references}
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

  /// {@template jetleaf_application.allow_definition_overriding}
  /// Whether a pod definition may be overridden.
  ///
  /// When true, later registrations of the same pod name will override
  /// earlier registrations.
  ///
  /// Defaults to `false`.
  /// {@endtemplate}
  bool _allowDefinitionOverriding = false;

  /// {@template jetleaf_application.keep_alive}
  /// Whether the application should stay alive after startup.
  ///
  /// When true, the application will not exit automatically after
  /// startup completes, typically used for web applications or
  /// long-running services.
  ///
  /// Defaults to `false`.
  /// {@endtemplate}
  bool _keepAlive = false;

  /// {@template jetleaf_application.lazy_initialization}
  /// Whether pods should be lazily initialized instead of eagerly.
  ///
  /// When true, pods are created on first access rather than during
  /// application startup.
  ///
  /// Defaults to `false`.
  /// {@endtemplate}
  bool _lazyInitialization = false;

  /// {@template jetleaf_application.add_command_line_properties}
  /// Whether command line properties should be added to the environment.
  ///
  /// When true, command line arguments in the form `--name=value` are
  /// parsed and added to the environment as properties.
  ///
  /// Defaults to `true`.
  /// {@endtemplate}
  bool _addCommandLineProperties = true;

  /// {@template jetleaf_application.add_conversion_service}
  /// Whether a conversion service should be added to the environment.
  ///
  /// When true, a default conversion service is registered for type
  /// conversion operations throughout the framework.
  ///
  /// Defaults to `true`.
  /// {@endtemplate}
  bool _addConversionService = true;

  /// {@template jetleaf_application.log_startup_info}
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

  /// {@template jetleaf_application.system_detector}
  /// Detector for system properties and runtime environment.
  ///
  /// Used to detect information about the runtime environment,
  /// including AOT vs JIT compilation mode.
  /// {@endtemplate}
  final SystemDetector _detector = SystemDetector();

  /// Cached system properties detected at application launch.
  SystemProperties? _system;

  /// {@macro jetleaf_application_support}
  _JetleafApplicationSupport(this._primarySource);

  /// {@template jetleaf_application._get_conversion_service}
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

  /// Sets the compile-time generated AOT registrar.
  void setAotRegistrar(AotRegistrar registrar) {
    _aotRegistrar = registrar;
    try {
      (registrar as dynamic)();
    } catch (_) {}
  }

  /// Sets the compile-time generated AOT registrar.
  void setRegistrar(AotRegistrar registrar) => setAotRegistrar(registrar);

  /// Returns the detected system environment properties for this application.
  SystemProperties? getSystem() => _system;

  // ============================== MAIN APPLICATION CLASS ==============================

  /// {@template jetleaf_application.get_main_class}
  /// Gets the main application class.
  ///
  /// Returns the [Class] representing the main application class
  /// {@endtemplate}
  Class<Object> getMainClass() => _mainApplicationClass;

  // ============================== WEB APPLICATION TYPE ==============================

  /// {@template jetleaf_application.get_application_type}
  /// Gets the application type.
  ///
  /// Returns the detected or configured [ApplicationType]
  /// {@endtemplate}
  ApplicationType getApplicationType() => _applicationType;

  /// {@template jetleaf_application.set_application_type}
  /// Sets the application type explicitly.
  ///
  /// Overrides automatic application type detection.
  ///
  /// [webApplicationType] the application type to set
  /// {@endtemplate}
  void setApplicationType(ApplicationType webApplicationType) {
    _applicationType = webApplicationType;
    _isApplicationTypeSet = true;
  }

  // ============================== ALLOW POD DEFINITION OVERRIDING ==============================

  /// {@template jetleaf_application.get_allow_pod_definition_overriding}
  /// Gets whether pod definition overriding is allowed.
  ///
  /// Returns `true` if pod definition overriding is allowed
  /// {@endtemplate}
  bool getAllowPodDefinitionOverriding() => _allowDefinitionOverriding;

  /// {@template jetleaf_application.set_allow_pod_definition_overriding}
  /// Sets whether pod definition overriding is allowed.
  ///
  /// [allowDefinitionOverriding] whether to allow pod definition overriding
  /// {@endtemplate}
  void setAllowPodDefinitionOverriding(bool allowDefinitionOverriding) {
    _allowDefinitionOverriding = allowDefinitionOverriding;
  }

  // ============================== ALLOW CIRCULAR REFERENCES ==============================

  /// {@template jetleaf_application.get_allow_circular_references}
  /// Gets whether circular references are allowed.
  ///
  /// Returns `true` if circular references are allowed
  /// {@endtemplate}
  bool getAllowCircularReferences() => _allowCircularReferences;

  /// {@template jetleaf_application.set_allow_circular_references}
  /// Sets whether circular references are allowed.
  ///
  /// [allowCircularReferences] whether to allow circular references
  /// {@endtemplate}
  void setAllowCircularReferences(bool allowCircularReferences) {
    _allowCircularReferences = allowCircularReferences;
  }

  // ============================== BANNER MODE ==============================

  /// {@template jetleaf_application.get_banner_mode}
  /// Gets the banner display mode.
  ///
  /// Returns the configured [BannerMode]
  /// {@endtemplate}
  BannerMode getBannerMode() => _bannerMode;

  /// {@template jetleaf_application.set_banner_mode}
  /// Sets the banner display mode.
  ///
  /// [bannerMode] the banner mode to set
  /// {@endtemplate}
  void setBannerMode(BannerMode bannerMode) {
    _bannerMode = bannerMode;
  }

  // ============================== KEEP ALIVE ==============================

  /// {@template jetleaf_application.get_keep_alive}
  /// Gets whether the application should stay alive after startup.
  ///
  /// Returns `true` if the application should stay alive
  /// {@endtemplate}
  bool getKeepAlive() => _keepAlive;

  /// {@template jetleaf_application.set_keep_alive}
  /// Sets whether the application should stay alive after startup.
  ///
  /// [keepAlive] whether the application should stay alive
  /// {@endtemplate}
  void setKeepAlive(bool keepAlive) {
    _keepAlive = keepAlive;
  }

  // ============================== LAZY INITIALIZATION ==============================

  /// {@template jetleaf_application.get_lazy_initialization}
  /// Gets whether lazy initialization is enabled.
  ///
  /// Returns `true` if lazy initialization is enabled
  /// {@endtemplate}
  bool getLazyInitialization() => _lazyInitialization;

  /// {@template jetleaf_application.set_lazy_initialization}
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

  /// {@template jetleaf_application.get_log_startup_info}
  /// Gets whether startup information logging is enabled.
  ///
  /// Returns `true` if startup information logging is enabled
  /// {@endtemplate}
  bool getLogStartupInfo() => _logStartupInfo;

  /// {@template jetleaf_application.set_log_startup_info}
  /// Sets whether startup information logging is enabled.
  ///
  /// [logStartupInfo] whether to enable startup information logging
  /// {@endtemplate}
  void setLogStartupInfo(bool logStartupInfo) {
    logStartupInfo = logStartupInfo;
  }

  // ============================== REGISTER SHUTDOWN HOOK ==============================

  /// {@template jetleaf_application.get_register_shutdown_hook}
  /// Gets whether shutdown hook registration is enabled.
  ///
  /// Returns `true` if shutdown hook registration is enabled
  /// {@endtemplate}
  bool getRegisterShutdownHook() => _registerShutdownHook;

  /// {@template jetleaf_application.set_register_shutdown_hook}
  /// Sets whether shutdown hook registration is enabled.
  ///
  /// [registerShutdownHook] whether to enable shutdown hook registration
  /// {@endtemplate}
  void setRegisterShutdownHook(bool registerShutdownHook) {
    _registerShutdownHook = registerShutdownHook;
  }

  // ============================== ADD COMMAND LINE PROPERTIES ==============================

  /// {@template jetleaf_application.get_add_command_line_properties}
  /// Gets whether command line property parsing is enabled.
  ///
  /// Returns `true` if command line property parsing is enabled
  /// {@endtemplate}
  bool getAddCommandLineProperties() => _addCommandLineProperties;

  /// {@template jetleaf_application.set_add_command_line_properties}
  /// Sets whether command line property parsing is enabled.
  ///
  /// [addCommandLineProperties] whether to enable command line property parsing
  /// {@endtemplate}
  void setAddCommandLineProperties(bool addCommandLineProperties) {
    _addCommandLineProperties = addCommandLineProperties;
  }

  // ============================== ADD CONVERSION SERVICE ==============================

  /// {@template jetleaf_application.get_add_conversion_service}
  /// Gets whether conversion service registration is enabled.
  ///
  /// Returns `true` if conversion service registration is enabled
  /// {@endtemplate}
  bool getAddConversionService() => _addConversionService;

  /// {@template jetleaf_application.add_conversion_service}
  /// Sets whether conversion service registration is enabled.
  ///
  /// [addConversionService] whether to enable conversion service registration
  /// {@endtemplate}
  void addConversionService(bool addConversionService) {
    _addConversionService = addConversionService;
  }

  /// {@template jetleaf_application.get_conversion_service}
  /// Gets the conversion service.
  ///
  /// Returns the configured [ConfigurableConversionService]
  /// {@endtemplate}
  ConfigurableConversionService getConversionService() => _getConversionService();

  /// {@template jetleaf_application.set_conversion_service}
  /// Sets the conversion service.
  ///
  /// [conversionService] the conversion service to set
  /// {@endtemplate}
  void setConversionService(ConfigurableConversionService conversionService) {
    _conversionService = conversionService;
  }

  // ============================== BOOTSTRAP REGISTRY INITIALIZERS ==============================

  /// {@template jetleaf_application.get_bootstrap_registry_initializers}
  /// Gets the bootstrap registry initializers.
  ///
  /// Returns an unmodifiable list of bootstrap registry initializers
  /// {@endtemplate}
  List<BootstrapRegistryInitializer> getBootstrapRegistryInitializers() => List.unmodifiable(_bootstrapInitializers);

  /// {@template jetleaf_application.add_bootstrap_registry_initializers}
  /// Adds multiple bootstrap registry initializers.
  ///
  /// [initializers] the bootstrap registry initializers to add
  /// {@endtemplate}
  void addBootstrapRegistryInitializers(List<BootstrapRegistryInitializer> initializers) {
    _bootstrapInitializers.addAll(initializers);
  }

  /// {@template jetleaf_application.add_bootstrap_registry_initializer}
  /// Adds a single bootstrap registry initializer.
  ///
  /// [initializer] the bootstrap registry initializer to add
  /// {@endtemplate}
  void addBootstrapRegistryInitializer(BootstrapRegistryInitializer initializer) {
    _bootstrapInitializers.add(initializer);
  }

  /// {@template jetleaf_application.set_bootstrap_registry_initializers}
  /// Sets the bootstrap registry initializers.
  ///
  /// [initializers] the bootstrap registry initializers to set
  /// {@endtemplate}
  void setBootstrapRegistryInitializers(List<BootstrapRegistryInitializer> initializers) {
    _bootstrapInitializers = initializers;
  }

  // ============================== CONTEXT INITIALIZERS ==============================

  /// {@template jetleaf_application.get_initializers}
  /// Gets the application context initializers.
  ///
  /// Returns an unmodifiable list of application context initializers
  /// {@endtemplate}
  List<ApplicationContextInitializer> getInitializers() => List.unmodifiable(_initializers);

  /// {@template jetleaf_application.add_initializers}
  /// Adds multiple application context initializers.
  ///
  /// [initializers] the application context initializers to add
  /// {@endtemplate}
  void addInitializers(List<ApplicationContextInitializer> initializers) {
    _initializers.addAll(initializers);
  }

  /// {@template jetleaf_application.set_initializers}
  /// Sets the application context initializers.
  ///
  /// [initializers] the application context initializers to set
  /// {@endtemplate}
  void setInitializers(List<ApplicationContextInitializer> initializers) {
    _initializers = initializers;
  }

  /// {@template jetleaf_application.add_initializer}
  /// Adds a single application context initializer.
  ///
  /// [initializer] the application context initializer to add
  /// {@endtemplate}
  void addInitializer(ApplicationContextInitializer initializer) {
    _initializers.add(initializer);
  }

  // ============================== LISTENERS ==============================

  /// {@template jetleaf_application.get_listeners}
  /// Gets the application event listeners.
  ///
  /// Returns an unmodifiable list of application event listeners
  /// {@endtemplate}
  List<ApplicationEventListener<ApplicationEvent>> getListeners() => List.unmodifiable(_listeners);

  /// {@template jetleaf_application.set_listeners}
  /// Sets the application event listeners.
  ///
  /// [listeners] the application event listeners to set
  /// {@endtemplate}
  void setListeners(List<ApplicationEventListener<ApplicationEvent>> listeners) {
    _listeners = listeners;
  }

  /// {@template jetleaf_application.add_listeners}
  /// Adds multiple application event listeners.
  ///
  /// [listeners] the application event listeners to add
  /// {@endtemplate}
  void addListeners(List<ApplicationEventListener<ApplicationEvent>> listeners) {
    _listeners.addAll(listeners);
  }

  // ============================== ADDITIONAL PROFILES ==============================

  /// {@template jetleaf_application.get_additional_profiles}
  /// Gets the additional active profiles.
  ///
  /// Returns an unmodifiable set of additional active profiles
  /// {@endtemplate}
  Set<String> getAdditionalProfiles() => Set.unmodifiable(_additionalProfiles);

  /// {@template jetleaf_application.set_additional_profiles}
  /// Sets the additional active profiles.
  ///
  /// [profiles] the additional active profiles to set
  /// {@endtemplate}
  void setAdditionalProfiles(Set<String> profiles) {
    _additionalProfiles = profiles;
  }

  // ============================== DEFAULT PROPERTIES ==============================

  /// {@template jetleaf_application.get_default_properties}
  /// Gets the default properties.
  ///
  /// Returns an unmodifiable map of default properties
  /// {@endtemplate}
  Map<String, Object> getDefaultProperties() => Map.unmodifiable(_defaultProperties);

  /// {@template jetleaf_application.set_default_properties}
  /// Sets the default properties.
  ///
  /// [defaultProperties] the default properties to set
  /// {@endtemplate}
  void setDefaultProperties(Map<String, String> defaultProperties) {
    _defaultProperties = defaultProperties;
  }

  // ============================== APPLICATION STARTUP ==============================

  /// {@template jetleaf_application.get_startup}
  /// Gets the application startup tracker.
  ///
  /// Returns the [ApplicationStartup] instance
  /// {@endtemplate}
  ApplicationStartup getStartup() => _applicationStartup;

  /// {@template jetleaf_application.set_application_startup}
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

  /// {@template jetleaf_application.get_environment_prefix}
  /// Gets the environment property prefix.
  ///
  /// Returns the environment property prefix
  /// {@endtemplate}
  String getEnvironmentPrefix() => _environmentPrefix;

  /// {@template jetleaf_application.set_environment_prefix}
  /// Sets the environment property prefix.
  ///
  /// [environmentPrefix] the environment property prefix to set
  /// {@endtemplate}
  void setEnvironmentPrefix(String environmentPrefix) {
    _environmentPrefix = environmentPrefix;
  }

  // ============================== POD NAME GENERATOR ==============================

  /// {@template jetleaf_application.get_pod_name_generator}
  /// Gets the pod name generator.
  ///
  /// Returns the configured [PodNameGenerator], or null if not set
  /// {@endtemplate}
  PodNameGenerator? getPodNameGenerator() => _podNameGenerator;

  /// {@template jetleaf_application.set_pod_name_generator}
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
  /// final app = JetleafApplication();
  /// app.addExceptionReporter(ExceptionReporter());
  /// ```
  void addExceptionReporter(ExceptionReporter reporter) {
    _exceptionReporters.add(reporter);
  }

  /// Returns the list of exception reporters.
  ///
  /// ### Example
  /// ```dart
  /// final app = JetleafApplication();
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
  /// final app = JetleafApplication();
  /// app.addExitCodeExceptionHandler(ExitCodeExceptionHandler());
  /// ```
  void addExitCodeExceptionHandler(ExitCodeExceptionHandler handler) {
    _exitCodeExceptionHandlers.add(handler);
  }

  /// Returns the list of exit code exception handlers.
  ///
  /// ### Example
  /// ```dart
  /// final app = JetleafApplication();
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
  /// final app = JetleafApplication();
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
  /// final app = JetleafApplication();
  /// app.setLoggingListener(LoggingListener());
  /// final listener = app.getLoggingListener();
  /// ```
  LoggingListener? getLoggingListener() => _loggingListener;
}