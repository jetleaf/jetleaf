import '../aot/aot_runtime_executor.dart';
import '../../hint/default_runtime_hint_descriptor.dart';
import '../../hint/runtime_hint_descriptor.dart';
import '../runtime_executor.dart';

/// {@template jit_runtime_executor}
/// Pure Dart runtime executor for JIT and AOT environments.
///
/// In Jetleaf v2, all execution is unified under Ahead-of-Time and hint-driven
/// invocation with zero reliance on `dart:mirrors`.
/// {@endtemplate}
class JitRuntimeExecutor extends AotRuntimeExecutor implements RuntimeExecutor {
  /// {@macro jit_runtime_executor}
  JitRuntimeExecutor([RuntimeHintDescriptor? descriptor])
      : super(descriptor ?? DefaultRuntimeHintDescriptor());
}