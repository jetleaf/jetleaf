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

import 'dart:io';

import 'package:jetleaf_core/lang.dart' show Constant;
import 'package:path/path.dart' as p;

/// {@template workspace}
/// Minimal pub-workspace awareness for the `jl` toolchain.
///
/// A **workspace root** is a `pubspec.yaml` that declares a top-level
/// `workspace:` list of member directories. Members each have their own
/// `pubspec.yaml` (with `resolution: workspace`) and are scanned and built
/// independently — exactly like separate Jetleaf apps sharing one package
/// source tree.
///
/// The `jl dev` / `jl run` / `jl test` / `jl build` / `jl status` / `jl stop`
/// commands are single-project by default; when invoked at a workspace root
/// they fan out to the members automatically. Running them inside a member
/// directory is unchanged.
/// {@endtemplate}
final class Workspace {
  Workspace._();

  /// Reads the top-level `workspace:` list from `<root>/pubspec.yaml` without
  /// requiring a YAML dependency.
  ///
  /// Supports both block and inline list forms:
  /// ```yaml
  /// workspace:
  ///   - common
  ///   - gateway
  /// ```
  /// ```yaml
  /// workspace: [common, gateway]
  /// ```
  static List<String> membersFromPubspec(Directory root) {
    final file = File(p.join(root.path, Constant.PUBSPEC_YAML_FILE_NAME));
    if (!file.existsSync()) return const [];

    final lines = file.readAsLinesSync();
    final members = <String>[];
    var inWorkspace = false;

    for (final rawLine in lines) {
      if (inWorkspace) {
        final trimmed = rawLine.trimRight();
        if (trimmed.isEmpty || trimmed.trimLeft().startsWith('#')) continue;
        // A non-indented, non-comment line ends the block.
        if (!rawLine.startsWith(' ') && !rawLine.startsWith('-')) {
          inWorkspace = false;
        } else {
          final match = RegExp(r'^\s+-\s+([^\s#]+)').firstMatch(rawLine);
          if (match != null) {
            final name = _stripQuotes(match.group(1)!);
            if (name.isNotEmpty) members.add(name);
          }
          continue;
        }
      }

      final trimmed = rawLine.trimRight();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;

      final block = RegExp(r'^workspace\s*:').firstMatch(trimmed);
      if (block != null) {
        final inline = RegExp(r'^workspace\s*:\s*\[([^\]]*)\]').firstMatch(trimmed);
        if (inline != null) {
          for (final element in inline.group(1)!.split(',')) {
            final name = _stripQuotes(element.trim());
            if (name.isNotEmpty) members.add(name);
          }
        } else if (trimmed.endsWith(':')) {
          inWorkspace = true;
        } else {
          // `workspace: name1 name2` (unsupported list-less form) — ignore.
          inWorkspace = false;
        }
        continue;
      }
    }

    return members;
  }

  static String _stripQuotes(String value) {
    var v = value.trim();
    if (v.length >= 2 &&
        ((v.startsWith('"') && v.endsWith('"')) || (v.startsWith("'") && v.endsWith("'")))) {
      v = v.substring(1, v.length - 1);
    }
    return v.trim();
  }

  /// Whether [root] is a pub workspace root.
  static bool isRoot(Directory root) => membersFromPubspec(root).isNotEmpty;

  /// Member directories of the workspace at [root] (each must contain a
  /// `pubspec.yaml`).
  static List<Directory> members(Directory root) => [
    for (final name in membersFromPubspec(root)) ...[
      if (Directory(p.join(root.path, name)).existsSync() && File(p.join(root.path, name, Constant.PUBSPEC_YAML_FILE_NAME)).existsSync()) ...[
        Directory(p.join(root.path, name))
      ]
    ],
  ];

  /// Returns the member directory owning [path] (longest-prefix match), or
  /// `null` when [path] is not inside a member of the workspace at [root].
  static Directory? memberOwning(Directory root, String path) {
    final absolute = p.normalize(p.isAbsolute(path) ? path : p.join(root.path, path));
    Directory? best;
    var bestLength = 0;
    for (final member in members(root)) {
      final memberPath = p.normalize(member.path);
      if (absolute == memberPath || p.isWithin(memberPath, absolute)) {
        if (memberPath.length > bestLength) {
          best = member;
          bestLength = memberPath.length;
        }
      }
    }
    return best;
  }
}