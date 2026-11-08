import 'package:jetleaf_core/lang.dart';

/// {@template aot_runtime_executor}
/// An [RuntimeExecutor] implementation that leverages Ahead-of-Time (AOT) 
/// generative hints to perform instance creation, method invocation, and 
/// field access at runtime without relying on mirrors or dynamic reflection.
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
/// ```dart
/// // Register AOT constructor
/// AotRuntimeExecutor.registerNamedConstructor('UserService', ([args]) => UserService());
///
/// // Register AOT method
/// AotRuntimeExecutor.registerMethod('UserService.findUser', (inst, args) {
///   final id = args.getPositionalArguments()[0] as String;
///   return (inst as UserService).findUser(id);
/// });
///
/// // Execute
/// final user = AotRuntimeExecutor.constructByName('UserService');
/// final executor = AotRuntimeExecutor(DefaultRuntimeHintDescriptor());
/// final result = executor.invokeMethod(user, 'findUser', ExecutableArgument.unmodified(const {}, ['u123']));
/// ```
///
/// ## Use Cases
/// - Performing runtime operations in a fully AOT compiled Dart environment.
/// - Replacing mirror-based reflection with precomputed generative resolutions.
/// - Integrating with Jetleaf's hint system for deterministic and type-safe execution.
///
/// ## Field
/// - [descriptor]: The [RuntimeHintDescriptor] registry used to resolve hints
///   for all types that this executor may operate on.
/// {@endtemplate}
class AotRuntimeExecutor implements RuntimeExecutor {
  /// Named factory registry for AOT instantiation without mirrors.
  static final Map<String, Object Function([ExecutableArgument? argument])> _namedConstructors = {};

  /// Type-based factory registry for AOT instantiation without mirrors.
  static final Map<Type, Object Function([ExecutableArgument? argument])> _typeConstructors = {};

  /// Registers a runtime [Type] for a class name and optional qualified name.
  static void registerType(String name, Type type, [String? qualifiedName]) {
    StandardDeclaration.registerType(name, type, qualifiedName);
  }

  /// Registers a named constructor factory for AOT instantiation.
  static void registerNamedConstructor(String name, Object Function([ExecutableArgument? argument]) factory) {
    _namedConstructors[name] = factory;
  }

  /// Instantiates a registered named constructor by [name] with optional [argument].
  static Object? constructByName(String name, [ExecutableArgument? argument]) {
    final factory = _namedConstructors[name];
    if (factory != null) {
      try {
        return factory(argument);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  /// Registers a typed constructor factory for AOT instantiation.
  static void registerConstructor<T>(Object Function([ExecutableArgument? argument]) factory) {
    _typeConstructors[T] = factory;
  }

  /// Method registry for AOT method invocation without mirrors.
  static final Map<String, Object? Function(Object instance, ExecutableArgument argument)> _methodInvokers = {};

  /// Registers a method invoker for AOT execution.
  static void registerMethod(String methodKey, Object? Function(Object instance, ExecutableArgument argument) invoker) {
    _methodInvokers[methodKey] = invoker;
  }

  /// Field getter registry for AOT field access without mirrors.
  static final Map<String, Object? Function(Object instance)> _fieldGetters = {};

  /// Field setter registry for AOT field mutation without mirrors.
  static final Map<String, void Function(Object instance, Object? value)> _fieldSetters = {};

  /// Registers a field getter for AOT execution.
  static void registerFieldGetter(String fieldKey, Object? Function(Object instance) getter) {
    _fieldGetters[fieldKey] = getter;
  }

  /// Registers a field setter for AOT execution.
  static void registerFieldSetter(String fieldKey, void Function(Object instance, Object? value) setter) {
    _fieldSetters[fieldKey] = setter;
  }

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
      if (parentClassName != null && _namedConstructors.containsKey('$parentClassName.$name')) {
        return _namedConstructors['$parentClassName.$name']!(argument) as T;
      }
      if (parentQualifiedName != null && _namedConstructors.containsKey('$parentQualifiedName.$name')) {
        return _namedConstructors['$parentQualifiedName.$name']!(argument) as T;
      }
      if (_namedConstructors.containsKey(name)) {
        return _namedConstructors[name]!(argument) as T;
      }
    }

    if (parentClassName != null && _namedConstructors.containsKey(parentClassName)) {
      return _namedConstructors[parentClassName]!(argument) as T;
    }
    if (parentQualifiedName != null && _namedConstructors.containsKey(parentQualifiedName)) {
      return _namedConstructors[parentQualifiedName]!(argument) as T;
    }
    if (returnType != null && _typeConstructors.containsKey(returnType)) {
      return _typeConstructors[returnType]!(argument) as T;
    }
    if (T != dynamic && T != Object && _typeConstructors.containsKey(T)) {
      return _typeConstructors[T]!(argument) as T;
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
        final fullKey = '$candidate.$method';
        if (_methodInvokers.containsKey(fullKey)) {
          return _methodInvokers[fullKey]!(instance as Object, argument);
        }
      }
      if (_methodInvokers.containsKey(method)) {
        return _methodInvokers[method]!(instance as Object, argument);
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
    if (instance != null) {
      final rawClassName = instance.runtimeType.toString();
      final className = rawClassName.split('<').first;
      for (final candidate in _hierarchyNames(className)) {
        final fullKey = '$candidate.$name';
        if (_fieldGetters.containsKey(fullKey)) {
          return _fieldGetters[fullKey]!(instance as Object);
        }
        if (_methodInvokers.containsKey(fullKey)) {
          return _methodInvokers[fullKey]!(instance as Object, ExecutableArgument.unmodified(const {}, const []));
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
    if (instance != null) {
      final rawClassName = instance.runtimeType.toString();
      final className = rawClassName.split('<').first;
      for (final candidate in _hierarchyNames(className)) {
        final fullKey = '$candidate.$name';
        if (_fieldSetters.containsKey(fullKey)) {
          _fieldSetters[fullKey]!(instance as Object, value);
          return;
        }
        if (_methodInvokers.containsKey(fullKey)) {
          _methodInvokers[fullKey]!(instance as Object, ExecutableArgument.unmodified(const {}, [value]));
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