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

import 'package:jetleaf_convert/convert.dart';

/// {@template application_conversion_service}
/// A specialized [SimpleConversionService] for JetLeaf applications.
///
/// This service provides type conversion support within the JetLeaf ecosystem,
/// enabling automatic conversion between common Dart and framework types.
/// It is typically used in application contexts to simplify property binding,
/// configuration parsing, and other conversion-heavy operations.
///
/// ### Usage Example
/// ```dart
/// final conversionService = ApplicationConversionService();
///
/// // Example: Converting a String to an int
/// int? port = conversionService.convert<String, int>('8080');
/// print(port); // 8080
///
/// // Example: Registering custom converters
/// conversionService.addConverter<MyType, String>((myType) => myType.toString());
/// ```
///
/// You normally do not instantiate this class directly unless you are
/// customizing conversions at the application level. For most use-cases,
/// JetLeaf bootstrapping will provide an instance automatically.
/// {@endtemplate}
class ApplicationConversionService extends SimpleConversionService {
  /// {@macro application_conversion_service}
  ApplicationConversionService() {
    try {
      DefaultConversionService.addDefaultConverters(this);
    } catch (_) { }
  }
}