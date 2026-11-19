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

import 'repository_aware_processor.dart';

export 'repository_aware_processor.dart';

/// {@template jetleaf_repository_application_module}
/// An application module that **registers repository-related infrastructure**
/// into the JetLeaf runtime by adding a [RepositoryAwareProcessor] to the
/// [ApplicationContext].
/// {@endtemplate}
final class RepositoryApplicationModule implements ApplicationModule {
  /// Reflective class descriptor for [RepositoryApplicationModule].
  static final Class<RepositoryApplicationModule> CLASS =
      Class<RepositoryApplicationModule>(null, PackageNames.DATA);

  /// {@macro jetleaf_repository_application_module}
  const RepositoryApplicationModule();

  @override
  Future<void> configure(ApplicationContext context) async {
    context.addPodProcessor(RepositoryAwareProcessor(context));
  }

  @override
  List<Object?> equalizedProperties() => [RepositoryApplicationModule];
}
