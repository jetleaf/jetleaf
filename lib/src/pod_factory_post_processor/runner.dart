import 'package:jetleaf_env/env.dart';
import 'package:jetleaf_lang/lang.dart';

/// {@template runner}
/// Base contract for application runners in Jetleaf.
///
/// A [Runner] is a component that can be invoked after the application
/// context has been created and initialized. It provides a hook into
/// the startup lifecycle, allowing custom logic to run before the
/// application is considered "ready".
///
/// Typically, you will not implement [Runner] directly, but instead use
/// its specialized forms: [ApplicationRunner] or [CommandLineRunner].
/// {@endtemplate}
abstract interface class Runner implements PriorityOrdered {}

/// {@template application_runner}
/// A runner that receives parsed [ApplicationArguments].
///
/// [ApplicationRunner] is typically used when you want to handle
/// structured, named application arguments such as `--port=8080`
/// or `--profile=dev`.
///
/// Example:
/// ```dart
/// final class MyRunner implements ApplicationRunner {
///   @override
///   void run(ApplicationArguments args) {
///     print('Active profiles: ${args.getOptionValues("profile")}');
///   }
/// }
/// ```
/// {@endtemplate}
abstract interface class ApplicationRunner extends Runner {
  /// Invoked after the application context has been loaded.
  ///
  /// [args] provides access to structured command-line arguments
  /// that have been parsed into key-value options.
  void run(ApplicationArguments args);
}

/// {@template command_line_runner}
/// A runner that receives raw command-line arguments.
///
/// [CommandLineRunner] is typically used when you want to process
/// arguments exactly as passed to the process (i.e. the `main(List<String> args)`
/// signature in Dart).
///
/// Example:
/// ```dart
/// final class MyRunner implements CommandLineRunner {
///   @override
///   void run(List<String> args) {
///     print('Raw args: $args');
///   }
/// }
/// ```
/// {@endtemplate}
abstract interface class CommandLineRunner extends Runner {
  /// Invoked after the application context has been loaded.
  ///
  /// [args] contains the raw, unprocessed command-line arguments.
  void run(List<String> args);
}