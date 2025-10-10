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

import 'package:jetleaf/jetleaf.dart';

void main(List<String> args) async {
  await JetApplication.run(ExampleApplication(), args);
}

@JetLeafApplication()
class ExampleApplication {
}

class ExampleAnnotationLifecycle {
  @OnApplicationStarting()
  void onStarting() {
    print("Application is starting...");
  }

  @OnApplicationStarting()
  void onStartingWithContext(Class<Object> mainClass) {
    print("Application is starting with main class: $mainClass...");
  }

  @OnApplicationStarting()
  void onStartingWithContextAndMainClass(ConfigurableBootstrapContext context, Class<Object> mainClass) {
    print("Application is starting with main class: $mainClass and context: $context...");
  }

  @OnApplicationStarted()
  void onStarted() {
    print("Application is started...");
  }

  @OnApplicationReady()
  void onReady() {
    print("Application is ready...");
  }

  @OnApplicationFailed()
  void onFailed() {
    print("Application failed to start...");
  }
}