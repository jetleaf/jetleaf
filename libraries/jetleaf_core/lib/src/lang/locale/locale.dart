import '../exceptions.dart';

part '_locale.dart';

/// {@template locale}
/// A representation of a locale, consisting of a language code and optional
/// country and variant codes.
///
/// Useful for internationalization (i18n) and localization (l10n),
/// supporting language tags like `"en"`, `"en-US"`, or `"fr-FR-Paris"`.
/// The locale follows the pattern: `language[-country[-variant]]`.
///
/// ## Usage
///
/// Create a locale with just a language:
/// ```dart
/// final locale = Locale('en');
/// print(locale.getLanguageTag()); // Output: "en"
/// ```
///
/// Create a locale with language and country:
/// ```dart
/// final locale = Locale('en', 'US');
/// print(locale.getLanguageTag()); // Output: "en-US"
/// ```
///
/// Create a locale with language, country, and variant:
/// ```dart
/// final locale = Locale('fr', 'FR', 'Paris');
/// print(locale.getLanguageTag()); // Output: "fr-FR-Paris"
/// ```
///
/// Parse a locale from a string:
/// ```dart
/// final locale = Locale.parse('es-MX');
/// print(locale.getLanguage()); // Output: "es"
/// print(locale.getCountry()); // Output: "MX"
/// ```
///
/// ## Validation
///
/// The class automatically validates and normalizes input:
/// - Language codes are converted to lowercase and must be 2-3 characters
/// - Country codes are converted to uppercase and must be exactly 2 characters
/// - Variants must contain only word characters and hyphens
///
/// Invalid inputs will throw [InvalidFormatException].
/// {@endtemplate}
abstract class Locale {
  /// {@template get_language_tag_method}
  /// Returns the full language tag (`language[-country[-variant]]`).
  /// 
  /// This method constructs the complete locale identifier by combining
  /// the language, country (if present), and variant (if present) with
  /// hyphens as separators.
  /// 
  /// Example:
  /// ```dart
  /// final locale1 = Locale('en');
  /// print(locale1.getLanguageTag()); // Output: "en"
  /// 
  /// final locale2 = Locale('en', 'US');
  /// print(locale2.getLanguageTag()); // Output: "en-US"
  /// 
  /// final locale3 = Locale('fr', 'FR', 'Paris');
  /// print(locale3.getLanguageTag()); // Output: "fr-FR-Paris"
  /// ```
  /// {@endtemplate}
  String getLanguageTag();

  /// {@template get_language_method}
  /// Returns the language code of this locale.
  /// 
  /// The language code is always normalized to lowercase and represents
  /// the ISO 639 language identifier.
  /// 
  /// Example:
  /// ```dart
  /// final locale = Locale('EN', 'us');
  /// print(locale.getLanguage()); // Output: "en"
  /// ```
  /// {@endtemplate}
  String getLanguage();

  /// {@template get_country_method}
  /// Returns the country code of this locale, or null if not specified.
  /// 
  /// The country code is always normalized to uppercase and represents
  /// the ISO 3166 country identifier.
  /// 
  /// Example:
  /// ```dart
  /// final locale1 = Locale('en', 'us');
  /// print(locale1.getCountry()); // Output: "US"
  /// 
  /// final locale2 = Locale('fr');
  /// print(locale2.getCountry()); // Output: null
  /// ```
  /// {@endtemplate}
  String? getCountry();

  /// {@template get_variant_method}
  /// Returns the variant of this locale, or null if not specified.
  /// 
  /// The variant provides additional specificity beyond language and country,
  /// useful for regional dialects or specialized locale requirements.
  /// 
  /// Example:
  /// ```dart
  /// final locale1 = Locale('en', 'US', 'POSIX');
  /// print(locale1.getVariant()); // Output: "POSIX"
  /// 
  /// final locale2 = Locale('en', 'US');
  /// print(locale2.getVariant()); // Output: null
  /// ```
  /// {@endtemplate}
  String? getVariant();

  /// {@template get_normalized_language_method}
  /// Returns normalized language (lowercase).
  /// 
  /// This method ensures the language code is in the standard lowercase format,
  /// which is useful for consistent comparisons and storage.
  /// 
  /// Example:
  /// ```dart
  /// final locale = Locale('EN');
  /// print(locale.getNormalizedLanguage()); // Output: "en"
  /// ```
  /// {@endtemplate}
  String getNormalizedLanguage();

  /// {@template get_normalized_country_method}
  /// Returns normalized country (uppercase), or null if not specified.
  /// 
  /// This method ensures the country code is in the standard uppercase format,
  /// which is useful for consistent comparisons and storage.
  /// 
  /// Example:
  /// ```dart
  /// final locale1 = Locale('en', 'us');
  /// print(locale1.getNormalizedCountry()); // Output: "US"
  /// 
  /// final locale2 = Locale('fr');
  /// print(locale2.getNormalizedCountry()); // Output: null
  /// ```
  /// {@endtemplate}
  String? getNormalizedCountry();

