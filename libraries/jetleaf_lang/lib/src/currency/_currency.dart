part of 'currency.dart';

/// {@template _currency}
/// Private implementation class for Currency that contains all the actual
/// currency data and behavior. This class implements the abstract Currency
/// interface and provides the concrete functionality.
/// {@endtemplate}
class _Currency extends Currency {
  @override
  final String currencyCode;

  @override
  final String symbol;

  @override
  final int defaultFractionDigits;

  @override
  final int numericCode;

  @override
  final String displayName;

  /// {@macro _currency}
  _Currency({
    required this.currencyCode,
    required this.symbol,
    required this.defaultFractionDigits,
    required this.numericCode,
    required this.displayName,
  });

  @override
  String getSymbol([Locale? locale]) {
    if (locale != null) {
      // Try to get locale-specific symbol
      final localeSpecificSymbol = CurrencyDatabase.getLocaleSpecificSymbol(
        currencyCode, 
        locale.getLanguageTag(),
      );
      if (localeSpecificSymbol != null) {
        return localeSpecificSymbol;
      }

      // Try with just getLanguage() code if full locale tag doesn't work
      final languageSpecificSymbol = CurrencyDatabase.getLocaleSpecificSymbol(
        currencyCode, 
        locale.getLanguage(),
      );
      if (languageSpecificSymbol != null) {
        return languageSpecificSymbol;
      }
    }

    // Fall back to default symbol
    return symbol;
  }

  @override
  String getDisplayName([Locale? locale]) {
    if (locale != null) {
      // Try to get locale-specific display name
      final localeSpecificName = CurrencyDatabase.getLocaleSpecificName(
        currencyCode, 
        locale.getLanguageTag(),
      );
      if (localeSpecificName != null) {
        return localeSpecificName;
      }

      // Try with just getLanguage() code if full locale tag doesn't work
      final languageSpecificName = CurrencyDatabase.getLocaleSpecificName(
        currencyCode, 
        locale.getLanguage(),
      );
      if (languageSpecificName != null) {
        return languageSpecificName;
      }
    }

    // Fall back to default English display name
    return displayName;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Currency && other.currencyCode == currencyCode;
  }

  @override
  int get hashCode => currencyCode.hashCode;

  @override
  String toDetailedString() {
    return 'Currency{code: $currencyCode, symbol: $symbol, digits: $defaultFractionDigits, numeric: $numericCode, name: $displayName}';
  }

  @override
  Currency copyWith({
    String? currencyCode,
    String? symbol,
    int? defaultFractionDigits,
    int? numericCode,
    String? displayName,
  }) {
    return _Currency(
      currencyCode: currencyCode ?? this.currencyCode,
      symbol: symbol ?? this.symbol,
      defaultFractionDigits: defaultFractionDigits ?? this.defaultFractionDigits,
      numericCode: numericCode ?? this.numericCode,
      displayName: displayName ?? this.displayName,
    );
  }
}