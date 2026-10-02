import 'package:test/test.dart';
import 'package:jetleaf_lang/lang.dart';

import '../dependencies/exceptions.dart';

void main() {
  group('MimeType', () {
    group('construction', () {
      test('creates with type and subtype', () {
        final mt = MimeType('text', 'plain');
        expect(mt.type, equals('text'));
        expect(mt.subtype, equals('plain'));
        expect(mt.parameters, isEmpty);
      });

      test('creates with wildcard subtype', () {
        final mt = MimeType('text');
        expect(mt.type, equals('text'));
        expect(mt.subtype, equals('*'));
      });

      test('normalizes type and subtype to lowercase', () {
        final mt = MimeType('TEXT', 'PLAIN');
        expect(mt.type, equals('text'));
        expect(mt.subtype, equals('plain'));
      });

      test('creates with charset parameter', () {
        final mt = MimeType.fromCharset('text', 'plain', 'UTF-8');
        expect(mt.type, equals('text'));
        expect(mt.subtype, equals('plain'));
        expect(mt.charset, equals('UTF-8'));
      });

      test('creates with parameters map', () {
        final mt = MimeType('text', 'plain', {'charset': 'UTF-8', 'level': '1'});
        expect(mt.getParameter('charset'), equals('UTF-8'));
        expect(mt.getParameter('level'), equals('1'));
      });

      test('copies from another MimeType with charset', () {
        final original = MimeType('text', 'plain', {'charset': 'UTF-8'});
        final copy = MimeType.copyOf(original, parameters: {'level': '1'});
        expect(copy.type, equals('text'));
        expect(copy.subtype, equals('plain'));
        expect(copy.getParameter('charset'), equals('UTF-8'));
        expect(copy.getParameter('level'), equals('1'));
      });

      test('throws on empty type', () {
        expect(() => MimeType('', 'plain'), throwsIllegalArgumentException);
      });

      test('throws on empty subtype', () {
        expect(() => MimeType('text', ''), throwsIllegalArgumentException);
      });
    });

    group('wildcard', () {
      test('isWildcardType returns true for *', () {
        expect(MimeType('*', '*').isWildcardType, isTrue);
      });

      test('isWildcardType returns false for text', () {
        expect(MimeType('text', 'plain').isWildcardType, isFalse);
      });

      test('isWildcardSubtype returns true for *', () {
        expect(MimeType('text', '*').isWildcardSubtype, isTrue);
      });

      test('isWildcardSubtype returns true for *+xml', () {
        expect(MimeType('application', '*+xml').isWildcardSubtype, isTrue);
      });

      test('isWildcardSubtype returns false for plain', () {
        expect(MimeType('text', 'plain').isWildcardSubtype, isFalse);
      });

      test('isConcrete returns true for text/plain', () {
        expect(MimeType('text', 'plain').isConcrete, isTrue);
      });

      test('isConcrete returns false for text/*', () {
        expect(MimeType('text', '*').isConcrete, isFalse);
      });

      test('isConcrete returns false for */*', () {
        expect(MimeType('*', '*').isConcrete, isFalse);
      });
    });

    group('subtypeSuffix', () {
      test('returns xml for application/soap+xml', () {
        expect(MimeType('application', 'soap+xml').subtypeSuffix, equals('xml'));
      });

      test('returns null for text/plain', () {
        expect(MimeType('text', 'plain').subtypeSuffix, isNull);
      });

      test('returns json for application/vnd.api+json', () {
        expect(MimeType('application', 'vnd.api+json').subtypeSuffix, equals('json'));
      });
    });

    group('includes', () {
      test('wildcard type includes anything', () {
        expect(MimeType('*', '*').includes(MimeType('text', 'plain')), isTrue);
      });

      test('same type and subtype includes', () {
        expect(MimeType('text', 'plain').includes(MimeType('text', 'plain')), isTrue);
      });

      test('wildcard subtype includes', () {
        expect(MimeType('text', '*').includes(MimeType('text', 'plain')), isTrue);
      });

      test('different type does not include', () {
        expect(MimeType('text', 'plain').includes(MimeType('image', 'png')), isFalse);
      });

      test('wildcard with suffix includes matching suffix', () {
        expect(
          MimeType('application', '*+xml').includes(MimeType('application', 'soap+xml')),
          isTrue,
        );
      });

      test('does not include null', () {
        expect(MimeType('text', 'plain').includes(null), isFalse);
      });
    });

    group('isCompatibleWith', () {
      test('compatible with same type and subtype', () {
        expect(
          MimeType('text', 'plain').isCompatibleWith(MimeType('text', 'plain')),
          isTrue,
        );
      });

      test('wildcard type is compatible with anything', () {
        expect(MimeType('*', '*').isCompatibleWith(MimeType('text', 'plain')), isTrue);
      });

      test('compatible with wildcard type', () {
        expect(MimeType('text', 'plain').isCompatibleWith(MimeType('*', '*')), isTrue);
      });

      test('compatible with wildcard subtype', () {
        expect(MimeType('text', 'plain').isCompatibleWith(MimeType('text', '*')), isTrue);
      });

      test('not compatible with different type', () {
        expect(MimeType('text', 'plain').isCompatibleWith(MimeType('image', 'png')), isFalse);
      });

      test('not compatible with null', () {
        expect(MimeType('text', 'plain').isCompatibleWith(null), isFalse);
      });
    });

    group('equalsTypeAndSubtype', () {
      test('equal ignoring case', () {
        expect(
          MimeType('text', 'plain').equalsTypeAndSubtype(MimeType('TEXT', 'PLAIN')),
          isTrue,
        );
      });

      test('not equal with different subtype', () {
        expect(
          MimeType('text', 'plain').equalsTypeAndSubtype(MimeType('text', 'html')),
          isFalse,
        );
      });

      test('not equal with null', () {
        expect(MimeType('text', 'plain').equalsTypeAndSubtype(null), isFalse);
      });
    });

    group('isPresentIn', () {
      test('finds matching type', () {
        final list = [MimeType('text', 'plain'), MimeType('text', 'html')];
        expect(MimeType('text', 'plain').isPresentIn(list), isTrue);
      });

      test('does not find non-matching type', () {
        final list = [MimeType('text', 'plain'), MimeType('text', 'html')];
        expect(MimeType('image', 'png').isPresentIn(list), isFalse);
      });
    });

    group('isMoreSpecific', () {
      test('concrete is more specific than wildcard', () {
        expect(MimeType('text', 'plain').isMoreSpecific(MimeType('text', '*')), isTrue);
      });

      test('wildcard is not more specific than concrete', () {
        expect(MimeType('text', '*').isMoreSpecific(MimeType('text', 'plain')), isFalse);
      });

      test('more parameters is more specific', () {
        final moreSpecific = MimeType('text', 'plain', {'charset': 'UTF-8'});
        final lessSpecific = MimeType('text', 'plain');
        expect(moreSpecific.isMoreSpecific(lessSpecific), isTrue);
      });
    });

    group('isLessSpecific', () {
      test('wildcard is less specific than concrete', () {
        expect(MimeType('text', '*').isLessSpecific(MimeType('text', 'plain')), isTrue);
      });

      test('concrete is not less specific than wildcard', () {
        expect(MimeType('text', 'plain').isLessSpecific(MimeType('text', '*')), isFalse);
      });
    });

    group('equality', () {
      test('equal mime types are equal', () {
        expect(
          MimeType('text', 'plain'),
          equals(MimeType('text', 'plain')),
        );
      });

      test('equal ignoring case', () {
        expect(
          MimeType('text', 'plain'),
          equals(MimeType('TEXT', 'PLAIN')),
        );
      });

      test('different subtypes are not equal', () {
        expect(
          MimeType('text', 'plain'),
          isNot(equals(MimeType('text', 'html'))),
        );
      });

      test('same type and subtype with different parameters are not equal', () {
        expect(
          MimeType('text', 'plain'),
          isNot(equals(MimeType('text', 'plain', {'charset': 'UTF-8'}))),
        );
      });
    });

    group('hashCode', () {
      test('equal mime types have same hash code', () {
        final mt1 = MimeType('text', 'plain');
        final mt2 = MimeType('text', 'plain');
        expect(mt1.hashCode, equals(mt2.hashCode));
      });
    });

    group('compareTo', () {
      test('compares by type', () {
        expect(
          MimeType('application', 'json').compareTo(MimeType('text', 'plain')),
          lessThan(0),
        );
      });

      test('compares by subtype when types equal', () {
        expect(
          MimeType('text', 'html').compareTo(MimeType('text', 'plain')),
          lessThan(0),
        );
      });

      test('compares by parameter count when types and subtypes equal', () {
        final withParams = MimeType('text', 'plain', {'charset': 'UTF-8'});
        final withoutParams = MimeType('text', 'plain');
        expect(withParams.compareTo(withoutParams), greaterThan(0));
      });
    });

    group('toString', () {
      test('returns type/subtype', () {
        expect(MimeType('text', 'plain').toString(), equals('text/plain'));
      });

      test('includes parameters', () {
        expect(
          MimeType('text', 'plain', {'charset': 'UTF-8'}).toString(),
          equals('text/plain;charset=UTF-8'),
        );
      });

      test('caches toString value', () {
        final mt = MimeType('text', 'plain');
        final first = mt.toString();
        final second = mt.toString();
        expect(identical(first, second), isTrue);
      });
    });

    group('valueOf', () {
      test('parses text/plain', () {
        final mt = MimeType.valueOf('text/plain');
        expect(mt.type, equals('text'));
        expect(mt.subtype, equals('plain'));
      });

      test('parses with parameters', () {
        final mt = MimeType.valueOf('text/plain;charset=UTF-8');
        expect(mt.type, equals('text'));
        expect(mt.subtype, equals('plain'));
        expect(mt.getParameter('charset'), equals('UTF-8'));
      });

      test('parses wildcard', () {
        final mt = MimeType.valueOf('*/*');
        expect(mt.type, equals('*'));
        expect(mt.subtype, equals('*'));
      });

      test('parses application/vnd.api+json', () {
        final mt = MimeType.valueOf('application/vnd.api+json');
        expect(mt.type, equals('application'));
        expect(mt.subtype, equals('vnd.api+json'));
        expect(mt.subtypeSuffix, equals('json'));
      });
    });
  });
}
