import 'package:jetleaf_core/context.dart';
import 'package:jetleaf_core/lang.dart';

/// {@template jetleaf_exception}
/// A [RuntimeException] thrown when the application context is considered
/// "abandoned" during startup or shutdown.
///
/// This typically indicates a failure or interruption during the
/// initialization or lifecycle process of the Jetleaf application context.
///
/// Use this exception to signal that the [ConfigurableApplicationContext]
/// is no longer valid and cannot continue.
///
/// ### Example
/// ```dart
/// if (context == null) {
///   throw JetleafException.nullable();
/// }
///
/// if (context.failed) {
///   throw JetleafException(context);
/// }
/// ```
/// {@endtemplate}
class JetleafException extends RuntimeException {
  /// The application context that was abandoned, if available.
  final ConfigurableApplicationContext? _applicationContext;

  /// {@macro jetleaf_exception}
  ///
  /// Creates a [JetleafException] with a reference to the abandoned
  /// [applicationContext].
  ///
  /// Use this when the context exists but is no longer valid, such as after
  /// a failed refresh or shutdown sequence.
  JetleafException(this._applicationContext) : super("Application context was abandoned");

  /// Returns the [ConfigurableApplicationContext] that was abandoned,
  /// or `null` if no context was ever created.
  ///
  /// ### Example
  /// ```dart
  /// try {
  ///   // startup logic...
  /// } on JetleafException catch (ex) {
  ///   final ctx = ex.getApplicationContext();
  ///   log.warn('Context abandoned: $ctx');
  /// }
  /// ```
  ConfigurableApplicationContext? getApplicationContext() => _applicationContext;
}

/// {@template missing_aot_registrar_exception}
/// A [RuntimeException] thrown when a Jetleaf application is launched in
/// production or AOT mode without an [AotRegistrar].
///
/// In development mode, Jetleaf automatically generates and binds the AOT
/// registrar via `ensureDevelopmentRuntime`. In production or AOT builds,
/// dynamic source scanning is disabled, so the application must be built using
/// `jl build` and pass `registerGeneratedArtifacts` (from
/// `lib/_jetleaf/main.dart`) to `JetleafApplication.run(...)` or
/// `JetleafApplication.setAotRegistrar(...)`.
/// {@endtemplate}
class MissingAotRegistrarException extends RuntimeException {
  /// {@macro missing_aot_registrar_exception}
  MissingAotRegistrarException([String? message])
      : super(
          message ??
              'No AOT registrar was provided for this production or AOT build.\n\n'
              'In development mode, Jetleaf automatically generates and binds the AOT registrar. '
              'In production or AOT-compiled builds (e.g. `dart compile exe`, `dart.vm.product=true`), '
              'dynamic source scanning is disabled, so you must:\n'
              '  1. Build the application artifacts:\n'
              '       jl build\n'
              '  2. Import the generated registry and pass `registerGeneratedArtifacts` at startup:\n\n'
              '     Using `JetleafApplication.run`:\n'
              '       import \'package:my_app/_jetleaf/main.dart\';\n\n'
              '       Future<void> main(List<String> args) async {\n'
              '         await JetleafApplication.run(\n'
              '           MyApplication,\n'
              '           args,\n'
              '           aotRegistrar: registerGeneratedArtifacts,\n'
              '         );\n'
              '       }\n\n'
              '     Or using `JetleafApplication` directly:\n'
              '       import \'package:my_app/_jetleaf/main.dart\';\n\n'
              '       Future<void> main(List<String> args) async {\n'
              '         final app = JetleafApplication(MyApplication);\n'
              '         app.setAotRegistrar(registerGeneratedArtifacts);\n'
              '         await app.create(args);\n'
              '       }',
        );
}