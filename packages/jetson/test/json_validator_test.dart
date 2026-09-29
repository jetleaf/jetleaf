// ---------------------------------------------------------------------------
// 🍃 Jetleaf Framework - https://jetleaf.hapnium.com
//
// Copyright © 2025 Hapnium & Jetleaf Contributors. All rights reserved.
//
// This source file is part of the Jetleaf Framework and is protected
// under copyright law. You may not copy, modify, or distribute this file
// except in compliance with the Jetleaf license.
//
// For licensing terms, see the LICENSE file in the root of this project.
// ---------------------------------------------------------------------------
// 
// 🔧 Powered by Hapnium — the Dart backend engine 🍃

import 'package:jetson/src/exceptions.dart';
import 'package:jetson/src/json/json_validator.dart';
import 'package:test/test.dart';

void main() {
  group('JsonValidator', () {
    group('validateJsonString', () {
      group('Valid JSON', () {
        test('valid JSON object', () {
          expect(
            () => JsonValidator.validateJsonString('{"name":"Alice","age":30}'),
            returnsNormally,
          );
        });

        test('valid JSON array', () {
          expect(
            () => JsonValidator.validateJsonString('[1,2,3]'),
            returnsNormally,
          );
        });

        test('valid JSON string value', () {
          expect(
            () => JsonValidator.validateJsonString('"hello"'),
            returnsNormally,
          );
        });

        test('valid JSON number value', () {
          expect(
            () => JsonValidator.validateJsonString('[42]'),
            returnsNormally,
          );
        });

        test('valid JSON boolean value', () {
          expect(
            () => JsonValidator.validateJsonString('[true]'),
            returnsNormally,
          );
        });

        test('valid JSON null value', () {
          expect(
            () => JsonValidator.validateJsonString('[null]'),
            returnsNormally,
          );
        });

        test('nested valid JSON', () {
          expect(
            () => JsonValidator.validateJsonString('{"user":{"name":"Alice","address":{"city":"Denver"}}}'),
            returnsNormally,
          );
        });

        test('valid JSON with array of objects', () {
          expect(
            () => JsonValidator.validateJsonString('[{"id":1},{"id":2}]'),
            returnsNormally,
          );
        });

        test('empty JSON object', () {
          expect(
            () => JsonValidator.validateJsonString('{}'),
            returnsNormally,
          );
        });

        test('empty JSON array', () {
          expect(
            () => JsonValidator.validateJsonString('[]'),
            returnsNormally,
          );
        });

        test('JSON with escaped strings', () {
          expect(
            () => JsonValidator.validateJsonString('{"text":"hello\\"world"}'),
            returnsNormally,
          );
        });

        test('JSON with unicode', () {
          expect(
            () => JsonValidator.validateJsonString('{"emoji":"🍃"}'),
            returnsNormally,
          );
        });

        test('JSON with negative numbers', () {
          expect(
            () => JsonValidator.validateJsonString('[-1,-3.14]'),
            returnsNormally,
          );
        });

        test('JSON with zero', () {
          expect(
            () => JsonValidator.validateJsonString('{"zero":0}'),
            returnsNormally,
          );
        });

        test('JSON with false boolean', () {
          expect(
            () => JsonValidator.validateJsonString('{"flag":false}'),
            returnsNormally,
          );
        });

        test('JSON with empty string value', () {
          expect(
            () => JsonValidator.validateJsonString('{"empty":""}'),
            returnsNormally,
          );
        });

        test('JSON with whitespace', () {
          expect(
            () => JsonValidator.validateJsonString('{"key": "value"}'),
            returnsNormally,
          );
        });

        test('JSON with newlines', () {
          expect(
            () => JsonValidator.validateJsonString('{\n"key": "value"\n}'),
            returnsNormally,
          );
        });
      });

      group('Invalid JSON', () {
        test('null input throws MalformedJsonException', () {
          expect(
            () => JsonValidator.validateJsonString(null),
            throwsA(isA<MalformedJsonException>()),
          );
        });

        test('empty string throws MalformedJsonException', () {
          expect(
            () => JsonValidator.validateJsonString(''),
            throwsA(isA<MalformedJsonException>()),
          );
        });

        test('whitespace-only string throws MalformedJsonException', () {
          expect(
            () => JsonValidator.validateJsonString('   '),
            throwsA(isA<MalformedJsonException>()),
          );
        });

        test('HTML string throws MalformedJsonException', () {
          expect(
            () => JsonValidator.validateJsonString('<html><body>Hello</body></html>'),
            throwsA(isA<MalformedJsonException>()),
          );
        });

        test('DOCTYPE HTML throws MalformedJsonException', () {
          expect(
            () => JsonValidator.validateJsonString('<!DOCTYPE html><html></html>'),
            throwsA(isA<MalformedJsonException>()),
          );
        });

        test('div tag throws MalformedJsonException', () {
          expect(
            () => JsonValidator.validateJsonString('<div>Content</div>'),
            throwsA(isA<MalformedJsonException>()),
          );
        });

        test('head tag throws MalformedJsonException', () {
          expect(
            () => JsonValidator.validateJsonString('<head></head>'),
            throwsA(isA<MalformedJsonException>()),
          );
        });

        test('script tag throws MalformedJsonException', () {
          expect(
            () => JsonValidator.validateJsonString('<script>alert("xss")</script>'),
            throwsA(isA<MalformedJsonException>()),
          );
        });

        test('style tag throws MalformedJsonException', () {
          expect(
            () => JsonValidator.validateJsonString('<style>body{color:red}</style>'),
            throwsA(isA<MalformedJsonException>()),
          );
        });

        test('plain text throws MalformedJsonException', () {
          expect(
            () => JsonValidator.validateJsonString('hello world'),
            throwsA(isA<MalformedJsonException>()),
          );
        });

        test('malformed JSON throws MalformedJsonException', () {
          expect(
            () => JsonValidator.validateJsonString('{"name":"Alice"'),
            throwsA(isA<MalformedJsonException>()),
          );
        });

        test('JSON with missing comma throws MalformedJsonException', () {
          expect(
            () => JsonValidator.validateJsonString('{"name":"Alice" "age":30}'),
            throwsA(isA<MalformedJsonException>()),
          );
        });

        test('JSON with trailing comma throws MalformedJsonException', () {
          expect(
            () => JsonValidator.validateJsonString('{"name":"Alice",}'),
            throwsA(isA<MalformedJsonException>()),
          );
        });

        test('JSON with single quotes throws MalformedJsonException', () {
          expect(
            () => JsonValidator.validateJsonString("{'name':'Alice'}"),
            throwsA(isA<MalformedJsonException>()),
          );
        });

        test('unquoted keys throw MalformedJsonException', () {
          expect(
            () => JsonValidator.validateJsonString('{name: "Alice"}'),
            throwsA(isA<MalformedJsonException>()),
          );
        });
      });
    });

    group('validateJsonMap', () {
      group('Valid maps', () {
        test('valid simple map', () {
          expect(
            () => JsonValidator.validateJsonMap({'name': 'Alice', 'age': 30}),
            returnsNormally,
          );
        });

        test('valid nested map', () {
          expect(
            () => JsonValidator.validateJsonMap({
              'user': {'name': 'Alice', 'age': 30},
            }),
            returnsNormally,
          );
        });

        test('valid map with array', () {
          expect(
            () => JsonValidator.validateJsonMap({
              'names': ['Alice', 'Bob'],
            }),
            returnsNormally,
          );
        });

        test('valid map with null values', () {
          expect(
            () => JsonValidator.validateJsonMap({
              'name': 'Alice',
              'age': null,
            }),
            returnsNormally,
          );
        });

        test('valid map with boolean values', () {
          expect(
            () => JsonValidator.validateJsonMap({
              'active': true,
              'deleted': false,
            }),
            returnsNormally,
          );
        });

        test('valid map with number values', () {
          expect(
            () => JsonValidator.validateJsonMap({
              'integer': 42,
              'double': 3.14,
            }),
            returnsNormally,
          );
        });

        test('valid map with empty nested structures', () {
          expect(
            () => JsonValidator.validateJsonMap({
              'empty': {},
              'list': [],
            }),
            returnsNormally,
          );
        });

        test('valid map with empty string keys', () {
          expect(
            () => JsonValidator.validateJsonMap({
              '': 'empty key',
            }),
            returnsNormally,
          );
        });

        test('valid map with empty string values', () {
          expect(
            () => JsonValidator.validateJsonMap({
              'key': '',
            }),
            returnsNormally,
          );
        });
      });

      group('Invalid maps', () {
        test('null map throws MalformedJsonException', () {
          expect(
            () => JsonValidator.validateJsonMap(null),
            throwsA(isA<MalformedJsonException>()),
          );
        });

        test('map with function value throws MalformedJsonException', () {
          expect(
            () => JsonValidator.validateJsonMap({'func': () => 1}),
            throwsA(isA<MalformedJsonException>()),
          );
        });
      });

      group('Deeply nested structures', () {
        test('deeply nested valid map', () {
          expect(
            () => JsonValidator.validateJsonMap({
              'level1': {
                'level2': {
                  'level3': {
                    'value': 42,
                  },
                },
              },
            }),
            returnsNormally,
          );
        });

        test('map with array of objects', () {
          expect(
            () => JsonValidator.validateJsonMap({
              'users': [
                {'name': 'Alice', 'age': 30},
                {'name': 'Bob', 'age': 25},
              ],
            }),
            returnsNormally,
          );
        });

        test('complex nested structure', () {
          expect(
            () => JsonValidator.validateJsonMap({
              'data': {
                'items': [
                  {'id': 1, 'tags': ['a', 'b']},
                  {'id': 2, 'tags': ['c']},
                ],
                'count': 2,
              },
            }),
            returnsNormally,
          );
        });
      });
    });

    group('isHtml', () {
      test('detects HTML with html tag', () {
        expect(JsonValidator.isHtml('<html></html>'), isTrue);
      });

      test('detects HTML with body tag', () {
        expect(JsonValidator.isHtml('<body>Hello</body>'), isTrue);
      });

      test('detects HTML with div tag', () {
        expect(JsonValidator.isHtml('<div>Content</div>'), isTrue);
      });

      test('detects DOCTYPE', () {
        expect(JsonValidator.isHtml('<!DOCTYPE html>'), isTrue);
      });

      test('detects head tag', () {
        expect(JsonValidator.isHtml('<head></head>'), isTrue);
      });

      test('detects script tag', () {
        expect(JsonValidator.isHtml('<script></script>'), isTrue);
      });

      test('detects style tag', () {
        expect(JsonValidator.isHtml('<style></style>'), isTrue);
      });

      test('case insensitive detection', () {
        expect(JsonValidator.isHtml('<HTML></HTML>'), isTrue);
        expect(JsonValidator.isHtml('<BODY></BODY>'), isTrue);
        expect(JsonValidator.isHtml('<DIV></DIV>'), isTrue);
      });

      test('returns false for JSON object', () {
        expect(JsonValidator.isHtml('{"name":"Alice"}'), isFalse);
      });

      test('returns false for JSON array', () {
        expect(JsonValidator.isHtml('[1,2,3]'), isFalse);
      });

      test('returns false for plain text', () {
        expect(JsonValidator.isHtml('hello world'), isFalse);
      });

      test('returns false for numbers', () {
        expect(JsonValidator.isHtml('42'), isFalse);
      });

      test('returns false for booleans', () {
        expect(JsonValidator.isHtml('true'), isFalse);
      });
    });

    group('isPlainText', () {
      test('returns true for plain text', () {
        expect(JsonValidator.isPlainText('hello world'), isTrue);
      });

      test('returns true for text not starting with JSON chars', () {
        expect(JsonValidator.isPlainText('test'), isTrue);
      });

      test('returns true for numbers as text', () {
        expect(JsonValidator.isPlainText('42abc'), isTrue);
      });

      test('returns false for JSON object', () {
        expect(JsonValidator.isPlainText('{"name":"Alice"}'), isFalse);
      });

      test('returns false for JSON array', () {
        expect(JsonValidator.isPlainText('[1,2,3]'), isFalse);
      });

      test('returns false for JSON string', () {
        expect(JsonValidator.isPlainText('"hello"'), isFalse);
      });

      test('returns false for empty JSON object', () {
        expect(JsonValidator.isPlainText('{}'), isFalse);
      });

      test('returns false for empty JSON array', () {
        expect(JsonValidator.isPlainText('[]'), isFalse);
      });
    });
  });
}