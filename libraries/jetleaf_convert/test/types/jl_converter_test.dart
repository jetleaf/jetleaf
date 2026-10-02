import 'package:jetleaf_convert/convert.dart';
import 'package:test/test.dart';
import 'package:jetleaf_lang/lang.dart';
import 'dart:typed_data';

@JetleafTest()
void main() {
  final service = DefaultConversionService();

  group('UUID Converters', () {
    test('String to Uuid conversion - standard format', () {
      const uuidString = '550e8400-e29b-41d4-a716-446655440000';
      final result = service.convert<Uuid>(uuidString, Class<Uuid>());
      expect(result?.toString(), uuidString);
    });

    test('String to Uuid conversion - no hyphens', () {
      const uuidString = '550e8400e29b41d4a716446655440000';
      final result = service.convert<Uuid>(uuidString, Class<Uuid>());
      expect(result, isA<Uuid>());
    });

    test('String to Uuid conversion throws on invalid format', () {
      expect(() => service.convert<Uuid>('invalid-uuid', Class<Uuid>()), 
          throwsA(isA<ConversionFailedException>()));
    });

    test('Uuid to String conversion', () {
      final uuid = Uuid.fromString('550e8400-e29b-41d4-a716-446655440000');
      final result = service.convert<String>(uuid, Class<String>());
      expect(result, '550e8400-e29b-41d4-a716-446655440000');
    });
  });

  group('Byte Multi Converter', () {
    test('Byte to String conversion', () {
      final byteData = Byte.fromString('Hello World');
      final result = service.convert<String>(byteData, Class<String>());
      expect(result, 'Hello World');
    });

    test('String to Byte conversion', () {
      final result = service.convert<Byte>('Test String', Class<Byte>());
      expect(result?.toString(), 'Test String');
    });

    test('Byte to List<int> conversion', () {
      final byteData = Byte.fromString('ABC');
      final result = service.convert<List<int>>(byteData, Class<List<int>>());
      expect(result, [65, 66, 67]); // ASCII codes for 'A', 'B', 'C'
    });

    test('List<int> to Byte conversion', () {
      final list = [72, 101, 108, 108, 111]; // ASCII for 'Hello'
      final result = service.convert<Byte>(list, Class<Byte>());
      expect(result?.toString(), 'Hello');
    });

    test('Byte to Uint8List conversion', () {
      final byteData = Byte.fromString('Test');
      final result = service.convert<Uint8List>(byteData, Class<Uint8List>());
      expect(result, isA<Uint8List>());
      expect(result?.length, 4);
    });

    test('Uint8List to Byte conversion', () {
      final uint8List = Uint8List.fromList([84, 101, 115, 116]); // ASCII for 'Test'
      final result = service.convert<Byte>(uint8List, Class<Byte>());
      expect(result?.toString(), 'Test');
    });

    test('Empty List<int> to Byte conversion', () {
      final result = service.convert<Byte>(<int>[], Class<Byte>());
      expect(result?.isEmpty, true);
    });
  });

  group('Locale Converters', () {
    test('String to Locale conversion - language only', () {
      final result = service.convert<Locale>('en', Class<Locale>());
      expect(result?.getLanguage(), 'en');
      expect(result?.getCountry(), isNull);
    });

    test('String to Locale conversion - language and country', () {
      final result = service.convert<Locale>('en_US', Class<Locale>());
      expect(result?.getLanguage(), 'en');
      expect(result?.getCountry(), 'US');
    });

    test('String to Locale conversion - with hyphen', () {
      final result = service.convert<Locale>('fr-CA', Class<Locale>());
      expect(result?.getLanguage(), 'fr');
      expect(result?.getCountry(), 'CA');
    });

    test('Locale to String conversion', () {
      final locale = Locale('es', 'MX');
      final result = service.convert<String>(locale, Class<String>());
      expect(result, 'es-MX');
    });

    test('Locale to String conversion - language only', () {
      final locale = Locale('de');
      final result = service.convert<String>(locale, Class<String>());
      expect(result, 'de');
    });
  });

  group('Currency Converters', () {
    test('String to Currency conversion - ISO code', () {
      final result = service.convert<Currency>('USD', Class<Currency>());
      expect(result?.currencyCode, 'USD');
    });

    test('String to Currency conversion - lowercase ISO code', () {
      final result = service.convert<Currency>('eur', Class<Currency>());
      expect(result?.currencyCode, 'EUR');
    });

    test('String to Currency conversion throws on invalid code', () {
      expect(() => service.convert<Currency>('INVALID', Class<Currency>()), 
          throwsA(isA<ConversionFailedException>()));
    });

    test('Currency to String conversion', () {
      final currency = Currency.getInstance('JPY');
      final result = service.convert<String>(currency, Class<String>());
      expect(result, 'JPY');
    });

    test('Currency to String conversion with symbol', () {
      final currency = Currency.getInstance('GBP');
      final result = service.convert<String>(currency, Class<String>());
      expect(result, 'GBP');
    });
  });
}