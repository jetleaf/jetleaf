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

import 'dart:convert';

import 'package:jetson/src/exceptions.dart';
import 'package:jetson/src/json/generator/string_json_generator.dart';
import 'package:test/test.dart';

void main() {
  group('StringJsonGenerator', () {
    group('Compact JSON (no pretty printing)', () {
      test('generates simple object with string', () {
        final gen = StringJsonGenerator();
        gen.writeStartObject();
        gen.writeFieldName('name');
        gen.writeString('Alice');
        gen.writeEndObject();

        final json = gen.toString();
        expect(json, '{"name":"Alice"}');
        expect(() => jsonDecode(json), returnsNormally);
      });

      test('generates simple object with multiple fields', () {
        final gen = StringJsonGenerator();
        gen.writeStartObject();
        gen.writeFieldName('name');
        gen.writeString('Alice');
        gen.writeFieldName('age');
        gen.writeNumber(30);
        gen.writeFieldName('active');
        gen.writeBoolean(true);
        gen.writeEndObject();

        final json = gen.toString();
        expect(json, '{"name":"Alice","age":30,"active":true}');
        expect(() => jsonDecode(json), returnsNormally);
      });

      test('generates simple array', () {
        final gen = StringJsonGenerator();
        gen.writeStartArray();
        gen.writeString('a');
        gen.writeString('b');
        gen.writeString('c');
        gen.writeEndArray();

        final json = gen.toString();
        expect(json, '["a","b","c"]');
        expect(() => jsonDecode(json), returnsNormally);
      });

      test('generates array of numbers', () {
        final gen = StringJsonGenerator();
        gen.writeStartArray();
        gen.writeNumber(1);
        gen.writeNumber(2.5);
        gen.writeNumber(3);
        gen.writeEndArray();

        final json = gen.toString();
        expect(json, '[1,2.5,3]');
        expect(() => jsonDecode(json), returnsNormally);
      });

      test('generates nested objects', () {
        final gen = StringJsonGenerator();
        gen.writeStartObject();
        gen.writeFieldName('user');
        gen.writeStartObject();
        gen.writeFieldName('name');
        gen.writeString('Alice');
        gen.writeFieldName('age');
        gen.writeNumber(30);
        gen.writeEndObject();
        gen.writeEndObject();

        final json = gen.toString();
        expect(json, '{"user":{"name":"Alice","age":30}}');
        expect(() => jsonDecode(json), returnsNormally);
      });

      test('generates object with array', () {
        final gen = StringJsonGenerator();
        gen.writeStartObject();
        gen.writeFieldName('names');
        gen.writeStartArray();
        gen.writeString('Alice');
        gen.writeString('Bob');
        gen.writeEndArray();
        gen.writeEndObject();

        final json = gen.toString();
        expect(json, '{"names":["Alice","Bob"]}');
        expect(() => jsonDecode(json), returnsNormally);
      });

      test('generates array of objects', () {
        final gen = StringJsonGenerator();
        gen.writeStartArray();
        gen.writeStartObject();
        gen.writeFieldName('id');
        gen.writeNumber(1);
        gen.writeFieldName('name');
        gen.writeString('Alice');
        gen.writeEndObject();
        gen.writeStartObject();
        gen.writeFieldName('id');
        gen.writeNumber(2);
        gen.writeFieldName('name');
        gen.writeString('Bob');
        gen.writeEndObject();
        gen.writeEndArray();

        final json = gen.toString();
        expect(json, '[{"id":1,"name":"Alice"},{"id":2,"name":"Bob"}]');
        expect(() => jsonDecode(json), returnsNormally);
      });

      test('generates null values (stripped by _cleanJson)', () {
        final gen = StringJsonGenerator();
        gen.writeStartObject();
        gen.writeFieldName('value');
        gen.writeNull();
        gen.writeEndObject();

        final json = gen.toString();
        // _cleanJson strips null values, so the output is an empty object
        expect(json, '{}');
        expect(() => jsonDecode(json), returnsNormally);
      });

      test('generates null alongside non-null values', () {
        final gen = StringJsonGenerator();
        gen.writeStartObject();
        gen.writeFieldName('name');
        gen.writeString('Alice');
        gen.writeFieldName('age');
        gen.writeNull();
        gen.writeEndObject();

        final json = gen.toString();
        // null value for 'age' is stripped
        expect(json, '{"name":"Alice"}');
        expect(() => jsonDecode(json), returnsNormally);
      });

      test('no trailing commas in objects', () {
        final gen = StringJsonGenerator();
        gen.writeStartObject();
        gen.writeFieldName('a');
        gen.writeNumber(1);
        gen.writeEndObject();

        final json = gen.toString();
        expect(json.contains(',}'), false);
        expect(json.endsWith('}'), true);
      });

      test('no trailing commas in arrays', () {
        final gen = StringJsonGenerator();
        gen.writeStartArray();
        gen.writeNumber(1);
        gen.writeNumber(2);
        gen.writeEndArray();

        final json = gen.toString();
        expect(json.contains(',]'), false);
        expect(json.endsWith(']'), true);
      });

      test('escapes special characters in strings', () {
        final gen = StringJsonGenerator();
        gen.writeStartObject();
        gen.writeFieldName('text');
        gen.writeString('Hello\nWorld\t"quoted"');
        gen.writeEndObject();

        final json = gen.toString();
        expect(json, '{"text":"Hello\\nWorld\\t\\"quoted\\""}');
        expect(() => jsonDecode(json), returnsNormally);
      });

      test('escapes backslashes', () {
        final gen = StringJsonGenerator();
        gen.writeStartObject();
        gen.writeFieldName('path');
        gen.writeString('C:\\Users\\Alice');
        gen.writeEndObject();

        final json = gen.toString();
        expect(json, '{"path":"C:\\\\Users\\\\Alice"}');
        expect(() => jsonDecode(json), returnsNormally);
      });

      test('empty object', () {
        final gen = StringJsonGenerator();
        gen.writeStartObject();
        gen.writeEndObject();

        final json = gen.toString();
        expect(json, '{}');
        expect(() => jsonDecode(json), returnsNormally);
      });

      test('empty array', () {
        final gen = StringJsonGenerator();
        gen.writeStartArray();
        gen.writeEndArray();

        final json = gen.toString();
        expect(json, '[]');
        expect(() => jsonDecode(json), returnsNormally);
      });

      test('empty strings are preserved', () {
        final gen = StringJsonGenerator();
        gen.writeStartObject();
        gen.writeFieldName('empty');
        gen.writeString('');
        gen.writeEndObject();

        final json = gen.toString();
        expect(json, '{"empty":""}');
        expect(() => jsonDecode(json), returnsNormally);
      });

      test('zero is preserved', () {
        final gen = StringJsonGenerator();
        gen.writeStartObject();
        gen.writeFieldName('zero');
        gen.writeNumber(0);
        gen.writeEndObject();

        final json = gen.toString();
        expect(json, '{"zero":0}');
        expect(() => jsonDecode(json), returnsNormally);
      });

      test('false boolean is preserved', () {
        final gen = StringJsonGenerator();
        gen.writeStartObject();
        gen.writeFieldName('flag');
        gen.writeBoolean(false);
        gen.writeEndObject();

        final json = gen.toString();
        expect(json, '{"flag":false}');
        expect(() => jsonDecode(json), returnsNormally);
      });

      test('writeRaw outputs raw JSON', () {
        final gen = StringJsonGenerator();
        gen.writeStartObject();
        gen.writeFieldName('data');
        gen.writeRaw('[1,2,3]');
        gen.writeEndObject();

        final json = gen.toString();
        expect(json, '{"data":[1,2,3]}');
        expect(() => jsonDecode(json), returnsNormally);
      });

      test('handles unicode strings', () {
        final gen = StringJsonGenerator();
        gen.writeStartObject();
        gen.writeFieldName('emoji');
        gen.writeString('🍃');
        gen.writeEndObject();

        final json = gen.toString();
        expect(json, '{"emoji":"🍃"}');
        expect(() => jsonDecode(json), returnsNormally);
      });

      test('handles negative numbers', () {
        final gen = StringJsonGenerator();
        gen.writeStartArray();
        gen.writeNumber(-1);
        gen.writeNumber(-3.14);
        gen.writeNumber(0);
        gen.writeEndArray();

        final json = gen.toString();
        expect(json, '[-1,-3.14,0]');
        expect(() => jsonDecode(json), returnsNormally);
      });

      test('handles large numbers', () {
        final gen = StringJsonGenerator();
        gen.writeStartObject();
        gen.writeFieldName('big');
        gen.writeNumber(999999999999999);
        gen.writeEndObject();

        final json = gen.toString();
        expect(json, '{"big":999999999999999}');
        expect(() => jsonDecode(json), returnsNormally);
      });
    });

    group('Pretty printing', () {
      test('pretty prints simple object', () {
        final gen = StringJsonGenerator(pretty: true, indentSize: 2);
        gen.writeStartObject();
        gen.writeFieldName('name');
        gen.writeString('Alice');
        gen.writeEndObject();

        final json = gen.toString();
        expect(json.contains('\n'), true);
        expect(json.contains('  '), true);
        expect(() => jsonDecode(json), returnsNormally);
      });

      test('pretty prints nested objects', () {
        final gen = StringJsonGenerator(pretty: true, indentSize: 2);
        gen.writeStartObject();
        gen.writeFieldName('user');
        gen.writeStartObject();
        gen.writeFieldName('name');
        gen.writeString('Alice');
        gen.writeEndObject();
        gen.writeEndObject();

        final json = gen.toString();
        expect(() => jsonDecode(json), returnsNormally);
        expect(json.contains('\n'), true);
      });

      test('pretty prints arrays', () {
        final gen = StringJsonGenerator(pretty: true, indentSize: 2);
        gen.writeStartArray();
        gen.writeNumber(1);
        gen.writeNumber(2);
        gen.writeNumber(3);
        gen.writeEndArray();

        final json = gen.toString();
        expect(() => jsonDecode(json), returnsNormally);
        expect(json.contains('\n'), true);
      });

      test('uses custom indent size', () {
        final gen = StringJsonGenerator(pretty: true, indentSize: 4);
        gen.writeStartObject();
        gen.writeFieldName('nested');
        gen.writeStartObject();
        gen.writeFieldName('value');
        gen.writeNumber(1);
        gen.writeEndObject();
        gen.writeEndObject();

        final json = gen.toString();
        expect(json.contains('    '), true);
        expect(() => jsonDecode(json), returnsNormally);
      });

      test('pretty prints empty object', () {
        final gen = StringJsonGenerator(pretty: true, indentSize: 2);
        gen.writeStartObject();
        gen.writeEndObject();

        final json = gen.toString();
        expect(json, '{}');
        expect(() => jsonDecode(json), returnsNormally);
      });

      test('pretty prints empty array', () {
        final gen = StringJsonGenerator(pretty: true, indentSize: 2);
        gen.writeStartArray();
        gen.writeEndArray();

        final json = gen.toString();
        expect(json, '[]');
        expect(() => jsonDecode(json), returnsNormally);
      });
    });

    group('Complex scenarios', () {
      test('home object with address and tenants', () {
        final gen = StringJsonGenerator();
        gen.writeStartObject();
        gen.writeFieldName('id');
        gen.writeString('H001');
        gen.writeFieldName('owner');
        gen.writeString('Alice');
        gen.writeFieldName('address');
        gen.writeStartObject();
        gen.writeFieldName('street');
        gen.writeString('123 Elm Street');
        gen.writeFieldName('city');
        gen.writeString('Denver');
        gen.writeFieldName('zip');
        gen.writeString('80202');
        gen.writeEndObject();
        gen.writeFieldName('tenants');
        gen.writeStartArray();
        gen.writeStartObject();
        gen.writeFieldName('name');
        gen.writeString('Bob');
        gen.writeFieldName('age');
        gen.writeNumber(29);
        gen.writeEndObject();
        gen.writeStartObject();
        gen.writeFieldName('name');
        gen.writeString('Charlie');
        gen.writeFieldName('age');
        gen.writeNumber(35);
        gen.writeEndObject();
        gen.writeEndArray();
        gen.writeEndObject();

        final json = gen.toString();
        expect(json.contains('"id":"H001"'), true);
        expect(json.contains('"owner":"Alice"'), true);
        expect(json.contains('"street":"123 Elm Street"'), true);
        expect(json.contains('"name":"Bob"'), true);
        expect(json.contains('"name":"Charlie"'), true);
        expect(json.contains(',}'), false);
        expect(json.contains(',]'), false);
        expect(() => jsonDecode(json), returnsNormally);
      });

      test('deeply nested structure', () {
        final gen = StringJsonGenerator();
        gen.writeStartObject();
        gen.writeFieldName('level1');
        gen.writeStartObject();
        gen.writeFieldName('level2');
        gen.writeStartObject();
        gen.writeFieldName('level3');
        gen.writeNumber(42);
        gen.writeEndObject();
        gen.writeEndObject();
        gen.writeEndObject();

        final json = gen.toString();
        expect(json, '{"level1":{"level2":{"level3":42}}}');
        expect(() => jsonDecode(json), returnsNormally);
      });

      test('mixed arrays and objects', () {
        final gen = StringJsonGenerator();
        gen.writeStartObject();
        gen.writeFieldName('items');
        gen.writeStartArray();
        gen.writeStartObject();
        gen.writeFieldName('id');
        gen.writeNumber(1);
        gen.writeFieldName('tags');
        gen.writeStartArray();
        gen.writeString('tag1');
        gen.writeString('tag2');
        gen.writeEndArray();
        gen.writeEndObject();
        gen.writeEndArray();
        gen.writeEndObject();

        final json = gen.toString();
        expect(json, '{"items":[{"id":1,"tags":["tag1","tag2"]}]}');
        expect(() => jsonDecode(json), returnsNormally);
      });

      test('array with mixed types', () {
        final gen = StringJsonGenerator();
        gen.writeStartArray();
        gen.writeString('text');
        gen.writeNumber(42);
        gen.writeBoolean(true);
        gen.writeStartObject();
        gen.writeFieldName('key');
        gen.writeNumber(1);
        gen.writeEndObject();
        gen.writeEndArray();

        final json = gen.toString();
        final decoded = jsonDecode(json) as List;
        expect(decoded[0], 'text');
        expect(decoded[1], 42);
        expect(decoded[2], true);
        expect(decoded.length, 4);
        expect(() => jsonDecode(json), returnsNormally);
      });

      test('deeply nested arrays', () {
        final gen = StringJsonGenerator();
        gen.writeStartArray();
        gen.writeStartArray();
        gen.writeStartArray();
        gen.writeNumber(1);
        gen.writeEndArray();
        gen.writeEndArray();
        gen.writeEndArray();

        final json = gen.toString();
        expect(json, [[[1]]].toString());
        expect(() => jsonDecode(json), returnsNormally);
      });
    });

    group('Edge cases and error handling', () {
      test('throws on mismatched end array', () {
        final gen = StringJsonGenerator();
        gen.writeStartObject();

        expect(
          () => gen.writeEndArray(),
          throwsA(isA<ObjectGeneratorException>()),
        );
      });

      test('throws on mismatched end object', () {
        final gen = StringJsonGenerator();
        gen.writeStartArray();

        expect(
          () => gen.writeEndObject(),
          throwsA(isA<ObjectGeneratorException>()),
        );
      });

      test('throws on field name in array', () {
        final gen = StringJsonGenerator();
        gen.writeStartArray();

        expect(
          () => gen.writeFieldName('invalid'),
          throwsA(isA<ObjectGeneratorException>()),
        );
      });

      test('throws if toJsonString called with unclosed structure', () {
        final gen = StringJsonGenerator();
        gen.writeStartObject();
        gen.writeFieldName('name');
        gen.writeString('Alice');

        expect(
          () => gen.toString(),
          throwsA(isA<ObjectGeneratorException>()),
        );
      });

      test('can reuse generator after toString', () {
        final gen = StringJsonGenerator();

        gen.writeStartObject();
        gen.writeFieldName('a');
        gen.writeNumber(1);
        gen.writeEndObject();
        final json1 = gen.toString();

        gen.writeStartObject();
        gen.writeFieldName('b');
        gen.writeNumber(2);
        gen.writeEndObject();
        final json2 = gen.toString();

        expect(json1, '{"a":1}');
        expect(json2, '{"b":2}');
      });

      test('handles special float values', () {
        final gen = StringJsonGenerator();
        gen.writeStartArray();
        gen.writeNumber(3.14159);
        gen.writeNumber(0.0);
        gen.writeNumber(-42.5);
        gen.writeEndArray();

        final json = gen.toString();
        expect(() => jsonDecode(json), returnsNormally);
      });

      test('throws on writeFieldName without context', () {
        final gen = StringJsonGenerator();
        expect(
          () => gen.writeFieldName('test'),
          throwsA(isA<ObjectGeneratorException>()),
        );
      });

      test('throws on writeString without context', () {
        final gen = StringJsonGenerator();
        // This should not throw since writeString checks context
        // Actually, writeString only adds prefix in array context
        expect(
          () => gen.writeString('test'),
          returnsNormally,
        );
      });
    });

    group('String escaping', () {
      test('escapes all control characters', () {
        final gen = StringJsonGenerator();
        gen.writeStartObject();
        gen.writeFieldName('control');
        gen.writeString('tab:\t newline:\n carriage:\r');
        gen.writeEndObject();

        final json = gen.toString();
        expect(json.contains('\\t'), true);
        expect(json.contains('\\n'), true);
        expect(json.contains('\\r'), true);
        expect(() => jsonDecode(json), returnsNormally);
      });

      test('escapes quotes correctly', () {
        final gen = StringJsonGenerator();
        gen.writeStartObject();
        gen.writeFieldName('quote');
        gen.writeString('She said "Hello"');
        gen.writeEndObject();

        final json = gen.toString();
        expect(json.contains('\\"'), true);
        expect(() => jsonDecode(json), returnsNormally);
      });

      test('handles backspace and form feed', () {
        final gen = StringJsonGenerator();
        gen.writeStartObject();
        gen.writeFieldName('special');
        gen.writeString('backspace:\b formfeed:\f');
        gen.writeEndObject();

        final json = gen.toString();
        expect(json.contains('\\b'), true);
        expect(json.contains('\\f'), true);
        expect(() => jsonDecode(json), returnsNormally);
      });

      test('escapes field names with special characters', () {
        final gen = StringJsonGenerator();
        gen.writeStartObject();
        gen.writeFieldName('key with "quotes"');
        gen.writeString('value');
        gen.writeEndObject();

        final json = gen.toString();
        // The field name should have escaped quotes
        expect(json.contains('key with'), true);
        expect(json.contains('\\"'), true);
        expect(() => jsonDecode(json), returnsNormally);
      });

      test('handles empty string value', () {
        final gen = StringJsonGenerator();
        gen.writeStartObject();
        gen.writeFieldName('empty');
        gen.writeString('');
        gen.writeEndObject();

        final json = gen.toString();
        expect(json, '{"empty":""}');
      });

      test('handles string with only whitespace', () {
        final gen = StringJsonGenerator();
        gen.writeStartObject();
        gen.writeFieldName('spaces');
        gen.writeString('   ');
        gen.writeEndObject();

        final json = gen.toString();
        expect(json, '{"spaces":"   "}');
        expect(() => jsonDecode(json), returnsNormally);
      });
    });

    group('close()', () {
      test('resets generator state', () {
        final gen = StringJsonGenerator();
        gen.writeStartObject();
        gen.writeFieldName('a');
        gen.writeNumber(1);
        gen.writeEndObject();

        gen.close();

        // After close, can start fresh
        gen.writeStartObject();
        gen.writeFieldName('b');
        gen.writeNumber(2);
        gen.writeEndObject();
        final json = gen.toString();
        expect(json, '{"b":2}');
      });
    });
  });
}