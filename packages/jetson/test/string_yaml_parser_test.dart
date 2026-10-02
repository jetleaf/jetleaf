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

import 'package:test/test.dart';
import 'package:jetson/src/yaml/parser/string_yaml_parser.dart';
import 'package:jetson/src/yaml/yaml_token.dart';

void main() {
  group('StringYamlParser', () {
    group('Empty input', () {
      test('should parse empty document', () {
        final parser = StringYamlParser('');
        expect(parser.nextToken(), isFalse);
      });

      test('should parse whitespace-only input', () {
        final parser = StringYamlParser('   ');
        expect(parser.nextToken(), isFalse);
      });
    });

    group('Document markers', () {
      test('should handle document start marker', () {
        final parser = StringYamlParser('---');
        expect(parser.nextToken(), isTrue);
        expect(parser.getCurrentToken(), YamlToken.DOCUMENT_START);
      });

      test('should handle document end marker', () {
        final parser = StringYamlParser('...');
        expect(parser.nextToken(), isTrue);
        expect(parser.getCurrentToken(), YamlToken.DOCUMENT_END);
      });

      test('should handle document start and end markers', () {
        final parser = StringYamlParser('---\n...\n');
        final tokens = <YamlToken>[];
        while (parser.nextToken()) {
          tokens.add(parser.getCurrentToken()!);
        }
        expect(tokens.first, YamlToken.DOCUMENT_START);
        expect(tokens, contains(YamlToken.DOCUMENT_END));
      });

      test('should handle multiple documents', () {
        final parser = StringYamlParser('---\n...\n---\n...');
        final documentCounts = <YamlToken, int>{
          YamlToken.DOCUMENT_START: 0,
          YamlToken.DOCUMENT_END: 0,
        };

        while (parser.nextToken()) {
          final token = parser.getCurrentToken()!;
          if (documentCounts.containsKey(token)) {
            documentCounts[token] = documentCounts[token]! + 1;
          }
        }

        expect(documentCounts[YamlToken.DOCUMENT_START], 2);
        expect(documentCounts[YamlToken.DOCUMENT_END], greaterThanOrEqualTo(1));
      });
    });

    group('Flow collections', () {
      test('should handle flow sequences', () {
        final parser = StringYamlParser('[a, b, c]');
        final tokens = <YamlToken>[];
        while (parser.nextToken()) {
          tokens.add(parser.getCurrentToken()!);
        }

        expect(tokens, contains(YamlToken.SEQUENCE_START));
        expect(tokens, contains(YamlToken.SCALAR));
        expect(tokens, contains(YamlToken.SEQUENCE_END));
      });

      test('should handle flow mappings', () {
        final parser = StringYamlParser('{key: value}');
        final tokens = <YamlToken>[];
        while (parser.nextToken()) {
          tokens.add(parser.getCurrentToken()!);
        }

        expect(tokens, contains(YamlToken.MAPPING_START));
        expect(tokens, contains(YamlToken.KEY));
        expect(tokens, contains(YamlToken.SCALAR));
        expect(tokens, contains(YamlToken.MAPPING_END));
      });

      test('should handle nested flow collections', () {
        final parser = StringYamlParser('{key: [a, b]}');
        final tokens = <YamlToken>[];
        while (parser.nextToken()) {
          tokens.add(parser.getCurrentToken()!);
        }

        expect(tokens, contains(YamlToken.MAPPING_START));
        expect(tokens, contains(YamlToken.KEY));
        expect(tokens, contains(YamlToken.SEQUENCE_START));
        expect(tokens, contains(YamlToken.SCALAR));
        expect(tokens, contains(YamlToken.SEQUENCE_END));
        expect(tokens, contains(YamlToken.MAPPING_END));
      });
    });

    group('close()', () {
      test('parser cannot be used after close', () async {
        final parser = StringYamlParser('[a, b]');
        parser.nextToken();
        await parser.close();

        expect(parser.nextToken(), isFalse);
        expect(parser.getCurrentToken(), isNull);
      });
    });

    group('Sequence items', () {
      test('should parse simple sequence items', () {
        final parser = StringYamlParser('- item1\n- item2\n- item3');
        final tokens = <YamlToken>[];
        final values = <String?>[];

        while (parser.nextToken()) {
          final token = parser.getCurrentToken()!;
          tokens.add(token);
          final value = parser.getCurrentValue();
          if (value != null) {
            values.add(value);
          }
        }

        // The parser emits SEQUENCE_START for each item
        expect(tokens.where((t) => t == YamlToken.SEQUENCE_START).length, greaterThanOrEqualTo(1));
        expect(values, contains('item1'));
        expect(values, contains('item2'));
        expect(values, contains('item3'));
      });
    });

    group('Block scalars', () {
      test('should handle literal block scalar', () {
        final parser = StringYamlParser('literal: |\n  This is a\n  literal block\n  scalar');
        final results = <String, String>{};
        String? currentKey;

        while (parser.nextToken()) {
          final token = parser.getCurrentToken();
          if (token == YamlToken.KEY) {
            currentKey = parser.getCurrentValue();
          } else if (token == YamlToken.SCALAR && currentKey != null) {
            results[currentKey] = parser.getCurrentValue()!;
            currentKey = null;
          }
        }

        expect(results['literal']?.contains('This is a'), isTrue);
        expect(results['literal']?.contains('literal block'), isTrue);
      });

      test('should handle folded block scalar', () {
        final parser = StringYamlParser('folded: >\n  This is a folded\n  block scalar');
        final results = <String, String>{};
        String? currentKey;

        while (parser.nextToken()) {
          final token = parser.getCurrentToken();
          if (token == YamlToken.KEY) {
            currentKey = parser.getCurrentValue();
          } else if (token == YamlToken.SCALAR && currentKey != null) {
            results[currentKey] = parser.getCurrentValue()!;
            currentKey = null;
          }
        }

        expect(results['folded']?.contains('This is a folded'), isTrue);
      });
    });
  });
}