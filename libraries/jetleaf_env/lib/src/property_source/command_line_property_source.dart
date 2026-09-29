import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_utils/utils.dart';
import 'package:meta/meta.dart';

import 'listable_property_source.dart';

/// {@template command_line_property_source}
/// A base class for property sources that are backed by command line arguments.
///
/// This class is capable of handling both option arguments (e.g., `--port=8080`)
/// and non-option arguments (e.g., positional values like `input.txt`).
///
/// It supports retrieving these arguments as properties through the familiar
/// [getProperty] interface and allows customization of the key used to
/// access non-option arguments.
///
/// Commonly extended by concrete sources such as argument parsers.
///
/// Example:
/// ```dart
/// class SimpleCommandLinePropertySource extends CommandLinePropertySource<MyArgsParser> {
///   SimpleCommandLinePropertySource(MyArgsParser parser) : super(parser);
///
///   @override
///   bool containsOption(String name) => source.hasOption(name);
///
///   @override
///   List<String>? getOptionValues(String name) => source.getOptionValues(name);
///
///   @override
///   List<String> getNonOptionArgs() => source.getNonOptionArgs();
/// }
///
/// final source = SimpleCommandLinePropertySource(parser);
/// print(source.getProperty('host')); // "localhost"
/// print(source.getProperty('nonOptionArgs')); // "input.txt,config.json"
/// ```
/// {@endtemplate}
@Generic(CommandLinePropertySource)
abstract class CommandLinePropertySource<T> extends ListablePropertySource<T> {
  /// {@macro command_line_property_source}
  CommandLinePropertySource(T source) : super(CommandLinePropertySource.COMMAND_LINE_PROPERTY_SOURCE_NAME, source);

  /// {@template command_line_property_source_named}
  /// Creates a [CommandLinePropertySource] with a custom name.
  ///
  /// This can be useful if you are managing multiple sources of arguments.
  ///
  /// Example:
  /// ```dart
  /// CommandLinePropertySource.named('myArgs', parser);
  /// ```
  /// {@endtemplate}
  CommandLinePropertySource.named(super.name, super.source);

  /// {@template command_line_property_source_name}
  /// The default name used to register this property source in the environment.
  ///
  /// Default value is `'commandLineArgs'`.
  /// {@endtemplate}
  static const String COMMAND_LINE_PROPERTY_SOURCE_NAME = 'commandLineArgs';

  /// {@template command_line_property_source_name}
  /// The default name used to register this property source in the environment.
  ///
  /// Default value is `'jlaCommandLineArgs'`.
  /// {@endtemplate}
  static const String JETLEAF_COMMAND_LINE_PROPERTY_SOURCE_NAME = "jlaCommandLineArgs";

  /// {@template command_line_property_source_non_option_key}
  /// The default key used to access non-option arguments from [getProperty].
  ///
  /// The value of this key is a comma-delimited string of all non-option args.
  /// Default value is `'nonOptionArgs'`.
  /// {@endtemplate}
  static const String DEFAULT_NON_OPTION_ARGS_PROPERTY_NAME = 'nonOptionArgs';

  /// {@template command_line_property_source_non_option_property}
  /// The current key used to access non-option arguments.
  ///
  /// You can customize this using [setNonOptionArgsPropertyName].
  /// {@endtemplate}
  String _nonOptionArgsPropertyName = DEFAULT_NON_OPTION_ARGS_PROPERTY_NAME;

  /// {@template command_line_property_source_set_non_option_key}
  /// Allows setting a custom property name for non-option arguments.
  ///
  /// Example:
  /// ```dart
  /// source.setNonOptionArgsPropertyName('positionalArgs');
  /// ```
  /// {@endtemplate}
  void setNonOptionArgsPropertyName(String name) {
    _nonOptionArgsPropertyName = name;
  }

  @override
  bool containsProperty(String name) {
    if (_nonOptionArgsPropertyName == name) {
      return getNonOptionArgs().isNotEmpty;
    }
    return containsOption(name);
  }

  @override
  String? getProperty(String name) {
    if (_nonOptionArgsPropertyName == name) {
      final args = getNonOptionArgs();
      return args.isEmpty ? null : StringUtils.collectionToCommaDelimitedString(args);
    }

    final optionValues = getOptionValues(name);
    return optionValues == null ? null : StringUtils.collectionToCommaDelimitedString(optionValues);
  }

  /// {@template command_line_property_source_contains_option}
  /// Returns whether the set of parsed options includes the given name.
  ///
  /// Implementations must define how option presence is detected.
  ///
  /// Example:
  /// ```dart
  /// if (containsOption('debug')) {
  ///   print('Debug mode enabled.');
  /// }
  /// ```
  /// {@endtemplate}
  @protected
  bool containsOption(String name);

  /// {@template command_line_property_source_get_option_values}
  /// Returns the values for a given option name.
  ///
  /// Behavior:
  /// - `--flag` returns `[]`
  /// - `--key=value` returns `["value"]`
  /// - multiple occurrences (`--key=1 --key=2`) return `["1", "2"]`
  /// - if the key is missing, returns `null`
  ///
  /// Example:
  /// ```dart
  /// final values = getOptionValues('files');
  /// if (values != null) {
  ///   print(values.join(', '));
  /// }
  /// ```
  /// {@endtemplate}
  @protected
  List<String>? getOptionValues(String name);

  /// {@template command_line_property_source_get_non_option_args}
  /// Returns the list of arguments that are not in `--key=value` format.
  ///
  /// These are typically positional or unnamed arguments.
  ///
  /// Example:
  /// ```dart
  /// final extras = getNonOptionArgs();
  /// print(extras); // ['input.txt', 'output.log']
  /// ```
  /// {@endtemplate}
  @protected
  List<String> getNonOptionArgs();
}