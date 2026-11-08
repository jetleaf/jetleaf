import '../runtime_executor.dart';

/// {@template runtime_executor_resolving}
/// An abstract base class responsible for orchestrating the **runtime resolution**
/// of types, methods, and fields across multiple libraries.
///
/// `RuntimeExecutorResolving` provides a structured way to prepare a fully
/// configured [RuntimeExecutor] instance by combining multiple sources of
/// runtime information.
/// {@endtemplate}
abstract class RuntimeExecutorResolving {
  /// A list of libraries that should be included during resolution.
  final List<dynamic> libraries;

  /// Constructs a new `RuntimeExecutorResolving` instance.
  ///
  /// {@macro runtime_executor_resolving}
  RuntimeExecutorResolving({this.libraries = const []});

  /// Executes the complete runtime resolution process.
  Future<RuntimeExecutor> resolve();
}
