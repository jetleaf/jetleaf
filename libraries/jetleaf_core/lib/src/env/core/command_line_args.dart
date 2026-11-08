/// {@template command_line_args}
/// A utility class for parsing and storing command-line arguments.
///
/// This class separates arguments into **option arguments** (e.g., `--key=value`)
/// and **non-option arguments** (e.g., standalone values like file paths).
///
/// ### Example:
/// ```dart
/// var args = CommandLineArgs();
/// args.addOptionArg('config', 'dev');
/// args.addNonOptionArg('main.dart');
///
/// print(args.containsOption('config')); // true
/// print(args.getOptionValues('config')); // ['dev']
/// print(args.getNonOptionArgs()); // ['main.dart']
/// ```
/// {@endtemplate}
class CommandLineArgs {
  final Map<String, List<String>> _optionArgs = {};
  final List<String> _nonOptionArgs = [];

  /// {@template command_line_args_add_option_arg}
  /// Adds an option argument with an optional value.
  ///
  /// - [optionName] is the name of the option (e.g., `--config` becomes `'config'`).
  /// - [optionValue] is the value associated with the option (can be `null`).
  ///
  /// If [optionValue] is `null`, it is ignored.
  /// {@endtemplate}
  void addOptionArg(String optionName, String? optionValue) {
    _optionArgs.putIfAbsent(optionName, () => []);
    if (optionValue != null) {
      _optionArgs[optionName]!.add(optionValue);
    }
  }

  /// {@template command_line_args_get_option_names}
  /// Returns a set of all option names that were parsed.
  ///
  /// Example: If `--config=dev` was parsed, `'config'` will be included.
  /// {@endtemplate}
  Set<String> getOptionNames() => _optionArgs.keys.toSet();

  /// {@template command_line_args_contains_option}
  /// Returns `true` if the given [optionName] exists among the parsed arguments.
  /// {@endtemplate}
  bool containsOption(String optionName) => _optionArgs.containsKey(optionName);

  /// {@template command_line_args_get_option_values}
  /// Returns the list of values for the given [optionName], or `null` if not found.
  ///
  /// Some options can have multiple values (e.g., `--tag a --tag b`).
  /// {@endtemplate}
  List<String>? getOptionValues(String optionName) => _optionArgs[optionName];

  /// {@template command_line_args_add_non_option_arg}
  /// Adds a non-option argument (e.g., a file name or input path).
  /// {@endtemplate}
  void addNonOptionArg(String value) {
    _nonOptionArgs.add(value);
  }

  /// {@template command_line_args_get_non_option_args}
  /// Returns a read-only list of all non-option arguments in the order they were added.
  /// {@endtemplate}
  List<String> getNonOptionArgs() => List.unmodifiable(_nonOptionArgs);
}

/// {@template simple_command_line_args_parser}
/// A basic parser that splits a list of command-line strings into
/// `CommandLineArgs`, supporting both option and non-option arguments.
///
/// ### Supported Syntax:
/// - `--key=value` → option `key` with value `value`
/// - `--flag` → option `flag` with no value (value is `null`)
/// - `foo.dart` → non-option argument
///
/// ### Example:
/// ```dart
/// final parser = SimpleCommandLineArgsParser();
/// final args = parser.parse(['--env=prod', '--verbose', 'main.dart']);
///
/// print(args.containsOption('env')); // true
/// print(args.getOptionValues('env')); // ['prod']
/// print(args.getOptionValues('verbose')); // []
/// print(args.getNonOptionArgs()); // ['main.dart']
/// ```
/// {@endtemplate}
class SimpleCommandLineArgsParser {
  /// {@template simple_command_line_args_parser_parse}
  /// Parses the raw [args] list into a structured [CommandLineArgs] object.
  ///
  /// - Option arguments must begin with `--`.
  /// - If an `=` is present, the left is treated as the key, the right as the value.
  /// - If no `=`, the key is stored with a `null` value.
  /// - All other arguments are treated as non-option arguments.
  /// {@endtemplate}
  CommandLineArgs parse(List<String> args) {
    final result = CommandLineArgs();

    for (final arg in args) {
      if (arg.startsWith('--')) {
        final eqIndex = arg.indexOf('=');
        if (eqIndex != -1) {
          final name = arg.substring(2, eqIndex);
          final value = arg.substring(eqIndex + 1);
          result.addOptionArg(name, value);
        } else {
          final name = arg.substring(2);
          result.addOptionArg(name, null);
        }
      } else {
        result.addNonOptionArg(arg);
      }
    }

    return result;
  }
}