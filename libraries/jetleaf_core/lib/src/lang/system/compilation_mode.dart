/// {@template compilation_mode}
/// Dart supports multiple runtime modes, each optimized for different use cases:
///
/// - [debug]: Development mode with hot reload and assertions enabled
/// - [profile]: Performance analysis mode with minimal optimizations
/// - [release]: Production mode with full optimizations
///
/// Jetleaf uses this enum to determine runtime behavior and feature availability.
///
/// Example:
/// ```dart
/// if (SystemEnvironment.getCompilationMode() == CompilationMode.release) {
///   logger.info('Production mode enabled');
/// }
/// ```
/// {@endtemplate}
enum CompilationMode {
  /// {@macro compilation_mode}
  debug,

  /// {@macro compilation_mode}
  profile,

  /// {@macro compilation_mode}
  special,

  /// {@macro compilation_mode}
  release;

  /// Returns true if this is a development mode
  bool isDevelopment() => this == CompilationMode.debug;

  /// Returns true if this is a production mode
  bool isProduction() => this == CompilationMode.release || this == CompilationMode.special;

  @override
  String toString() => name;
}