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

import 'package:jetleaf/jetleaf.dart' hide Logger;
import 'common_infrastructure.dart';

/// =============================================================
/// AUTO CONFIGURATION: library-level default pods
/// =============================================================

@Configuration()
class DefaultInfrastructure {
  @Pod()
  Logger coreLogger() => Logger("Core");

  @Pod()
  HttpClientService httpClientService() => HttpClientService();

  @Pod()
  CacheManager defaultCache() => CacheManager(100);
}

/// =============================================================
/// AUTO CONFIGURATION: metrics + tracing
/// =============================================================

@Configuration(null, false) // no proxying pod methods here
class MetricsAutoConfiguration {
  @Pod()
  MetricsRegistry metrics() => MetricsRegistry();

  @Pod()
  TracingService tracing(@Qualifier("appLogger") Logger logger) => TracingService(logger);
}

/// =============================================================
/// APP CONFIGURATION: manual, app-specific
/// =============================================================

@Configuration()
@Import([ClassType<DefaultInfrastructure>(), ClassType<MetricsAutoConfiguration>()])
class ConfigAppConfig {
  final bool enableDb;
  ConfigAppConfig({this.enableDb = true});

  @Pod()
  Logger appLogger() => Logger("App");

  @Pod()
  DataSource? dataSource(@Qualifier("coreLogger") Logger logger) {
    if (!enableDb) {
      logger.log("⚠️ Database disabled by config");
      return null;
    }
    return DataSource("jdbc:postgresql://db:5432/app", "appUser", "securePass");
  }

  @Pod()
  ConfigUserService configUserService(DataSource? ds, CacheManager cache, @Qualifier("appLogger") Logger logger) {
    return ConfigUserService(ds, cache, logger);
  }
}

/// =============================================================
/// Service layer pods using imported + local pods
/// =============================================================

class ConfigUserService {
  final DataSource? ds;
  final CacheManager cache;
  final Logger logger;

  ConfigUserService(this.ds, this.cache, this.logger);

  void createUser(String name) {
    if (ds != null) ds!.connect();
    cache.put("user:$name", name);
    logger.log("✅ Created user $name");
  }
}