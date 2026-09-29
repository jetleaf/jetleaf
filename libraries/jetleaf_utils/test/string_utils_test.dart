import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_utils/jetleaf_utils.dart';
import 'package:test/test.dart';

void main() {
  group('StringUtils', () {
    group('hasLength', () {
      test('returns false for null', () {
        expect(StringUtils.hasLength(null), isFalse);
      });

      test('returns false for empty string', () {
        expect(StringUtils.hasLength(''), isFalse);
      });

      test('returns true for non-empty string', () {
        expect(StringUtils.hasLength('hello'), isTrue);
      });

      test('returns true for whitespace-only string', () {
        expect(StringUtils.hasLength(' '), isTrue);
      });
    });

    group('containsWhitespace', () {
      test('returns false for null', () {
        expect(StringUtils.containsWhitespace(null), isFalse);
      });

      test('returns false for empty string', () {
        expect(StringUtils.containsWhitespace(''), isFalse);
      });

      test('returns false for no whitespace', () {
        expect(StringUtils.containsWhitespace('hello'), isFalse);
      });

      test('returns true for string with space', () {
        expect(StringUtils.containsWhitespace('hello world'), isTrue);
      });

      test('returns true for string with tab', () {
        expect(StringUtils.containsWhitespace('hello\tworld'), isTrue);
      });

      test('returns true for string with newline', () {
        expect(StringUtils.containsWhitespace('hello\nworld'), isTrue);
      });
    });

    group('trimAllWhitespace', () {
      test('removes all whitespace', () {
        expect(StringUtils.trimAllWhitespace('  a b  '), 'ab');
      });

      test('returns empty for whitespace-only', () {
        expect(StringUtils.trimAllWhitespace('   '), '');
      });

      test('returns original if no whitespace', () {
        expect(StringUtils.trimAllWhitespace('hello'), 'hello');
      });

      test('handles empty string', () {
        expect(StringUtils.trimAllWhitespace(''), '');
      });
    });

    group('trimLeadingCharacter', () {
      test('trims leading character', () {
        expect(StringUtils.trimLeadingCharacter('/foo/bar/', '/'), 'foo/bar/');
      });

      test('trims multiple leading characters', () {
        expect(StringUtils.trimLeadingCharacter('///foo', '/'), 'foo');
      });

      test('returns original if no leading match', () {
        expect(StringUtils.trimLeadingCharacter('foo/', '/'), 'foo/');
      });
    });

    group('trimTrailingCharacter', () {
      test('trims trailing character', () {
        expect(StringUtils.trimTrailingCharacter('/foo/bar/', '/'), '/foo/bar');
      });

      test('trims multiple trailing characters', () {
        expect(StringUtils.trimTrailingCharacter('foo///', '/'), 'foo');
      });

      test('returns original if no trailing match', () {
        expect(StringUtils.trimTrailingCharacter('/foo', '/'), '/foo');
      });
    });

    group('startsWithIgnoreCase', () {
      test('returns true for matching prefix', () {
        expect(StringUtils.startsWithIgnoreCase('Hello World', 'hello'), isTrue);
      });

      test('returns false for non-matching prefix', () {
        expect(StringUtils.startsWithIgnoreCase('Hello World', 'world'), isFalse);
      });

      test('returns false for null string', () {
        expect(StringUtils.startsWithIgnoreCase(null, 'hello'), isFalse);
      });

      test('returns false for null prefix', () {
        expect(StringUtils.startsWithIgnoreCase('hello', null), isFalse);
      });

      test('returns false if prefix longer than string', () {
        expect(StringUtils.startsWithIgnoreCase('hi', 'hello'), isFalse);
      });
    });

    group('endsWithIgnoreCase', () {
      test('returns true for matching suffix', () {
        expect(StringUtils.endsWithIgnoreCase('Hello World', 'world'), isTrue);
      });

      test('returns false for non-matching suffix', () {
        expect(StringUtils.endsWithIgnoreCase('Hello World', 'hello'), isFalse);
      });

      test('returns false for null string', () {
        expect(StringUtils.endsWithIgnoreCase(null, 'world'), isFalse);
      });

      test('returns false for null suffix', () {
        expect(StringUtils.endsWithIgnoreCase('world', null), isFalse);
      });
    });

    group('countOccurrencesOf', () {
      test('counts occurrences', () {
        expect(StringUtils.countOccurrencesOf('abcabc', 'a'), 2);
      });

      test('returns 0 for no occurrences', () {
        expect(StringUtils.countOccurrencesOf('abc', 'x'), 0);
      });

      test('returns 0 for empty string', () {
        expect(StringUtils.countOccurrencesOf('', 'a'), 0);
      });

      test('returns 0 for empty substring', () {
        expect(StringUtils.countOccurrencesOf('abc', ''), 0);
      });

      test('counts overlapping occurrences', () {
        expect(StringUtils.countOccurrencesOf('aaa', 'aa'), 1);
      });
    });

    group('replace', () {
      test('replaces pattern', () {
        expect(StringUtils.replace('hello world', 'world', 'dart'), 'hello dart');
      });

      test('returns original if pattern not found', () {
        expect(StringUtils.replace('hello', 'xyz', 'abc'), 'hello');
      });

      test('replaces all occurrences', () {
        expect(StringUtils.replace('abcabc', 'a', 'x'), 'xbcxbc');
      });
    });

    group('delete', () {
      test('deletes pattern', () {
        expect(StringUtils.delete('hello world', ' world'), 'hello');
      });

      test('returns original if pattern not found', () {
        expect(StringUtils.delete('hello', 'xyz'), 'hello');
      });
    });

    group('deleteAny', () {
      test('deletes specified characters', () {
        expect(StringUtils.deleteAny('hello world', 'aeiou'), 'hll wrld');
      });

      test('returns original if no chars to delete', () {
        expect(StringUtils.deleteAny('hello', null), 'hello');
      });

      test('returns original if empty chars', () {
        expect(StringUtils.deleteAny('hello', ''), 'hello');
      });
    });

    group('quote', () {
      test('quotes string', () {
        expect(StringUtils.quote('hello'), "'hello'");
      });

      test('returns null for null', () {
        expect(StringUtils.quote(null), isNull);
      });
    });

    group('unqualify', () {
      test('removes prefix up to last separator', () {
        expect(StringUtils.unqualify('com.example.MyClass'), 'MyClass');
      });

      test('returns original if no separator', () {
        expect(StringUtils.unqualify('MyClass'), 'MyClass');
      });

      test('uses custom separator', () {
        expect(StringUtils.unqualify('com/example/MyClass', '/'), 'MyClass');
      });
    });

    group('capitalize', () {
      test('capitalizes first letter', () {
        expect(StringUtils.capitalize('hello'), 'Hello');
      });

      test('handles already capitalized', () {
        expect(StringUtils.capitalize('Hello'), 'Hello');
      });

      test('handles empty string', () {
        expect(StringUtils.capitalize(''), '');
      });
    });

    group('uncapitalize', () {
      test('uncapitalizes first letter', () {
        expect(StringUtils.uncapitalize('Hello'), 'hello');
      });

      test('handles already lowercase', () {
        expect(StringUtils.uncapitalize('hello'), 'hello');
      });
    });

    group('getFilename', () {
      test('extracts filename', () {
        expect(StringUtils.getFilename('/foo/bar/baz.txt'), 'baz.txt');
      });

      test('returns null for null', () {
        expect(StringUtils.getFilename(null), isNull);
      });

      test('returns filename if no path', () {
        expect(StringUtils.getFilename('baz.txt'), 'baz.txt');
      });
    });

    group('getFilenameExtension', () {
      test('extracts extension', () {
        expect(StringUtils.getFilenameExtension('file.txt'), 'txt');
      });

      test('returns null for no extension', () {
        expect(StringUtils.getFilenameExtension('file'), isNull);
      });

      test('returns null for null', () {
        expect(StringUtils.getFilenameExtension(null), isNull);
      });

      test('ignores dot in folder path', () {
        expect(StringUtils.getFilenameExtension('/foo.bar/file'), isNull);
      });
    });

    group('stripFilenameExtension', () {
      test('strips extension', () {
        expect(StringUtils.stripFilenameExtension('file.txt'), 'file');
      });

      test('returns original if no extension', () {
        expect(StringUtils.stripFilenameExtension('file'), 'file');
      });

      test('ignores dot in folder path', () {
        expect(StringUtils.stripFilenameExtension('/foo.bar/file'), '/foo.bar/file');
      });
    });

    group('cleanPath', () {
      test('normalizes separators', () {
        expect(StringUtils.cleanPath('foo\\bar'), 'foo/bar');
      });

      test('resolves dot', () {
        expect(StringUtils.cleanPath('/foo/./bar'), '/foo/bar');
      });

      test('resolves dotdot', () {
        expect(StringUtils.cleanPath('/foo/../bar'), '/bar');
      });

      test('preserves leading slash', () {
        expect(StringUtils.cleanPath('/foo/bar'), '/foo/bar');
      });

      test('handles empty string', () {
        expect(StringUtils.cleanPath(''), '');
      });
    });

    group('split', () {
      test('splits at delimiter', () {
        expect(StringUtils.split('a:b', ':'), ['a', 'b']);
      });

      test('returns null if delimiter not found', () {
        expect(StringUtils.split('abc', ':'), isNull);
      });

      test('returns null for null input', () {
        expect(StringUtils.split(null, ':'), isNull);
      });

      test('returns null for null delimiter', () {
        expect(StringUtils.split('abc', null), isNull);
      });
    });

    group('collectionToDelimitedString', () {
      test('joins with delimiter', () {
        expect(StringUtils.collectionToDelimitedString(['a', 'b', 'c'], ','), 'a,b,c');
      });

      test('applies prefix and suffix', () {
        expect(
          StringUtils.collectionToDelimitedString(['a', 'b'], ', ', "'", "'"),
          "'a', 'b'",
        );
      });

      test('returns empty for null', () {
        expect(StringUtils.collectionToDelimitedString(null, ','), '');
      });

      test('returns empty for empty list', () {
        expect(StringUtils.collectionToDelimitedString([], ','), '');
      });
    });

    group('collectionToCommaDelimitedString', () {
      test('joins with comma', () {
        expect(StringUtils.collectionToCommaDelimitedString(['a', 'b']), 'a,b');
      });
    });

    group('tokenizeToStringArray', () {
      test('tokenizes by delimiters', () {
        expect(StringUtils.tokenizeToStringArray('a,b;c', ',;'), ['a', 'b', 'c']);
      });

      test('trims tokens by default', () {
        expect(StringUtils.tokenizeToStringArray(' a , b ', ','), ['a', 'b']);
      });

      test('ignores empty tokens by default', () {
        expect(StringUtils.tokenizeToStringArray('a,,b,', ','), ['a', 'b']);
      });

      test('returns empty for null', () {
        expect(StringUtils.tokenizeToStringArray(null, ','), isEmpty);
      });
    });

    group('delimitedListToStringArray', () {
      test('splits by delimiter', () {
        expect(StringUtils.delimitedListToStringArray('a,b,c', ','), ['a', 'b', 'c']);
      });

      test('returns single element if no delimiter', () {
        expect(StringUtils.delimitedListToStringArray('abc', null), ['abc']);
      });

      test('returns empty for null', () {
        expect(StringUtils.delimitedListToStringArray(null, ','), isEmpty);
      });
    });

    group('commaDelimitedListToStringList', () {
      test('splits by comma', () {
        expect(StringUtils.commaDelimitedListToStringList('a,b,c'), ['a', 'b', 'c']);
      });
    });

    group('commaDelimitedListToSet', () {
      test('splits by comma and returns set', () {
        expect(StringUtils.commaDelimitedListToSet('a,b,a'), {'a', 'b'});
      });
    });

    group('matchesCharacter', () {
      test('returns true for matching single character', () {
        expect(StringUtils.matchesCharacter('a', 'a'), isTrue);
      });

      test('returns false for multi-char string', () {
        expect(StringUtils.matchesCharacter('ab', 'a'), isFalse);
      });

      test('returns false for null', () {
        expect(StringUtils.matchesCharacter(null, 'a'), isFalse);
      });

      test('returns false for non-matching', () {
        expect(StringUtils.matchesCharacter('b', 'a'), isFalse);
      });
    });

    group('truncate', () {
      test('returns original if within threshold', () {
        expect(StringUtils.truncate('hello', 10), 'hello');
      });

      test('truncates if over threshold', () {
        expect(StringUtils.truncate('hello world', 5), 'hello (truncated)...');
      });

      test('throws for zero threshold', () {
        expect(() => StringUtils.truncate('hello', 0), throwsA(isA<InvalidArgumentException>()));
      });

      test('throws for negative threshold', () {
        expect(() => StringUtils.truncate('hello', -1), throwsA(isA<InvalidArgumentException>()));
      });
    });
  });
}
