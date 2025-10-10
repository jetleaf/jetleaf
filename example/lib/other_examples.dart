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

// ----------------------------------------------------------------------------------------------------------
// QUALIFIER
// ----------------------------------------------------------------------------------------------------------

import 'package:jetleaf/jetleaf.dart';

abstract interface class Notifier {
  void send(String msg);
}

@Component()
class NotificationService {
  final Notifier notifier;

  NotificationService(@Qualifier('smsOtherNotifier') this.notifier);
}

@Component('smsOtherNotifier')
class SmsNotifier implements Notifier {
  void send(String msg) => print("SMS: $msg");
}

@Component('emailOtherNotifier')
class EmailNotifier implements Notifier {
  void send(String msg) => print("Email: $msg");
}

// ----------------------------------------------------------------------------------------------------------
// LAZY
// ----------------------------------------------------------------------------------------------------------

@Lazy()
@Component()
class ExpensiveReportService {
  ExpensiveReportService() {
    print("ExpensiveReportService initialized lazily!");
  }
}

// ----------------------------------------------------------------------------------------------------------
// ORDER
// ----------------------------------------------------------------------------------------------------------

@Order(0)
@Component()
class HighestPriorityMiddleware {}

@Order(2)
@Component()
class SecondMiddleware {}

@Order(1)
@Component()
class FirstMiddleware {}

// ----------------------------------------------------------------------------------------------------------
// PRIMARY
// ----------------------------------------------------------------------------------------------------------

abstract interface class PaymentProcessor {
  void processPayment();
}

class StripePaymentProcessor implements PaymentProcessor {
  @override
  void processPayment() {
    print("Processing payment with Stripe");
  }
}

class PayPalPaymentProcessor implements PaymentProcessor {
  @override
  void processPayment() {
    print("Processing payment with PayPal");
  }
}

@Configuration()
class PaymentConfig {
  @Pod()
  @Primary()
  PaymentProcessor primaryProcessor() => StripePaymentProcessor();

  @Pod(value: 'paypalProcessor')
  PaymentProcessor paypalProcessor() => PayPalPaymentProcessor();
}

// ----------------------------------------------------------------------------------------------------------
// PROFILE
// ----------------------------------------------------------------------------------------------------------

abstract interface class DatabaseService {
  void connect();
}

@Component()
@Profile(['development'])
class DevDatabaseService implements DatabaseService {
  @override
  void connect() {
    print("Connecting to development database");
  }
}

@Component()
@Profile(['production'])
class ProdDatabaseService implements DatabaseService {
  @override
  void connect() {
    print("Connecting to production database");
  }
}

@Component()
@Profile.not(['production'])
class DebugService {}

// ----------------------------------------------------------------------------------------------------------
// SCOPE
// ----------------------------------------------------------------------------------------------------------

@Component()
@Scope('singleton')
class SingletonCacheService {}

@Component()
@Scope('prototype')
class PrototypeWorker {}

// ----------------------------------------------------------------------------------------------------------
// PRE DESTROY
// ----------------------------------------------------------------------------------------------------------

@Service()
class CacheManagerService {
  final _cache = <String, String>{};

  void put(String k, String v) => _cache[k] = v;

  @PreDestroy()
  void clearCache() {
    print("Clearing cache before shutdown...");
    _cache.clear();
  }
}

// ----------------------------------------------------------------------------------------------------------
// CLEAN UP
// ----------------------------------------------------------------------------------------------------------

@Service()
class WorkerPool {
  final _workers = <String>[];

  @Cleanup()
  Future<void> shutdownWorkers() async {
    print("Shutting down workers...");
    _workers.clear();
  }
}

// ----------------------------------------------------------------------------------------------------------
// PRE CONSTRUCT
// ----------------------------------------------------------------------------------------------------------

@Service()
class DataInitializer {
  @PreConstruct()
  void prepare() {
    print("PreConstruct: Preparing database schema...");
  }
}

// ----------------------------------------------------------------------------------------------------------
// POST CONSTRUCT
// ----------------------------------------------------------------------------------------------------------

@Service("otherUserService")
class OtherUserService {
  @Autowired()
  // @Qualifier("databaseService")
  late final DatabaseService db;

  @PostConstruct()
  void init() {
    print("PostConstruct: Warm up caches with users...");
  }
}

// ----------------------------------------------------------------------------------------------------------
// DEPENDS ON
// ----------------------------------------------------------------------------------------------------------

@Component("otherAnalyticsService")
@DependsOn(["databaseService"])
class OtherAnalyticsService {
  void init() => print("Analytics depends on database");
}

// ----------------------------------------------------------------------------------------------------------
// ROLE + DESCRIPTION
// ----------------------------------------------------------------------------------------------------------

@Role(DesignRole.APPLICATION)
@Description('Handles user-related business operations')
class UserServiceWithRole {
  Future<String> findUser(String id) async => "User($id)";
}