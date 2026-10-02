import '../exceptions.dart';
import 'locale.dart';

part '_language_range.dart';

/// {@template language_range}
/// Represents a language range as defined in RFC 4647.
///
/// A language range is a sequence of language subtags separated by hyphens,
/// used to match against language tags. It supports both basic filtering
/// (exact matching) and lookup (finding the best match).
///
/// Language ranges follow the format: `language[-subtag[-subtag...]]`
/// where subtags can be specific language variants, regions, or scripts.
///
/// ## Usage
///
/// Create a language range:
/// ```dart
/// final range = LanguageRange('en-US');
/// print(range.getRange()); // Output: "en-us"
/// ```
///
/// Parse from string:
/// ```dart
/// final range = LanguageRange.parse('fr-CA-*');
/// ```
///
/// Check weight for matching:
/// ```dart
/// final range = LanguageRange('en', weight: 0.9);
/// print(range.getWeight()); // Output: 0.9
/// ```
///
/// Match against locales:
/// ```dart
/// final range = LanguageRange('en');
/// final locale = Locale('en', 'US');
/// print(range.matches(locale)); // Output: true
/// ```
///
/// ## RFC 4647 Compliance
///
/// This class implements RFC 4647 language range matching with support for:
/// - Basic filtering (exact subtag matching)
/// - Lookup (finding the best single match)
/// - Wildcard matching with `*` suffix
/// - Weight-based preference matching
///
/// {@endtemplate}
abstract class LanguageRange {
  /// The max weight
  static const double MAX_WEIGHT = 1.0;

  /// {@template get_range_method}
  /// Returns the language range as a string in lowercase format.
  ///
  /// Example:
  /// ```dart
  /// final range = LanguageRange('en-US-x-twain');
  /// print(range.getRange()); // Output: "en-us-x-twain"
  /// ```
  /// {@endtemplate}
  String getRange();

  /// {@template get_weight_method}
  /// Returns the weight of this language range (0.0 to 1.0).
  ///
  /// The weight indicates the preference level for this range when
  /// matching against available locales. Higher weights are preferred.
  ///
  /// Example:
  /// ```dart
  /// final range1 = LanguageRange('en', weight: 1.0);
  /// final range2 = LanguageRange('fr', weight: 0.5);
  /// print(range1.getWeight()); // Output: 1.0
  /// print(range2.getWeight()); // Output: 0.5
  /// ```
  /// {@endtemplate}
  double getWeight();

  /// {@template is_wildcard_method}
  /// Returns true if this language range ends with `*` (wildcard).
  ///
  /// A wildcard range matches any language that starts with the prefix.
  ///
  /// Example:
  /// ```dart
  /// final range1 = LanguageRange('en-*');
  /// final range2 = LanguageRange('en-US');
  /// print(range1.isWildcard()); // Output: true
  /// print(range2.isWildcard()); // Output: false
  /// ```
  /// {@endtemplate}
  bool isWildcard();

  /// {@template matches_method}
  /// Check if this language range matches a given language tag or Locale.
  ///
  /// This performs RFC 4647 basic filtering: the range matches the tag if
  /// it exactly equals the tag, or if it exactly equals a prefix of the tag
  /// such that the first character following the prefix is "-".
  ///
  /// Example:
  /// ```dart
  /// final range = LanguageRange('en');
  /// print(range.matches('en')); // Output: true
  /// print(range.matches('en-US')); // Output: true
  /// print(range.matches('en-US-x-twain')); // Output: true
  /// print(range.matches('fr')); // Output: false
  /// print(range.matches('eng')); // Output: false
  /// ```
  /// {@endtemplate}
  bool matches(dynamic languageTag);

  /// {@template get_matching_subtags_method}
  /// Get all subtags from this language range.
  ///
  /// Returns a list of all subtag components separated by hyphens.
  ///
  /// Example:
  /// ```dart
  /// final range = LanguageRange('en-US-x-twain');
  /// print(range.getMatchingSubtags()); // Output: ['en', 'us', 'x', 'twain']
  /// ```
  /// {@endtemplate}
  List<String> getMatchingSubtags();

