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

/// ==================================================================================
/// Domain Events
/// ==================================================================================

class UserCreatedEvent extends ApplicationEvent {
  UserCreatedEvent(String super.source);
  
  @override
  String getPackageName() => "example";
}

class OrderPlacedEvent extends ApplicationEvent {
  final double total;
  OrderPlacedEvent(String super.source, this.total);

  @override
  String getPackageName() => "example";
}

/// ==================================================================================
/// Application Services
/// ==================================================================================
class UserService {
  final Logger logger;
  UserService(this.logger);

  void createUser(String userId) {
    logger.log("Creating user $userId...");
    // publish event somewhere
  }
}

class OrderService {
  final Logger logger;
  OrderService(this.logger);

  void placeOrder(String orderId, double total) {
    logger.log("Placing order $orderId for \$$total...");
    // publish event somewhere
  }
}

/// ==================================================================================
/// Application Lifecycle & Event Listeners
/// ==================================================================================
class ApplicationLifecycle {
  final Logger logger = Logger("Lifecycle");

  /// Earliest hook → environment ready
  @OnEnvironmentPrepared()
  void configureEnv(ConfigurableEnvironment env) {
    logger.log("🔧 Environment prepared: profiles=${env.getActiveProfiles()}");
  }

  /// Bootstrap stage
  @OnApplicationStarting()
  void starting(ConfigurableBootstrapContext ctx) {
    logger.log("🚀 Application is starting, bootstrapContext=$ctx");
  }

  /// Context loaded but not refreshed yet
  @OnContextLoaded()
  void onContextLoaded(ConfigurableApplicationContext context) {
    logger.log("📦 Context loaded with ${context.getPodAwareProcessorCount()} aware pods");
  }

  /// Context prepared → last chance to tweak beans
  @OnContextPrepared()
  void onContextPrepared(ConfigurableApplicationContext context) {
    logger.log("🛠 Context prepared, overriding DataSource...");
  }

  /// After refresh but before "ready"
  @OnApplicationStarted()
  void afterStart(ConfigurableApplicationContext context, Duration duration) {
    logger.log("✅ App started in ${duration.inMilliseconds}ms");
  }

  /// Fully ready to serve requests
  @OnApplicationReady()
  void ready(ConfigurableApplicationContext context) {
    logger.log("🌐 Application is ready → serving traffic");
  }

  /// Stopping gracefully
  @OnApplicationStopping()
  void stopping() {
    logger.log("🛑 Application stopping...");
  }

  /// Stopped completely
  @OnApplicationStopped()
  void stopped(ApplicationContext context) {
    logger.log("💤 Application stopped with ${context.getNumberOfPodDefinitions()} pods released");
  }

  /// Failed startup
  @OnApplicationFailed()
  void failed(Object error, [ConfigurableApplicationContext? ctx]) {
    logger.log("🔥 Application failed with error=$error, context=$ctx");
  }
}

/// ==================================================================================
/// Event-driven Listeners
/// ==================================================================================
@Service()
class EventConsumers {
  final Logger logger = Logger("Events");

  /// Generic event listener
  @EventListener()
  void onAnyEvent(ApplicationEvent e) {
    logger.log("📩 Event received: $e at ${e.getTimestamp()}");
  }

  /// Specific typed event (user created)
  @EventListener(EventType<UserCreatedEvent>())
  void onUserCreated(UserCreatedEvent e) {
    logger.log("👤 User created → id=${e.getSource()}");
  }

  /// Specific typed event (order placed)
  @EventListener(EventType<OrderPlacedEvent>())
  void onOrderPlaced(OrderPlacedEvent e) {
    logger.log("🛒 Order placed → id=${e.getSource()}, total=\$${e.total}");
  }

  /// Context refreshed core event
  @EventListener(EventType<ContextRefreshedEvent>('core'))
  void onContextRefreshed() {
    logger.log("♻️  Context was refreshed");
  }
}