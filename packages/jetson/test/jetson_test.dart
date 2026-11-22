// ---------------------------------------------------------------------------
// 🍃 Jetleaf Framework - https://jetleaf.hapnium.com
//
// Copyright © 2025 Hapnium & Jetleaf Contributors. All rights reserved.
//
// This source file is part of the JetLeaf Framework and is protected
// under copyright law. You may not copy, modify, or distribute this file
// except in compliance with the Jetleaf license.
//
// For licensing terms, see the LICENSE file in the root of this project.
// ---------------------------------------------------------------------------
//
// 🔧 Powered by Hapnium — the Dart backend engine 🍃

import 'package:jetleaf_core/lang.dart';
import 'package:jetson/src/base/object_mapper.dart';
import 'package:test/test.dart';

final class Address {}

final class User {
  final String email;
  final String password;
  final Address address;

  const User(this.address, this.email, this.password);
}

/// Jetson smoke test.
///
/// Runs without the Jetleaf AOT registry by round-tripping a document into a
/// plain [Map]. Constructing rich DTO instances requires the generated AOT
/// registry and is covered by `jl test` entries.
void main() {
  test('readValue round-trips a flat payload into a map', () {
    final jetson = ObjectMapper();

    final value = jetson.readValue(
      '{"email": "ada@example.dev", "password": "secret", "address": {"city": "Denver"}}',
      Class<Map<String, dynamic>>(),
    );

    expect(value['email'], 'ada@example.dev');
    expect(value['password'], 'secret');
    expect(value['address'], isA<Map<String, dynamic>>());
    expect((value['address'] as Map<String, dynamic>)['city'], 'Denver');
  });

  test('readValue preserves empty collections and null fields', () {
    final jetson = ObjectMapper();

    final value = jetson.readValue(
      '{"items": [], "meta": null, "ok": true}',
      Class<Map<String, dynamic>>(),
    );

    expect(value['items'], isEmpty);
    expect(value.containsKey('meta'), isTrue);
    expect(value['meta'], isNull);
    expect(value['ok'], isTrue);
  });
}