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
    JetleafProperty.custom("logging.type", "flat", "Logging type"),
    JetleafProperty.custom("logging.level", "all", "Logging level"),
    JetleafProperty.custom("logging.show.time-only", true, "Show time only"),
    JetleafProperty.custom("logging.show.date-only", true, "Show date only"),
    JetleafProperty.custom("logging.show.level", true, "Show level"),
    JetleafProperty.custom("logging.show.tag", true, "Show tag"),
    JetleafProperty.custom("logging.show.timestamp", true, "Show timestamp"),
    JetleafProperty.custom("logging.show.thread", true, "Show thread"),
    JetleafProperty.custom("logging.show.location", true, "Show location"),
    JetleafProperty.custom("logging.show.emoji", true, "Show emoji"),
    JetleafProperty.custom("logging.use-human-readable-time", true, "Use human readable time"),
    JetleafProperty.custom("logging.enabled", true, "Enable logging"),
    JetleafProperty.custom("logging.file", "", "Output log file path"),
    JetleafProperty.custom("logging.steps", [
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
    JetleafProperty.custom("logging.enabled.AbstractPropertyResolver", true, "Enable logging for AbstractPropertyResolver"),
    JetleafProperty.custom("logging.level.AbstractPropertyResolver", "DEBUG", "Logging level for AbstractPropertyResolver"),

    // Banner
    JetleafProperty.custom("banner.location", "resources/banners/banner.txt", "Banner location"),

    // Profiles
    JetleafProperty.custom("jetleaf.profiles.active", "default", "Active profile"),
    JetleafProperty.custom("jetleaf.profiles.default", "default", "Default profile"),

    // Version
    // JetleafProperty.custom("jetleaf.version", "1.0.0", "JetLeaf version"),
    // JetleafProperty.custom("jetleaf.application.version", "0.0.1", "Application version"),
  });
}