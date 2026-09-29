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

import 'dart:io';
import 'package:jetleaf/jetleaf.dart' hide Logger;
import 'common_infrastructure.dart';

/// =============================================================
/// Infrastructure Pods
/// =============================================================

@Service()
class AutowiredHttpClientService {
  @Autowired()
  final HttpClient client;

  AutowiredHttpClientService(@Qualifier("createHttpClient") this.client);

  void get(String url) => print("🌍 Fetching $url with HttpClient");
}

/// =============================================================
/// Complex Service Layer
/// =============================================================

@Service()
@RequiredAll() // injects all eligible fields automatically
class AnalyticsService {
  late MetricsRegistry metrics;   // auto-injected

  @Qualifier("coreLogger")
  late Logger logger;             // auto-injected

  void trackEvent(String name) {
    metrics.increment(name);
    logger.log("Tracked event: $name");
  }
}

/// Example of fine-grained injection with @Autowired and @TargetType
@Service()
class ApiGatewayService {
  @Autowired()
  @TargetType<AutowiredHttpClientService>()
  late final ObjectProvider<Object> httpClientProvider;

  @Autowired()
  @Qualifier("coreLogger")
  @TargetType<Logger>()
  late final ObjectFactory<Object> loggerFactory;

  void handleRequest(String url) async {
    final clientValue = await httpClientProvider.getIfAvailable();
    final client = clientValue?.getValue() as AutowiredHttpClientService;

    final loggerValue = await loggerFactory.get();
    final logger = loggerValue.getValue() as Logger;

    logger.log("➡️ API Request → $url");
    client.get(url);
  }
}

/// Example of using @KeyValueOf for registry injection
@Service()
class RegistryService {
  @Autowired()
  @Qualifier("coreLogger")
  @KeyValueOf<String, Logger>()
  late final Map<Object, Object> namedLoggers;

  void logToAll(String msg) {
    for (var entry in namedLoggers.entries) {
      (entry.value as Logger).log("(${entry.key}) $msg");
    }
  }
}

/// Example of property injection with @Value
@Service()
class DatabaseService {
  @Value('#{database.url}')
  late final String databaseUrl;

  @Value('#{database.user:defaultUser}')
  late final String username;

  @Value('#{database.password:secret}')
  late final String password;

  void connect() => print("🔗 Connecting to DB at $databaseUrl as $username");
}

/// A service that uses Optional injection
@Service()
class OptionalService {
  @Autowired()
  @Qualifier("coreLogger")
  @TargetType<Logger>()
  late final Optional<Object> optionalLogger;

  void maybeLog(String msg) {
    if (optionalLogger.isPresent()) {
      (optionalLogger.get() as Logger).log(msg);
    } else {
      print("⚠️ No logger present, skipping log.");
    }
  }
}

/// A service that uses List and Set injection
@Service()
class AggregatorService {
  @Autowired()
  @TargetType<Logger>()
  @Qualifier("coreLogger")
  late final List<Object> loggers;

  @Autowired()
  @TargetType<AutowiredHttpClientService>()
  late final Set<Object> httpClients;

  void aggregate(String msg) {
    for (var l in loggers) {
      (l as Logger).log("Agg: $msg");
    }
    for (var hc in httpClients) {
      (hc as AutowiredHttpClientService).get("http://aggregate.local");
    }
  }
}