  /// {@template get_prefix_range_method}
  /// Get a prefix language range by removing the last subtag.
  ///
  /// Useful for fallback matching - if exact match fails, try matching
  /// with a shorter prefix.
  ///
  /// Example:
  /// ```dart
  /// final range = LanguageRange('en-US-x-twain');
  /// final prefix = range.getPrefixRange();
  /// print(prefix.getRange()); // Output: "en-us-x"
  /// ```
  /// {@endtemplate}
  LanguageRange? getPrefixRange();

  /// {@template lookup_method}
  /// Perform RFC 4647 lookup matching against available language tags.
  ///
  /// Lookup returns the single best match among available tags, or null
  /// if no match is found. For each range, tries exact match first, then
  /// progressively shorter prefixes.
  ///
  /// Parameters:
  /// - [availableTags]: List of language tags to search against
  /// - [defaultLocale]: Fallback locale if no match found (optional)
  ///
  /// Example:
  /// ```dart
  /// final range = LanguageRange('en-US-x-twain');
  /// final available = ['en-US', 'en-GB', 'fr-FR', 'de-DE'];
  /// print(range.lookup(available)); // Output: "en-us"
  /// ```
  /// {@endtemplate}
  String? lookup(List<String> availableTags, {String? defaultLocale});

  /// {@template filter_method}
  /// Perform RFC 4647 basic filtering against available language tags.
  ///
  /// Returns all tags that match this language range, maintaining order.
  /// All matching tags are returned, not just the best match.
  ///
  /// Example:
  /// ```dart
  /// final range = LanguageRange('en');
  /// final available = ['en', 'en-US', 'en-GB', 'fr-FR'];
  /// print(range.filter(available)); // Output: ['en', 'en-us', 'en-gb']
  /// ```
  /// {@endtemplate}
  List<String> filter(List<String> availableTags);

  /// {@template to_locale_method}
  /// Convert this language range to a Locale object.
  ///
  /// Extracts language and country from the range to create a Locale.
  /// If the range has only one subtag, only language is set.
  ///
  /// Example:
  /// ```dart
  /// final range = LanguageRange('en-US');
  /// final locale = range.toLocale();
  /// print(locale.getLanguageTag()); // Output: "en-us"
  /// ```
  /// {@endtemplate}
  Locale toLocale();

  /// {@template constructor}
  /// Creates a new language range.
  ///
  /// Parameters:
  /// - [range]: The language range string (e.g., "en", "en-US", "en-*")
  /// - [weight]: Optional weight for preference matching (0.0 to 1.0, default: 1.0)
  ///
  /// Throws [InvalidFormatException] if range is invalid.
  /// {@endtemplate}
  factory LanguageRange(String range, {double weight = 1.0}) => _LanguageRange(range, weight);

  /// {@template parse_method}
  /// Parses a language range string that may include weight.
  ///
  /// Format: `language-range[;q=weight]`
  /// Weight format follows HTTP Accept-Language header convention.
  ///
  /// Example:
  /// ```dart
  /// final range1 = LanguageRange.parse('en-US;q=0.9');
  /// print(range1.getWeight()); // Output: 0.9
  ///
  /// final range2 = LanguageRange.parse('fr');
  /// print(range2.getWeight()); // Output: 1.0
  /// ```
  /// {@endtemplate}
  static LanguageRange parse(String rangeString) => _LanguageRange.parse(rangeString);

  /// {@template parse_list_method}
  /// Parse a comma-separated list of language ranges (from Accept-Language header).
  ///
  /// Automatically sorts by weight (descending) for priority matching.
  ///
  /// Example:
  /// ```dart
  /// final ranges = LanguageRange.parseList('en-US;q=0.9, fr;q=0.8, de');
  /// // Returns: [de (1.0), en-us (0.9), fr (0.8)]
  /// ```
  /// {@endtemplate}
  static List<LanguageRange> parseList(String rangeListString) => _LanguageRange.parseList(rangeListString);

  @override
  String toString() => getRange();
}