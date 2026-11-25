import '../core/granted_authority.dart';
import '../core/simple_granted_authority.dart';

/// {@template role_hierarchy}
/// Defines reachability relationships between roles so that holding a
/// higher-level role implies holding every subordinate role.
///
/// Rules are expressed with `>` and may be separated by newlines, semicolons,
/// or chained on one line. A chain such as `ADMIN > MODERATOR > USER` records
/// two direct edges and expansion discovers the transitive closure.
///
/// ```
/// ROLE_ADMIN > ROLE_MODERATOR
/// ROLE_MODERATOR > ROLE_USER
/// ```
///
/// ### Contract and invariants
/// - Setting a hierarchy replaces all previously configured rules.
/// - Blank lines are ignored and whitespace around role names is trimmed.
/// - Expansion includes the original authorities plus every reachable role.
/// - Cycles are safe: already-visited role names are never queued twice.
/// - The returned authorities are fresh [SimpleGrantedAuthority] instances in a
///   non-growable list.
///
/// ### Example
/// ```dart
/// final hierarchy = RoleHierarchy('''
///   ROLE_ADMIN > ROLE_MODERATOR
///   ROLE_MODERATOR > ROLE_USER
/// ''');
///
/// final effective = hierarchy.getReachableGrantedAuthorities({
///   const SimpleGrantedAuthority('ROLE_ADMIN'),
/// });
/// print(effective.map((a) => a.authority)); // ROLE_ADMIN, ROLE_MODERATOR, ROLE_USER
/// ```
/// {@endtemplate}
class RoleHierarchy {
  /// {@template role_hierarchy._direct_children}
  /// Direct child roles keyed by their parent role name.
  ///
  /// Transitive relationships are derived from these edges at query time rather
  /// than precomputed, so changing the hierarchy takes effect immediately.
  /// {@endtemplate}
  final Map<String, Set<String>> _directChildren = {};

  /// {@macro role_hierarchy}
  RoleHierarchy([String? hierarchySpecification]) {
    if (hierarchySpecification != null && hierarchySpecification.trim().isNotEmpty) {
      setHierarchy(hierarchySpecification);
    }
  }

  /// Parses and replaces the hierarchy rules from [hierarchySpecification].
  ///
  /// Supports newline- or semicolon-separated rules as well as chained rules
  /// such as `ROLE_ADMIN > ROLE_MODERATOR > ROLE_USER`. Any existing rules are
  /// discarded before parsing begins.
  ///
  /// ### Parameters
  /// - [hierarchySpecification] — the text containing `>` separated role names.
  ///
  /// ### Returns
  /// Nothing; the parsed edges replace the current hierarchy.
  void setHierarchy(String hierarchySpecification) {
    _directChildren.clear();
    final lines = hierarchySpecification.split(RegExp(r'[\r\n;]+'));
    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;
      final parts = line.split('>').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      for (var i = 0; i < parts.length - 1; i++) {
        _directChildren.putIfAbsent(parts[i], () => <String>{}).add(parts[i + 1]);
      }
    }
  }

  /// Expands [authorities] with every directly and transitively implied role.
  ///
  /// ### Parameters
  /// - [authorities] — the authorities actually granted to a principal.
  ///
  /// ### Returns
  /// A non-growable list of [SimpleGrantedAuthority] objects containing the
  /// original role names and all roles reachable from them. Duplicate names are
  /// collapsed.
  List<GrantedAuthority> getReachableGrantedAuthorities(Iterable<GrantedAuthority> authorities) {
    final visited = <String>{};
    final queue = <String>[];

    for (final auth in authorities) {
      if (visited.add(auth.authority)) {
        queue.add(auth.authority);
      }
    }

    while (queue.isNotEmpty) {
      final current = queue.removeLast();
      final children = _directChildren[current];
      if (children == null) continue;
      for (final child in children) {
        if (visited.add(child)) {
          queue.add(child);
        }
      }
    }

    return visited.map(SimpleGrantedAuthority.new).toList(growable: false);
  }
}