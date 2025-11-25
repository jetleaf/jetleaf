/// {@template environment_source}
/// Represents a single raw source of environment configuration.
///
/// An [EnvironmentSource] is typically produced during environment loading
/// before any merging, resolution, or profile selection occurs. Multiple
/// sources may contribute to the final runtime environment, such as:
///
/// - `.env` files
/// - `application.yaml` / `application.json`
/// - profile-specific overlays (e.g., `application-dev.yaml`)
/// - external configuration providers
///
/// This class stores only the *raw* key/value pairs associated with a
/// particular profile, leaving interpretation and conflict resolution to
/// higher-level environment processors.
///
/// ### Example
/// ```dart
/// final source = EnvironmentSource(
///   'dev',
///   {
///     'server.port': 8080,
///     'logging.level': 'debug',
///   },
/// );
///
/// print(source.profile); // → dev
/// print(source.properties['server.port']); // → 8080
/// ```
///
/// ### Design Notes
/// - Immutable and safe for reuse
/// - Does not merge or override values—represents only a single source
/// - Used by environment loaders before producing parsed/merged data
///
/// ### Related Types
/// - [ParsedEnvironmentData] — final merged representation
/// - `Environment` — runtime property resolution API
/// {@endtemplate}
final class EnvironmentSource {
  /// The profile associated with this configuration source.
  ///
  /// Common profile names include:
  /// - `"default"`
  /// - `"dev"`
  /// - `"prod"`
  /// - `"test"`
  ///
  /// Profiles allow selective activation and layered configuration behavior.
  final String profile;

  /// The raw key/value properties defined by this source.
  ///
  /// Keys are typically normalized dot-notation identifiers, e.g.:
  /// - `"server.port"`
  /// - `"feature.cache.enabled"`
  /// - `"logging.level.jetleaf"`
  ///
  /// Values may be:
  /// - `String`, `num`, or `bool`
  /// - lists or nested maps depending on the file format
  ///
  /// No transformation, interpolation, or resolution is applied at this stage.
  final Map<String, Object> properties;

  /// Creates a new immutable environment configuration source.
  ///
  /// Both [profile] and [properties] must be provided and will not be modified
  /// after construction.
  const EnvironmentSource(this.profile, this.properties);
}

/// {@template parsed_environment_data}
/// Represents the fully parsed result of an environment configuration source.
///
/// The [ParsedEnvironmentSource] model encapsulates the resolved environment
/// metadata extracted from YAML, JSON, `.env`, or other configuration inputs
/// during application bootstrap.
///
/// It is typically produced by environment parsers and consumed by:
/// - `Environment` initialization
/// - profile activation logic
/// - property resolution and merging
///
/// ### Purpose
/// This structure provides a normalized representation that:
/// - isolates configuration per package/module
/// - associates a specific active profile (e.g., `dev`, `prod`)
/// - exposes concrete key/value properties for lookup
///
/// ### Example
/// ```dart
/// final data = ParsedEnvironmentData(
///   'jetleaf_core',
///   'dev',
///   {'server.port': 8080, 'cache.enabled': true},
/// );
///
/// print(data.profile); // → dev
/// print(data.properties['server.port']); // → 8080
/// ```
///
/// ### Design Notes
/// - Immutable and safely shareable across threads/isolates
/// - Does not perform resolution or interpolation—only stores parsed values
/// - May be merged by higher-level environment loaders
/// {@endtemplate}
final class ParsedEnvironmentSource extends EnvironmentSource {
  /// The package or module name associated with this environment data.
  ///
  /// Used to scope configuration so that multiple packages can contribute
  /// independent environment definitions without collision.
  ///
  /// Example: `jetleaf_web`, `jetleaf_cache`, or a user-defined package.
  final String packageName;

  /// Creates an immutable parsed environment representation.
  ///
  /// All fields must be provided and cannot be modified after construction.
  const ParsedEnvironmentSource(this.packageName, super.profile, super.properties);
}