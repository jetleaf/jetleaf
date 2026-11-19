import 'package:jetleaf_core/lang.dart';

/// {@template aot_runtime_executor}
/// An [RuntimeExecutor] implementation that leverages Ahead-of-Time (AOT) 
/// generative hints to perform instance creation, method invocation, and 
/// field access at runtime without relying on runtime reflection.
///
/// ## Purpose
/// The [AotRuntimeExecutor] is designed for environments where:
/// - Generative hints for constructors, methods, and fields are precomputed.
/// - Deterministic execution is required (e.g., for production AOT builds).
/// - Performance and type safety are critical, and runtime reflection overhead must be minimized.
///
/// ## How It Works
/// This executor queries a [RuntimeHintDescriptor] for type-specific [RuntimeHint]s. 
/// Each hint knows how to construct instances, invoke methods, and access fields 
/// for its associated type. The executor delegates all operations to these hints 
/// and enforces strict execution semantics:
/// - If a hint successfully executes an operation, the result is returned.
/// - If no suitable hint is found, a type-specific exception is thrown 
///   ([ConstructorNotFoundException], [MethodNotFoundException], [FieldAccessException], 
///   or [FieldMutationException]).
///
/// ## Example
/// Generated registries register every closure they emit against [MaterializedLibrary]
/// (`registerNamedConstructor`, `registerMethod`, `registerFieldGetter`, ...).
/// The executor then resolves through that registry:
/// ```dart
/// final executor = AotRuntimeExecutor(DefaultRuntimeHintDescriptor());
/// final user = MaterializedLibrary.constructByName('UserService');
/// final result = executor.invokeMethod(user, 'findUser', ExecutableArgument.unmodified(const {}, ['u123']));
/// ```
///
/// ## Use Cases
/// - Performing runtime operations in a fully AOT compiled Dart environment.
/// - Replacing reflection-based reflection with precomputed generative resolutions.
/// - Integrating with Jetleaf's hint system for deterministic and type-safe execution.
///
/// ## Field
/// - [descriptor]: The [RuntimeHintDescriptor] registry used to resolve hints
///   for all types that this executor may operate on.
/// {@endtemplate}
class AotRuntimeExecutor implements RuntimeExecutor {
  /// The registry used to resolve and execute generative descriptors.
  ///
  /// This descriptor maintains a mapping of types to [RuntimeHint]
  /// instances and is queried whenever an instance, method, or field
  /// operation is invoked via this executor.
  final RuntimeHintDescriptor descriptor;

  /// {@macro aot_runtime_executor}
  const AotRuntimeExecutor(this.descriptor);

  @override
  T newInstance<T>(String name, ExecutableArgument argument, ConstructorDeclaration constructor, [Type? returnType]) {
    final parentClassName = constructor.getParentClass()?.getName();
    final parentQualifiedName = constructor.getParentClass()?.getPointerQualifiedName();

    if (name.isNotEmpty) {
      final forParent = MaterializedLibrary.lookupNamedConstructor('$parentClassName.$name') ??
          (parentQualifiedName != null ? MaterializedLibrary.lookupNamedConstructor('$parentQualifiedName.$name') : null);
      if (forParent != null) {
        return forParent(argument) as T;
      }
      final direct = MaterializedLibrary.lookupNamedConstructor(name);
      if (direct != null) {
        return direct(argument) as T;
      }
    }

    final byParent = MaterializedLibrary.lookupNamedConstructor(parentClassName ?? '') ??
        (parentQualifiedName != null ? MaterializedLibrary.lookupNamedConstructor(parentQualifiedName) : null);
    if (byParent != null) {
      return byParent(argument) as T;
    }
    if (returnType != null) {
      final byReturnType = MaterializedLibrary.lookupTypeConstructor(returnType);
      if (byReturnType != null) {
        return byReturnType(argument) as T;
      }
    }
    if (T != dynamic && T != Object) {
      final typed = MaterializedLibrary.lookupTypeConstructor(T);
      if (typed != null) {
        return typed(argument) as T;
      }
    }

    final hint = descriptor.getHint<T>(type: returnType ?? T);
    final targetType = (returnType != null && returnType != Object) 
      ? returnType 
      : (T != dynamic && T != Object ? T : (constructor.getParentClass()?.getName() ?? 'Unknown'));
    final type = hint?.obtainTypeOfRuntimeHint() ?? targetType;
    
    if (hint case final hint?) {
      final result = hint.createNewInstance<T>(name, argument);
      if (result.getIsExecuted()) {
        if (result.getResult() case final object?) {
          return object as T;
        } else {
          throw UnsupportedRuntimeOperationException(hint.obtainTypeOfRuntimeHint(), "Constructor creation cannot be null");
        }
      }
    }
    
    throw ConstructorNotFoundException(type, name);
  }

