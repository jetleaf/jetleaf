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

import 'package:jetleaf/jetleaf.dart';

final class ExampleApplicationModule implements ApplicationModule {
  @override
  Future<void> configure(ApplicationContext context) async {
    String name = context.getApplicationName();
    print("Running application of $name from ExampleApplicationModule");
  }

  @override
  List<Object?> equalizedProperties() => [ExampleApplicationModule];
}

@Component()
final class ComplexApplicationModule implements ApplicationModule {
  @override
  Future<void> configure(ApplicationContext context) async {
    String name = context.getApplicationName();
    print("Running application of $name from ComplexApplicationModule");
  }

  @override
  List<Object?> equalizedProperties() => [ComplexApplicationModule];
}