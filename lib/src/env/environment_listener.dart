// ---------------------------------------------------------------------------
// 🍃 JetLeaf Framework - https://jetleaf.hapnium.com
//
// Copyright © 2025 Hapnium & JetLeaf Contributors. All rights reserved.
//
// This source file is part of the JetLeaf Framework and is protected
// under copyright law. You may not copy, modify, or distribute this file
// except in compliance with the JetLeaf license.
//
// For licensing terms, see the LICENSE file in the root of this project.
// ---------------------------------------------------------------------------
// 
// 🔧 Powered by Hapnium — the Dart backend engine 🍃

import 'package:jetleaf_env/env.dart';
import 'package:jetleaf_env/property.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_logging/logging.dart';

import '../context/bootstrap_context.dart';
import '../jet_application.dart';
import '../jet_leaf_version.dart';
import '../listener/run_listener.dart';
import 'environment_parser.dart';
import 'property_source.dart';

typedef _ParsedEnvironmentData = (String profile, Map<String, Object> properties);

/// {@template environment_listener}
/// A listener that prepares and configures the application environment.
///
/// The [EnvironmentListener] is responsible for:
/// - Parsing environment configuration files (JSON, YAML, properties, env)
/// - Handling Dart-based configuration sources
/// - Fallback to `ConfigurationProperty` subclasses for backward compatibility
/// - Registering property sources into the environment
/// - Determining active and default profiles
///
/// This ensures that when your application starts, the environment is
/// properly populated with all available configuration sources.
///
/// ### Example
/// ```dart
/// void main() {
///   final context = ConfigurableBootstrapContext();
///   final environment = ConfigurableEnvironment();
///
///   final listener = EnvironmentListener();
///   listener.onEnvironmentPrepared(context, environment);
///
///   // After execution, environment contains all parsed property sources.
///   print(environment.getPropertySources());
/// }
/// ```
/// {@endtemplate}
final class EnvironmentListener extends ApplicationRunListener {
  final Log _logger = LogFactory.getLog(EnvironmentListener);

  /// {@macro environment_listener}
  EnvironmentListener();

