import 'package:jetleaf_lang/lang.dart';
import 'package:test/test.dart';

void main() {
  group('Locale', () {
    test('constructor creates valid locale with language only', () {
      final locale = Locale('en');
      expect(locale.getLanguage(), equals('en'));
      expect(locale.getCountry(), isNull);
      expect(locale.getVariant(), isNull);
    });

    test('constructor creates valid locale with language and country', () {
      final locale = Locale('en', 'US');
      expect(locale.getLanguage(), equals('en'));
      expect(locale.getCountry(), equals('US'));
      expect(locale.getVariant(), isNull);
    });

    test('constructor creates valid locale with all fields', () {
      final locale = Locale('fr', 'FR', 'Paris');
      expect(locale.getLanguage(), equals('fr'));
      expect(locale.getCountry(), equals('FR'));
      expect(locale.getVariant(), equals('Paris'));
    });

    test('defaultLocale is en-US', () {
      expect(Locale.DEFAULT_LOCALE.getLanguage(), equals('en'));
      expect(Locale.DEFAULT_LOCALE.getCountry(), equals('US'));
      expect(Locale.DEFAULT_LOCALE.getVariant(), isNull);
    });

    group('parse()', () {
      test('parses language only', () {
        final locale = Locale.parse('es');
        expect(locale.getLanguage(), equals('es'));
        expect(locale.getCountry(), isNull);
        expect(locale.getVariant(), isNull);
      });

      test('parses language and country', () {
        final locale = Locale.parse('de-DE');
        expect(locale.getLanguage(), equals('de'));
        expect(locale.getCountry(), equals('DE'));
        expect(locale.getVariant(), isNull);
      });

      test('parses language, country and variant', () {
        final locale = Locale.parse('fr-FR-Paris');
        expect(locale.getLanguage(), equals('fr'));
        expect(locale.getCountry(), equals('FR'));
        expect(locale.getVariant(), equals('Paris'));
      });

      test('throws when parsing empty string', () {
        expect(() => Locale.parse(''), throwsA(isA<InvalidFormatException>()));
      });

      test('throws when parsing invalid format', () {
        expect(() => Locale.parse('en-US-NY-NYC'), throwsA(isA<InvalidFormatException>()));
      });
    });

    group('languageTag', () {
      test('returns language only for simple locale', () {
        final locale = Locale('ja');
        expect(locale.getLanguageTag(), equals('ja'));
      });

      test('returns language-country for locale with country', () {
        final locale = Locale('pt', 'BR');
        expect(locale.getLanguageTag(), equals('pt-BR'));
      });

      test('returns full tag for locale with variant', () {
        final locale = Locale('en', 'GB', 'POSIX');
        expect(locale.getLanguageTag(), equals('en-GB-POSIX'));
      });
    });

    group('toString()', () {
      test('matches languageTag', () {
        final locale1 = Locale('it');
        final locale2 = Locale('ru', 'RU');
        final locale3 = Locale('zh', 'CN', 'Beijing');
        
        expect(locale1.toString(), equals(locale1.getLanguageTag()));
        expect(locale2.toString(), equals(locale2.getLanguageTag()));
        expect(locale3.toString(), equals(locale3.getLanguageTag()));
      });
    });

    group('equality', () {
      test('identical locales are equal', () {
        final locale1 = Locale('en', 'US');
        final locale2 = Locale('en', 'US');
        expect(locale1, equals(locale2));
      });

      test('different languages are not equal', () {
        final locale1 = Locale('en');
        final locale2 = Locale('fr');
        expect(locale1, isNot(equals(locale2)));
      });

      test('different countries are not equal', () {
        final locale1 = Locale('en', 'US');
        final locale2 = Locale('en', 'GB');
        expect(locale1, isNot(equals(locale2)));
      });

      test('different variants are not equal', () {
        final locale1 = Locale('fr', 'FR', 'Paris');
        final locale2 = Locale('fr', 'FR', 'Lyon');
        expect(locale1, isNot(equals(locale2)));
      });

      test('null variants are equal', () {
        final locale1 = Locale('es', 'ES');
        final locale2 = Locale('es', 'ES', null);
        expect(locale1, equals(locale2));
      });
    });

    group('hashCode', () {
      test('equal locales have same hashCode', () {
        final locale1 = Locale('de', 'DE');
        final locale2 = Locale('de', 'DE');
        expect(locale1.hashCode, equals(locale2.hashCode));
      });

      test('different locales have different hashCodes', () {
        final locale1 = Locale('it');
        final locale2 = Locale('it', 'IT');
        expect(locale1.hashCode, isNot(equals(locale2.hashCode)));
      });
    });

    group('additional methods', () {
      test('hasCountry() returns correct values', () {
        final locale1 = Locale('en', 'US');
        final locale2 = Locale('fr');
        
        expect(locale1.hasCountry(), isTrue);
        expect(locale2.hasCountry(), isFalse);
      });

      test('hasVariant() returns correct values', () {
        final locale1 = Locale('en', 'US', 'POSIX');
        final locale2 = Locale('en', 'US');
        
        expect(locale1.hasVariant(), isTrue);
        expect(locale2.hasVariant(), isFalse);
      });

      test('isDefault() identifies default locale', () {
        final defaultLocale = Locale('en', 'US');
        final otherLocale = Locale('fr', 'FR');
        
        expect(defaultLocale.isDefault(), isTrue);
        expect(otherLocale.isDefault(), isFalse);
      });

      test('copyWith() creates modified copies', () {
        final original = Locale('en', 'US', 'POSIX');
        final modified = original.copyWith(country: 'CA');
        
        expect(modified.getLanguage(), equals('en'));
        expect(modified.getCountry(), equals('CA'));
        expect(modified.getVariant(), equals('POSIX'));
      });

      test('matches() compares locales flexibly', () {
        final locale1 = Locale('en', 'US', 'POSIX');
        final locale2 = Locale('en', 'US', 'UTF8');
        final locale3 = Locale('en', 'CA');
        
        expect(locale1.matches(locale2), isTrue); // ignores variant by default
        expect(locale1.matches(locale2, ignoreVariant: false), isFalse);
        expect(locale1.matches(locale3), isFalse); // different countries
      });

      test('toMap() and fromMap() work correctly', () {
        final original = Locale('fr', 'CA', 'Quebec');
        final map = original.toJson();
        final restored = Locale.fromMap(map);
        
        expect(restored.getLanguage(), equals(original.getLanguage()));
        expect(restored.getCountry(), equals(original.getCountry()));
        expect(restored.getVariant(), equals(original.getVariant()));
      });
    });
  });
}