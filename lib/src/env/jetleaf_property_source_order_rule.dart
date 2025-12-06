import 'package:jetleaf/env.dart';

/// {@template jetleaf_property_source_order_rule}
/// A JetLeaf–specific ordering rule that sorts property sources according to
/// the official environmental precedence rules.
///
/// ### Precedence Table
///
/// | Category                         | Priority | Description                               |
/// | -------------------------------- | -------- | ------------------------------------------- |
/// | Command-line args                | 0        | Highest                                     |
/// | DVM system properties            | 1        | `systemProperties`                          |
/// | System environment variables     | 2        | `systemEnvironment`                         |
/// | Active profile-specific sources  | 3        | Sorted by appearance in `activeProfiles`    |
/// | Everything else                  | 10       | Lowest precedence                           |
///
/// ### **Profile Matching**
/// *A profile is recognized only if its name exactly equals a profile listed in `activeProfiles`.*  
///
/// Example:
/// ```dart
/// activeProfiles = ['prod', 'eu-west'];
///
/// // These names match EXACTLY:
/// "prod"      → index 0
/// "eu-west"   → index 1
///
/// // These DO NOT match:
/// "application-prod.properties"
/// "profile-prod"
/// "prod-config"
/// "application.properties"
/// ```
///
/// This rule does **NOT** attempt any filename parsing,  
/// **does NOT** look for `application.properties`,  
/// **does NOT** look for `application-*.properties`.  
///
/// Only the *source name itself* matters.
/// {@endtemplate}
class JetleafPropertySourceOrderRule implements PropertySourceOrderRule {
  /// Ordered list controlling profile precedence.
  ///
  /// Example:
  /// ```dart
  /// JetleafPropertySourceOrderRule(['dev', 'prod']);
  /// ```
  final List<String> activeProfiles;

  /// {@macro jetleaf_property_source_order_rule}
  const JetleafPropertySourceOrderRule(this.activeProfiles);

  /// Category index used internally to identify profile-based sources.
  ///
  /// This value is returned by [_priorityOf] for sources whose name
  /// matches an entry in [activeProfiles].
  final int _profileIndex = 3;

  /// Fallback priority used for property sources that do not match any
  /// recognized category (command line, system properties, environment,
  /// or active profiles).
  static const int _fallback = 1000;

  @override
  List<PropertySource> apply(List<PropertySource> sources) {
    return sources.toList()
      ..sort((a, b) {
        final pa = _priorityOf(a.getName());
        final pb = _priorityOf(b.getName());

        // Sort by category priority
        if (pa != pb) return pa.compareTo(pb);

        // If both are profiles → sort by activeProfiles order
        if (pa == _profileIndex) {
          return _getProfileIndex(a.getName()).compareTo(_getProfileIndex(b.getName()));
        }

        return 0; // stable
      });
  }

  /// {@template jetleaf_property_source_order_rule_priority_of}
  /// Determines the *category-level* priority of a property source based solely
  /// on its name.
  ///
  /// The result corresponds to the main precedence table used by the
  /// environment:
  ///
  /// - **0** → Command-line arguments            (`commandLineArgs`, `jlaCommandLineArgs`)
  /// - **1** → DVM system properties             (`systemProperties`)
  /// - **2** → System environment variables      (`systemEnvironment`)
  /// - **3** → Active profile-specific sources   (names must match exactly one of the entries in [activeProfiles])
  /// - **1000** → Everything else
  ///
  /// This method performs **no filename parsing**, **no extension parsing**,  
  /// and intentionally ignores patterns like `application-*.properties`.  
  ///
  /// It is used as the primary ordering key during sorting.
  /// {@endtemplate}
  int _priorityOf(String name) {
    // 0 — Command line arguments
    if (name == CommandLinePropertySource.COMMAND_LINE_PROPERTY_SOURCE_NAME ||
        name == CommandLinePropertySource.JETLEAF_COMMAND_LINE_PROPERTY_SOURCE_NAME) {
      return 0;
    }

    // 1 — DVM system properties
    if (name == GlobalEnvironment.SYSTEM_PROPERTIES_PROPERTY_SOURCE_NAME) {
      return 1;
    }

    // 2 — System environment
    if (name == GlobalEnvironment.SYSTEM_ENVIRONMENT_PROPERTY_SOURCE_NAME) {
      return 2;
    }

    // 3 — Profile (exact name match)
    if (activeProfiles.contains(name)) {
      return _profileIndex;
    }

    // Everything else → lowest category
    return _fallback;
  }

  /// {@template jetleaf_property_source_order_rule_profile_index}
  /// Determines the ordering *within* the profile category (category `3`).
  ///
  /// The index is based strictly on the position of the property-source name
  /// within the [activeProfiles] list.  
  ///
  /// ### Example:
  /// ```dart
  /// activeProfiles = ['prod', 'eu-west', 'debug'];
  ///
  /// _getProfileIndex('prod')     → 0
  /// _getProfileIndex('eu-west')  → 1
  /// _getProfileIndex('debug')    → 2
  /// _getProfileIndex('unknown')  → 999   // not a profile
  /// ```
  ///
  /// Property sources whose names do **not** match any active profile receive
  /// a large fallback index (`999`) so they always appear after all actual
  /// profile entries when category priorities are equal.
  /// {@endtemplate}
  int _getProfileIndex(String name) {
    final idx = activeProfiles.indexOf(name);
    return idx == -1 ? _fallback : idx + _profileIndex;
  }
}