  @override
  void onEnvironmentPrepared(ConfigurableBootstrapContext context, ConfigurableEnvironment environment) async {
    final otherParsers = <EnvironmentParser>[
      EnvEnvironmentParser(),
      JsonEnvironmentParser(),
      PropertiesEnvironmentParser(),
      YamlEnvironmentParser(),
    ];
    final dartParser = DartEnvironmentParser();
    final assets = Runtime.getAllAssets();
    final rootPackageName = Runtime.getAllPackages().find((p) => p.getIsRootPackage())?.getName();

    // --- 1) Collect parsed entries with package info -------------------------

    final otherParserResult = <ParsedEnvironmentData>[];
    for (final asset in assets) {
      final parser = otherParsers.find((p) => p.canParse(asset));

      if (parser != null) {
        otherParserResult.add(parser.load(asset));
      }
    }

    final parsedEntries = <ParsedEnvironmentData>[];
    final flattened = List<ParsedEnvironmentData>.from(otherParserResult.map((d) => (d.$1, d.$2, _flattenAndNormalizeMap(d.$3))));
    parsedEntries.addAll(flattened);

    // The use of dart environment parser can be tricky at some point, but since Jetleaf supports
    // multiple ways of declaring properties, we can use the dart environment parser to load them.
    final dartParserAssets = assets.where((asset) => dartParser.canParse(asset));
    for (final asset in dartParserAssets) {
      parsedEntries.add(dartParser.load(asset));
    }

    // --- 2) Build profile -> list of entries (preserving package info) ------
    final Map<String, List<ParsedEnvironmentData>> byProfile = {};
    for (final entry in parsedEntries) {
      final profile = entry.$2;
      byProfile.putIfAbsent(profile, () => []).add(entry);
    }

    // --- 3) For each profile, sort entries so rootPackage entries come first ---
    // (We will process entries in order: root-package first, then others)
    List<_ParsedEnvironmentData> envResult = [];
    for (final profile in byProfile.keys) {
      final entries = byProfile[profile]!;

      // sort so root package entries come first
      entries.sort((a, b) {
        final aPkg = a.$1;
        final bPkg = b.$1;
        if (aPkg == rootPackageName && bPkg != rootPackageName) return -1;
        if (bPkg == rootPackageName && aPkg != rootPackageName) return 1;
        // keep relative order otherwise (stable) — keep original order by not swapping
        return 0;
      });

      // merged map for this profile (keys are dotted after flatten)
      final Map<String, Object> merged = {};

      // process entries in order: root (user) ones first => they set initial values
      for (final entry in entries) {
        final props = entry.$3;
        final flat = _flattenAndNormalizeMap(props);

        // Merge BUT preserve existing keys (user-first)
        flat.forEach((key, incoming) {
          final existing = merged[key];
          merged[key] = _mergePreserveExisting(existing, incoming);
        });
      }

      envResult.add((profile, merged));
    }

    // 4) Register property sources: add unprofiled sources always; add profile-specific
    // only when their profile is in effectiveProfiles.
    //
    // The `list` is expected to be ParsedEnvironmentData tuples like (profile, Map).
    final sources = environment.getPropertySources();

    for (final item in envResult) {
      final sourceName = item.$1;
      final properties = item.$2;

      if(sourceName == AbstractEnvironment.RESERVED_DEFAULT_PROFILE_NAME) {
        DefaultPropertiesPropertySource.addOrMerge(properties, sources);
      } else {
        sources.addLast(PropertiesPropertySource(sourceName, properties));
      }
    }

    for (final source in sources) {
      environment.getPropertySources().addFirst(source);
    }

    // 5) Register version property source
    final versionContent = <String, Object>{};

    if (environment.getProperty(JetApplication.JETLEAF_VERSION) == null) {
      versionContent[JetApplication.JETLEAF_VERSION] = JetLeafVersion.getVersion();
    }

    if (environment.getProperty(JetApplication.JETLEAF_APPLICATION_VERSION) == null) {
      versionContent[JetApplication.JETLEAF_APPLICATION_VERSION] = context.getApplicationClass().getPackage()?.getVersion() ?? "unknown";
    }

    environment.getPropertySources().addLast(PropertiesPropertySource("versioned", versionContent));

    // 6) Look for active profiles: system props -> system env -> parsed assets (list)
    String? activeRaw = environment.getProperty(AbstractEnvironment.ACTIVE_PROFILES_PROPERTY_NAME);

    // 7) Look for default profiles (if active wasn't provided)
    String? defaultRaw = environment.getProperty(AbstractEnvironment.DEFAULT_PROFILES_PROPERTY_NAME);

    // 8) Apply to environment
    if (activeRaw != null && activeRaw.trim().isNotEmpty) {
      final activeProfiles = _parseProfilesString(activeRaw);
      if (activeProfiles.isNotEmpty) {
        environment.setActiveProfiles(activeProfiles);
        if (_logger.getIsDebugEnabled()) {
          _logger.debug('Set active profiles from config: $activeProfiles');
        }
      }
    }

    if (defaultRaw != null && defaultRaw.trim().isNotEmpty) {
      final defaultProfiles = _parseProfilesString(defaultRaw);
      if (defaultProfiles.isNotEmpty) {
        environment.setDefaultProfiles(defaultProfiles);
        if (_logger.getIsDebugEnabled()) {
          _logger.debug('Set default profiles from config: $defaultProfiles');
        }
      }
    }

    // If nothing set, ensure there is at least [AbstractEnvironment.RESERVED_DEFAULT_PROFILE_NAME]
    if (environment.getDefaultProfiles().isEmpty) {
      environment.setDefaultProfiles([AbstractEnvironment.RESERVED_DEFAULT_PROFILE_NAME]);
    }

    if (environment.getActiveProfiles().isEmpty) {
      environment.setActiveProfiles([AbstractEnvironment.RESERVED_DEFAULT_PROFILE_NAME]);
    }

    // 9) Set logging property
    // --- COPY logging.* properties into shared LogProperties (profile-aware) ----

    // Build a profile -> properties map from envResult
    final Map<String, Map<String, Object>> profileToProps = {};
    for (final item in envResult) {
      profileToProps[item.$1] = item.$2;
    }

    final activeProfiles = environment.getActiveProfiles();
    final activeSet = activeProfiles.toSet();

    // Collector for stringified logging props
    final Map<String, String> collected = {};

    // 1) Apply non-active profiles first (preserve entries)
    for (final entry in profileToProps.entries) {
      final profile = entry.key;
      final props = entry.value;

      if (activeSet.contains(profile)) continue; // skip active for now

      // iterate keys and take only logging.* keys
      props.forEach((key, value) {
        if (!key.startsWith('logging.')) return;
        // preserve existing (first wins for non-active block)
        collected.putIfAbsent(key, () => value.toString());
      });
    }

    // 2) Apply active profiles in the order the environment declares them (override)
    for (final profile in activeProfiles) {
      final props = profileToProps[profile];
      if (props == null) continue;
      props.forEach((key, value) {
        if (!key.startsWith('logging.')) return;
        // active profile always wins (overwrites previous)
        collected[key] = value.toString();
      });
    }

    // 3) Persist into LogProperties (global registry)
    LogProperties.instance.setProperties(collected, overwrite: true);

    if (_logger.getIsDebugEnabled()) {
      _logger.debug('Loaded ${collected.length} logging properties from environment: ${collected.keys.toList()}');
    }
  }

