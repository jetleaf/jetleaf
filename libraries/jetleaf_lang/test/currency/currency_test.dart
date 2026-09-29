import 'package:jetleaf_lang/lang.dart';
import 'package:test/test.dart';

void main() {
  group('Currency', () {
    group('getInstance', () {
      test('should return Currency instance for valid currency code', () {
        final usd = Currency.getInstance('USD');
        expect(usd.currencyCode, 'USD');
        expect(usd.symbol, '\$');
        expect(usd.defaultFractionDigits, 2);
        expect(usd.numericCode, 840);
        expect(usd.displayName, 'US Dollar');
      });

      test('should return same instance for same currency code (singleton)', () {
        final usd1 = Currency.getInstance('USD');
        final usd2 = Currency.getInstance('USD');
        expect(identical(usd1, usd2), isTrue);
      });

      test('should handle lowercase currency codes', () {
        final eur = Currency.getInstance('eur');
        expect(eur.currencyCode, 'EUR');
        expect(eur.symbol, '€');
      });

      test('should throw UnsupportedOperationException for empty currency code', () {
        expect(() => Currency.getInstance(''), throwsA(isA<UnsupportedOperationException>()));
      });

      test('should throw UnsupportedOperationException for unsupported currency code', () {
        expect(() => Currency.getInstance('XYZ'), throwsA(isA<UnsupportedOperationException>()));
      });

      test('should handle all major currencies', () {
        final currencies = ['USD', 'EUR', 'GBP', 'JPY', 'CHF', 'CAD', 'AUD'];
        for (final code in currencies) {
          final currency = Currency.getInstance(code);
          expect(currency.currencyCode, code);
          expect(currency.symbol.isNotEmpty, isTrue);
          expect(currency.displayName.isNotEmpty, isTrue);
        }
      });
    });

    group('getInstanceFromLocale', () {
      test('should return USD for US locale', () {
        final currency = Currency.getInstanceFromLocale(Locale('en', 'US'));
        expect(currency.currencyCode, 'USD');
      });

      test('should return EUR for German locale', () {
        final currency = Currency.getInstanceFromLocale(Locale('de', 'DE'));
        expect(currency.currencyCode, 'EUR');
      });

      test('should return GBP for UK locale', () {
        final currency = Currency.getInstanceFromLocale(Locale('en', 'GB'));
        expect(currency.currencyCode, 'GBP');
      });

      test('should return JPY for Japanese locale', () {
        final currency = Currency.getInstanceFromLocale(Locale('ja', 'JP'));
        expect(currency.currencyCode, 'JPY');
      });

      test('should handle various European countries with EUR', () {
        final euroCountries = ['DE', 'FR', 'IT', 'ES', 'NL', 'BE', 'AT'];
        for (final country in euroCountries) {
          final currency = Currency.getInstanceFromLocale(Locale('en', country));
          expect(currency.currencyCode, 'EUR');
        }
      });

      test('should throw UnsupportedOperationException for locale without country', () {
        expect(() => Currency.getInstanceFromLocale(Locale('en')), throwsA(isA<UnsupportedOperationException>()));
      });

      test('should throw UnsupportedOperationException for unsupported country', () {
        expect(() => Currency.getInstanceFromLocale(Locale('en', 'XX')), throwsA(isA<UnsupportedOperationException>()));
      });
    });

    group('getAvailableCurrencies', () {
      test('should return non-empty set of currency codes', () {
        final currencies = Currency.getAvailableCurrencies();
        expect(currencies.isNotEmpty, isTrue);
        expect(currencies.contains('USD'), isTrue);
        expect(currencies.contains('EUR'), isTrue);
        expect(currencies.contains('GBP'), isTrue);
      });

      test('should return unmodifiable set', () {
        final currencies = Currency.getAvailableCurrencies();
        expect(() => currencies.add('TEST'), throwsUnsupportedError);
      });

      test('should contain all major world currencies', () {
        final currencies = Currency.getAvailableCurrencies();
        final majorCurrencies = [
          'USD', 'EUR', 'GBP', 'JPY', 'CHF', 'CAD', 'AUD', 'NZD',
          'CNY', 'INR', 'KRW', 'BRL', 'MXN', 'ZAR', 'RUB'
        ];
        for (final code in majorCurrencies) {
          expect(currencies.contains(code), isTrue, reason: 'Missing currency: $code');
        }
      });
    });

    group('getAllCurrencies', () {
      test('should contain USD and EUR', () {
        final currencies = Currency.getAllCurrencies();
        final codes = currencies.map((c) => c.currencyCode).toSet();
        expect(codes.contains('USD'), isTrue);
        expect(codes.contains('EUR'), isTrue);
      });

      test('should have same length as available currencies', () {
        final allCurrencies = Currency.getAllCurrencies();
        final availableCodes = Currency.getAvailableCurrencies();
        expect(allCurrencies.length, availableCodes.length);
      });
    });

    group('isSupported', () {
      test('should return true for supported currencies', () {
        expect(Currency.isSupported('USD'), isTrue);
        expect(Currency.isSupported('EUR'), isTrue);
        expect(Currency.isSupported('GBP'), isTrue);
      });

      test('should return false for unsupported currencies', () {
        expect(Currency.isSupported('XYZ'), isFalse);
        expect(Currency.isSupported('ABC'), isFalse);
      });

      test('should handle case insensitive input', () {
        expect(Currency.isSupported('usd'), isTrue);
        expect(Currency.isSupported('Eur'), isTrue);
        expect(Currency.isSupported('gbp'), isTrue);
      });

      test('should return false for empty string', () {
        expect(Currency.isSupported(''), isFalse);
      });
    });

    group('getSymbol', () {
      test('should return correct symbols for major currencies', () {
        expect(Currency.getInstance('USD').getSymbol(), '\$');
        expect(Currency.getInstance('EUR').getSymbol(), '€');
        expect(Currency.getInstance('GBP').getSymbol(), '£');
        expect(Currency.getInstance('JPY').getSymbol(), '¥');
        expect(Currency.getInstance('INR').getSymbol(), '₹');
      });

      test('should return same symbol regardless of locale parameter', () {
        final usd = Currency.getInstance('USD');
        expect(usd.getSymbol(), usd.getSymbol(Locale('en', 'US')));
        expect(usd.getSymbol(), usd.getSymbol(Locale('fr', 'FR')));
      });
    });

    group('getDisplayName', () {
      test('should return correct display names', () {
        expect(Currency.getInstance('USD').getDisplayName(), 'US Dollar');
        expect(Currency.getInstance('EUR').getDisplayName(), 'Euro');
        expect(Currency.getInstance('GBP').getDisplayName(), 'British Pound Sterling');
        expect(Currency.getInstance('JPY').getDisplayName(), 'Japanese Yen');
      });

      test('should return same name regardless of locale parameter', () {
        final usd = Currency.getInstance('USD');
        expect(usd.getDisplayName(), usd.getDisplayName(Locale('en', 'US')));
        expect(usd.getDisplayName(), usd.getDisplayName(Locale('de', 'DE')));
      });
    });

    group('defaultFractionDigits', () {
      test('should return correct fraction digits for various currencies', () {
        expect(Currency.getInstance('USD').defaultFractionDigits, 2);
        expect(Currency.getInstance('EUR').defaultFractionDigits, 2);
        expect(Currency.getInstance('JPY').defaultFractionDigits, 0);
        expect(Currency.getInstance('KWD').defaultFractionDigits, 3);
        expect(Currency.getInstance('BHD').defaultFractionDigits, 3);
      });

      test('should handle zero fraction digits correctly', () {
        final zeroFractionCurrencies = ['JPY', 'KRW', 'VND', 'CLP', 'PYG'];
        for (final code in zeroFractionCurrencies) {
          if (Currency.isSupported(code)) {
            expect(Currency.getInstance(code).defaultFractionDigits, 0);
          }
        }
      });

      test('should handle three fraction digits correctly', () {
        final threeFractionCurrencies = ['KWD', 'BHD', 'OMR', 'JOD', 'TND'];
        for (final code in threeFractionCurrencies) {
          if (Currency.isSupported(code)) {
            expect(Currency.getInstance(code).defaultFractionDigits, 3);
          }
        }
      });
    });

    group('numericCode', () {
      test('should return correct numeric codes', () {
        expect(Currency.getInstance('USD').numericCode, 840);
        expect(Currency.getInstance('EUR').numericCode, 978);
        expect(Currency.getInstance('GBP').numericCode, 826);
        expect(Currency.getInstance('JPY').numericCode, 392);
      });

      test('should have unique numeric codes', () {
        final currencies = Currency.getAllCurrencies();
        final numericCodes = currencies.map((c) => c.numericCode).toSet();
        expect(numericCodes.length, currencies.length);
      });
    });

    group('equality and hashCode', () {
      test('should be equal for same currency code', () {
        final usd1 = Currency.getInstance('USD');
        final usd2 = Currency.getInstance('USD');
        expect(usd1, equals(usd2));
        expect(usd1.hashCode, equals(usd2.hashCode));
      });

      test('should not be equal for different currency codes', () {
        final usd = Currency.getInstance('USD');
        final eur = Currency.getInstance('EUR');
        expect(usd, isNot(equals(eur)));
        expect(usd.hashCode, isNot(equals(eur.hashCode)));
      });

      test('should not be equal to non-Currency objects', () {
        final usd = Currency.getInstance('USD');
        expect(usd, isNot(equals('USD')));
        expect(usd, isNot(equals(840)));
        expect(usd, isNot(equals(null)));
      });
    });

    group('toString', () {
      test('should return currency code', () {
        expect(Currency.getInstance('USD').toString(), 'USD');
        expect(Currency.getInstance('EUR').toString(), 'EUR');
        expect(Currency.getInstance('GBP').toString(), 'GBP');
      });
    });

    group('toDetailedString', () {
      test('should return detailed currency information', () {
        final usd = Currency.getInstance('USD');
        final detailed = usd.toDetailedString();
        expect(detailed, contains('USD'));
        expect(detailed, contains('\$'));
        expect(detailed, contains('2'));
        expect(detailed, contains('840'));
        expect(detailed, contains('US Dollar'));
      });

      test('should include all currency properties', () {
        final eur = Currency.getInstance('EUR');
        final detailed = eur.toDetailedString();
        expect(detailed, contains('code: EUR'));
        expect(detailed, contains('symbol: €'));
        expect(detailed, contains('digits: 2'));
        expect(detailed, contains('numeric: 978'));
        expect(detailed, contains('name: Euro'));
      });
    });

    group('compareTo', () {
      test('should compare currencies by currency code', () {
        final aud = Currency.getInstance('AUD');
        final usd = Currency.getInstance('USD');
        final eur = Currency.getInstance('EUR');
        
        expect(aud.compareTo(usd), lessThan(0)); // AUD < USD
        expect(usd.compareTo(aud), greaterThan(0)); // USD > AUD
        expect(eur.compareTo(eur), equals(0)); // EUR == EUR
      });

      test('should enable sorting of currencies', () {
        final currencies = [
          Currency.getInstance('USD'),
          Currency.getInstance('AUD'),
          Currency.getInstance('EUR'),
          Currency.getInstance('GBP'),
        ];
        
        currencies.sort((a, b) => a.compareTo(b));
        final codes = currencies.map((c) => c.currencyCode).toList();
        expect(codes, ['AUD', 'EUR', 'GBP', 'USD']);
      });
    });

    group('copyWith', () {
      test('should create copy with modified properties', () {
        final original = Currency.getInstance('USD');
        final copy = original.copyWith(symbol: 'US\$');
        
        expect(copy.currencyCode, original.currencyCode);
        expect(copy.symbol, 'US\$');
        expect(copy.defaultFractionDigits, original.defaultFractionDigits);
        expect(copy.numericCode, original.numericCode);
        expect(copy.displayName, original.displayName);
      });

      test('should create copy with all properties unchanged when no parameters', () {
        final original = Currency.getInstance('EUR');
        final copy = original.copyWith();
        
        expect(copy.currencyCode, original.currencyCode);
        expect(copy.symbol, original.symbol);
        expect(copy.defaultFractionDigits, original.defaultFractionDigits);
        expect(copy.numericCode, original.numericCode);
        expect(copy.displayName, original.displayName);
      });

      test('should create copy with multiple modified properties', () {
        final original = Currency.getInstance('GBP');
        final copy = original.copyWith(
          symbol: 'UK£',
          defaultFractionDigits: 3,
          displayName: 'UK Pound',
        );
        
        expect(copy.currencyCode, original.currencyCode);
        expect(copy.symbol, 'UK£');
        expect(copy.defaultFractionDigits, 3);
        expect(copy.numericCode, original.numericCode);
        expect(copy.displayName, 'UK Pound');
      });
    });

    group('comprehensive currency data validation', () {
      test('should have valid data for all currencies', () {
        final currencies = Currency.getAllCurrencies();
        
        for (final currency in currencies) {
          // Currency code should be 3 characters
          expect(currency.currencyCode.length, 3);
          expect(currency.currencyCode, equals(currency.currencyCode.toUpperCase()));
          
          // Symbol should not be empty
          expect(currency.symbol.isNotEmpty, isTrue);
          
          // Fraction digits should be valid
          expect(currency.defaultFractionDigits, inInclusiveRange(0, 4));
          
          // Numeric code should be positive
          expect(currency.numericCode, greaterThan(0));
          
          // Display name should not be empty
          expect(currency.displayName.isNotEmpty, isTrue);
        }
      });

      test('should handle edge cases for fraction digits', () {
        // Test currencies with 0 fraction digits
        if (Currency.isSupported('JPY')) {
          expect(Currency.getInstance('JPY').defaultFractionDigits, 0);
        }
        
        // Test currencies with 3 fraction digits
        if (Currency.isSupported('KWD')) {
          expect(Currency.getInstance('KWD').defaultFractionDigits, 3);
        }
      });

      test('should have consistent locale to currency mapping', () {
        // Test some known mappings
        final testMappings = {
          'US': 'USD',
          'GB': 'GBP',
          'DE': 'EUR',
          'JP': 'JPY',
          'CA': 'CAD',
          'AU': 'AUD',
        };
        
        for (final entry in testMappings.entries) {
          final locale = Locale('en', entry.key);
          final currency = Currency.getInstanceFromLocale(locale);
          expect(currency.currencyCode, entry.value);
        }
      });
    });

    group('performance and caching', () {
      test('should handle concurrent access safely', () {
        // This is a basic test - in a real scenario you'd want more sophisticated concurrency testing
        final futures = List.generate(100, (i) => 
          Future(() => Currency.getInstance('USD'))
        );
        
        return Future.wait(futures).then((currencies) {
          // All should be the same instance
          final first = currencies.first;
          expect(currencies.every((c) => identical(c, first)), isTrue);
        });
      });
    });
  });
}