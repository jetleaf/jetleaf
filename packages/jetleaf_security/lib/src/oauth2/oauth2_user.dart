import 'package:jetleaf_core/lang.dart' show EqualsAndHashCode;

import '../core/granted_authority.dart';

/// {@template oauth2_user}
/// An authenticated OAuth2/OIDC principal with provider attributes and granted
/// authorities.
///
/// Instances are created by provider verifiers after the identity token or
/// userinfo response has been validated. Both [attributes] and [authorities]
/// are wrapped as unmodifiable views so the authenticated identity cannot be
/// mutated after verification.
///
/// - [id] is the provider's stable identifier (`sub` or `id`).
/// - [emailVerified] reflects the provider's claim only; a provider that does
///   not expose such a claim must leave it `false` rather than assume it.
/// - [authorities] default to an empty set unless the provider assigns roles.
///
/// ### See also
/// - [OAuth2AuthenticationToken] — wraps this user in an authentication.
///
/// ### Example
/// ```dart
/// final user = OAuth2User(
///   id: '1234567890',
///   name: 'alice',
///   email: 'alice@example.com',
///   emailVerified: true,
///   authorities: {SimpleGrantedAuthority('ROLE_USER')},
/// );
/// ```
/// {@endtemplate}
class OAuth2User with EqualsAndHashCode {
  /// Stable user identifier from the provider (for example `sub` or `id`).
  final String id;

  /// Display name or username.
  final String name;

  /// Email address, when the provider exposes one.
  final String? email;

  /// Whether the provider asserted a verified email address.
  final bool emailVerified;

  /// Raw attributes from the userinfo endpoint or ID token.
  final Map<String, Object?> attributes;

  /// Authorities granted to this user.
  final Set<GrantedAuthority> authorities;

  /// {@macro oauth2_user}
  ///
  /// ### Parameters
  /// - [id] — the provider's unique identifier for the user.
  /// - [name] — display name used for [OAuth2AuthenticationToken.name].
  /// - [email] — optional email address.
  /// - [emailVerified] — whether the provider verified the email; defaults to
  ///   `false` so absence is never treated as verification.
  /// - [attributes] — provider attributes, stored as an unmodifiable map.
  /// - [authorities] — granted authorities, stored as an unmodifiable set.
  OAuth2User({
    required this.id,
    required this.name,
    this.email,
    this.emailVerified = false,
    Map<String, Object?> attributes = const {},
    Set<GrantedAuthority> authorities = const {},
  })  : attributes = Map.unmodifiable(attributes),
        authorities = Set.unmodifiable(authorities);

  @override
  String toString() => 'OAuth2User(id: $id, name: $name, email: $email)';

  /// Contributes the runtime type and all user attributes to equality and
  /// hashing.
  ///
  /// ### Returns
  /// The ordered list of properties used by [EqualsAndHashCode].
  @override
  List<Object?> equalizedProperties() => [
    runtimeType,
    id,
    name,
    email,
    emailVerified,
    attributes,
    authorities,
  ];
}