  // ---------- helpers (put these inside EnvironmentListener as private methods) ----------

  /// {@template environment_listener_parse_profiles}
  /// Parse a raw profiles string into a list of profile names.
  ///
  /// Splits on commas and whitespace, trims each profile, and removes
  /// any empty entries.
  ///
  /// ### Example
  /// ```dart
  /// final listener = EnvironmentListener();
  /// final profiles = listener._parseProfilesString("dev, test prod");
  /// print(profiles); // ["dev", "test", "prod"]
  /// ```
  /// {@endtemplate}
  List<String> _parseProfilesString(String? raw) {
    if (raw == null) return <String>[];
    return raw.split(RegExp(r'[,\s]+')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
  }
}

List<_ParsedEnvironmentData> flattenEnvironment(List<_ParsedEnvironmentData> inputs) {
  final Map<String, Map<String, Object>> acc = {};

  for (final (profile, properties) in inputs) {
    final mergedForProfile = acc.putIfAbsent(profile, () => <String, Object>{});

    // First flatten incoming properties into dotted keys and normalize values
    final flat = _flattenAndNormalizeMap(properties);

    // Merge flattened keys into accumulator
    flat.forEach((key, incoming) {
      final existing = mergedForProfile[key];
      mergedForProfile[key] = _mergeKeyValues(existing, incoming);
    });
  }

  // Return list of (profile, properties) tuples
  return acc.entries.map((e) => (e.key, Map<String, Object>.from(e.value))).toList();
}

/// --- Flatten & normalize -------------------------------------------------

/// Flatten nested maps into dotted keys and normalize values (split comma-strings, expand lists).
Map<String, Object> _flattenAndNormalizeMap(Map<String, Object?> source) {
  final Map<String, Object> out = {};
  void walk(String prefix, Object? node) {
    if (node == null) return;

    if (node is Map) {
      // For map: recurse into keys
      node.forEach((k, v) {
        final key = prefix.isEmpty ? k.toString() : '$prefix.$k';
        walk(key, v);
      });
      return;
    }

    if (node is List) {
      // Normalize each list item, flatten nested lists and comma-strings
      final normalized = <Object>[];
      for (final item in node) {
        final n = _normalizeValueForKey(prefix, item);
        if (n is List) {
          for (final inner in n) {
            if (!_containsDeep(normalized, inner)) normalized.add(inner);
          }
        } else {
          if (!_containsDeep(normalized, n)) normalized.add(n);
        }
      }
      out[prefix] = normalized;
      return;
    }

    // Primitive (String/num/bool/other)
    final norm = _normalizeValueForKey(prefix, node);
    out[prefix] = norm;
  }

  walk('', source);
  return out;
}

/// Normalize a value based on content:
/// - If value is a string with commas -> split into list of trimmed tokens
/// - If value is a string that represents a bracketed/list-like -> leave as-is (no JSON parsing)
/// - Otherwise return value unchanged
Object _normalizeValueForKey(String key, Object? value) {
  if (value == null) return '';

  // If it's already a list, handle at caller
  if (value is List) return value;

  // Strings that are comma-separated: split into list tokens
  if (value is String) {
    // Heuristic: if there is a comma and not a file path (paths contain '/' or ':' often)
    // For keys like 'steps' or when commas are present, split into tokens.
    if (value.contains(',') && !_looksLikeFilePath(value)) {
      final tokens = value
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      return tokens;
    }
    return value;
  }

  // TypedData, num, bool, etc. — return as-is
  return value;
}

bool _looksLikeFilePath(String s) {
  // crude heuristic: file paths usually contain '/' or '\\' or end with .txt/.yaml etc.
  return s.contains('/') || s.contains('\\') || s.contains('.txt') || s.contains('.yaml') || s.contains('.yml') || s.contains('.properties');
}

/// --- Merge rules ---------------------------------------------------------

/// Merge existing and incoming (both normalized).
/// - If both null -> null
/// - If existing null -> incoming
/// - If both lists -> merged dedup list
/// - If one list, one scalar -> ensure scalar is in list
/// - If both scalars:
///    - if equal -> scalar
///    - else -> prefer incoming (later wins)
Object _mergeKeyValues(Object? existing, Object? incoming) {
  if (existing == null) return incoming as Object;

  // Normalize: existing could be scalar or List
  final exIsList = existing is List;
  final inIsList = incoming is List;

  if (exIsList && inIsList) {
    return _mergeListsDedup(existing, incoming);
  }

  if (exIsList && !inIsList) {
    final list = List<Object>.from(existing);
    _addToListIfNotPresent(list, incoming);
    return list;
  }

  if (!exIsList && inIsList) {
    final list = List<Object>.from(incoming);
    _addToListIfNotPresent(list, existing);
    return list;
  }

  // both scalars
  if (_deepEquals(existing, incoming)) {
    return existing;
  }

  // If both are strings and one is empty, return non-empty
  if (existing is String && incoming is String) {
    if (existing.isEmpty && incoming.isNotEmpty) return incoming;
    if (incoming.isEmpty && existing.isNotEmpty) return existing;
  }

  // Otherwise choose incoming (last-wins) — that's what keeps the dart-parser style
  return incoming as Object;
}

Object _mergePreserveExisting(Object? existing, Object? incoming) {
  // If no existing, incoming becomes the value
  if (existing == null) return incoming as Object;

  // If equal, keep existing
  if (_deepEquals(existing, incoming)) return existing;

  final exIsList = existing is List;
  final inIsList = incoming is List;

  // Both lists -> existing's items first, then append unique incoming items
  if (exIsList && inIsList) {
    final result = List<Object>.from(existing);
    for (final item in incoming) {
      if (!_containsDeep(result, item)) result.add(item as Object);
    }
    return result;
  }

  // existing list, incoming scalar -> add incoming if not present (existing order preserved)
  if (exIsList && !inIsList) {
    final result = List<Object>.from(existing);
    if (!_containsDeep(result, incoming)) result.add(incoming as Object);
    return result;
  }

  // existing scalar, incoming list -> prefer existing first, then append missing incoming items
  if (!exIsList && inIsList) {
    final result = <Object>[];
    result.add(existing);
    for (final item in incoming) {
      if (!_containsDeep(result, item)) result.add(item as Object);
    }
    return result;
  }

  // both scalars but different -> keep existing (user-first)
  return existing;
}

/// Merge two lists preserving order and deduplicating deeply.
List<Object> _mergeListsDedup(List a, List b) {
  final List<Object> result = [];
  for (final item in a) {
    final cloned = _shallowCloneValue(item);
    if (!_containsDeep(result, cloned)) result.add(cloned);
  }
  for (final item in b) {
    final cloned = _shallowCloneValue(item);
    if (!_containsDeep(result, cloned)) result.add(cloned);
  }
  return result;
}

void _addToListIfNotPresent(List list, Object? value) {
  final v = _shallowCloneValue(value);
  if (!_containsDeep(list, v)) list.add(v);
}

/// Shallow clone simple values to avoid surprising shared references for maps/lists.
Object _shallowCloneValue(Object? v) {
  if (v == null) return '';
  if (v is Map) return Map<String, Object>.from(v.cast<String, Object>());
  if (v is List) return List<Object>.from(v);
  return v;
}

/// Deep-equality containment check for lists (works for primitives, maps and lists).
bool _containsDeep(List list, Object? item) {
  for (final e in list) {
    if (_deepEquals(e, item)) return true;
  }
  return false;
}

/// Recursive deep equals (small, cycle-safe).
bool _deepEquals(Object? a, Object? b, [Set<int>? va, Set<int>? vb]) {
  if (identical(a, b)) return true;
  if (a == null || b == null) return false;

  // Allow list vs list, map vs map
  if (a.runtimeType != b.runtimeType) {
    if (!(a is List && b is List) && !(a is Map && b is Map)) return false;
  }

  va ??= <int>{};
  vb ??= <int>{};
  final ida = identityHashCode(a);
  final idb = identityHashCode(b);
  if (va.contains(ida) && vb.contains(idb)) return true;
  va.add(ida);
  vb.add(idb);

  if (a is Map && b is Map) {
    final ma = a.cast<Object?, Object?>();
    final mb = b.cast<Object?, Object?>();
    if (ma.length != mb.length) return false;
    for (final k in ma.keys) {
      if (!mb.containsKey(k)) return false;
      if (!_deepEquals(ma[k], mb[k], va, vb)) return false;
    }
    return true;
  }

  if (a is List && b is List) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (!_deepEquals(a[i], b[i], va, vb)) return false;
    }
    return true;
  }

  return a == b;
}