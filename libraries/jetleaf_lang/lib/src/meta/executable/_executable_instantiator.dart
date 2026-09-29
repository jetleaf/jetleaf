part of 'executable_instantiator.dart';

/// {@template _executable_instantiator}
/// Internal implementation of [ExecutableInstantiator], providing the actual
/// logic for dynamically instantiating classes and invoking methods at runtime
/// using reflection-like capabilities.
///
/// This class works closely with:
/// - [_selector] ([ExecutableSelector]) to pick the most appropriate constructor
///   or method among multiple options.
/// - [_resolver] ([ExecutableArgumentResolver]) to automatically supply values
///   for positional and named parameters based on type bindings or predicates.
///
/// ---
/// ## Responsibilities
/// 1. Dynamically instantiate objects of [_class] with optional argument resolution.
/// 2. Dynamically invoke instance methods with automatic parameter resolution.
/// 3. Support fluent API for configuring custom selectors and argument resolvers.
/// 4. Prioritize no-argument constructors when requested.
///
/// ---
/// ## Example
/// ```dart
/// final instantiator = _ExecutableInstantiator(Class.forType(MyClass))
///   .withSelector(ExecutableSelector().and(Class<ApplicationContext>()))
///   .withArgumentResolver(ExecutableArgumentResolver().and(Class<ApplicationContext>(), context));
///
/// final instance = instantiator.newInstance<MyClass>();
/// final result = instantiator.invoke<String>(instance, "doWork");
/// ```
/// {@endtemplate}
final class _ExecutableInstantiator implements ExecutableInstantiator {
  /// The class that will be instantiated or whose methods will be invoked.
  final Class _class;

  /// Selector used to pick the best matching constructor or method.
  ExecutableSelector _selector = ExecutableSelector();

  /// Resolver used to supply argument values for constructors and methods.
  ExecutableArgumentResolver _resolver = ExecutableArgumentResolver();

  /// {@macro _executable_instantiator}
  _ExecutableInstantiator(this._class);

  @override
  Executed? invoke<Executed>(Object? instance, String methodName) {
    final method = _class.getMethod(methodName);
    if (method != null) {
      final args = _resolver.resolve(method);
      return method.invoke(instance, args.getNamedArguments(), args.getPositionalArguments());
    }

    return null;
  }

  @override
  Executed? newInstance<Executed>({bool checkNoArgFirst = true, bool tryDefault = false}) {
    Constructor? constructor;

    if (checkNoArgFirst) {
      // Try to get a no-arg constructor first
      constructor = _class.getNoArgConstructor();
    }

    // If no no-arg constructor or checkNoArgFirst is false, use selector
    constructor ??= _selector.select(_class.getConstructors());

    // If no constructor is selected, use default constructor
    if (tryDefault && constructor == null) {
      constructor ??= _class.getDefaultConstructor();
    }

    if (constructor != null) {
      final args = _resolver.resolve(constructor);
      return constructor.newInstance<Executed>(args.getNamedArguments(), args.getPositionalArguments());
    }

    return null;
  }

  @override
  ExecutableInstantiator withArgumentResolver(ExecutableArgumentResolver resolver) {
    _resolver = resolver;
    return this;
  }

  @override
  ExecutableInstantiator withSelector(ExecutableSelector selector) {
    _selector = selector;
    return this;
  }
}