import 'package:jetleaf_lang/lang.dart';

/// {@template application_argument}
/// Defines the contract for accessing and parsing command-line arguments passed to an application.
///
/// This interface allows inspection of raw arguments, detection of option-based arguments
/// (like `--name=value`), and separation of non-option arguments.
///
/// Example usage:
///
/// ```dart
/// class MyAppArgs implements ApplicationArguments {
///   final List<String> _args;
///   MyAppArgs(this._args);
///
///   @override
///   List<String> getSourceArgs() => _args;
///
///   @override
///   Set<String> getOptionNames() => {...};
///
///   @override
///   bool containsOption(String name) => {...};
///
///   @override
///   List<String> getOptionValues(String name) => {...};
///
///   @override
///   List<String> getNonOptionArgs() => [...];
/// }
/// ```
///
/// This is typically used during application startup to parse user-supplied flags and
/// parameters, especially in CLI-based or microservice setups.
/// {@endtemplate}
abstract interface class ApplicationArguments implements PackageIdentifier {
  /// {@template application_argument_get_source_args}
  /// Returns the raw unprocessed arguments passed to the application.
  ///
  /// These are the exact strings supplied on the command line.
  ///
  /// Example:
  /// ```dart
  /// print(args.getSourceArgs()); // ['--port=8080', '--debug']
  /// ```
  ///
  /// @return a list of raw arguments.
  /// {@endtemplate}
  List<String> getSourceArgs();

  /// {@template application_argument_get_option_names}
  /// Returns the names of all parsed option arguments.
  ///
  /// Option arguments are those starting with `--`. For example, given:
  /// ```
  /// --foo=bar --debug
  /// ```
  /// this returns:
  /// ```dart
  /// ['foo', 'debug']
  /// ```
  ///
  /// @return a set of option names, or an empty set if none.
  /// {@endtemplate}
  Set<String> getOptionNames();

  /// {@template application_argument_contains_option}
  /// Checks whether a given option name is present in the parsed arguments.
  ///
  /// Example:
  /// ```dart
  /// if (args.containsOption('debug')) {
  ///   print('Debug mode is enabled');
  /// }
  /// ```
  ///
  /// @param name the option name to check.
  /// @return true if the option exists, false otherwise.
  /// {@endtemplate}
  bool containsOption(String name);

  /// {@template application_argument_get_option_values}
  /// Returns a list of values associated with a given option name.
  ///
  /// Behavior:
  /// - If the option is present without a value (`--flag`), returns an empty list `[]`.
  /// - If the option has one value (`--name=John`), returns `['John']`.
  /// - If the option has multiple values (`--name=John --name=Doe`), returns `['John', 'Doe']`.
  /// - If the option is not present, returns `null`.
  ///
  /// Example:
  /// ```dart
  /// final names = args.getOptionValues('name');
  /// if (names != null) {
  ///   print(names); // might print: ['Alice', 'Bob']
  /// }
  /// ```
  ///
  /// @param name the name of the option.
  /// @return list of values or null if the option is not present.
  /// {@endtemplate}
  List<String>? getOptionValues(String name);

  /// {@template application_argument_get_non_option_args}
  /// Returns all non-option arguments (those without `--` prefix).
  ///
  /// These are usually positional parameters.
  ///
  /// Example:
  /// ```dart
  /// dart run main.dart file.txt --verbose
  /// // getNonOptionArgs() returns ['file.txt']
  /// ```
  ///
  /// @return a list of non-option arguments, or an empty list if none.
  /// {@endtemplate}
  List<String> getNonOptionArgs();
}