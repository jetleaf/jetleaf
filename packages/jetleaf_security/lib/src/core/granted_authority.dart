/// {@template granted_authority}
/// Represents a single authority granted to an authenticated principal, such
/// as a role (`ROLE_ADMIN`) or a fine-grained permission (`users:read`).
///
/// Authorities are the unit of authorization decisions: a [Authentication]
/// exposes a set of them, and authorization strategies check membership rather
/// than inspecting the principal itself.
///
/// Implementations are expected to be immutable and value-comparable so sets
/// of authorities can be shared safely across request zones.
///
/// ### Example
/// ```dart
/// bool canEdit(Set<GrantedAuthority> authorities) =>
///     authorities.any((a) => a.authority == 'articles:write');
/// ```
///
/// ### See also
/// - [GrantedAuthority.authority] — the value used in authorization checks.
/// {@endtemplate}
abstract interface class GrantedAuthority {
  /// Returns the string representation of this authority.
  ///
  /// ### Returns
  /// A non-null identifier whose spelling is defined by the application.
  String get authority;
}
