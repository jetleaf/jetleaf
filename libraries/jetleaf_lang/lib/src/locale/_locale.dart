part of 'locale.dart';

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
class _Locale implements Locale {
  /// {@template locale_language_field}
  /// The ISO 639 language code (e.g., `"en"`, `"fr"`, `"es"`).
  /// 
  /// This field is automatically normalized to lowercase during construction.
  /// Must be 2-3 characters long and contain only letters.
  /// 
  /// Example:
  /// ```dart
  /// final locale = Locale('EN'); // Normalized to 'en'
  /// print(locale.getLanguage()); // Output: "en"
  /// ```
  /// {@endtemplate}
  String _language;

  /// {@template locale_country_field}
  /// The optional ISO 3166 country code (e.g., `"US"`, `"FR"`, `"NG"`).
  /// 
  /// This field is automatically normalized to uppercase during construction.
  /// Must be exactly 2 characters long if provided.
  /// 
  /// Example:
  /// ```dart
  /// final locale = Locale('en', 'us'); // Country normalized to 'US'
  /// print(locale.getCountry()); // Output: "US"
  /// ```
  /// {@endtemplate}
  String? _country;

  /// {@template locale_variant_field}
  /// An optional variant for additional locale granularity
  /// (e.g., `"POSIX"`, `"Paris"`).
  /// 
  /// Variants provide additional specificity beyond language and country.
  /// Must contain only word characters (letters, digits, underscore) and hyphens.
  /// 
  /// Example:
  /// ```dart
  /// final locale = Locale('en', 'US', 'POSIX');
  /// print(locale.getVariant()); // Output: "POSIX"
  /// ```
  /// {@endtemplate}
  String? _variant;

  /// {@macro locale}
  _Locale(this._language, [this._country, this._variant]) {
    final normalizedLang = _language.toLowerCase();
    final normalizedCountry = _country?.toUpperCase();

    if (normalizedLang.isEmpty || !RegExp(r'^[a-z]{2,3}$').hasMatch(normalizedLang)) {
      throw InvalidFormatException('Invalid language code: $_language');
    }

    if (normalizedCountry != null && (normalizedCountry.isEmpty || !RegExp(r'^[A-Z]{2}$').hasMatch(normalizedCountry))) {
      throw InvalidFormatException('Invalid country code: $_country');
    }

    if (_variant != null && (_variant!.isEmpty || !RegExp(r'^[\w-]+$').hasMatch(_variant!))) {
      throw InvalidFormatException('Invalid variant: $_variant');
    }

    _language = normalizedLang;
    if (_country != null) _country = normalizedCountry;
    if (_variant != null) _variant = _variant;
  }

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
  static _Locale parse(String localeString) {
    final parts = localeString.split('-');
    if (parts.isEmpty || parts[0].isEmpty) {
      throw InvalidFormatException('Invalid locale string: $localeString');
    }

    if (parts.length > 3) {
      throw InvalidFormatException('Invalid locale string: $localeString. Expected at most 3 parts separated by hyphens.');
    }

    return _Locale(
      parts[0],
      parts.length > 1 ? parts[1] : null,
      parts.length > 2 ? parts[2] : null,
    );
  }

  @override
  String getLanguageTag() {
    final buffer = StringBuffer(_language);
    if (_country != null) buffer.write('-$_country');
    if (_variant != null) buffer.write('-$_variant');
    return buffer.toString();
  }

  @override
  String getLanguage() => _language;

  @override
  String? getCountry() => _country;

  @override
  String? getVariant() => _variant;

  @override
  String getNormalizedLanguage() => _language.toLowerCase();

  @override
  String? getNormalizedCountry() => _country?.toUpperCase();

  @override
  String? getNormalizedVariant() => _variant?.toUpperCase();

  @override
  bool hasCountry() => _country != null && _country!.isNotEmpty;

  @override
  bool hasVariant() => _variant != null && _variant!.isNotEmpty;

  @override
  bool isDefault() => this == Locale.DEFAULT_LOCALE;

  @override
  Locale copyWith({String? language, String? country, String? variant}) {
    return Locale(
      language ?? _language,
      country ?? _country,
      variant ?? _variant,
    );
  }

  @override
  int compareTo(Locale other) {
    final langCompare = _language.compareTo(other.getLanguage());
    if (langCompare != 0) return langCompare;

    final countryCompare = (_country ?? '').compareTo(other.getCountry() ?? '');
    if (countryCompare != 0) return countryCompare;

    return (_variant ?? '').compareTo(other.getVariant() ?? '');
  }

  @override
  bool matches(Locale other, {bool ignoreVariant = true}) {
    if (getNormalizedLanguage() != other.getNormalizedLanguage()) return false;
    if (getNormalizedCountry() != other.getNormalizedCountry()) return false;
    if (!ignoreVariant && getNormalizedVariant() != other.getNormalizedVariant()) return false;
    return true;
  }

  @override
  Map<String, String?> toJson() => {
    'language': _language,
    'country': _country,
    'variant': _variant,
  };

  @override
  String toString() => getLanguageTag();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Locale &&
          other.getLanguage() == _language &&
          other.getCountry() == _country &&
          other.getVariant() == _variant;

  @override
  int get hashCode => Object.hash(_language, _country, _variant);
}