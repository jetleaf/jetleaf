import 'package:jetleaf_core/lang.dart' show EqualsAndHashCode;

import 'granted_authority.dart';

/// {@template simple_granted_authority}
/// Basic concrete [GrantedAuthority] implementation storing a single authority
/// string.
///
/// Instances are immutable and compare by their authority text, so they can be
/// placed in sets and reused across requests without copying.
///
/// ### Example
/// ```dart
/// const admin = SimpleGrantedAuthority('ROLE_ADMIN');
/// print(admin.authority); // ROLE_ADMIN
/// ```
///
/// ### See also
/// - [GrantedAuthority] — the contract being implemented.
/// {@endtemplate}
class SimpleGrantedAuthority with EqualsAndHashCode implements GrantedAuthority {
  @override
  final String authority;

  /// {@macro simple_granted_authority}
  const SimpleGrantedAuthority(this.authority);

  @override
  String toString() => authority;

  /// Contributes the runtime type and [authority] to equality and hashing.
  ///
  /// ### Returns
  /// The ordered list of properties used by [EqualsAndHashCode].
  @override
  List<Object?> equalizedProperties() => [runtimeType, authority];
}