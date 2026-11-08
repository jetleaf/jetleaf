import 'package:test/test.dart';
import 'package:jetleaf_web/src/http/http_status.dart';

void main() {
  group('HttpStatus - Predefined Constants', () {
    test('OK has code 200', () {
      expect(HttpStatus.OK.getCode(), 200);
      expect(HttpStatus.OK.getName(), 'OK');
    });

    test('NOT_FOUND has code 404', () {
      expect(HttpStatus.NOT_FOUND.getCode(), 404);
      expect(HttpStatus.NOT_FOUND.getName(), 'NOT_FOUND');
    });

    test('INTERNAL_SERVER_ERROR has code 500', () {
      expect(HttpStatus.INTERNAL_SERVER_ERROR.getCode(), 500);
    });

    test('CREATED has code 201', () {
      expect(HttpStatus.CREATED.getCode(), 201);
    });

    test('BAD_REQUEST has code 400', () {
      expect(HttpStatus.BAD_REQUEST.getCode(), 400);
    });

    test('UNAUTHORIZED has code 401', () {
      expect(HttpStatus.UNAUTHORIZED.getCode(), 401);
    });

    test('FORBIDDEN has code 403', () {
      expect(HttpStatus.FORBIDDEN.getCode(), 403);
    });

    test('IM_A_TEAPOT has code 418', () {
      expect(HttpStatus.IM_A_TEAPOT.getCode(), 418);
    });

    test('TOO_MANY_REQUESTS has code 429', () {
      expect(HttpStatus.TOO_MANY_REQUESTS.getCode(), 429);
    });

    test('CONNECTION_NOT_REACHABLE has code 600', () {
      expect(HttpStatus.CONNECTION_NOT_REACHABLE.getCode(), 600);
    });

    test('REQUEST_CANCELLED has code 601', () {
      expect(HttpStatus.REQUEST_CANCELLED.getCode(), 601);
    });
  });

  group('HttpStatus - Category Detection', () {
    test('1xx informational', () {
      expect(HttpStatus.CONTINUE.is1xxInformational(), isTrue);
      expect(HttpStatus.SWITCHING_PROTOCOLS.is1xxInformational(), isTrue);
      expect(HttpStatus.OK.is1xxInformational(), isFalse);
    });

    test('2xx successful', () {
      expect(HttpStatus.OK.is2xxSuccessful(), isTrue);
      expect(HttpStatus.CREATED.is2xxSuccessful(), isTrue);
      expect(HttpStatus.NO_CONTENT.is2xxSuccessful(), isTrue);
      expect(HttpStatus.BAD_REQUEST.is2xxSuccessful(), isFalse);
    });

    test('3xx redirection', () {
      expect(HttpStatus.MOVED_PERMANENTLY.is3xxRedirection(), isTrue);
      expect(HttpStatus.FOUND.is3xxRedirection(), isTrue);
      expect(HttpStatus.NOT_MODIFIED.is3xxRedirection(), isTrue);
      expect(HttpStatus.OK.is3xxRedirection(), isFalse);
    });

    test('4xx client error', () {
      expect(HttpStatus.BAD_REQUEST.is4xxClientError(), isTrue);
      expect(HttpStatus.NOT_FOUND.is4xxClientError(), isTrue);
      expect(HttpStatus.INTERNAL_SERVER_ERROR.is4xxClientError(), isFalse);
    });

    test('5xx server error', () {
      expect(HttpStatus.INTERNAL_SERVER_ERROR.is5xxServerError(), isTrue);
      expect(HttpStatus.BAD_GATEWAY.is5xxServerError(), isTrue);
      expect(HttpStatus.OK.is5xxServerError(), isFalse);
    });

    test('6xx connection error', () {
      expect(HttpStatus.CONNECTION_NOT_REACHABLE.is6xxConnectionError(), isTrue);
      expect(HttpStatus.REQUEST_CANCELLED.is6xxConnectionError(), isTrue);
      expect(HttpStatus.OK.is6xxConnectionError(), isFalse);
    });
  });

  group('HttpStatus - fromCode()', () {
    test('returns predefined status for known code', () {
      expect(HttpStatus.fromCode(200), equals(HttpStatus.OK));
    });

    test('returns predefined status for 404', () {
      expect(HttpStatus.fromCode(404), equals(HttpStatus.NOT_FOUND));
    });

    test('creates dynamic status for unknown 1xx code', () {
      final status = HttpStatus.fromCode(150);
      expect(status.getCode(), 150);
      expect(status.getName(), 'UNKNOWN_150');
      expect(status.is1xxInformational(), isTrue);
    });

    test('creates dynamic status for unknown 2xx code', () {
      final status = HttpStatus.fromCode(250);
      expect(status.getCode(), 250);
      expect(status.is2xxSuccessful(), isTrue);
    });

    test('creates dynamic status for unknown 4xx code', () {
      final status = HttpStatus.fromCode(450);
      expect(status.getCode(), 450);
      expect(status.is4xxClientError(), isTrue);
    });

    test('caches dynamic status for future use', () {
      final s1 = HttpStatus.fromCode(777);
      final s2 = HttpStatus.fromCode(777);
      expect(identical(s1, s2), isTrue);
    });
  });

  group('HttpStatus - fromString()', () {
    test('returns predefined status for known name', () {
      final status = HttpStatus.fromString('OK');
      expect(status.getCode(), 200);
    });

    test('case-insensitive lookup', () {
      final status = HttpStatus.fromString('ok');
      expect(status.getCode(), 200);
    });

    test('returns unknown status for unrecognized name', () {
      final status = HttpStatus.fromString('CUSTOM');
      expect(status.getCode(), 0);
    });
  });

  group('HttpStatus - getAllStatusCodes()', () {
    test('returns a non-empty list', () {
      final all = HttpStatus.getAllStatusCodes();
      expect(all.length, greaterThan(50));
    });

    test('list is unmodifiable', () {
      final all = HttpStatus.getAllStatusCodes();
      expect(() => all.add(HttpStatus.OK), throwsUnsupportedError);
    });
  });

  group('HttpStatus - isPredefined()', () {
    test('returns true for known codes', () {
      expect(HttpStatus.isPredefined(200), isTrue);
      expect(HttpStatus.isPredefined(404), isTrue);
    });

    test('returns false for unknown codes', () {
      expect(HttpStatus.isPredefined(99999), isFalse);
    });
  });

  group('HttpStatus - Equality', () {
    test('same constants are equal', () {
      expect(HttpStatus.OK, equals(HttpStatus.OK));
    });

    test('different constants are not equal', () {
      expect(HttpStatus.OK, isNot(equals(HttpStatus.NOT_FOUND)));
    });

    test('fromCode returns same instance for predefined codes', () {
      final s1 = HttpStatus.fromCode(200);
      final s2 = HttpStatus.fromCode(200);
      expect(identical(s1, s2), isTrue);
    });
  });
}