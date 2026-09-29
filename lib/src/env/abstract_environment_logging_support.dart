import 'package:jetleaf_env/env.dart';
import 'package:jetleaf_lang/jetleaf_lang.dart';
import 'package:jetleaf_logging/jetleaf_logging.dart';
import 'package:meta/meta.dart';

import 'abstract_versioned_support.dart';
import 'models.dart';

/// Provides profile-aware logging configuration support during environment
/// initialization.
///
/// This abstract class extends [AbstractVersionedSupport] and contributes an
/// additional bootstrapping phase that aggregates and applies logging-related
/// properties from all profile-specific environment sources.
///
/// The logging properties processed by this class follow the key prefix
/// `"logging."` and are merged in a two-phase strategy:
///
/// 1. **Non-active profiles**  
///    Properties from profiles that are *not* currently active are applied
///    first. Their values are preserved in the order encountered—first match
///    wins.
///
/// 2. **Active profiles**  
///    Properties belonging to active profiles are then applied, in the exact
///    order defined by the environment. These properties override any previous
///    entries from non-active profiles.
///
/// The resolved set of logging properties is stored globally in
/// [LogProperties], making the merged configuration available to the entire
/// application.
///
/// Subclasses may extend this behavior to further customize logging
/// initialization logic.
abstract class AbstractEnvironmentLoggingSupport extends AbstractVersionedSupport {
  /// Collects and merges logging-related configuration from all provided
  /// [EnvironmentSource] instances and persists them into the global
  /// [LogProperties] registry.
  ///
  /// The merge behavior is profile-aware and follows a defined precedence:
  ///
  /// ### 1. Non-active profiles  
  /// All sources whose profile is *not* active are processed first.  
  /// Only keys beginning with `"logging."` are considered.  
  /// If multiple non-active profiles define the same key, the first encountered
  /// value is retained.
  ///
  /// ### 2. Active profiles  
  /// Active profiles are processed in their declared order from the environment.
  /// Logging keys from active profiles override previously collected values,
  /// ensuring that active profiles always take precedence.
  ///
  /// ### 3. Persisting  
  /// The final merged logging configuration is written into
  /// [LogProperties.instance], replacing any existing entries (`overwrite: true`).
  ///
  /// A debug log entry is emitted when logging configuration is successfully
  /// loaded.
  @protected
  void setupLoggingProperties(ConfigurableEnvironment environment, List<EnvironmentSource> sources) {
    // --- COPY logging.* properties into shared LogProperties (profile-aware) ----

    final activeProfiles = environment.getActiveProfiles();
    final activeSet = activeProfiles.toSet();

    // Collector for stringified logging props
    final Map<String, String> collected = {};

    // 1) Apply non-active profiles first (preserve entries)
    for (final source in sources) {
      final profile = source.profile;
      final props = source.properties;

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
      final source = sources.find((source) => source.profile.equals(profile));
      if (source == null) continue;
      source.properties.forEach((key, value) {
        if (!key.startsWith('logging.')) return;
        // active profile always wins (overwrites previous)
        collected[key] = value.toString();
      });
    }

    // 3) Persist into LogProperties (global registry)
    LogProperties.instance.setProperties(collected, overwrite: true);

    if (logger.getIsDebugEnabled()) {
      logger.debug('Loaded ${collected.length} logging properties from environment: ${collected.keys.toList()}');
    }
  }
}