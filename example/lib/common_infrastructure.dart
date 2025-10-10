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

import 'dart:io';

import 'package:jetleaf/jetleaf.dart';

/// =============================================================
/// Shared Infrastructure Classes - Used across all examples
/// =============================================================

class Logger {
  final String scope;
  Logger(this.scope);

  void log(String msg) => print("[$scope] $msg");
}

class DataSource {
  final String url;
  final String username;
  final String password;

  DataSource(this.url, this.username, this.password);

  void connect() => print("🔗 Connected to $url as $username");
}

class CacheManager {
  final int size;
  CacheManager(this.size);

  void put(String key, Object value) =>
      print("🗄️  Caching [$key] → $value");
}

class HttpClientService {
  final HttpClient client = HttpClient();
  void get(String url) => print("🌍 Fetching $url");
}

class MetricsRegistry {
  final Map<String, int> counters = {};
  void inc(String name) {
    counters[name] = (counters[name] ?? 0) + 1;
    print("📊 $name = ${counters[name]}");
  }
  
  void increment(String name) => inc(name);
}

class MessageBroker {
  final String endpoint;
  MessageBroker(this.endpoint);

  void publish(String topic, String message) =>
      print("📢 [$endpoint] $topic → $message");
}

@Component()
class Database {
  Future<List<User>> query(String sql) async => [];
  Future<void> execute(String sql, List<dynamic> params) async {}
}

class User {
  final String name;
  final String email;

  User({required this.name, required this.email});
}

class ConfigSource {
  final Map<String, String> values;
  ConfigSource(this.values);

  String? get(String key) => values[key];
}

class TracingService {
  final Logger logger;
  TracingService(this.logger);

  void trace(String operation) => logger.log("Tracing $operation");
}