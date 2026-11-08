import '../locale/locale.dart';
import '../exceptions.dart';
import 'currency_database.dart';

part '_currency.dart';

/// {@template currency}
/// Abstract base class for currency operations following ISO 4217 standards.
///
/// This class provides a common interface for all currency types and
/// includes static methods to manage and retrieve currency instances
/// according to ISO 4217 codes or locale information.
///
/// Use this class to:
/// - Retrieve currency instances by code or locale.
/// - Access currency metadata such as symbol, numeric code, or display name.
/// - Work with all available currencies in a consistent manner.
///
/// Example usage:
/// ```dart
/// // Get a currency by ISO code
/// final usd = Currency.getInstance('USD');
///
/// // Get a currency by locale
/// final eur = Currency.getInstanceFromLocale(Locale('de', 'DE'));
///
/// // List all available currencies
/// final allCurrencies = Currency.getAllCurrencies();
///
/// // Access currency properties
/// print(usd.symbol); // $
/// print(eur.displayName); // Euro
/// ```
/// {@endtemplate}
abstract class Currency {
  /// The ISO 4217 currency code (e.g., "USD", "EUR", "GBP").
  String get currencyCode;

  /// The currency symbol (e.g., "$", "€", "£").
  String get symbol;

  /// The default number of fraction digits for this currency.
  int get defaultFractionDigits;

  /// The numeric code for this currency as defined by ISO 4217.
  int get numericCode;

  /// The display name of this currency in English.
  String get displayName;

  /// Cache for currency instances to ensure singleton behavior.
  static final Map<String, Currency> _currencyCache = <String, Currency>{};

  /// {@macro currency}
  ///
  /// Returns a [Currency] instance for the given ISO 4217 currency code.
  ///
  /// Throws [UnsupportedOperationException] if the currency code is invalid or unsupported.
  ///
  /// Example:
  /// ```dart
  /// final usd = Currency.getInstance('USD');
  /// final eur = Currency.getInstance('EUR');
  /// ```
  static Currency getInstance(String currencyCode) {
    if (currencyCode.isEmpty) {
      throw UnsupportedOperationException('Currency code cannot be empty');
    }

    final upperCode = currencyCode.toUpperCase();

    if (_currencyCache.containsKey(upperCode)) {
      return _currencyCache[upperCode]!;
    }

    final data = CurrencyDatabase.getCurrencyData(upperCode);
    if (data == null) {
      throw UnsupportedOperationException('Unsupported currency code: $currencyCode');
    }

    final currency = _Currency(
      currencyCode: upperCode,
      symbol: data['symbol'] as String,
      defaultFractionDigits: data['digits'] as int,
      numericCode: data['numeric'] as int,
      displayName: data['name'] as String,
    );

    _currencyCache[upperCode] = currency;
    return currency;
  }

  /// {@macro currency}
  ///
  /// Returns a [Currency] instance for the given [Locale].
  ///
  /// Determines the currency using the country code from the locale.
  /// Throws [UnsupportedOperationException] if the locale has no associated currency.
  ///
  /// Example:
  /// ```dart
  /// final usd = Currency.getInstanceFromLocale(Locale('en', 'US'));
  /// final eur = Currency.getInstanceFromLocale(Locale('de', 'DE'));
  /// ```
  static Currency getInstanceFromLocale(Locale locale) {
    if (locale.getCountry() == null) {
      throw UnsupportedOperationException('Locale must have a country code to determine currency');
    }

    final currencyCode = CurrencyDatabase.getCurrencyCodeForLocale(locale.getCountry()!);
    if (currencyCode == null) {
      throw UnsupportedOperationException('No currency found for locale: ${locale.getLanguageTag()}');
    }

    return getInstance(currencyCode);
  }

  /// Returns a set of all available ISO 4217 currency codes.
  ///
  /// Example:
  /// ```dart
  /// final codes = Currency.getAvailableCurrencies();
  /// print(codes.contains('USD')); // true
  /// ```
  static Set<String> getAvailableCurrencies() {
    return CurrencyDatabase.getAllCurrencyCodes();
  }

  /// Returns a list of all available [Currency] instances.
  ///
  /// Example:
  /// ```dart
  /// final currencies = Currency.getAllCurrencies();
  /// for (final currency in currencies) {
  ///   print('${currency.currencyCode}: ${currency.displayName}');
  /// }
  /// ```
  static List<Currency> getAllCurrencies() {
    return CurrencyDatabase.getAllCurrencyCodes()
        .map((code) => getInstance(code))
        .toList();
  }

  /// Returns true if the given currency code is supported.
  ///
  /// Example:
  /// ```dart
  /// print(Currency.isSupported('USD')); // true
  /// print(Currency.isSupported('XYZ')); // false
  /// ```
  static bool isSupported(String currencyCode) {
    return CurrencyDatabase.isSupported(currencyCode);
  }

  /// Returns the currency symbol, optionally localized by [locale].
  ///
  /// Falls back to the default symbol if no locale-specific version exists.
  ///
  /// Example:
  /// ```dart
  /// final usd = Currency.getInstance('USD');
  /// print(usd.getSymbol()); // $
  /// print(usd.getSymbol(Locale('es', 'MX'))); // US$
  /// print(usd.getSymbol(Locale('zh', 'CN'))); // 美元
  /// ```
  String getSymbol([Locale? locale]);

  /// Returns the display name, optionally localized by [locale].
  ///
  /// Falls back to the English display name if no locale-specific version exists.
  ///
  /// Example:
  /// ```dart
  /// final usd = Currency.getInstance('USD');
  /// print(usd.getDisplayName()); // US Dollar
  /// print(usd.getDisplayName(Locale('es', 'ES'))); // Dólar estadounidense
  /// print(usd.getDisplayName(Locale('zh', 'CN'))); // 美元
  /// ```
  String getDisplayName([Locale? locale]);

  /// Returns the currency code as the string representation.
  @override
  String toString() => currencyCode;

  /// Compares this currency to another for equality based on currency code.
  @override
  bool operator ==(Object other);

  /// Returns a hash code based on the currency code.
  @override
  int get hashCode;

  /// Compares this currency to another by currency code.
  ///
  /// Example:
  /// ```dart
  /// final usd = Currency.getInstance('USD');
  /// final eur = Currency.getInstance('EUR');
  /// print(usd.compareTo(eur)); // negative value
  /// ```
  int compareTo(Currency other) => currencyCode.compareTo(other.currencyCode);

  /// Returns a detailed string representation including all currency properties.
  ///
  /// Example:
  /// ```dart
  /// final usd = Currency.getInstance('USD');
  /// print(usd.toDetailedString());
  /// // Output: Currency(code: USD, symbol: $, digits: 2, numericCode: 840, displayName: US Dollar)
  /// ```
  String toDetailedString();

  /// Creates a copy of this currency with optional overrides.
  ///
  /// Example:
  /// ```dart
  /// final usd = Currency.getInstance('USD');
  /// final customUsd = usd.copyWith(symbol: 'US$');
  /// ```
  Currency copyWith({
    String? currencyCode,
    String? symbol,
    int? defaultFractionDigits,
    int? numericCode,
    String? displayName,
  });
}