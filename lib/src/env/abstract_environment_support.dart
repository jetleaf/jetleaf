import 'package:jetleaf_env/env.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:meta/meta.dart';

import 'abstract_environment_logging_support.dart';
import 'models.dart';
import 'property_source.dart';

/// Provides the foundational mechanics for loading, normalizing, merging,
/// ordering, and installing configuration sources into a JetLeaf
/// [ConfigurableEnvironment].
///
/// `AbstractEnvironmentSupport` forms the core of JetLeaf’s environment
/// processing pipeline. It implements a structured, deterministic sequence for
/// turning raw, parsed environment assets—YAML, JSON, `.properties`, Dart maps,
/// package-embedded configs, and others—into final property sources that the
/// runtime can consume.
///
/// The class coordinates several responsibilities:
///
/// ---
/// ## 🔹 Core Responsibilities
///
/// ### **1. Profile-Aware Source Construction**
/// Using [getEnvironmentSources], parsed environment assets are:
/// - grouped by profile
/// - sorted by package precedence (root → JetLeaf → Dart → others)
/// - flattened into dotted-key maps
/// - normalized (comma-splitting, list flattening, deduplication)
/// - merged using user-first semantics  
/// Producing one canonical [EnvironmentSource] per profile.
///
///
/// ### **2. Deterministic Source Ordering**
/// Through [_ordered], the class enforces JetLeaf’s package-based precedence:
/// - root package overrides all
/// - JetLeaf system config next
/// - Dart and other library configs last  
/// This ensures configuration layering is predictable and stable across
/// environments.
///
///
/// ### **3. Value Normalization & Deep Structural Operations**
/// Includes:
/// - `_normalizeValueForKey` (string splitting, path detection)
/// - `flattenAndNormalizeMap` (map flattening, list normalization)
/// - `mergePreserveExisting` (user-first merges)
/// - deep structural equality and deduplication utilities  
///
/// These are essential for handling real-world configuration formats where
/// lists, inline CSV, file paths, nested maps, and overrides must be combined
/// consistently.
///
///
/// ### **4. Environment Installation**
/// [prepareEnvironmentSources] resolves placeholders (e.g. `${}`, `#{}`) and
/// installs each merged source into the environment’s property source chain.
/// Ordering ensures:
/// 1. profile-matched and user-oriented sources appear first
/// 2. fallback and non-profiled sources are demoted to the end
///
///
/// ---
/// ## 🔹 Intended Usage
///
/// This class is extended internally by JetLeaf environment loaders and can be
/// used by framework integrators who need custom environment semantics.
/// Typical subclasses:
/// - load configuration from custom file formats  
/// - implement remote configuration providers  
/// - add runtime-generated environment sources  
///
///
/// ---
/// ## 🔹 Extensibility Points
///
/// - Override `resolveProperties` to apply placeholder resolution, type
///   conversion, or custom expression evaluation.
/// - Override or supplement `_normalizeValueForKey` for domain-specific parsing.
/// - Extend `_ordered` if additional package precedence rules are desired.
///
///
/// ---
/// ## 🔹 Guarantees
///
/// Subclasses inheriting this support gain:
/// - deterministic merge order
/// - safe deep structural comparisons
/// - consistent flattening & normalization rules
/// - predictable precedence behavior across packages and profiles
/// - a fully processed, ready-to-use chain of property sources in the
///   environment
///
///
/// ---
/// ## Lifecycle
///
/// `AbstractEnvironmentSupport` is typically invoked during:
/// - application startup
/// - environment refresh cycles
/// - test container initialization
///
///
/// ---
/// ## Notes
///
/// - This class is **not** meant for direct instantiation.
/// - All key operations are `@protected` to guide subclassing while preventing
///   misuse.
/// - The design mirrors JetLeaf’s philosophy of *user-first configuration
///   precedence with deterministic behavior*.
///
///
///
/// ---
abstract class AbstractEnvironmentSupport extends AbstractEnvironmentLoggingSupport {
  /// Constructs and merges environment sources by profile from a list of parsed
  /// environment assets.
  ///
  /// This method transforms a list of [ParsedEnvironmentSource] into a list of
  /// fully merged [EnvironmentSource] objects, ready to be applied to a
  /// [ConfigurableEnvironment].
  ///
  /// ## Processing Steps
  ///
  /// 1. **Group by profile**  
  ///    All parsed sources are grouped according to their `profile` property.  
  ///    This allows profile-specific configuration to be isolated and merged separately.
  ///
  /// 2. **Sort by package precedence**  
  ///    Within each profile, sources are sorted using [_ordered] to ensure a
  ///    deterministic merge order:
  ///    - Root (user) package entries first
  ///    - JetLeaf main package
  ///    - JetLeaf subpackages
  ///    - Dart packages
  ///    - All others last
  ///
  /// 3. **Flatten and normalize**  
  ///    Each source's properties map is flattened using `flattenAndNormalizeMap`
  ///    to produce a single-level map with dotted keys and normalized values.
  ///
  /// 4. **Merge properties**  
  ///    Properties from multiple sources within the same profile are merged using
  ///    `mergePreserveExisting`, which ensures:
  ///    - Existing values are preserved (user-first)
  ///    - Lists are combined and deduplicated
  ///    - Scalars are preserved according to precedence rules
  ///
  /// 5. **Create [EnvironmentSource] objects**  
  ///    After merging, each profile produces a single [EnvironmentSource] object
  ///    containing all merged properties.
  ///
  /// ## Returns
  /// A list of [EnvironmentSource] objects, one per profile, with fully merged,
  /// normalized, and flattened property maps.
  ///
  /// ### Example
  /// ```dart
  /// final parsed = getParsedEnvironmentSources();
  /// final sources = getEnvironmentSources(parsed);
  /// for (var src in sources) {
  ///   print("Profile: ${src.profile}, Properties: ${src.properties}");
  /// }
  /// ```
  @protected
  List<EnvironmentSource> getEnvironmentSources(List<ParsedEnvironmentSource> parsedSources) {
    final Map<String, List<ParsedEnvironmentSource>> profiledSources = {};
    for (final entry in parsedSources) {
      final profile = entry.profile;
      profiledSources.putIfAbsent(profile, () => []).add(entry);
    }

    final packages = Runtime.getAllPackages();
    final sources = <EnvironmentSource>[];
    for (final profile in profiledSources.keys) {
      final entries = profiledSources[profile]!;

      // sort so root package entries come first
      entries.sort((a, b) => _ordered(a, packages).compareTo(_ordered(b, packages)));

      // merged map for this profile (keys are dotted after flatten)
      final Map<String, Object> merged = {};

      // process entries in order: root (user) ones first => they set initial values
      for (final entry in entries) {
        final flat = flattenAndNormalizeMap(entry.properties);

        // Merge BUT preserve existing keys (user-first)
        flat.forEach((key, incoming) {
          final existing = merged[key];
          merged[key] = mergePreserveExisting(existing, incoming);
        });
      }

      sources.add(EnvironmentSource(profile, merged));
    }

    return sources;
  }

