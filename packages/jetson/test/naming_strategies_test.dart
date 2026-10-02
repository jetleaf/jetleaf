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

import 'package:jetson/src/naming_strategy/naming_strategies.dart';
import 'package:test/test.dart';

void main() {
  group('SnakeCaseNamingStrategy', () {
    final strategy = SnakeCaseNamingStrategy();

    group('toJsonName (camelCase → snake_case)', () {
      test('converts simple camelCase', () {
        expect(strategy.toJsonName('userName'), 'user_name');
      });

      test('converts multiple words', () {
        expect(strategy.toJsonName('firstName'), 'first_name');
      });

      test('converts acronym correctly', () {
        expect(strategy.toJsonName('httpRequest'), 'http_request');
      });

      test('converts single word', () {
        expect(strategy.toJsonName('name'), 'name');
      });

      test('converts leading uppercase (each letter individually)', () {
        // Each uppercase letter becomes its own _x segment
        expect(strategy.toJsonName('XMLParser'), 'x_m_l_parser');
      });

      test('converts createdAt', () {
        expect(strategy.toJsonName('createdAt'), 'created_at');
      });

      test('handles already snake_case (no change needed)', () {
        // user_name has no uppercase, so toJsonName returns it unchanged
        expect(strategy.toJsonName('user_name'), 'user_name');
      });

      test('handles empty string', () {
        expect(strategy.toJsonName(''), '');
      });

      test('converts single character', () {
        expect(strategy.toJsonName('a'), 'a');
      });

      test('converts two characters', () {
        expect(strategy.toJsonName('ab'), 'ab');
      });

      test('converts with consecutive uppercase (each letter individually)', () {
        expect(strategy.toJsonName('parseJSON'), 'parse_j_s_o_n');
      });

      test('converts with all uppercase', () {
        expect(strategy.toJsonName('XML'), 'x_m_l');
      });

      test('handles underscore at start (removed by replaceFirst)', () {
        // The regex adds _ before uppercase, then replaceFirst removes leading _
        expect(strategy.toJsonName('_private'), 'private');
      });
    });

    group('toDartName (snake_case → camelCase)', () {
      test('converts simple snake_case', () {
        expect(strategy.toDartName('user_name'), 'userName');
      });

      test('converts multiple words', () {
        expect(strategy.toDartName('first_name'), 'firstName');
      });

      test('converts acronym correctly', () {
        expect(strategy.toDartName('http_request'), 'httpRequest');
      });

      test('converts single word', () {
        expect(strategy.toDartName('name'), 'name');
      });

      test('converts xml_parser', () {
        expect(strategy.toDartName('xml_parser'), 'xmlParser');
      });

      test('converts created_at', () {
        expect(strategy.toDartName('created_at'), 'createdAt');
      });

      test('handles already camelCase', () {
        expect(strategy.toDartName('userName'), 'userName');
      });

      test('handles empty string', () {
        expect(strategy.toDartName(''), '');
      });

      test('handles single character', () {
        expect(strategy.toDartName('a'), 'a');
      });

      test('handles no underscores', () {
        expect(strategy.toDartName('name'), 'name');
      });

      test('handles multiple consecutive underscores', () {
        expect(strategy.toDartName('user__name'), 'user_Name');
      });

      test('handles trailing underscore', () {
        expect(strategy.toDartName('name_'), 'name_');
      });
    });

    group('Bidirectional consistency', () {
      test('toJsonName produces snake_case', () {
        expect(strategy.toJsonName('userName'), 'user_name');
      });

      test('toDartName converts snake_case to camelCase', () {
        expect(strategy.toDartName('user_name'), 'userName');
      });
    });
  });

  group('KebabCaseNamingStrategy', () {
    final strategy = KebabCaseNamingStrategy();

    group('toJsonName (camelCase → kebab-case)', () {
      test('converts simple camelCase', () {
        expect(strategy.toJsonName('userName'), 'user-name');
      });

      test('converts multiple words', () {
        expect(strategy.toJsonName('firstName'), 'first-name');
      });

      test('converts acronym correctly', () {
        expect(strategy.toJsonName('httpRequest'), 'http-request');
      });

      test('converts single word', () {
        expect(strategy.toJsonName('name'), 'name');
      });

      test('converts leading uppercase (each letter individually)', () {
        // Each uppercase letter becomes its own -x segment
        expect(strategy.toJsonName('XMLParser'), 'x-m-l-parser');
      });

      test('converts createdAt', () {
        expect(strategy.toJsonName('createdAt'), 'created-at');
      });

      test('handles already kebab-case (no change needed)', () {
        // user-name has no uppercase, so toJsonName returns it unchanged
        expect(strategy.toJsonName('user-name'), 'user-name');
      });

      test('handles empty string', () {
        expect(strategy.toJsonName(''), '');
      });

      test('converts single character', () {
        expect(strategy.toJsonName('a'), 'a');
      });

      test('converts with consecutive uppercase (each letter individually)', () {
        expect(strategy.toJsonName('parseJSON'), 'parse-j-s-o-n');
      });

      test('converts with all uppercase', () {
        expect(strategy.toJsonName('XML'), 'x-m-l');
      });
    });

    group('toDartName (kebab-case → camelCase)', () {
      test('converts simple kebab-case', () {
        expect(strategy.toDartName('user-name'), 'userName');
      });

      test('converts multiple words', () {
        expect(strategy.toDartName('first-name'), 'firstName');
      });

      test('converts acronym correctly', () {
        expect(strategy.toDartName('http-request'), 'httpRequest');
      });

      test('converts single word', () {
        expect(strategy.toDartName('name'), 'name');
      });

      test('converts xml-parser', () {
        expect(strategy.toDartName('xml-parser'), 'xmlParser');
      });

      test('converts created-at', () {
        expect(strategy.toDartName('created-at'), 'createdAt');
      });

      test('handles already camelCase', () {
        expect(strategy.toDartName('userName'), 'userName');
      });

      test('handles empty string', () {
        expect(strategy.toDartName(''), '');
      });

      test('handles single character', () {
        expect(strategy.toDartName('a'), 'a');
      });

      test('handles no hyphens', () {
        expect(strategy.toDartName('name'), 'name');
      });

      test('handles multiple consecutive hyphens', () {
        expect(strategy.toDartName('user--name'), 'user-Name');
      });

      test('handles trailing hyphen', () {
        expect(strategy.toDartName('name-'), 'name-');
      });
    });

    group('Bidirectional consistency', () {
      test('toJsonName produces kebab-case', () {
        expect(strategy.toJsonName('userName'), 'user-name');
      });

      test('toDartName converts kebab-case to camelCase', () {
        expect(strategy.toDartName('user-name'), 'userName');
      });
    });
  });

  group('CamelCaseNamingStrategy', () {
    final strategy = CamelCaseNamingStrategy();

    group('toJsonName', () {
      test('preserves camelCase', () {
        expect(strategy.toJsonName('userName'), 'userName');
      });

      test('preserves multiple words', () {
        expect(strategy.toJsonName('firstName'), 'firstName');
      });

      test('preserves acronym', () {
        expect(strategy.toJsonName('httpRequest'), 'httpRequest');
      });

      test('preserves single word', () {
        expect(strategy.toJsonName('name'), 'name');
      });

      test('preserves XMLParser', () {
        expect(strategy.toJsonName('XMLParser'), 'XMLParser');
      });

      test('preserves createdAt', () {
        expect(strategy.toJsonName('createdAt'), 'createdAt');
      });

      test('preserves snake_case (no transformation)', () {
        expect(strategy.toJsonName('user_name'), 'user_name');
      });

      test('preserves kebab-case (no transformation)', () {
        expect(strategy.toJsonName('user-name'), 'user-name');
      });

      test('handles empty string', () {
        expect(strategy.toJsonName(''), '');
      });

      test('preserves numbers', () {
        expect(strategy.toJsonName('field1'), 'field1');
      });

      test('preserves special characters', () {
        expect(strategy.toJsonName('field_name'), 'field_name');
      });
    });

    group('toDartName', () {
      test('preserves camelCase', () {
        expect(strategy.toDartName('userName'), 'userName');
      });

      test('preserves multiple words', () {
        expect(strategy.toDartName('firstName'), 'firstName');
      });

      test('preserves acronym', () {
        expect(strategy.toDartName('httpRequest'), 'httpRequest');
      });

      test('preserves single word', () {
        expect(strategy.toDartName('name'), 'name');
      });

      test('preserves XMLParser', () {
        expect(strategy.toDartName('XMLParser'), 'XMLParser');
      });

      test('preserves createdAt', () {
        expect(strategy.toDartName('createdAt'), 'createdAt');
      });

      test('preserves snake_case (no transformation)', () {
        expect(strategy.toDartName('user_name'), 'user_name');
      });

      test('preserves kebab-case (no transformation)', () {
        expect(strategy.toDartName('user-name'), 'user-name');
      });

      test('handles empty string', () {
        expect(strategy.toDartName(''), '');
      });

      test('preserves numbers', () {
        expect(strategy.toDartName('field1'), 'field1');
      });
    });

    group('Bidirectional consistency', () {
      test('userName roundtrip', () {
        const original = 'userName';
        final converted = strategy.toDartName(strategy.toJsonName(original));
        expect(converted, original);
      });

      test('httpRequest roundtrip', () {
        const original = 'httpRequest';
        final converted = strategy.toDartName(strategy.toJsonName(original));
        expect(converted, original);
      });

      test('xmlParser roundtrip', () {
        const original = 'xmlParser';
        final converted = strategy.toDartName(strategy.toJsonName(original));
        expect(converted, original);
      });

      test('createdAt roundtrip', () {
        const original = 'createdAt';
        final converted = strategy.toDartName(strategy.toJsonName(original));
        expect(converted, original);
      });

      test('user_name (preserved) roundtrip', () {
        const original = 'user_name';
        final converted = strategy.toDartName(strategy.toJsonName(original));
        expect(converted, original);
      });

      test('user-name (preserved) roundtrip', () {
        const original = 'user-name';
        final converted = strategy.toDartName(strategy.toJsonName(original));
        expect(converted, original);
      });
    });
  });

  group('Cross-strategy comparison', () {
    test('different strategies produce different outputs', () {
      const input = 'userName';
      final snake = SnakeCaseNamingStrategy().toJsonName(input);
      final kebab = KebabCaseNamingStrategy().toJsonName(input);
      final camel = CamelCaseNamingStrategy().toJsonName(input);

      expect(snake, 'user_name');
      expect(kebab, 'user-name');
      expect(camel, 'userName');
    });

    test('single word is same across all strategies', () {
      const input = 'name';
      final snake = SnakeCaseNamingStrategy().toJsonName(input);
      final kebab = KebabCaseNamingStrategy().toJsonName(input);
      final camel = CamelCaseNamingStrategy().toJsonName(input);

      expect(snake, 'name');
      expect(kebab, 'name');
      expect(camel, 'name');
    });
  });
}