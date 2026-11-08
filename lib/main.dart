/// 🚀 **Jetleaf Application Bootstrap, Context & Runner Kernel**
///
/// This library provides the core bootstrap mechanisms, lifecycle runners,
/// banner rendering, exception handling, and shutdown orchestration for Jetleaf applications:
/// - **Application Bootstrap:** [JetleafApplication], `@JetleafApplicationStarter`.
/// - **Execution Runners:** [CommandLineRunner], [ApplicationRunner].
/// - **Bootstrap Context:** [BootstrapContext], [DefaultBootstrapContext], [BootstrapContextFactory].
/// - **Exception Handling:** [ApplicationExceptionHandler], [ExceptionReporterManager].
/// - **Shutdown Handling:** [ApplicationShutdownHandler], [ApplicationShutdownHandlerHook].
/// - **Banner Customization:** [Banner], [DefaultBanner], [BannerMode].
///
/// ---
///
/// ## 🔄 Application Bootstrap Lifecycle
///
/// ```text
/// ┌────────────────────────────────────────────────────────────────────────┐
/// │                     Jetleaf Bootstrap Pipeline                         │
/// ├────────────────────────────────────────────────────────────────────────┤
/// │ 1. Environment Preparation   Property sources, profiles, and arguments │
/// │                                    │                                   │
/// │ 2. Banner Output             Console ASCII banner & version stamp      │
/// │                                    │                                   │
/// │ 3. Bootstrap Context Setup   Pre-instantiation and initializers        │
/// │                                    │                                   │
/// │ 4. Application Context Init  AnnotationConfigApplicationContext setup  │
/// │                                    │                                   │
/// │ 5. AOT Registry Loading      Function-pointer tables registered        │
/// │                                    │                                   │
/// │ 6. Singleton Instantiation   All eager singleton pods materialized     │
/// │                                    │                                   │
/// │ 7. Runners Execution         CommandLineRunner / ApplicationRunner     │
/// │                                    │                                   │
/// │                        >>> APPLICATION RUNNING <<<                     │
/// └────────────────────────────────────────────────────────────────────────┘
/// ```
///
/// ---
///
/// ## 📦 Exports Categorization
///
/// ### 🚀 Bootstrap & Starters
/// - [JetleafApplication] — primary bootstrap driver managing configuration, context, and shutdown.
/// - `@JetleafApplicationStarter` — root annotation marking the entry-point application class.
/// - [BootstrapContext] — lightweight early context used during environment and logging setup.
///
/// ### 🏃 Runners & Entry Points
/// - [CommandLineRunner] — receives raw `List<String> args` after container initialization.
/// - [ApplicationRunner] — receives parsed [ApplicationArguments] with option flags.
///
/// ### 🎨 Banner & Diagnostics
/// - [Banner] — contract for rendering the startup banner.
/// - [DefaultBanner] — standard Jetleaf ASCII banner with active version information.
/// - [BannerMode] — controls whether banner output is displayed or muted (`CONSOLE`, `OFF`).
///
/// ---
///
/// ## 🎯 Usage Example: Customizing Runners and Shutdown Hooks
///
/// ```dart
/// import 'package:jetleaf/main.dart';
///
/// @JetleafApplicationStarter()
/// class CliUtility implements ApplicationRunner {
///   @override
///   int getOrder() => 1;
///
///   @override
///   void run(ApplicationArguments args) {
///     if (args.containsOption('dry-run')) {
///       print('Running utility in dry-run mode.');
///     } else {
///       print('Executing batch changes...');
///     }
///   }
/// }
///
/// void main(List<String> args) async {
///   final app = JetleafApplication(CliUtility);
///   app.setBannerMode(BannerMode.CONSOLE);
///   app.setApplicationType(ApplicationType.NONE);
///
///   await app.create(args, null);
/// }
/// ```
///
/// {@category Jetleaf}
library;

export 'src/banner/banner.dart';
export 'src/banner/_banner.dart';

export 'src/pod_factory_post_processor/property_source_ordering_pod_factory_post_processor.dart';
export 'src/pod_factory_post_processor/runner.dart';

export 'src/context/bootstrap_context.dart';
export 'src/context/bootstrap_context_impl.dart';
export 'src/context/context_factory.dart';
export 'src/context/default_context_factory.dart';

export 'src/entry/application_import_selector.dart';
export 'src/entry/application_type_filter.dart';
export 'src/entry/jetleaf_config_parser.dart';

export 'src/env/property_source.dart';
export 'src/env/dart_config_parser.dart';
export 'src/env/environment_listener.dart';
export 'src/env/environment_parser.dart';
export 'src/env/jetleaf_property_source_order_rule.dart';
export 'src/env/models.dart';

export 'src/exception_handler/application_exception_handler.dart';
export 'src/exception_handler/exception_handler.dart';
export 'src/exception_handler/exception_reporter_manager.dart';

export 'src/listener/lifecycle_run_listener.dart';
export 'src/listener/run_listener.dart';
export 'src/listener/run_listeners.dart';

export 'src/logging/jetleaf_logging_property.dart';
export 'src/logging/logging_listener.dart';
export 'src/logging/startup_logger.dart';

export 'src/shutdown/application_shutdown_handler.dart';
export 'src/shutdown/application_shutdown_handler_hook.dart';

export 'src/jetleaf_application.dart';
export 'src/jetleaf_application_starter.dart';
export 'src/jetleaf_exception.dart';
export 'src/jetleaf_version.dart';