  /// Determines the precedence ranking of a parsed environment source based on
  /// the package it originates from.
  ///
  /// This method inspects the `packageName` of the given
  /// [ParsedEnvironmentSource] and categorizes it into an ordered tier.  
  /// The result is used to sort environment sources so they are merged or applied
  /// in a predictable and meaningful order.
  ///
  /// ## Ordering Rules (lower number = higher priority)
  ///
  /// | Order | Description                                      | Criteria                                                 |
  /// |-------|--------------------------------------------------|-----------------------------------------------------------|
  /// | **0** | Root package                                     | `package.getIsRootPackage()`                              |
  /// | **1** | JetLeaf main package                              | `name == PackageNames.MAIN`                               |
  /// | **2** | JetLeaf subpackages                               | `name.startsWith(PackageNames.MAIN)`                      |
  /// | **3** | Dart core or Dart-prefixed packages               | `name == "dart"` or `name.startsWith("dart")`             |
  /// | **4** | All other packages                                | Everything not matching above                             |
  ///
  /// If the package cannot be found in the provided [packages] list, the method
  /// returns `Ordered.LOWEST_PRECEDENCE` so that unknown sources are applied last.
  ///
  /// ## Returns
  /// An integer representing the precedence of the source.  
  /// Lower integers indicate higher priority during environment merging.
  ///
  /// ## Example
  /// ```dart
  /// final order = _ordered(mySource, allPackages);
  /// if (order == 0) print("Root-level configuration");
  /// ```
  int _ordered(ParsedEnvironmentSource source, List<Package> packages) {
    final package = packages.find((pk) => source.packageName.equals(pk.getName()));
    if (package != null) {
      final name = package.getName();

      // 0 = root
      if (package.getIsRootPackage()) {
        return 0;
      }

      // 1 = jetleaf main package
      if (name == PackageNames.MAIN) {
        return 1;
      }

      // 2 = jetleaf subpackages
      if (name.startsWith(PackageNames.MAIN)) {
        return 2;
      }

      // 3 = dart packages
      if (name == Constant.DART_PACKAGE_NAME || name.startsWith(Constant.DART_PACKAGE_NAME)) {
        return 3;
      }

      // 4 = everything else
      return 4;
    }

    // If no package info is available, push to the end
    return Ordered.LOWEST_PRECEDENCE;
  }

