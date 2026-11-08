import 'abstract_runtime_executor_resolving.dart';
import '../aot/aot_runtime_executor.dart';
import '../default_runtime_executor.dart';
import '../jit/jit_runtime_executor.dart';
import '../runtime_executor.dart';

/// {@template default_runtime_executor_resolving}
/// A concrete implementation of [AbstractRuntimeExecutorResolving] that
/// resolves a fully configured [RuntimeExecutor].
/// {@endtemplate}
final class DefaultRuntimeExecutorResolving extends AbstractRuntimeExecutorResolving {
  /// {@macro default_runtime_executor_resolving}
  DefaultRuntimeExecutorResolving({super.libraries = const []});

  @override
  Future<RuntimeExecutor> resolve() async {
    final descriptor = await getRuntimeHintDescriptor(libraries);
    return DefaultRuntimeExecutor(AotRuntimeExecutor(descriptor), JitRuntimeExecutor(descriptor));
  }
}