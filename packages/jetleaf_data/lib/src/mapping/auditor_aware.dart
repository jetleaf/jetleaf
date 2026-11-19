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

import 'dart:async';

import 'package:jetleaf_core/lang.dart';

/// {@template jetleaf_auditor_aware}
/// Strategy interface for resolving the **current auditor** (user or principal
/// identifier) when populating `@CreatedBy` and `@LastModifiedBy` entity fields.
///
/// Applications or security modules (such as `jetleaf_security`) register a
/// pod implementing [AuditorAware] to integrate identity resolution with
/// automatic entity auditing.
///
/// ### Usage Example
/// ```dart
/// @Service()
/// final class SecurityAuditorAware implements AuditorAware<String> {
///   @override
///   FutureOr<String?> getCurrentAuditor() => 'system-admin';
/// }
/// ```
///
/// ### See Also
/// - `CreatedBy`
/// - `LastModifiedBy`
/// {@endtemplate}
@Generic(AuditorAware)
abstract interface class AuditorAware<T> {
  /// Reflective [Class] handle for [AuditorAware].
  static final Class<AuditorAware> CLASS = Class<AuditorAware>(null, PackageNames.DATA);

  /// Returns the current auditor identifier, or `null` if no principal is
  /// active in the current execution context.
  FutureOr<T?> getCurrentAuditor();
}
