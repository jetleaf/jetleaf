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

import 'package:jetleaf_env/property.dart';

class Application extends ApplicationConfigurationProperty {
  @override
  ApplicationConfigurationProperties properties() => ApplicationConfigurationProperties({
    JetProperty.custom("logging.type", "flat", "Logging type"),
    JetProperty.custom("logging.level", "all", "Logging level"),
    JetProperty.custom("logging.show.time-only", true, "Show time only"),
    JetProperty.custom("logging.show.date-only", true, "Show date only"),
    JetProperty.custom("logging.show.level", true, "Show level"),
    JetProperty.custom("logging.show.tag", true, "Show tag"),
    JetProperty.custom("logging.show.timestamp", true, "Show timestamp"),
    JetProperty.custom("logging.show.thread", true, "Show thread"),
    JetProperty.custom("logging.show.location", true, "Show location"),
    JetProperty.custom("logging.show.emoji", true, "Show emoji"),
    JetProperty.custom("logging.use-human-readable-time", true, "Use human readable time"),
    JetProperty.custom("logging.enabled", true, "Enable logging"),
    JetProperty.custom("logging.file", "", "Output log file path"),
    JetProperty.custom("logging.steps", [
      "thread",
      "location",
      "date",
      "timestamp",
      "level",
      "tag",
      "message",
      "error",
      "stacktrace",
    ], "Logging steps"),

    // AbstractPropertyResolver
    JetProperty.custom("logging.enabled.AbstractPropertyResolver", true, "Enable logging for AbstractPropertyResolver"),
    JetProperty.custom("logging.level.AbstractPropertyResolver", "DEBUG", "Logging level for AbstractPropertyResolver"),

    // Banner
    JetProperty.custom("banner.location", "resources/banners/banner.txt", "Banner location"),

    // Profiles
    JetProperty.custom("jetleaf.profiles.active", "default", "Active profile"),
    JetProperty.custom("jetleaf.profiles.default", "default", "Default profile"),

    // Version
    // JetProperty.custom("jetleaf.version", "1.0.0", "JetLeaf version"),
    // JetProperty.custom("jetleaf.application.version", "0.0.1", "Application version"),
  });
}