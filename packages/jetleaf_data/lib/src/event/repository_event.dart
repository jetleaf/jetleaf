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

import 'package:jetleaf_core/context.dart';
import 'package:jetleaf_core/lang.dart';

import '../core/repository_definition.dart';

export 'intercepted_repository_method_event.dart';

/// {@template jetleaf_repository_event}
/// Base event class for **repository-related application events**.
///
/// All repository events extend [RepositoryEvent] and are associated with a
/// [RepositoryDefinition] as the source.
/// {@endtemplate}
abstract class RepositoryEvent extends ApplicationEvent {
  /// Reflective class descriptor for [RepositoryEvent].
  static final Class<RepositoryEvent> CLASS = Class<RepositoryEvent>(null, PackageNames.DATA);

  /// {@macro jetleaf_repository_event}
  const RepositoryEvent(RepositoryDefinition super.source, super.timestamp);

  @override
  String getPackageName() => PackageNames.DATA;
}
