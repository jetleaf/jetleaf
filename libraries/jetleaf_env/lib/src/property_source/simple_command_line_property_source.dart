import '../core/command_line_args.dart';
import 'command_line_property_source.dart';
import 'property_source.dart';

/// {@template simple_command_line_property_source}
/// A [CommandLinePropertySource] that adapts [CommandLineArgs] into a resolvable
/// [PropertySource].
///
/// This class wraps a parsed list of command-line arguments and exposes them as
/// key-value properties, allowing flexible configuration using flags like:
///
/// - `--key=value`
/// - `--key value`
/// - multiple `--key=value` for lists
///
/// ### Behavior
/// - If a key is not present, the property will be `null`.
/// - If present without value (`--debug`), returns an empty list.
/// - If present with one value, returns that value as a string.
/// - If present multiple times, returns all values as a comma-separated string.
///
/// ### Example usage:
/// ```dart
/// final args = ['--env=prod', '--debug', '--features=a', '--features=b'];
/// final propertySource = SimpleCommandLinePropertySource(args);
///
/// print(propertySource.getProperty('env'));       // "prod"
/// print(propertySource.getProperty('debug'));     // ""
/// print(propertySource.getProperty('features'));  // "a,b"
/// print(propertySource.containsProperty('debug')); // true
/// ```
///
/// This class is often registered within the [MutablePropertySources] collection
/// and resolved through a [PropertyResolver] during app bootstrap.
/// {@endtemplate}
class SimpleCommandLinePropertySource extends CommandLinePropertySource<CommandLineArgs> {
  /// {@macro simple_command_line_property_source}
  SimpleCommandLinePropertySource(List<String> args) : super(SimpleCommandLineArgsParser().parse(args));

  /// {@template simple_command_line_property_source_named}
  /// Creates a [SimpleCommandLinePropertySource] with a custom name.
  ///
  /// Useful when managing multiple argument sources, e.g., merging CLI args
  /// with environment or test inputs under separate namespaces.
  ///
  /// Example:
  /// ```dart
  /// final source = SimpleCommandLinePropertySource.named('cli', ['--port=8080']);
  /// print(source.name); // 'cli'
  /// ```
  /// {@endtemplate}
  SimpleCommandLinePropertySource.named(String name, List<String> args) : super.named(name, SimpleCommandLineArgsParser().parse(args));

  @override
  bool containsProperty(String name) => getSource().containsOption(name);

  @override
  List<String> getPropertyNames() => getSource().getOptionNames().toList();

  @override
  bool containsOption(String name) => getSource().containsOption(name);

  @override
  List<String>? getOptionValues(String name) => getSource().getOptionValues(name);

  @override
  List<String> getNonOptionArgs() => getSource().getNonOptionArgs();
}