  /// {@template get_normalized_variant_method}
  /// Returns normalized variant (uppercase), or null if not specified.
  /// 
  /// This method ensures the variant is in uppercase format for consistency,
  /// though variants can contain various characters including hyphens.
  /// 
  /// Example:
  /// ```dart
  /// final locale1 = Locale('en', 'US', 'posix');
  /// print(locale1.getNormalizedVariant()); // Output: "POSIX"
  /// 
  /// final locale2 = Locale('en', 'US');
  /// print(locale2.getNormalizedVariant()); // Output: null
  /// ```
  /// {@endtemplate}
  String? getNormalizedVariant();

  /// {@template has_country_method}
  /// Returns true if the locale has a country code.
  /// 
  /// This method checks whether a country code was specified during
  /// locale creation and is not empty.
  /// 
  /// Example:
  /// ```dart
  /// final locale1 = Locale('en', 'US');
  /// print(locale1.hasCountry()); // Output: true
  /// 
  /// final locale2 = Locale('fr');
  /// print(locale2.hasCountry()); // Output: false
  /// ```
  /// {@endtemplate}
  bool hasCountry();

  /// {@template has_variant_method}
  /// Returns true if the locale has a variant.
  /// 
  /// This method checks whether a variant was specified during
  /// locale creation and is not empty.
  /// 
  /// Example:
  /// ```dart
  /// final locale1 = Locale('en', 'US', 'POSIX');
  /// print(locale1.hasVariant()); // Output: true
  /// 
  /// final locale2 = Locale('en', 'US');
  /// print(locale2.hasVariant()); // Output: false
  /// ```
  /// {@endtemplate}
  bool hasVariant();

  /// {@template is_default_method}
  /// Returns true if this is the default locale.
  /// 
  /// This method compares the current locale with [DEFAULT_LOCALE]
  /// to determine if they are equivalent.
  /// 
  /// Example:
  /// ```dart
  /// final locale1 = Locale('en', 'US');
  /// print(locale1.isDefault()); // Output: true
  /// 
  /// final locale2 = Locale('fr', 'FR');
  /// print(locale2.isDefault()); // Output: false
  /// ```
  /// {@endtemplate}
  bool isDefault();

  /// {@template copy_with_method}
  /// Copy this locale with optional replacements.
  /// 
  /// This method creates a new [Locale] instance based on the current one,
  /// allowing you to override specific components while keeping others unchanged.
  /// 
  /// Parameters:
  /// - [language]: New language code (optional)
  /// - [country]: New country code (optional)
  /// - [variant]: New variant (optional)
  /// 
  /// Example:
  /// ```dart
  /// final original = Locale('en', 'US', 'POSIX');
  /// 
  /// // Change only the country
  /// final modified1 = original.copyWith(country: 'CA');
  /// print(modified1.getLanguageTag()); // Output: "en-CA-POSIX"
  /// 
  /// // Change language and remove variant
  /// final modified2 = original.copyWith(language: 'fr', variant: null);
  /// print(modified2.getLanguageTag()); // Output: "fr-US"
  /// ```
  /// {@endtemplate}
  Locale copyWith({String? language, String? country, String? variant});

  /// {@template compare_to_method}
  /// Compare locales for sorting.
  /// 
  /// This method implements [Comparable] interface to enable sorting
  /// of locale collections. Comparison is done hierarchically:
  /// 1. First by language code
  /// 2. Then by country code (empty treated as empty string)
  /// 3. Finally by variant (empty treated as empty string)
  /// 
  /// Returns:
  /// - Negative value if this locale comes before [other]
  /// - Zero if locales are equal
  /// - Positive value if this locale comes after [other]
  /// 
  /// Example:
  /// ```dart
  /// final locales = [
  ///   Locale('fr', 'FR'),
  ///   Locale('en', 'US'),
  ///   Locale('en', 'CA'),
  /// ];
  /// 
  /// locales.sort((a, b) => a.compareTo(b));
  /// // Result: [en-CA, en-US, fr-FR]
  /// ```
  /// {@endtemplate}
  int compareTo(Locale other);

