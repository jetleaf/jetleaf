import 'package:jetleaf_lang/lang.dart';

import 'environment.dart';

/// A mixin that provides access to a globally attached [Environment].
///
/// This is typically used by configuration classes that need to
/// resolve properties without explicitly passing around the
/// [Environment] instance.
///
/// The environment must first be attached with [attach] before
/// attempting to access it through the [environment] getter.
///
/// Example:
/// ```dart
/// void main() {
///   final env = Environment();
///   ConfigurationPropertySource.attach(env);
///
///   final config = MyConfig(); // uses ConfigurationPropertySource
///   print(config.environment.getProperty("app.name"));
/// }
/// ```
///
/// ⚠️ If [environment] is accessed before calling [attach], an error
/// will be thrown.
mixin ConfigurationPropertySource {
  /// The globally attached [Environment].
  static Environment? _environment;

  /// Attaches a global [Environment] instance to this property source.
  ///
  /// Must be called before accessing [environment].
  static void attach(Environment environment) {
    _environment = environment;
  }

  /// Returns the globally attached [Environment].
  ///
  /// Throws a [IllegalStateException] if no environment has been attached via [attach].
  Environment get environment {
    if (_environment == null) {
      throw IllegalStateException(
        "No Environment has been attached. "
        "Call ConfigurationPropertySource.attach(env) first.",
      );
    }
    return _environment!;
  }
}