  static Iterable<String> _hierarchyNames(String className) sync* {
    yield className;
    final clean = className.replaceFirst(RegExp(r'^_+'), '');
    if (clean != className) yield clean;
    final visited = <String>{className};
    final queue = <String>[className];
    while (queue.isNotEmpty) {
      final curr = queue.removeAt(0);
      ClassDeclaration? decl;
      try {
        decl = Runtime.findClassByName(curr);
      } catch (_) {
        decl = null;
      }
      if (decl == null) continue;
      if (decl.getSuperClass() case final sup?) {
        final sName = sup.getName();
        if (visited.add(sName)) {
          yield sName;
          queue.add(sName);
        }
      }
      for (final m in decl.getMixins()) {
        final mName = m.getName();
        if (visited.add(mName)) {
          yield mName;
          queue.add(mName);
        }
      }
      for (final iface in decl.getInterfaces()) {
        final iName = iface.getName();
        if (visited.add(iName)) {
          yield iName;
          queue.add(iName);
        }
      }
    }
  }

  @override
  Object? invokeMethod<T>(T instance, String method, ExecutableArgument argument) {
    if (instance != null) {
      final rawClassName = instance.runtimeType.toString();
      final className = rawClassName.split('<').first;
      for (final candidate in _hierarchyNames(className)) {
        final invoker = MaterializedLibrary.lookupMethodInvoker('$candidate.$method');
        if (invoker != null) {
          return invoker(instance as Object, argument);
        }
      }
      final direct = MaterializedLibrary.lookupMethodInvoker(method);
      if (direct != null) {
        return direct(instance as Object, argument);
      }
    }

    final hint = descriptor.getHint<T>(type: T, instance: instance);
    final type = hint?.obtainTypeOfRuntimeHint() ?? T;
    
    if (hint case final hint?) {
      final result = hint.invokeMethod<T>(instance, method, argument);
      if (result.getIsExecuted()) {
        return result.getResult();
      }
    }
    
    throw MethodNotFoundException(type, method);
  }

  @override
  Object? getValue<T>(T instance, String name) {
    // Class-qualified key (e.g. 'DataClass.property') — static accessor registered by the AOT registry.
    if (name.contains('.')) {
      final getter = MaterializedLibrary.lookupFieldGetter(name);
      if (getter != null) {
        return getter(null as dynamic);
      }
      final invoker = MaterializedLibrary.lookupMethodInvoker(name);
      if (invoker != null) {
        return invoker(null as dynamic, ExecutableArgument.unmodified(const {}, const []));
      }
    }

    if (instance != null) {
      final rawClassName = instance.runtimeType.toString();
      final className = rawClassName.split('<').first;
      for (final candidate in _hierarchyNames(className)) {
        final fullKey = '$candidate.$name';
        final getter = MaterializedLibrary.lookupFieldGetter(fullKey);
        if (getter != null) {
          return getter(instance as Object);
        }
        final invoker = MaterializedLibrary.lookupMethodInvoker(fullKey);
        if (invoker != null) {
          return invoker(instance as Object, ExecutableArgument.unmodified(const {}, const []));
        }
      }
    }

    final hint = descriptor.getHint<T>(type: T, instance: instance);
    final type = hint?.obtainTypeOfRuntimeHint() ?? T;
    
    if (hint case final hint?) {
      final result = hint.getFieldValue<T>(instance, name);
      if (result.getIsExecuted()) {
        return result.getResult();
      }
    }
    
    throw FieldAccessException(type, name);
  }

  @override
  void setValue<T>(T instance, String name, Object? value) {
    // Class-qualified key (e.g. 'DataClass.property') — static accessor registered by the AOT registry.
    if (name.contains('.')) {
      final setter = MaterializedLibrary.lookupFieldSetter(name);
      if (setter != null) {
        setter(null as dynamic, value);
        return;
      }
      final invoker = MaterializedLibrary.lookupMethodInvoker(name);
      if (invoker != null) {
        invoker(null as dynamic, ExecutableArgument.unmodified(const {}, [value]));
        return;
      }
    }

    if (instance != null) {
      final rawClassName = instance.runtimeType.toString();
      final className = rawClassName.split('<').first;
      for (final candidate in _hierarchyNames(className)) {
        final fullKey = '$candidate.$name';
        final setter = MaterializedLibrary.lookupFieldSetter(fullKey);
        if (setter != null) {
          setter(instance as Object, value);
          return;
        }
        final invoker = MaterializedLibrary.lookupMethodInvoker(fullKey);
        if (invoker != null) {
          invoker(instance as Object, ExecutableArgument.unmodified(const {}, [value]));
          return;
        }
      }
    }

    final hint = descriptor.getHint<T>(type: T, instance: instance);
    final type = hint?.obtainTypeOfRuntimeHint() ?? T;
    
    if (hint case final hint?) {
      final result = hint.setFieldValue<T>(instance, name, value);
      if (result.getIsExecuted()) {
        return;
      }
    }
    
    throw FieldMutationException(type, name);
  }
}
