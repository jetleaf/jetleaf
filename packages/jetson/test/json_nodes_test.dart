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

import 'package:jetson/src/json/node/json_boolean_node.dart';
import 'package:jetson/src/json/node/json_null_node.dart';
import 'package:jetson/src/json/node/json_number_node.dart';
import 'package:jetson/src/json/node/json_text_node.dart';
import 'package:jetson/src/json/node/json_map_node.dart';
import 'package:jetson/src/json/node/json_array_node.dart';
import 'package:jetleaf_lang/jetleaf_lang.dart';
import 'package:test/test.dart';

void main() {
  group('JsonTextNode', () {
    test('stores value correctly', () {
      final node = JsonTextNode('hello');
      expect(node.value, 'hello');
    });

    test('toObject returns the string value', () {
      final node = JsonTextNode('hello');
      expect(node.toObject(), 'hello');
    });

    test('isTextual returns true', () {
      final node = JsonTextNode('');
      expect(node.isTextual(), isTrue);
    });

    test('isObject returns false', () {
      final node = JsonTextNode('');
      expect(node.isObject(), isFalse);
    });

    test('isArray returns false', () {
      final node = JsonTextNode('');
      expect(node.isArray(), isFalse);
    });

    test('isNumber returns false', () {
      final node = JsonTextNode('');
      expect(node.isNumber(), isFalse);
    });

    test('isBoolean returns false', () {
      final node = JsonTextNode('');
      expect(node.isBoolean(), isFalse);
    });

    test('isNull returns false', () {
      final node = JsonTextNode('');
      expect(node.isNull(), isFalse);
    });

    test('handles empty string', () {
      final node = JsonTextNode('');
      expect(node.value, '');
      expect(node.toObject(), '');
    });

    test('handles string with special characters', () {
      final node = JsonTextNode('line1\nline2\ttab');
      expect(node.value, 'line1\nline2\ttab');
    });

    test('handles unicode strings', () {
      final node = JsonTextNode('🍃');
      expect(node.value, '🍃');
      expect(node.toObject(), '🍃');
    });
  });

  group('JsonNumberNode', () {
    test('stores integer value correctly', () {
      final node = JsonNumberNode(42);
      expect(node.value, 42);
    });

    test('stores double value correctly', () {
      final node = JsonNumberNode(3.14);
      expect(node.value, 3.14);
    });

    test('toObject returns the number value', () {
      final node = JsonNumberNode(42);
      expect(node.toObject(), 42);
    });

    test('isNumber returns true', () {
      final node = JsonNumberNode(0);
      expect(node.isNumber(), isTrue);
    });

    test('isObject returns false', () {
      final node = JsonNumberNode(0);
      expect(node.isObject(), isFalse);
    });

    test('isArray returns false', () {
      final node = JsonNumberNode(0);
      expect(node.isArray(), isFalse);
    });

    test('isTextual returns false', () {
      final node = JsonNumberNode(0);
      expect(node.isTextual(), isFalse);
    });

    test('isBoolean returns false', () {
      final node = JsonNumberNode(0);
      expect(node.isBoolean(), isFalse);
    });

    test('isNull returns false', () {
      final node = JsonNumberNode(0);
      expect(node.isNull(), isFalse);
    });

    test('handles zero', () {
      final node = JsonNumberNode(0);
      expect(node.value, 0);
      expect(node.toObject(), 0);
    });

    test('handles negative numbers', () {
      final node = JsonNumberNode(-42);
      expect(node.value, -42);
      expect(node.toObject(), -42);
    });

    test('handles large numbers', () {
      final node = JsonNumberNode(999999999999999);
      expect(node.value, 999999999999999);
    });

    test('handles scientific notation', () {
      final node = JsonNumberNode(1e10);
      expect(node.value, 1e10);
    });
  });

  group('JsonBooleanNode', () {
    test('stores true value correctly', () {
      final node = JsonBooleanNode(true);
      expect(node.value, isTrue);
    });

    test('stores false value correctly', () {
      final node = JsonBooleanNode(false);
      expect(node.value, isFalse);
    });

    test('toObject returns the boolean value', () {
      final node = JsonBooleanNode(true);
      expect(node.toObject(), true);
    });

    test('isBoolean returns true', () {
      final node = JsonBooleanNode(true);
      expect(node.isBoolean(), isTrue);
    });

    test('isObject returns false', () {
      final node = JsonBooleanNode(true);
      expect(node.isObject(), isFalse);
    });

    test('isArray returns false', () {
      final node = JsonBooleanNode(true);
      expect(node.isArray(), isFalse);
    });

    test('isTextual returns false', () {
      final node = JsonBooleanNode(true);
      expect(node.isTextual(), isFalse);
    });

    test('isNumber returns false', () {
      final node = JsonBooleanNode(true);
      expect(node.isNumber(), isFalse);
    });

    test('isNull returns false', () {
      final node = JsonBooleanNode(true);
      expect(node.isNull(), isFalse);
    });
  });

  group('JsonNullNode', () {
    test('const constructor works', () {
      const node = JsonNullNode();
      expect(node, isA<JsonNullNode>());
    });

    test('toObject returns Null instance', () {
      const node = JsonNullNode();
      expect(node.toObject(), isA<Null>());
    });

    test('isNull returns true', () {
      const node = JsonNullNode();
      expect(node.isNull(), isTrue);
    });

    test('isObject returns false', () {
      const node = JsonNullNode();
      expect(node.isObject(), isFalse);
    });

    test('isArray returns false', () {
      const node = JsonNullNode();
      expect(node.isArray(), isFalse);
    });

    test('isTextual returns false', () {
      const node = JsonNullNode();
      expect(node.isTextual(), isFalse);
    });

    test('isNumber returns false', () {
      const node = JsonNullNode();
      expect(node.isNumber(), isFalse);
    });

    test('isBoolean returns false', () {
      const node = JsonNullNode();
      expect(node.isBoolean(), isFalse);
    });
  });

  group('JsonMapNode', () {
    test('creates empty map node', () {
      final node = JsonMapNode();
      expect(node.fields, isEmpty);
    });

    test('set and get fields', () {
      final node = JsonMapNode();
      node.set('name', JsonTextNode('Alice'));
      node.set('age', JsonNumberNode(30));

      expect(node.get('name'), isA<JsonTextNode>());
      expect(node.get('age'), isA<JsonNumberNode>());
      expect(node.get('missing'), isNull);
    });

    test('toObject converts to Map', () {
      final node = JsonMapNode();
      node.set('name', JsonTextNode('Alice'));
      node.set('age', JsonNumberNode(30));

      final obj = node.toObject();
      expect(obj, {'name': 'Alice', 'age': 30});
    });

    test('isObject returns true', () {
      final node = JsonMapNode();
      expect(node.isObject(), isTrue);
    });

    test('isArray returns false', () {
      final node = JsonMapNode();
      expect(node.isArray(), isFalse);
    });

    test('isTextual returns false', () {
      final node = JsonMapNode();
      expect(node.isTextual(), isFalse);
    });

    test('isNumber returns false', () {
      final node = JsonMapNode();
      expect(node.isNumber(), isFalse);
    });

    test('isBoolean returns false', () {
      final node = JsonMapNode();
      expect(node.isBoolean(), isFalse);
    });

    test('isNull returns false', () {
      final node = JsonMapNode();
      expect(node.isNull(), isFalse);
    });

    test('handles nested objects', () {
      final inner = JsonMapNode();
      inner.set('value', JsonTextNode('nested'));

      final outer = JsonMapNode();
      outer.set('inner', inner);

      final obj = outer.toObject();
      expect(obj, {'inner': {'value': 'nested'}});
    });

    test('replaces existing field', () {
      final node = JsonMapNode();
      node.set('key', JsonTextNode('old'));
      node.set('key', JsonTextNode('new'));

      expect(node.toObject(), {'key': 'new'});
    });

    test('fields map returns internal fields', () {
      final node = JsonMapNode();
      node.set('a', JsonTextNode('1'));
      node.set('b', JsonNumberNode(2));

      expect(node.fields.length, 2);
      expect(node.fields.containsKey('a'), isTrue);
      expect(node.fields.containsKey('b'), isTrue);
    });
  });

  group('JsonArrayNode', () {
    test('creates empty array node', () {
      final node = JsonArrayNode();
      expect(node.elements, isEmpty);
    });

    test('add elements', () {
      final node = JsonArrayNode();
      node.add(JsonTextNode('Alice'));
      node.add(JsonNumberNode(30));

      expect(node.elements.length, 2);
    });

    test('toObject converts to List', () {
      final node = JsonArrayNode();
      node.add(JsonTextNode('Alice'));
      node.add(JsonNumberNode(30));
      node.add(JsonBooleanNode(true));

      final obj = node.toObject();
      expect(obj, ['Alice', 30, true]);
    });

    test('isArray returns true', () {
      final node = JsonArrayNode();
      expect(node.isArray(), isTrue);
    });

    test('isObject returns false', () {
      final node = JsonArrayNode();
      expect(node.isObject(), isFalse);
    });

    test('isTextual returns false', () {
      final node = JsonArrayNode();
      expect(node.isTextual(), isFalse);
    });

    test('isNumber returns false', () {
      final node = JsonArrayNode();
      expect(node.isNumber(), isFalse);
    });

    test('isBoolean returns false', () {
      final node = JsonArrayNode();
      expect(node.isBoolean(), isFalse);
    });

    test('isNull returns false', () {
      final node = JsonArrayNode();
      expect(node.isNull(), isFalse);
    });

    test('handles nested arrays', () {
      final inner = JsonArrayNode();
      inner.add(JsonTextNode('nested'));

      final outer = JsonArrayNode();
      outer.add(inner);

      final obj = outer.toObject();
      expect(obj, [['nested']]);
    });

    test('handles mixed types', () {
      final node = JsonArrayNode();
      node.add(JsonTextNode('text'));
      node.add(JsonNumberNode(42));
      node.add(JsonBooleanNode(false));
      node.add(JsonNullNode());

      final obj = node.toObject();
      expect(obj.length, 4);
      expect(obj[0], 'text');
      expect(obj[1], 42);
      expect(obj[2], false);
      expect(obj[3], isA<Null>());
    });

    test('elements list preserves order', () {
      final node = JsonArrayNode();
      node.add(JsonTextNode('first'));
      node.add(JsonTextNode('second'));
      node.add(JsonTextNode('third'));

      expect(node.elements[0].toObject(), 'first');
      expect(node.elements[1].toObject(), 'second');
      expect(node.elements[2].toObject(), 'third');
    });
  });

  group('Complex node structures', () {
    test('builds a complex JSON structure', () {
      final address = JsonMapNode();
      address.set('street', JsonTextNode('123 Main St'));
      address.set('city', JsonTextNode('Denver'));

      final user = JsonMapNode();
      user.set('name', JsonTextNode('Alice'));
      user.set('age', JsonNumberNode(30));
      user.set('address', address);

      final root = JsonMapNode();
      root.set('user', user);

      final obj = root.toObject();
      expect(obj, {
        'user': {
          'name': 'Alice',
          'age': 30,
          'address': {
            'street': '123 Main St',
            'city': 'Denver',
          },
        },
      });
    });

    test('builds array of objects', () {
      final users = JsonArrayNode();

      final user1 = JsonMapNode();
      user1.set('id', JsonNumberNode(1));
      user1.set('name', JsonTextNode('Alice'));

      final user2 = JsonMapNode();
      user2.set('id', JsonNumberNode(2));
      user2.set('name', JsonTextNode('Bob'));

      users.add(user1);
      users.add(user2);

      final obj = users.toObject();
      expect(obj.length, 2);
      expect(obj[0]['name'], 'Alice');
      expect(obj[1]['name'], 'Bob');
    });
  });
}