import 'package:meta/meta.dart';

import '../../hint/default_runtime_hint_descriptor.dart';
import '../../hint/runtime_hint_descriptor.dart';
import 'runtime_executor_resolving.dart';

/// An abstract base class that provides the core logic for discovering,
/// instantiating, and managing runtime hints and descriptors used by
/// Jetleaf's runtime executors.
abstract class AbstractRuntimeExecutorResolving extends RuntimeExecutorResolving {
  /// Constructs an instance of [AbstractRuntimeExecutorResolving].
  AbstractRuntimeExecutorResolving({super.libraries = const []});

  /// Finds and instantiates any configured [RuntimeHintDescriptor].
  @protected
  Future<RuntimeHintDescriptor> getRuntimeHintDescriptor(List<dynamic> libraries) async {
    return DefaultRuntimeHintDescriptor();
  }
}
