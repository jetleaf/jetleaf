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

import 'package:jetleaf_tools/_jetleaf/test.dart';

/// Registers the test-only registry so reflective paths (annotation
/// instances, constructors, method invokers) work in a plain test run.
///
/// Cached declarations carry only metadata — live types and annotation
/// instances come from the generated registry. Idempotent.
Future<void> ensureTestAotRegistered() => registerTestGeneratedArtifacts();