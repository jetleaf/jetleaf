// ---------------------------------------------------------------------------
// 🍃 JetLeaf Framework - https://jetleaf.hapnium.com
//
// Copyright © 2025 Hapnium & JetLeaf Contributors. All rights reserved.
//
// This source file is part of the JetLeaf Framework and is protected
// under copyright law. You may not copy, modify, or distribute this file
// except in compliance with the JetLeaf license.
//
// For licensing terms, see the LICENSE file in the root of this project.
// ---------------------------------------------------------------------------
//
// 🔧 Powered by Hapnium — the Dart backend engine 🍃

import 'package:jetleaf_core/lang.dart';

import '../exception/data_access_exception.dart';

/// {@template jetleaf_migration_version}
/// Comparable, segment-ordered version identifier for a schema `Migration`.
///
/// Supports both numeric dotted versions (`'1'`, `'1.2'`, `'2.0.1'`) and
/// Flyway-style versioned identifiers (`'V3__add_unique_index'`,
/// `'v2_1__add_column'`).
/// {@endtemplate}
final class MigrationVersion
    with EqualsAndHashCode
    implements Comparable<MigrationVersion> {
  /// Reflective [Class] handle for [MigrationVersion].
  static final Class<MigrationVersion> CLASS =
      Class<MigrationVersion>(null, PackageNames.DATA);

  final List<int> _segments;
  final String? _description;

  /// {@macro jetleaf_migration_version}
  const MigrationVersion(this._segments, [this._description])
      : assert(_segments.length > 0);

  /// Parses [source] into a [MigrationVersion].
  static MigrationVersion parse(String source) {
    var value = source.trim();
    String? description;

    final flywayMatch =
        RegExp(r'^[Vv]([0-9]+(?:[._][0-9]+)*)__(.+)$').firstMatch(value);
    if (flywayMatch != null) {
      value = flywayMatch.group(1)!;
      description = flywayMatch.group(2)!.replaceAll('_', ' ');
    } else if (value.startsWith(RegExp(r'[Vv]'))) {
      value = value.substring(1);
    }

    value = value.replaceAll('_', '.');

    final pieces = value.split('.');
    final segments = <int>[];
    for (final piece in pieces) {
      if (piece.isEmpty) {
        throw MigrationException(
          'Malformed migration version "$source" — empty segment',
        );
      }
      final parsed = int.tryParse(piece);
      if (parsed == null) {
        throw MigrationException(
          'Malformed migration version "$source" — segment "$piece" is not numeric',
        );
      }
      segments.add(parsed);
    }

    if (segments.isEmpty) {
      throw MigrationException('Malformed migration version "$source"');
    }

    return MigrationVersion(List.unmodifiable(segments), description);
  }

  /// Returns the ordered numeric version segments.
  List<int> getSegments() => _segments;

  /// Returns the human-readable migration description, if any.
  String? getDescription() => _description;

  /// Returns the canonical dotted version string (e.g. `'2.0.1'`).
  String getValue() => _segments.join('.');

  @override
  int compareTo(MigrationVersion other) {
    final otherSegments = other.getSegments();
    final length = _segments.length > otherSegments.length
        ? _segments.length
        : otherSegments.length;
    for (var i = 0; i < length; i++) {
      final left = i < _segments.length ? _segments[i] : 0;
      final right = i < otherSegments.length ? otherSegments[i] : 0;
      if (left != right) {
        return left.compareTo(right);
      }
    }
    return 0;
  }

  @override
  List<Object?> equalizedProperties() => [_segments, _description];

  @override
  String toString() =>
      _description != null ? '${getValue()} ($_description)' : getValue();
}