  /// {@template matches_method}
  /// Check if this locale matches another (optionally ignoring variant).
  /// 
  /// This method performs a flexible comparison between locales, allowing
  /// you to ignore the variant component for broader matching. Useful
  /// for finding compatible locales in internationalization scenarios.
  /// 
  /// Parameters:
  /// - [other]: The locale to compare against
  /// - [ignoreVariant]: Whether to ignore variant differences (default: true)
  /// 
  /// Example:
  /// ```dart
  /// final locale1 = Locale('en', 'US', 'POSIX');
  /// final locale2 = Locale('en', 'US', 'UTF8');
  /// final locale3 = Locale('en', 'CA');
  /// 
  /// // Matches ignoring variant (default)
  /// print(locale1.matches(locale2)); // Output: true
  /// 
  /// // Exact match including variant
  /// print(locale1.matches(locale2, ignoreVariant: false)); // Output: false
  /// 
  /// // Different countries don't match
  /// print(locale1.matches(locale3)); // Output: false
  /// ```
  /// {@endtemplate}
  bool matches(Locale other, {bool ignoreVariant = true});

  /// {@template to_map_method}
  /// Convert to map (useful for JSON serialization).
  /// 
  /// This method creates a Map representation of the locale, which is
  /// particularly useful for JSON serialization, database storage,
  /// or API communication.
  /// 
  /// Returns a Map with keys 'language', 'country', and 'variant'.
  /// Country and variant may be null if not specified.
  /// 
  /// Example:
  /// ```dart
  /// final locale = Locale('en', 'US', 'POSIX');
  /// final map = locale.toJson();
  /// print(map);
  /// // Output: {language: en, country: US, variant: POSIX}
  /// 
  /// // Convert to JSON
  /// import 'dart:convert';
  /// final json = jsonEncode(map);
  /// print(json); // Output: {"language":"en","country":"US","variant":"POSIX"}
  /// ```
  /// {@endtemplate}
  Map<String, String?> toJson();

  /// {@macro locale}
  factory Locale(String language, [String? country, String? variant]) => _Locale(language, country, variant);

  /// {@template default_locale}
  /// The default locale for the system or application (`en-US`).
  /// 
  /// This static field provides a fallback locale that can be used
  /// when no specific locale is available or when initializing
  /// internationalization systems.
  /// 
  /// Example:
  /// ```dart
  /// final defaultLocale = Locale.DEFAULT_LOCALE;
  /// print(defaultLocale.getLanguageTag()); // Output: "en-US"
  /// 
  /// // Check if a locale is the default
  /// final myLocale = Locale('en', 'US');
  /// print(myLocale.isDefault()); // Output: true
  /// ```
  /// {@endtemplate}
  static Locale DEFAULT_LOCALE = Locale('en', 'US');

  /// {@template parse_method}
  /// Parses a locale string of the form `"language[-country[-variant]]"`.
  /// 
  /// This factory method creates a [Locale] instance from a string representation.
  /// The string should follow the standard locale format with components
  /// separated by hyphens.
  /// 
  /// Throws [InvalidFormatException] if the locale string is empty or invalid.
  /// 
  /// Example:
  /// ```dart
  /// // Parse language only
  /// final locale1 = Locale.parse('en');
  /// print(locale1.getLanguageTag()); // Output: "en"
  /// 
  /// // Parse language and country
  /// final locale2 = Locale.parse('fr-CA');
  /// print(locale2.getLanguage()); // Output: "fr"
  /// print(locale2.getCountry()); // Output: "CA"
  /// 
  /// // Parse language, country, and variant
  /// final locale3 = Locale.parse('de-DE-Bavaria');
  /// print(locale3.getVariant()); // Output: "Bavaria"
  /// ```
  /// {@endtemplate}
  static Locale parse(String localeString) => _Locale.parse(localeString);

  /// {@template from_map_factory}
  /// Create a Locale from a map.
  /// 
  /// This factory constructor creates a [Locale] instance from a Map,
  /// which is useful for deserializing from JSON, database records,
  /// or API responses.
  /// 
  /// The map must contain a 'language' key with a non-null value.
  /// 'country' and 'variant' keys are optional.
  /// 
  /// Throws [InvalidFormatException] if the language key is missing or null.
  /// 
  /// Example:
  /// ```dart
  /// // From a simple map
  /// final map1 = {'language': 'en', 'country': 'US'};
  /// final locale1 = Locale.fromMap(map1);
  /// print(locale1.getLanguageTag()); // Output: "en-US"
  /// 
  /// // From JSON
  /// import 'dart:convert';
  /// final json = '{"language":"fr","country":"CA","variant":"Quebec"}';
  /// final map2 = jsonDecode(json) as Map<String, String?>;
  /// final locale2 = Locale.fromMap(map2);
  /// print(locale2.getLanguageTag()); // Output: "fr-CA-Quebec"
  /// ```
  /// {@endtemplate}
  factory Locale.fromMap(Map<String, String?> map) {
    if (map['language'] == null) {
      throw InvalidFormatException('Language is required in map');
    }
    return Locale(map['language']!, map['country'], map['variant']);
  }

  @override
  String toString() => getLanguageTag();
}