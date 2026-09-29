import 'package:jetleaf_lang/lang.dart';

import '../helpers/object.dart';

/// {@template argument_value_holder}
/// **Argument Value Holder**
///
/// Represents a structured container for arguments (both positional
/// and named) passed to constructors, methods, or functions within
/// the dependency injection / reflection framework.
///
/// # Purpose
/// - Provides a unified abstraction for storing arguments in different forms:
///   - [namedArgs] → explicitly named parameters.
///   - [positionalArgs] → standard ordered arguments.
///   - [arguments] → a normalized representation as [ArgumentValue] objects.
/// - Useful when invoking executables (constructors/methods) reflectively,
///   allowing consistent handling of parameter passing regardless of origin.
///
/// # Behavior
/// - Defaults to empty argument sets if none are provided.
/// - Immutable references to the provided maps/lists ensure predictable
///   argument evaluation.
/// - Can be extended to carry additional metadata (see [ExecutableHolder]).
///
/// # Example
/// ```dart
/// final args = ArgumentValueHolder(
///   namedArgs: {'timeout': 30},
///   positionalArgs: ['db_connection'],
///   arguments: [ArgumentValue.named('timeout', 30)],
/// );
///
/// print(args.namedArgs['timeout']);    // 30
/// print(args.positionalArgs.first);    // "db_connection"
/// print(args.arguments.first.name);    // "timeout"
/// ```
///
/// # Notes
/// - Serves as the base class for [ExecutableHolder].
/// - Primarily used internally when resolving or invoking pods.
/// {@endtemplate}
final class ArgumentValueHolder {
  /// Named arguments passed to the executable.
  final Map<String, Object?> namedArgs;

  /// Positional arguments passed to the executable.
  final List<Object?> positionalArgs;

  /// Normalized argument list, where each argument is wrapped in
  /// an [ArgumentValue] abstraction.
  final List<ArgumentValue> arguments;

  /// {@macro argument_value_holder}
  ArgumentValueHolder({
    this.namedArgs = const {},
    this.positionalArgs = const [],
    this.arguments = const [],
  });
}

/// {@template executable_holder}
/// **Executable Holder**
///
/// Extends [ArgumentValueHolder] with metadata about the
/// [Executable] being invoked.  
///
/// # Purpose
/// - Couples argument data with the specific executable
///   (constructor, method, or function) to be called.
/// - Allows reflection-based frameworks to:
///   - Inspect and validate executable signatures.
///   - Invoke the executable with properly structured arguments.
///   - Support DI wiring for constructors and annotated methods.
///
/// # Behavior
/// - Stores an [Executable] instance representing the reflective
///   target.
/// - Inherits argument storage ([namedArgs], [positionalArgs],
///   [arguments]) from [ArgumentValueHolder].
///
/// # Example
/// ```dart
/// final execHolder = ExecutableHolder(
///   executable: someConstructor,
///   positionalArgs: [42, "example"],
/// );
///
/// print(execHolder.executable.name);  // Constructor or method name
/// print(execHolder.positionalArgs);   // [42, "example"]
/// ```
///
/// # Notes
/// - Designed for internal framework use during pod instantiation.
/// - Works together with [DependencyObjectFactory] and reflection utilities.
/// {@endtemplate}
final class ExecutableHolder extends ArgumentValueHolder {
  /// The reflective executable (constructor, method, or function)
  /// associated with these arguments.
  final Executable executable;

  /// {@macro executable_holder}
  ExecutableHolder({
    required this.executable,
    super.namedArgs,
    super.positionalArgs,
    super.arguments,
  });
}