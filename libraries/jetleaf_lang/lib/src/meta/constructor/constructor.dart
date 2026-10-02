import 'package:jetleaf_build/jetleaf_build.dart';

import '../../commons/version.dart';
import '../../exceptions.dart';
import '../../utils/lang_utils.dart';
import '../../utils/method_utils.dart';
import '../annotation/annotation.dart';
import '../class/class.dart';
import '../core.dart';
import '../parameter/parameter.dart';
import '../protection_domain/protection_domain.dart';

part '_constructor.dart';

/// {@template constructor_interface}
/// Provides reflective access to class constructor metadata and instantiation.
///
/// This interface enables runtime inspection and invocation of class constructors,
/// including access to:
/// - Constructor parameters
/// - Factory constructor detection
/// - Instance creation
/// - Declaring class information
///
/// {@template constructor_interface_features}
/// ## Key Features
/// - Named and unnamed constructor support
/// - Parameter inspection
/// - Type-safe instance creation
/// - Factory constructor handling
///
/// ## Implementation Notes
/// Concrete implementations typically wrap platform-specific reflection objects
/// while providing this uniform interface.
/// {@endtemplate}
///
/// {@template constructor_interface_example}
/// ## Example Usage
/// ```dart
/// // Get constructor metadata
/// final namedConstructor = userClass.getConstructor('fromJson');
///
/// // Inspect parameters
/// if (namedConstructor.getParameterCount() > 0) {
///   final firstParam = namedConstructor.getParameterAt(0);
///   print('First parameter: ${firstParam.getName()}');
/// }
///
/// // Create instances
/// final user = namedConstructor.newInstance({'json': userData});
/// ```
/// {@endtemplate}
/// {@endtemplate}
abstract final class Constructor extends Executable implements Member {
  /// Checks if this is a factory constructor.
  ///
  /// {@template constructor_is_factory}
  /// Returns:
  /// - `true` if declared with `factory` keyword
  /// - `false` for generative constructors
  ///
  /// Note:
  /// Factory constructors may return instances of subtypes.
  /// {@endtemplate}
  bool isFactory();

  @override
  ConstructorDeclaration getDeclaration();
  
  /// Creates a new instance using named arguments.
  ///
  /// {@template constructor_new_instance}
  /// Parameters:
  /// - [arguments]: Optional named arguments matching constructor parameters
  ///
  /// Returns:
  /// - A new instance of the declaring class
  ///
  /// Throws:
  /// - [InvalidArgumentException] if arguments don't match parameters
  /// - [UnsupportedOperationException] for abstract classes
  ///
  /// Example:
  /// ```dart
  /// final instance = constructor.newInstance({'name': 'Alice', 'age': 30});
  /// 
  /// final instance = constructor.newInstance(null, ['Alice', 30]);
  /// ```
  /// {@endtemplate}
  Instance newInstance<Instance>([Map<String, dynamic>? arguments, List<dynamic> args = const []]);
  
  /// Creates a Constructor instance from reflection metadata.
  ///
  /// {@template constructor_factory}
  /// Parameters:
  /// - [declaration]: The constructor reflection metadata
  /// - [domain]: The protection domain for security
  ///
  /// Returns:
  /// - A concrete [Constructor] implementation
  ///
  /// Typical implementation:
  /// ```dart
  /// static Constructor declared(ConstructorDeclaration d, ProtectionDomain p) {
  ///   return _ConstructorImpl(d, p);
  /// }
  /// ```
  /// {@endtemplate}
  factory Constructor.declared(ConstructorDeclaration declaration, ProtectionDomain domain) = _Constructor;
}