  /// Recursively flattens and normalizes a nested configuration map into a
  /// single-level map using dotted keys.
  ///
  /// This method is designed for processing heterogeneous configuration sources
  /// (YAML, JSON, `.properties`, Dart maps, environment maps, etc.) into a
  /// consistent, uniform structure that can be reliably consumed by the
  /// `ConfigurableEnvironment`.
  ///
  /// ## Behavior
  ///
  /// ### 1. **Map Flattening**
  /// Nested maps are converted into dotted-key paths:
  ///
  /// ```dart
  /// {
  ///   "server": {
  ///     "port": 8080,
  ///     "ssl": { "enabled": true }
  ///   }
  /// }
  /// ```
  /// becomes:
  /// ```dart
  /// {
  ///   "server.port": 8080,
  ///   "server.ssl.enabled": true
  /// }
  /// ```
  ///
  /// ### 2. **List Normalization**
  /// When encountering lists:
  ///
  /// - Each element is normalized using `_normalizeValueForKey`.
  /// - Nested lists and comma-separated strings inside lists are flattened.
  /// - Duplicate elements are removed using deep equality.
  ///
  /// Example:
  /// ```dart
  /// ["a, b", ["b", "c"], "a"]
  /// ```
  /// becomes:
  /// ```dart
  /// ["a", "b", "c"]
  /// ```
  ///
  /// ### 3. **Scalar Normalization**
  /// Scalar values (`String`, `num`, `bool`, etc.) are normalized using
  /// `_normalizeValueForKey`, which handles comma-splitting and path heuristics.
  ///
  /// ### 4. **Null Handling**
  /// Null values are ignored and produce no output entry.
  ///
  /// ## Returns
  /// A `Map<String, Object>` where:
  /// - all keys are flattened (using “dot notation”)
  /// - all values are normalized and deduplicated
  ///
  /// ## Example
  /// ```dart
  /// flattenAndNormalizeMap({
  ///   "profiles": "dev, prod",
  ///   "database": {
  ///     "hosts": ["db1", "db2, db3"],
  ///     "port": 5432
  ///   }
  /// });
  /// ```
  ///
  /// Produces:
  /// ```dart
  /// {
  ///   "profiles": ["dev", "prod"],
  ///   "database.hosts": ["db1", "db2", "db3"],
  ///   "database.port": 5432
  /// }
  /// ```
  ///
  @protected
  Map<String, Object> flattenAndNormalizeMap(Map<String, Object?> source) {
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

  /// Normalizes a raw configuration [value] based on its type and the semantics
  /// implied by the associated [key].
  ///
  /// This method helps standardize environment and property values so that
  /// downstream merging and resolution behave consistently.
  ///
  /// ### Normalization Rules
  ///
  /// - **`null` → empty string**  
  ///   Null values are converted to an empty string to avoid null-handling
  ///   overhead in later processing.
  ///
  /// - **Lists**  
  ///   Returned unchanged. List merging is handled by the caller.
  ///
  /// - **Strings**  
  ///   - If the string contains commas **and** does *not* appear to be a file path  
  ///     (detected via [_looksLikeFilePath]), the string is treated as a
  ///     comma-separated list and split into trimmed tokens.  
  ///   - Otherwise, the string is returned unchanged.
  ///
  /// - **All other types** (numbers, booleans, TypedData, objects)  
  ///   Returned unchanged.
  ///
  /// ### Purpose
  /// This heuristic normalization supports common patterns in environment/config
  /// files where some scalar fields may contain lightweight CSV-like lists,
  /// while ensuring file paths and other meaningful strings are preserved verbatim.
  ///
  /// ### Examples
  /// ```dart
  /// _normalizeValueForKey("modes", "debug, test, prod");
  /// // → ["debug", "test", "prod"]
  ///
  /// _normalizeValueForKey("configFile", "config/app.yaml");
  /// // → "config/app.yaml"   (not split; detected as file path)
  ///
  /// _normalizeValueForKey("count", 3);
  /// // → 3
  ///
  /// _normalizeValueForKey("empty", null);
  /// // → ""
  /// ```
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

  /// Returns `true` if the given string *appears* to represent a file path.
  ///
  /// This is a **heuristic**, not a strict parser. It is intended for lightweight
  /// detection of asset-like or path-like strings inside environment or config
  /// structures.
  ///
  /// A string is considered “file path–like” if it matches any of these cues:
  ///
  /// - contains a forward slash `/`  
  /// - contains a backslash `\` (Windows-style paths)
  /// - ends with a typical file extension such as:
  ///   - `.txt`
  ///   - `.yaml`
  ///   - `.yml`
  ///   - `.properties`
  ///
  /// ### Notes
  /// - This function does *not* verify that the path exists.
  /// - It intentionally favors false-positives over false-negatives to ensure
  ///   that potential paths are not overlooked.
  ///
  /// ### Examples
  /// ```dart
  /// _looksLikeFilePath("config/app.yaml");   // true
  /// _looksLikeFilePath("C:\\data\\file.txt"); // true
  /// _looksLikeFilePath("settings.properties"); // true
  /// _looksLikeFilePath("dev");                 // false
  /// _looksLikeFilePath("username");            // false
  /// ```
  bool _looksLikeFilePath(String s) {
    // crude heuristic: file paths usually contain '/' or '\\' or end with .txt/.yaml etc.
    return s.contains('/') || s.contains('\\') || s.contains('.txt') || s.contains('.yaml') || s.contains('.yml') || s.contains('.properties');
  }

  /// Merges two values while *preserving the existing value's precedence*.
  /// 
  /// This method is used to combine configuration values coming from different
  /// sources (profiles, files, overrides, etc.) in a predictable, stable way.
  /// It favors the semantics:
  ///
  /// **existing value wins; incoming value augments.**
  ///
  /// The merge rules are:
  ///
  /// 1. **If [existing] is `null`**  
  ///    → Return [incoming] directly.
  ///
  /// 2. **If [existing] and [incoming] are deeply equal**  
  ///    → Keep [existing] as-is (no structural changes).
  ///
  /// 3. **If both values are lists**  
  ///    → Return a list that preserves all items in [existing] first, then appends
  ///      only the *unique* items from [incoming] (deep comparison).
  ///
  /// 4. **If [existing] is a list and [incoming] is a scalar**  
  ///    → Append [incoming] only if it is not already present.
  ///
  /// 5. **If [existing] is a scalar and [incoming] is a list**  
  ///    → Produce a new list that begins with [existing], followed by unique items
  ///      from [incoming].
  ///
  /// 6. **If both are scalars but not equal**  
  ///    → Keep [existing]; user-provided or earlier-loaded value takes precedence.
  ///
  /// Deep comparisons for uniqueness are performed using [_deepEquals], ensuring
  /// nested lists or maps are compared structurally, not by identity.
  ///
  /// ### Returns
  /// The merged value, following the rules above.
  ///
  /// ### Example
  /// ```dart
  /// mergePreserveExisting([1, 2], [2, 3]); 
  /// // → [1, 2, 3]
  ///
  /// mergePreserveExisting('a', ['a', 'b']); 
  /// // → ['a', 'b']
  ///
  /// mergePreserveExisting('x', 'y'); 
  /// // → 'x'   (existing wins)
  /// ```
  @protected
  Object mergePreserveExisting(Object? existing, Object? incoming) {
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

  /// Checks whether the given [list] contains an element that is deeply equal
  /// to [item], using [_deepEquals] for comparison.
  ///
  /// This method performs a deep structural comparison instead of relying on
  /// reference equality or the default `==` operator. It is useful when the
  /// list may contain nested collections (lists, maps) or complex objects that
  /// should be compared by structure rather than by identity.
  ///
  /// The search is linear in time complexity (`O(n)`), as each element is
  /// compared to [item] using deep equality.
  ///
  /// ### Returns
  /// `true` if any element in [list] is deeply equal to [item]; otherwise `false`.
  bool _containsDeep(List list, Object? item) {
    for (final e in list) {
      if (_deepEquals(e, item)) return true;
    }
    return false;
  }

  /// Recursively compares two objects for deep structural equality.
  ///
  /// This method supports deep equality for:
  /// - Primitive values (`==`)
  /// - Lists (element-by-element comparison)
  /// - Maps (key/value comparison)
  ///
  /// It gracefully handles:
  /// - Mixed list types (`List` vs `List<dynamic>`)
  /// - Mixed map types (`Map` vs `Map<dynamic, dynamic>`)
  /// - Cyclic references, using identity-based cycle detection to prevent
  ///   infinite recursion.
  ///
  /// Two objects are considered deeply equal when:
  /// - They are identical (`identical(a, b)`), or
  /// - They are both lists of the same length and each corresponding element is
  ///   deeply equal, or
  /// - They are both maps of the same size, containing identical key sets, and
  ///   each corresponding value is deeply equal.
  ///
  /// If the types differ but are both lists or both maps, the comparison still
  /// proceeds (based on structure, not exact generic type).
  ///
  /// ### Cycle Detection
  /// The optional sets [va] and [vb] track visited object identities for `a`
  /// and `b`. If both structures revisit the same identity chain, the comparison
  /// treats the cycle as equal.
  ///
  /// ### Returns
  /// `true` if the two objects are deeply structurally equal; otherwise `false`.
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

  /// Prepares and registers all resolved [EnvironmentSource] instances into the
  /// given [environment]'s `PropertySources` collection.
  ///
  /// This method is part of the environment bootstrapping phase and is responsible
  /// for translating each [EnvironmentSource]—including its flattened and merged
  /// properties—into actual property sources within the environment. Resolution,
  /// ordering, and scoping rules are all applied here.
  ///
  /// The process occurs in three stages:
  ///
  /// 1. **Resolve and install property sources**
  ///    - Each [EnvironmentSource] is resolved using [resolveProperties], allowing
  ///      placeholder resolution and cross-source references.
  ///    - Resolved properties are inserted into the target `PropertySources` via
  ///      [`DefaultPropertiesPropertySource.addOrMerge`], keyed by the source’s
  ///      profile name.
  ///
  /// 2. **Prioritize profiled/package-aware sources**
  ///    - Sources that correspond directly to known profiles are moved to the
  ///      *front* of the property sources list.
  ///    - This ensures that root-package and user-defined profiles take precedence
  ///      over system, library, or fallback sources.
  ///
  /// 3. **Demote all remaining sources**
  ///    - Any property sources not matched in step 2 are appended to the end of the
  ///      chain, giving them the lowest precedence.
  ///
  /// ### Ordering Behavior
  ///
  /// Final precedence (highest → lowest) is therefore:
  /// 1. Profiled and package-sorted `EnvironmentSource` entries  
  /// 2. All other property sources discovered or added earlier in boot
  ///
  /// ### Parameters
  /// - `sources`: The list of fully merged and flattened environment sources.
  /// - `environment`: The environment into which resolved properties are installed.
  ///
  /// ### Notes
  /// - The method assumes that [sources] have already been grouped and merged by
  ///   profile using `getEnvironmentSources`.
  /// - The ordering strategy mirrors JetLeaf's package-aware configuration loading
  ///   model.
  ///
  /// ### Internal Use
  /// This method is marked `@protected` and is intended for framework internals
  /// and advanced environment customizers.
  @protected
  void prepareEnvironmentSources(List<EnvironmentSource> sources, ConfigurableEnvironment environment) {
    final propertySources = environment.getPropertySources();

    for (final source in sources) {
      final resolvedProperties = resolveProperties(source.properties, environment, sources);
      DefaultPropertiesPropertySource.addOrMerge(resolvedProperties, propertySources, source.profile);
    }

    final added = <String>{};

    // Prioritize the profiled and package-aware sources.
    for (final propertySource in propertySources) {
      final source = sources.find((src) => src.profile.equals(propertySource.getName()));
      if (source != null) {
        added.add(propertySource.getName());
        environment.getPropertySources().addFirst(propertySource);
      }
    }

    // Move other sources to the last level
    for (final propertySource in propertySources) {
      if (added.add(propertySource.getName())) {
        environment.getPropertySources().addLast(propertySource);
      }
    }
  }

  // We need to resolve all dynamic values like ${} #{}
  Map<String, Object> resolveProperties(Map<String, Object> properties, ConfigurableEnvironment environment, List<EnvironmentSource> sources) {
    return properties;
  }
}