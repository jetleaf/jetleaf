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
import 'package:jetson/src/json/json_token.dart';
import 'package:test/test.dart';
import 'package:jetson/src/json/parser/string_json_parser.dart';

void main() {
  group('StringJsonParser', () {
    group('Primitive values (wrapped in containers)', () {
      test('parses a string value', () {
        final parser = StringJsonParser('{"val":"hello"}');
        parser.nextToken(); // START_OBJECT
        parser.nextToken(); // FIELD_NAME
        parser.nextToken(); // VALUE_STRING
        expect(parser.getCurrentToken(), JsonToken.VALUE_STRING);
        expect(parser.getCurrentValue(), 'hello');
      });

      test('parses a number value', () {
        final parser = StringJsonParser('{"val":42}');
        parser.nextToken(); // START_OBJECT
        parser.nextToken(); // FIELD_NAME
        parser.nextToken(); // VALUE_NUMBER
        expect(parser.getCurrentToken(), JsonToken.VALUE_NUMBER);
        expect(parser.getCurrentValue(), 42);
      });

      test('parses a float value', () {
        final parser = StringJsonParser('{"val":3.14}');
        parser.nextToken();
        parser.nextToken();
        parser.nextToken();
        expect(parser.getCurrentToken(), JsonToken.VALUE_NUMBER);
        expect(parser.getCurrentValue(), 3.14);
      });

      test('parses a negative number value', () {
        final parser = StringJsonParser('{"val":-42}');
        parser.nextToken();
        parser.nextToken();
        parser.nextToken();
        expect(parser.getCurrentToken(), JsonToken.VALUE_NUMBER);
        expect(parser.getCurrentValue(), -42);
      });

      test('parses a true boolean value', () {
        final parser = StringJsonParser('{"val":true}');
        parser.nextToken();
        parser.nextToken();
        parser.nextToken();
        expect(parser.getCurrentToken(), JsonToken.VALUE_BOOLEAN);
        expect(parser.getCurrentValue(), true);
      });

      test('parses a false boolean value', () {
        final parser = StringJsonParser('{"val":false}');
        parser.nextToken();
        parser.nextToken();
        parser.nextToken();
        expect(parser.getCurrentToken(), JsonToken.VALUE_BOOLEAN);
        expect(parser.getCurrentValue(), false);
      });

      test('parses a null value', () {
        final parser = StringJsonParser('{"val":null}');
        parser.nextToken();
        parser.nextToken();
        parser.nextToken();
        expect(parser.getCurrentToken(), JsonToken.VALUE_NULL);
        expect(parser.getCurrentValue(), isNull);
      });
    });

    group('Simple objects', () {
      test('parses empty object', () {
        final parser = StringJsonParser('{}');
        expect(parser.nextToken(), isTrue);
        expect(parser.getCurrentToken(), JsonToken.START_OBJECT);
        expect(parser.nextToken(), isTrue);
        expect(parser.getCurrentToken(), JsonToken.END_OBJECT);
        expect(parser.nextToken(), isFalse);
      });

      test('parses object with single field', () {
        final parser = StringJsonParser('{"name":"Alice"}');
        expect(parser.nextToken(), isTrue);
        expect(parser.getCurrentToken(), JsonToken.START_OBJECT);

        expect(parser.nextToken(), isTrue);
        expect(parser.getCurrentToken(), JsonToken.FIELD_NAME);
        expect(parser.getCurrentName(), 'name');

        expect(parser.nextToken(), isTrue);
        expect(parser.getCurrentToken(), JsonToken.VALUE_STRING);
        expect(parser.getCurrentValue(), 'Alice');

        expect(parser.nextToken(), isTrue);
        expect(parser.getCurrentToken(), JsonToken.END_OBJECT);

        expect(parser.nextToken(), isFalse);
      });

      test('parses object with multiple fields', () {
        final parser = StringJsonParser('{"email":"frank@gmail.com","name":"user"}');
        expect(parser.nextToken(), isTrue);
        expect(parser.getCurrentToken(), JsonToken.START_OBJECT);

        expect(parser.nextToken(), isTrue);
        expect(parser.getCurrentToken(), JsonToken.FIELD_NAME);
        expect(parser.getCurrentName(), 'email');

        expect(parser.nextToken(), isTrue);
        expect(parser.getCurrentToken(), JsonToken.VALUE_STRING);
        expect(parser.getCurrentValue(), 'frank@gmail.com');

        expect(parser.nextToken(), isTrue);
        expect(parser.getCurrentToken(), JsonToken.FIELD_NAME);
        expect(parser.getCurrentName(), 'name');

        expect(parser.nextToken(), isTrue);
        expect(parser.getCurrentToken(), JsonToken.VALUE_STRING);
        expect(parser.getCurrentValue(), 'user');

        expect(parser.nextToken(), isTrue);
        expect(parser.getCurrentToken(), JsonToken.END_OBJECT);

        expect(parser.nextToken(), isFalse);
      });

      test('parses object with mixed value types', () {
        final parser = StringJsonParser('{"name":"Alice","age":30,"active":true}');
        final tokens = <JsonToken>[];
        final values = <dynamic>[];

        while (parser.nextToken()) {
          tokens.add(parser.getCurrentToken()!);
          values.add(parser.getCurrentValue());
        }

        expect(tokens, [
          JsonToken.START_OBJECT,
          JsonToken.FIELD_NAME,
          JsonToken.VALUE_STRING,
          JsonToken.FIELD_NAME,
          JsonToken.VALUE_NUMBER,
          JsonToken.FIELD_NAME,
          JsonToken.VALUE_BOOLEAN,
          JsonToken.END_OBJECT,
        ]);
        expect(values[2], 'Alice');
        expect(values[4], 30);
        expect(values[6], true);
      });
    });

    group('Nested objects', () {
      test('parses nested object ordering', () {
        final parser = StringJsonParser('{"outer": {"a": 1}, "b": 2}');
        expect(parser.nextToken(), isTrue);
        expect(parser.getCurrentToken(), JsonToken.START_OBJECT);

        expect(parser.nextToken(), isTrue);
        expect(parser.getCurrentToken(), JsonToken.FIELD_NAME);
        expect(parser.getCurrentName(), 'outer');

        expect(parser.nextToken(), isTrue);
        expect(parser.getCurrentToken(), JsonToken.START_OBJECT);

        expect(parser.nextToken(), isTrue);
        expect(parser.getCurrentToken(), JsonToken.FIELD_NAME);
        expect(parser.getCurrentName(), 'a');

        expect(parser.nextToken(), isTrue);
        expect(parser.getCurrentToken(), JsonToken.VALUE_NUMBER);
        expect(parser.getCurrentValue(), 1);

        expect(parser.nextToken(), isTrue);
        expect(parser.getCurrentToken(), JsonToken.END_OBJECT);

        expect(parser.nextToken(), isTrue);
        expect(parser.getCurrentToken(), JsonToken.FIELD_NAME);
        expect(parser.getCurrentName(), 'b');

        expect(parser.nextToken(), isTrue);
        expect(parser.getCurrentToken(), JsonToken.VALUE_NUMBER);
        expect(parser.getCurrentValue(), 2);

        expect(parser.nextToken(), isTrue);
        expect(parser.getCurrentToken(), JsonToken.END_OBJECT);

        expect(parser.nextToken(), isFalse);
      });

      test('parses deeply nested objects', () {
        final parser = StringJsonParser('{"a":{"b":{"c":{"d":42}}}}');
        final tokens = <JsonToken>[];

        while (parser.nextToken()) {
          tokens.add(parser.getCurrentToken()!);
        }

        expect(tokens, [
          JsonToken.START_OBJECT,
          JsonToken.FIELD_NAME,
          JsonToken.START_OBJECT,
          JsonToken.FIELD_NAME,
          JsonToken.START_OBJECT,
          JsonToken.FIELD_NAME,
          JsonToken.START_OBJECT,
          JsonToken.FIELD_NAME,
          JsonToken.VALUE_NUMBER,
          JsonToken.END_OBJECT,
          JsonToken.END_OBJECT,
          JsonToken.END_OBJECT,
          JsonToken.END_OBJECT,
        ]);
      });
    });

    group('Arrays', () {
      test('parses empty array', () {
        final parser = StringJsonParser('[]');
        expect(parser.nextToken(), isTrue);
        expect(parser.getCurrentToken(), JsonToken.START_ARRAY);
        expect(parser.nextToken(), isTrue);
        expect(parser.getCurrentToken(), JsonToken.END_ARRAY);
        expect(parser.nextToken(), isFalse);
      });

      test('parses array of strings', () {
        final parser = StringJsonParser('["a","b","c"]');
        final tokens = <JsonToken>[];
        final values = <dynamic>[];

        while (parser.nextToken()) {
          tokens.add(parser.getCurrentToken()!);
          values.add(parser.getCurrentValue());
        }

        expect(tokens, [
          JsonToken.START_ARRAY,
          JsonToken.VALUE_STRING,
          JsonToken.VALUE_STRING,
          JsonToken.VALUE_STRING,
          JsonToken.END_ARRAY,
        ]);
        expect(values[1], 'a');
        expect(values[2], 'b');
        expect(values[3], 'c');
      });

      test('parses array of numbers', () {
        final parser = StringJsonParser('[1,2,3]');
        final values = <dynamic>[];

        while (parser.nextToken()) {
          values.add(parser.getCurrentValue());
        }

        expect(values.whereType<num>().toList(), [1, 2, 3]);
      });

      test('parses array of objects', () {
        final parser = StringJsonParser('[{"id":1},{"id":2}]');
        final tokens = <JsonToken>[];

        while (parser.nextToken()) {
          tokens.add(parser.getCurrentToken()!);
        }

        expect(tokens, [
          JsonToken.START_ARRAY,
          JsonToken.START_OBJECT,
          JsonToken.FIELD_NAME,
          JsonToken.VALUE_NUMBER,
          JsonToken.END_OBJECT,
          JsonToken.START_OBJECT,
          JsonToken.FIELD_NAME,
          JsonToken.VALUE_NUMBER,
          JsonToken.END_OBJECT,
          JsonToken.END_ARRAY,
        ]);
      });

      test('parses mixed type array', () {
        final parser = StringJsonParser('["text",42,true,null]');
        final tokens = <JsonToken>[];

        while (parser.nextToken()) {
          tokens.add(parser.getCurrentToken()!);
        }

        expect(tokens, [
          JsonToken.START_ARRAY,
          JsonToken.VALUE_STRING,
          JsonToken.VALUE_NUMBER,
          JsonToken.VALUE_BOOLEAN,
          JsonToken.VALUE_NULL,
          JsonToken.END_ARRAY,
        ]);
      });
    });

    group('Complex structures', () {
      test('parses object with nested array', () {
        final parser = StringJsonParser('{"names":["Alice","Bob"]}');
        final tokens = <JsonToken>[];

        while (parser.nextToken()) {
          tokens.add(parser.getCurrentToken()!);
        }

        expect(tokens, [
          JsonToken.START_OBJECT,
          JsonToken.FIELD_NAME,
          JsonToken.START_ARRAY,
          JsonToken.VALUE_STRING,
          JsonToken.VALUE_STRING,
          JsonToken.END_ARRAY,
          JsonToken.END_OBJECT,
        ]);
      });

      test('parses array with nested objects', () {
        final parser = StringJsonParser('[{"a":1},{"b":2}]');
        final tokens = <JsonToken>[];

        while (parser.nextToken()) {
          tokens.add(parser.getCurrentToken()!);
        }

        expect(tokens, [
          JsonToken.START_ARRAY,
          JsonToken.START_OBJECT,
          JsonToken.FIELD_NAME,
          JsonToken.VALUE_NUMBER,
          JsonToken.END_OBJECT,
          JsonToken.START_OBJECT,
          JsonToken.FIELD_NAME,
          JsonToken.VALUE_NUMBER,
          JsonToken.END_OBJECT,
          JsonToken.END_ARRAY,
        ]);
      });

      test('parses complex real-world structure', () {
        final json = '''
        {
          "user": {
            "name": "Alice",
            "age": 30,
            "address": {
              "street": "123 Main St",
              "city": "Denver"
            },
            "tags": ["admin", "user"]
          }
        }
        ''';
        final parser = StringJsonParser(json);
        final tokens = <JsonToken>[];
        final names = <String?>[];

        while (parser.nextToken()) {
          tokens.add(parser.getCurrentToken()!);
          if (parser.getCurrentToken() == JsonToken.FIELD_NAME) {
            names.add(parser.getCurrentName());
          }
        }

        expect(tokens.first, JsonToken.START_OBJECT);
        expect(tokens.last, JsonToken.END_OBJECT);
        expect(names, contains('user'));
        expect(names, contains('name'));
        expect(names, contains('age'));
        expect(names, contains('address'));
        expect(names, contains('street'));
        expect(names, contains('city'));
        expect(names, contains('tags'));
      });
    });

    group('Value types', () {
      test('parses empty string value', () {
        final parser = StringJsonParser('{"key":""}');
        parser.nextToken(); // START_OBJECT
        parser.nextToken(); // FIELD_NAME
        parser.nextToken(); // VALUE_STRING
        expect(parser.getCurrentToken(), JsonToken.VALUE_STRING);
        expect(parser.getCurrentValue(), '');
      });

      test('parses string with whitespace value', () {
        final parser = StringJsonParser('{"key":"  hello  "}');
        parser.nextToken();
        parser.nextToken();
        parser.nextToken();
        expect(parser.getCurrentToken(), JsonToken.VALUE_STRING);
        expect(parser.getCurrentValue(), '  hello  ');
      });

      test('parses zero value', () {
        final parser = StringJsonParser('{"key":0}');
        parser.nextToken();
        parser.nextToken();
        parser.nextToken();
        expect(parser.getCurrentToken(), JsonToken.VALUE_NUMBER);
        expect(parser.getCurrentValue(), 0);
      });

      test('parses scientific notation value', () {
        final parser = StringJsonParser('{"key":1e10}');
        parser.nextToken();
        parser.nextToken();
        parser.nextToken();
        expect(parser.getCurrentToken(), JsonToken.VALUE_NUMBER);
        expect(parser.getCurrentValue(), 1e10);
      });

      test('parses negative float value', () {
        final parser = StringJsonParser('{"key":-3.14}');
        parser.nextToken();
        parser.nextToken();
        parser.nextToken();
        expect(parser.getCurrentToken(), JsonToken.VALUE_NUMBER);
        expect(parser.getCurrentValue(), -3.14);
      });
    });

    group('skip()', () {
      test('skip on object skips entire object', () {
        final parser = StringJsonParser('{"skip":true,"keep":"yes"}');
        parser.nextToken(); // START_OBJECT
        parser.nextToken(); // FIELD_NAME "skip"

        parser.skip(); // Skip the value (true)

        // After skip, we should be at the next field or end
        final tokens = <JsonToken>[];
        while (parser.nextToken()) {
          tokens.add(parser.getCurrentToken()!);
        }
        // Should still have some tokens remaining
        expect(tokens, isNotEmpty);
      });

      test('skip on array skips entire array', () {
        final parser = StringJsonParser('{"data":[1,2,3],"other":"value"}');
        parser.nextToken(); // START_OBJECT
        parser.nextToken(); // FIELD_NAME "data"

        parser.skip(); // Skip the array [1,2,3]

        final tokens = <JsonToken>[];
        while (parser.nextToken()) {
          tokens.add(parser.getCurrentToken()!);
        }
        expect(tokens, isNotEmpty);
      });
    });

    group('close()', () {
      test('parser cannot be used after close', () async {
        final parser = StringJsonParser('{"a":1}');
        parser.nextToken();
        await parser.close();

        expect(parser.nextToken(), isFalse);
        expect(parser.getCurrentToken(), isNull);
      });
    });

    group('Invalid JSON', () {
      test('throws MalformedJsonException for null input', () {
        expect(
          () => StringJsonParser(''),
          throwsA(isA<MalformedJsonException>()),
        );
      });

      test('throws MalformedJsonException for malformed JSON', () {
        expect(
          () => StringJsonParser('{"a": true'),
          throwsA(isA<MalformedJsonException>()),
        );
      });

      test('throws MalformedJsonException for HTML input', () {
        expect(
          () => StringJsonParser('<html></html>'),
          throwsA(isA<MalformedJsonException>()),
        );
      });
    });

    group('getCurrentName()', () {
      test('returns field name for FIELD_NAME token', () {
        final parser = StringJsonParser('{"key":"value"}');
        parser.nextToken(); // START_OBJECT
        parser.nextToken(); // FIELD_NAME

        expect(parser.getCurrentToken(), JsonToken.FIELD_NAME);
        expect(parser.getCurrentName(), 'key');
      });

      test('getCurrentName returns last field name after advancing', () {
        final parser = StringJsonParser('{"key":42}');
        parser.nextToken(); // START_OBJECT
        parser.nextToken(); // FIELD_NAME - getCurrentName returns 'key'
        expect(parser.getCurrentName(), 'key');
        parser.nextToken(); // VALUE_NUMBER
        // getCurrentName still returns the last field name (parser tracks it)
        expect(parser.getCurrentName(), 'key');
      });
    });

    group('Edge cases', () {
      test('handles Unicode strings', () {
        final parser = StringJsonParser('{"emoji":"🍃","text":"こんにちは"}');
        parser.nextToken(); // START_OBJECT
        parser.nextToken(); // FIELD_NAME
        parser.nextToken(); // VALUE_STRING

        expect(parser.getCurrentValue(), '🍃');
      });

      test('handles escaped characters in strings', () {
        final parser = StringJsonParser('{"text":"line1\\nline2"}');
        parser.nextToken(); // START_OBJECT
        parser.nextToken(); // FIELD_NAME
        parser.nextToken(); // VALUE_STRING

        expect(parser.getCurrentValue(), 'line1\nline2');
      });

      test('handles large objects with many fields', () {
        final fields = List.generate(100, (i) => '"field$i":$i').join(',');
        final parser = StringJsonParser('{$fields}');
        var fieldCount = 0;

        while (parser.nextToken()) {
          if (parser.getCurrentToken() == JsonToken.FIELD_NAME) {
            fieldCount++;
          }
        }

        expect(fieldCount, 100);
      });
    });
  });
}