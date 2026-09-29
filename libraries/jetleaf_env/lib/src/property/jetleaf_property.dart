import 'package:jetleaf_lang/lang.dart';

/// {@template jetleaf_property}
/// Base class for all Jetleaf framework configuration properties.
///
/// A [JetleafProperty] defines a typed configuration entry used within
/// Jetleaf and related Jetleaf-based frameworks. Each property has:
///
/// - A unique [key] used for lookup in the environment.
/// - An optional [value] when the property is not set.
/// - An optional [description] to document its purpose.
///
/// Properties are strongly typed using generics. For example:
///
/// ```dart
/// const JetleafProperty serverPort = JetleafProperty("server.port", 8080, "The TCP port the server will bind to.");
/// ```
///
/// Jetleaf also supports user-defined properties via
/// [JetleafProperty.custom].
/// {@endtemplate}
abstract class JetleafProperty with EqualsAndHashCode {
  /// The unique key used to look up this property in the environment.
  final String key;

  /// The default value of this property if no explicit value is provided.
  final Object value;

  /// A human-readable description of the property.
  final String? description;

  /// {@macro jetleaf_property}
  const JetleafProperty(this.key, this.value, [this.description]);

  /// Creates a user-defined custom property.
  ///
  /// Example:
  /// ```dart
  /// final JetleafProperty myProp = JetleafProperty.custom("custom.prop", "hello");
  /// ```
  static JetleafProperty custom(String key, Object value, [String? description]) => _JetleafProperty(key, value, description);

  /// Creates a copy of this property with the specified properties changed.
  /// 
  /// {@macro jetleaf_property}
  JetleafProperty copyWith({String? key, Object? value, String? description}) => _JetleafProperty(key ?? this.key, value ?? this.value, description ?? this.description);

  @override
  String toString() => '$runtimeType(key: $key, value: $value, description: $description)';

  @override
  List<Object?> equalizedProperties() => [key, value, description];
}

/// Internal private subclass used for [JetleafProperty.custom].
///
/// This allows end users to define properties dynamically
/// without needing to subclass [JetleafProperty].
class _JetleafProperty extends JetleafProperty {
  /// Creates a new custom property instance.
  const _JetleafProperty(super.key, super.value, [super.description]);
}