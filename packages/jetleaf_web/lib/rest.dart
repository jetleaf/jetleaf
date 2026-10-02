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

/// Jetleaf REST sub-library
///
/// This sub-library defines the **REST client abstraction** of the
/// `jetleaf_web` package.
///
/// Importing `package:jetleaf_web/rest.dart` exposes APIs for building,
/// executing, and intercepting REST requests, along with request and
/// response representations and execution infrastructure.
///
/// This library is intended for outbound HTTP communication and does
/// not include server-side request handling concerns.
library;

export 'src/rest/request_spec.dart';
export 'src/rest/client.dart';
export 'src/rest/executor.dart';
export 'src/rest/interceptor.dart';
export 'src/rest/request.dart';
export 'src/rest/response.dart';