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
import 'package:jetson/src/yaml/parser/yaml_scanner.dart';
import 'package:test/test.dart';

void main() {
  group('JsonParsingException', () {
    test('stores message correctly', () {
      final exception = JsonParsingException('Invalid JSON');
      expect(exception.message, 'Invalid JSON');
    });

    test('stores cause when provided', () {
      final cause = Exception('original error');
      final exception = JsonParsingException('Invalid JSON', cause: cause);
      expect(exception.cause, cause);
    });

    test('cause is null when not provided', () {
      final exception = JsonParsingException('Invalid JSON');
      expect(exception.cause, isNull);
    });

    test('is a RuntimeException', () {
      final exception = JsonParsingException('test');
      expect(exception, isA<Exception>());
    });
  });

  group('MalformedJsonException', () {
    test('stores message correctly', () {
      final exception = MalformedJsonException('Malformed JSON');
      expect(exception.message, 'Malformed JSON');
    });

    test('stores cause when provided', () {
      final cause = Exception('parse error');
      final exception = MalformedJsonException('Malformed JSON', cause: cause);
      expect(exception.cause, cause);
    });

    test('cause is null when not provided', () {
      final exception = MalformedJsonException('test');
      expect(exception.cause, isNull);
    });
  });

  group('IllegalObjectTokenException', () {
    test('stores message correctly', () {
      final exception = IllegalObjectTokenException('Unexpected token');
      expect(exception.message, 'Unexpected token');
    });

    test('is throwable', () {
      expect(
        () => throw IllegalObjectTokenException('error'),
        throwsA(isA<IllegalObjectTokenException>()),
      );
    });
  });

  group('ObjectGeneratorException', () {
    test('stores message correctly', () {
      final exception = ObjectGeneratorException('Generator error');
      expect(exception.message, 'Generator error');
    });

    test('is throwable', () {
      expect(
        () => throw ObjectGeneratorException('error'),
        throwsA(isA<ObjectGeneratorException>()),
      );
    });
  });

  group('NoDeserializerFoundException', () {
    test('stores message correctly', () {
      final exception = NoDeserializerFoundException('No deserializer');
      expect(exception.message, 'No deserializer');
    });

    test('is throwable', () {
      expect(
        () => throw NoDeserializerFoundException('error'),
        throwsA(isA<NoDeserializerFoundException>()),
      );
    });
  });

  group('NoSerializerFoundException', () {
    test('stores message correctly', () {
      final exception = NoSerializerFoundException('No serializer');
      expect(exception.message, 'No serializer');
    });

    test('is throwable', () {
      expect(
        () => throw NoSerializerFoundException('error'),
        throwsA(isA<NoSerializerFoundException>()),
      );
    });
  });

  group('YamlException', () {
    test('stores message and position correctly', () {
      final position = YamlPosition(line: 0, column: 5);
      final exception = YamlException('YAML error', position);
      expect(exception.message, 'YAML error');
      expect(exception.position.line, 0);
      expect(exception.position.column, 5);
    });

    test('toString includes position info', () {
      final position = YamlPosition(line: 2, column: 10);
      final exception = YamlException('YAML error', position);
      expect(exception.toString(), contains('line 3'));
      expect(exception.toString(), contains('column 11'));
    });

    test('stores stackTrace when provided', () {
      final position = YamlPosition(line: 0, column: 0);
      final stackTrace = StackTrace.empty;
      final exception = YamlException('error', position, stackTrace: stackTrace);
      expect(exception.stackTrace, stackTrace);
    });
  });

  group('UnsupportedYamlFeatureException', () {
    test('stores feature name correctly', () {
      final position = YamlPosition(line: 0, column: 0);
      final exception = UnsupportedYamlFeatureException('anchors', position);
      expect(exception.feature, 'anchors');
      expect(exception.message, contains('anchors'));
    });

    test('is a YamlException', () {
      final position = YamlPosition(line: 0, column: 0);
      final exception = UnsupportedYamlFeatureException('tags', position);
      expect(exception, isA<YamlException>());
    });
  });

  group('YamlSyntaxException', () {
    test('stores message correctly', () {
      final position = YamlPosition(line: 1, column: 3);
      final exception = YamlSyntaxException('Unexpected token', position);
      expect(exception.message, contains('Syntax error'));
      expect(exception.message, contains('Unexpected token'));
    });

    test('is a YamlException', () {
      final position = YamlPosition(line: 0, column: 0);
      final exception = YamlSyntaxException('error', position);
      expect(exception, isA<YamlException>());
    });
  });

  group('FailedDeserializationException', () {
    test('stores message correctly', () {
      final exception = FailedDeserializationException('Deserialization failed');
      expect(exception.message, 'Deserialization failed');
    });

    test('stores cause when provided', () {
      final cause = Exception('type mismatch');
      final exception = FailedDeserializationException('failed', cause: cause);
      expect(exception.cause, cause);
    });

    test('stores stackTrace when provided', () {
      final stackTrace = StackTrace.empty;
      final exception = FailedDeserializationException('failed', stackTrace: stackTrace);
      expect(exception.stackTrace, stackTrace);
    });
  });

  group('YamlPosition', () {
    test('stores line and column correctly', () {
      final position = YamlPosition(line: 5, column: 10);
      expect(position.line, 5);
      expect(position.column, 10);
    });

    test('toString is 1-based', () {
      final position = YamlPosition(line: 0, column: 0);
      expect(position.toString(), 'line 1, column 1');
    });

    test('toString with non-zero values', () {
      final position = YamlPosition(line: 2, column: 5);
      expect(position.toString(), 'line 3, column 6');
    });
  });
}