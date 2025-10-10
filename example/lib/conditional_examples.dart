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
import 'common_infrastructure.dart';

/// =============================================================
///  Services
/// =============================================================

final class ConditionalUserService {
  final DataSource dataSource;
  final CacheManager cache;
  final Logger logger;

  ConditionalUserService(this.dataSource, this.cache, this.logger);

  void createUser(String name) {
    dataSource.connect();
    cache.put("user:$name", name);
    logger.log("✅ User $name created.");
  }
}

final class PaymentService {
  final DataSource dataSource;
  final MessageBroker broker;
  final Logger logger;

  PaymentService(this.dataSource, this.broker, this.logger);

  void processPayment(int amount) {
    dataSource.connect();
    broker.publish("payments", "Processed \$$amount");
    logger.log("💰 Payment processed: $amount");
  }
}

final class FeatureToggleService {
  final bool enabled;
  FeatureToggleService(this.enabled);

  void check() => print(enabled ? "🚀 Feature is ENABLED" : "❌ Feature is DISABLED");
}

final class ClusterManager {
  final List<String> nodes;
  ClusterManager(this.nodes);

  String pickNode() => nodes.isNotEmpty ? nodes.first : "no-node";
}

/// =============================================================
///  Conditional Configurations
/// =============================================================

/// 1. Property-based: SSL mode for DataSource
@ConditionalOnProperty(prefix: 'db', names: ['ssl.enabled'], havingValue: 'true')
final class SslDataSourceConfiguration {
  @Pod()
  DataSource sslDataSource() => DataSource(
    "jdbc:postgresql://secure-db:5432/app?ssl=true",
    "secureUser",
    "superSecret",
  );
}

/// 2. Missing class fallback (if DataSource isn't on classpath)
@ConditionalOnMissingClass(value: [ClassType<DataSource>()], names: ['dataSource'])
final class FallbackDataSourceConfiguration {
  @Pod()
  DataSource fallbackDataSource() => DataSource("memory://fallback", "na", "na");
}

/// 3. Missing Pod (if no cache configured, provide default)
@ConditionalOnMissingPod(types: [ClassType<CacheManager>()], names: ['cacheManager'])
final class DefaultCacheConfiguration {
  @Pod()
  CacheManager defaultCache() => CacheManager(100);
}

/// 4. Profile: Dev environment
@ConditionalOnProfile(['dev'])
final class DevConfiguration {
  @Pod()
  DataSource devDataSource() => DataSource("jdbc:h2:mem:devdb", "dev", "devpass");

  @Pod()
  Logger devLogger() => Logger("DEV");
}

/// 5. Profile: Prod environment
@ConditionalOnProfile(['prod'])
final class ProdConfiguration {
  @Pod()
  DataSource prodDataSource() => DataSource("jdbc:postgresql://prod-db:5432/app", "produser", "securepass");

  @Pod()
  Logger prodLogger() => Logger("PROD");
}

/// 6. Dart version–specific
@ConditionalOnDart("3.0")
final class Dart3Config {
  @Pod()
  Logger dart3Logger() => Logger("Dart3-Only");
}

/// 7. Dart version within range
@ConditionalOnDart("3.0", VersionRange(start: Version(3, 0, 0), end: Version(3, 1, 0)))
final class Dart3RangeConfig {
  @Pod()
  CacheManager experimentalCache() => CacheManager(9999);
}

/// 8. Conditional on existing Pod (UserService only if DataSource + Cache exist)
@ConditionalOnPod(types: [ClassType<DataSource>(), ClassType<CacheManager>()])
final class UserServiceConfiguration {
  @Pod()
  ConditionalUserService userService(DataSource ds, CacheManager cache, Logger logger) => ConditionalUserService(ds, cache, logger);
}

/// 9. Conditional on existing Class (PaymentService only if MessageBroker exists)
@ConditionalOnClass(value: [ClassType<MessageBroker>()])
final class PaymentServiceConfiguration {
  @Pod()
  PaymentService paymentService(DataSource ds, MessageBroker broker, Logger logger) => PaymentService(ds, broker, logger);
}

/// 10. Asset-based condition
@ConditionalOnAsset("assets/feature.flag")
final class FeatureFlagConfiguration {
  @Pod()
  FeatureToggleService featureToggle() => FeatureToggleService(true);
}

/// 11. Expression-driven condition
@ConditionalOnExpression("&{systemProperties['user.home']} != null")
final class UserHomeConfiguration {
  @Pod()
  Logger homeLogger() => Logger("HOME-LOGGER");
}

/// 12. Cluster mode (property-driven)
@ConditionalOnProperty(prefix: 'system', names: ['mode'], havingValue: 'cluster')
final class ClusterConfiguration {
  @Pod()
  ClusterManager clusterManager() => ClusterManager([
    "node1.local",
    "node2.local",
    "node3.local",
  ]);
}