import 'package:jetleaf_build/jetleaf_build.dart';
import 'package:meta/meta.dart';

import '../../../exceptions.dart';
import '../../../extensions/primitives/iterable.dart';
import '../../../io/input_stream/input_stream.dart';
import '../../../io/input_stream/input_stream_source.dart';
import '../../../io/input_stream/string_input_stream.dart';
import '../../class/class.dart';
import '../../method/method.dart';
import '../../protection_domain/protection_domain.dart';

part 'default_class_path_resource.dart';

/// {@template classpath_resource}
/// Provides access to resources, classes, methods, and fields located
/// in a package's classpath.
///
/// A [ClassPathResource] abstracts the ability to query package-level
/// declarations such as classes, methods, and fields. This provides a better
/// api for developers who wants to explore the classpath of a package.
///
/// ### Example
/// ```dart
/// void main() {
///   final resource = MyClassPathResource('package:my_app/src/models/user.dart');
///
///   // Get package metadata
///   final pkg = resource.getPackage();
///   print('Package: ${pkg.name}');
///
///   // Lookup a specific class
///   final userClass = resource.getClass(User);
///
///   // List all classes in the package
///   final classes = resource.getClasses();
///   print('Classes: ${classes.map((c) => c.name).toList()}');
///
///   // Retrieve top-level methods
///   final methods = resource.getMethods();
///   print('Methods: ${methods.map((m) => m.name).toList()}');
/// }
/// ```
///
/// This class is abstract and must be implemented by subclasses
/// that define how to load and resolve package resources.
/// {@endtemplate}
abstract final class ClassPathResource implements InputStreamSource {
  /// {@macro classpath_resource}
  factory ClassPathResource(String packageUri) = DefaultClassPathResource;

  /// {@template classpath_get_package}
  /// Retrieves metadata about the package.
  ///
  /// This includes information such as the package name, version,
  /// and available resources.
  ///
  /// ### Example
  /// ```dart
  /// final pkg = resource.getPackage();
  /// print('Loaded package: ${pkg.name}');
  /// ```
  /// {@endtemplate}
  Package getPackage();

  /// {@template classpath_get_class}
  /// Retrieves a class by its name from the package.
  ///
  /// - If [type] is provided, it returns the matching class.  
  /// - If omitted or `null`, returns a default or primary class.  
  ///
  /// ### Example
  /// ```dart
  /// final userClass = resource.getClass(User);
  /// print('Found class: ${userClass.name}');
  /// ```
  /// {@endtemplate}
  Class getClassOfType(Type type);

  /// {@template classpath_get_class}
  /// Retrieves a class by its name from the package.
  ///
  /// - If [type] is provided, it returns the matching class.  
  /// - If omitted or `null`, returns a default or primary class.  
  ///
  /// ### Example
  /// ```dart
  /// final userClass = resource.getClass<User>();
  /// print('Found class: ${userClass.name}');
  /// ```
  /// {@endtemplate}
  Class findClass<T>();

  /// {@template classpath_get_classes}
  /// Returns all classes defined in the package.
  ///
  /// ### Example
  /// ```dart
  /// final classes = resource.getClasses();
  /// for (var c in classes) {
  ///   print('Class: ${c.name}');
  /// }
  /// ```
  /// {@endtemplate}
  List<Class> getClasses();

  /// {@template classpath_get_method}
  /// Retrieves a top-level method by its name.
  ///
  /// - If [methodName] is provided, it returns the matching method.  
  /// - If omitted or `null`, it may return a default method depending
  ///   on the implementation.  
  ///
  /// ### Example
  /// ```dart
  /// final mainMethod = resource.getMethod('main');
  /// print('Method: ${mainMethod.name}');
  /// ```
  /// {@endtemplate}
  Method getMethod([String? methodName]);

  /// {@template classpath_get_methods}
  /// Returns all top-level methods defined in the package.
  ///
  /// ### Example
  /// ```dart
  /// final methods = resource.getMethods();
  /// methods.forEach((m) => print('Method: ${m.name}'));
  /// ```
  /// {@endtemplate}
  List<Method> getMethods();
}