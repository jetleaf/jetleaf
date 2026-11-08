part of 'class_path_resource.dart';

/// {@template default_classpath_resource}
/// Default implementation of [ClassPathResource] that resolves and
/// provides access to classes, methods, fields, and packages from the
/// Dart runtime.
///
/// This class uses the [Runtime] utilities to inspect available
/// declarations and the package URI to scope lookups to a specific
/// package or library. It also supports reading source code as an
/// [InputStream].
///
/// ### Example
/// ```dart
/// void main() {
///   final resource = DefaultClassPathResource('package:my_app/src/user.dart');
///
///   // Get package metadata
///   final pkg = resource.getPackage();
///   print('Package name: ${pkg.name}');
///
///   // Get all classes
///   final classes = resource.getClasses();
///   for (final c in classes) {
///     print('Class: ${c.getSimpleName()}');
///   }
///
///   // Lookup a specific class
///   final userClass = resource.getClass('User');
///   print('Found class: ${userClass.getSimpleName()}');
///
///   // Access top-level methods
///   final methods = resource.getMethods();
///   for (final m in methods) {
///     print('Method: ${m.getName()}');
///   }
///
///   // Stream source file as bytes
///   final inputStream = resource.getInputStream();
///   inputStream.stream.listen((chunk) {
///     print('Read ${chunk.length} bytes');
///   });
/// }
/// ```
///
/// {@endtemplate}
@internal
final class DefaultClassPathResource implements ClassPathResource {
  /// {@template classpath_package_uri}
  /// The package URI associated with this resource.
  ///
  /// Example: `"package:my_app/src/models/user.dart"`
  ///
  /// This is typically used internally to locate and resolve the
  /// corresponding classes, fields, or methods within the package.
  /// {@endtemplate}
  @protected
  final String packageUri;

  Iterable<ClassDeclaration> _classes = [];

  /// {@macro default_classpath_resource}
  DefaultClassPathResource(this.packageUri) {
    _classes = Runtime.getAllClassesInAPackageUri(packageUri);
  }

  Exception _throwIfNotFound([String? name]) => IllegalStateException("${name ?? 'Class'} for $packageUri not found");

  @override
  Class findClass<T>() {
    final declaration = Runtime.findClass<T>();
    return Class<T>.declared(declaration, ProtectionDomain.system());
  }

  @override
  Class getClassOfType(Type type) {
    final declaration = Runtime.findClassByType(type);
    return Class.declared(declaration, ProtectionDomain.system());
  }

  @override
  List<Class> getClasses() => _classes.map((d) => Class.declared(d, ProtectionDomain.system())).toList();

  @override
  InputStream getInputStream() {
    if(Runtime.getSourceLibrary(packageUri) case final source?) {
      return StringInputStream(source.sourceCode());
    }

    return StringInputStream("No content");
  }

  @override
  Method getMethod([String? methodName]) {
    var declaration = _classes.flatMap((c) => c.getMethods()).find((d) => d.getName() == methodName);
    if(declaration == null) {
      throw _throwIfNotFound(methodName);
    }
    
    return Method.declared(declaration, ProtectionDomain.system());
  }

  @override
  List<Method> getMethods() => _classes.flatMap((c) => c.getMethods()).map((d) => Method.declared(d, ProtectionDomain.system())).toList();

  @override
  Package getPackage() {
    if(Runtime.getSourceLibrary(packageUri) case final source?) {
      return source.getPackage();
    }
    
    throw _throwIfNotFound();
  }
}