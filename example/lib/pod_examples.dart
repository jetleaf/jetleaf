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
// BASIC POD DEFINITIONS
// ----------------------------------------------------------------------------------------------------------

import 'package:jetleaf/jetleaf.dart';

final class PodLogger {
  final String name;

  PodLogger(this.name);
}

final class HttpClient {
  final PodLogger logger;

  HttpClient(this.logger);
}

@Configuration()
class AppConfig {
  @Pod()
  PodLogger logger() => PodLogger('AppLogger');

  @Pod()
  HttpClient httpClient(PodLogger logger) => HttpClient(logger);
}

// ----------------------------------------------------------------------------------------------------------
// NAMED PODS
// ----------------------------------------------------------------------------------------------------------

abstract interface class Notifier {
  void send(String msg);
}

final class EmailNotifier implements Notifier {
  void send(String msg) => print("Email: $msg");
}

final class SmsNotifier implements Notifier {
  void send(String msg) => print("SMS: $msg");
}

@Configuration()
class NotificationConfig {
  @Pod(value: 'emailPodNotifier')
  Notifier emailNotifier() => EmailNotifier();

  @Pod(value: 'smsPodNotifier')
  Notifier smsNotifier() => SmsNotifier();
}

// ----------------------------------------------------------------------------------------------------------
// INIT + DESTROY METHODS
// ----------------------------------------------------------------------------------------------------------

class Cache {
  void init() => print('Cache initialized');
  void dispose() => print('Cache disposed');
}

@Configuration()
class CacheConfig {
  @Pod(
    initMethods: ['init'],
    destroyMethods: ['dispose'],
  )
  Cache cache() => Cache();
}

// ----------------------------------------------------------------------------------------------------------
// ENFORCING LIFECYCLE METHODS
// ----------------------------------------------------------------------------------------------------------

class Connection {
  void start() => print('Connection started');
  void shutdown() => print('Connection shutdown');
}

@Configuration()
class ConnectionConfig {
  @Pod(
    initMethods: ['start'],
    destroyMethods: ['shutdown'],
    enforceInitMethods: true,
    enforceDestroyMethods: true,
  )
  Connection connection() => Connection();
}

// ----------------------------------------------------------------------------------------------------------
// AUTOWIRE MODES
// ----------------------------------------------------------------------------------------------------------

class Repository {}

class Service {
  final Repository repo;
  Service(this.repo);
}

@Configuration()
class ServiceConfig {
  @Pod(value: 'servicePod', autowireMode: AutowireMode.BY_TYPE)
  Service service(Repository repo) => Service(repo);

  @Pod()
  Repository repository() => Repository();
}

// ----------------------------------------------------------------------------------------------------------
// POD WITH SCOPES
// ----------------------------------------------------------------------------------------------------------

final class DatabaseConnection {
  final String url;
  final bool readOnly;

  DatabaseConnection({required this.url, this.readOnly = false});
}

@Configuration()
class ScopedConfig {
  @Pod()
  @Scope('singleton')
  DatabaseConnection primaryDatabase() =>
      DatabaseConnection(url: 'postgresql://localhost:5432/primary');

  @Pod(value: 'readOnlyDatabase')
  @Scope('prototype')
  DatabaseConnection readOnlyDatabase() =>
      DatabaseConnection(url: 'postgresql://localhost:5432/readonly', readOnly: true);
}