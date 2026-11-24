import 'package:jetleaf_core/lang.dart';
import 'package:meta/meta_meta.dart';

/// {@template enable_web_security}
/// Marks a configuration class as the entry point for web security setup.
///
/// Applying this annotation opts a configuration class into the web security
/// filter chain and method-level security configuration. The container reads
/// the marker during startup and installs the corresponding infrastructure.
///
/// - Targets classes only.
/// - [debug] enables verbose filter-chain diagnostics.
/// - Equality is based on the [debug] flag.
///
/// ### Example
/// ```dart
/// @EnableWebSecurity(debug: true)
/// class SecurityConfig {
///   // security Pods and filter configuration
/// }
/// ```
///
/// ### See also
/// - [EnableMethodSecurity] — opt in to method-level authorization.
/// {@endtemplate}
@Target({TargetKind.classType})
final class EnableWebSecurity extends ReflectableAnnotation with EqualsAndHashCode {
  /// Enables verbose security filter debugging when `true`.
  final bool debug;

  /// {@macro enable_web_security}
  const EnableWebSecurity({this.debug = false});

  @override
  Type get annotationType => EnableWebSecurity;

  @override
  List<Object?> equalizedProperties() => [runtimeType, debug];
}

/// {@template enable_method_security}
/// Enables method-level security enforcement on annotated classes.
///
/// The individual switches control which families of annotations are honoured:
/// expression-based checks, authority-list checks, or role-list checks. All
/// three are processed by the same interception pipeline.
///
/// - Targets classes only.
/// - Expression-based checks are enabled by default.
/// - Equality is based on the three switch values.
///
/// ### Example
/// ```dart
/// @EnableMethodSecurity(securedEnabled: true)
/// class MethodSecurityConfig {}
/// ```
///
/// ### See also
/// - [EnableWebSecurity] — enables the web filter chain.
/// {@endtemplate}
@Target({TargetKind.classType})
final class EnableMethodSecurity extends ReflectableAnnotation with EqualsAndHashCode {
  /// Enables expression-based pre- and post-invocation checks.
  final bool prePostEnabled;

  /// Enables authority-list checks.
  final bool securedEnabled;

  /// Enables role-list checks.
  final bool jsr250Enabled;

  /// {@macro enable_method_security}
  const EnableMethodSecurity({
    this.prePostEnabled = true,
    this.securedEnabled = false,
    this.jsr250Enabled = false,
  });

  @override
  Type get annotationType => EnableMethodSecurity;

  @override
  List<Object?> equalizedProperties() => [runtimeType, prePostEnabled, securedEnabled, jsr250Enabled];
}
