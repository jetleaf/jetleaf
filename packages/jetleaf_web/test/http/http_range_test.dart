import 'package:test/test.dart';
import 'package:jetleaf_web/src/http/http_range.dart';

void main() {
  group('HttpRange - Creation', () {
    test('creates range with valid start and end', () {
      final range = HttpRange(start: 0, end: 100);
      expect(range.getStart(), 0);
      expect(range.getEnd(), 100);
    });

    test('getLength returns correct length', () {
      expect(HttpRange(start: 0, end: 99).getLength(), 100);
    });

    test('single byte range', () {
      expect(HttpRange(start: 5, end: 5).getLength(), 1);
    });

    test('throws on negative start', () {
      expect(() => HttpRange(start: -1, end: 10), throwsA(anything));
    });

    test('throws when end < start', () {
      expect(() => HttpRange(start: 10, end: 5), throwsA(anything));
    });
  });

  group('HttpRange - isValid()', () {
    test('valid range within content', () {
      expect(HttpRange(start: 0, end: 100).isValid(500), isTrue);
    });

    test('invalid range beyond content', () {
      expect(HttpRange(start: 0, end: 100).isValid(50), isFalse);
    });
  });

  group('HttpRange - getContentRange()', () {
    test('formats Content-Range header', () {
      expect(HttpRange(start: 0, end: 1023).getContentRange(5000), 'bytes 0-1023/5000');
    });
  });

  group('HttpRange - parseRangeHeader()', () {
    test('parses single range', () {
      final ranges = HttpRange.parseRangeHeader('bytes=0-499', 1000);
      expect(ranges.length, 1);
      expect(ranges[0].start, 0);
      expect(ranges[0].end, 499);
    });

    test('parses multiple ranges', () {
      final ranges = HttpRange.parseRangeHeader('bytes=0-499,500-999', 1000);
      expect(ranges.length, 2);
      expect(ranges[0].end, 499);
      expect(ranges[1].start, 500);
    });

    test('parses suffix range', () {
      final ranges = HttpRange.parseRangeHeader('bytes=-500', 1000);
      expect(ranges.length, 1);
      expect(ranges[0].start, 500);
      expect(ranges[0].end, 999);
    });

    test('clamps end to content length', () {
      final ranges = HttpRange.parseRangeHeader('bytes=0-9999', 1000);
      expect(ranges[0].end, 999);
    });

    test('throws on invalid prefix', () {
      expect(() => HttpRange.parseRangeHeader('bits=0-100', 1000), throwsA(anything));
    });
  });

  group('HttpRange - formatRangeHeader()', () {
    test('formats single range', () {
      expect(HttpRange.formatRangeHeader([HttpRange(start: 0, end: 499)]), 'bytes=0-499');
    });

    test('formats multiple ranges', () {
      final ranges = [HttpRange(start: 0, end: 499), HttpRange(start: 500, end: 999)];
      expect(HttpRange.formatRangeHeader(ranges), 'bytes=0-499, 500-999');
    });

    test('throws on empty ranges', () {
      expect(() => HttpRange.formatRangeHeader([]), throwsA(anything));
    });
  });

  group('HttpRange - merge()', () {
    test('merges overlapping ranges', () {
      final merged = HttpRange.merge([HttpRange(start: 0, end: 100), HttpRange(start: 50, end: 200)]);
      expect(merged.length, 1);
      expect(merged[0].end, 200);
    });

    test('merges adjacent ranges', () {
      final merged = HttpRange.merge([HttpRange(start: 0, end: 99), HttpRange(start: 100, end: 199)]);
      expect(merged.length, 1);
      expect(merged[0].start, 0);
      expect(merged[0].end, 199);
    });

    test('keeps separate ranges separate', () {
      final merged = HttpRange.merge([HttpRange(start: 0, end: 49), HttpRange(start: 100, end: 149)]);
      expect(merged.length, 2);
    });

    test('handles empty list', () {
      expect(HttpRange.merge([]), isEmpty);
    });

    test('handles single range', () {
      final range = HttpRange(start: 0, end: 10);
      expect(HttpRange.merge([range]), equals([range]));
    });
  });

  group('HttpRange - Equality', () {
    test('same ranges are equal', () {
      expect(HttpRange(start: 0, end: 10), equals(HttpRange(start: 0, end: 10)));
    });

    test('different ranges are not equal', () {
      expect(HttpRange(start: 0, end: 10), isNot(equals(HttpRange(start: 5, end: 10))));
    });
  });

  group('HttpRange - parse()', () {
    test('parses valid range header', () {
      final ranges = HttpRange.parse('bytes=0-499');
      expect(ranges.length, 1);
      expect(ranges[0].start, 0);
      expect(ranges[0].end, 499);
    });

    test('returns empty for null', () {
      expect(HttpRange.parse(null), isEmpty);
    });

    test('returns empty for invalid prefix', () {
      expect(HttpRange.parse('bits=0-100'), isEmpty);
    });
  });

  group('HttpRange - toHeader()', () {
    test('alias for formatRangeHeader', () {
      expect(HttpRange.toHeader([HttpRange(start: 0, end: 499)]), 'bytes=0-499');
    });
  });

  group('HttpRange - parseRanges()', () {
    test('alias for parseRangeHeader', () {
      final ranges = HttpRange.parseRanges('bytes=0-499', 1000);
      expect(ranges.length, 1);
    });
  });

  group('HttpRange - toString()', () {
    test('formats as start-end', () {
      expect(HttpRange(start: 0, end: 100).toString(), '0-100');
    });
  });
}