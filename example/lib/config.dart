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

abstract interface class Logger {
  void log(String message);
}

// ----------------------------------------- CONFIGURATION EXAMPLES --------------------------------------

@Configuration()
final class Config {
  @Pod()
  HttpClient createHttpClient() => HttpClient();
}

// ----------------------------------------- STEREOTYPE EXAMPLES ----------------------------------------

@Primary()
@Service("consoleLogger")
final class ConsoleLogger implements Logger {
  @override
  void log(String message) {
    print(message);
  }
}

@Service()
final class PrintLogger implements Logger {
  @override
  void log(String message) {
    print(message);
  }
}

// ----------------------------------------- AUTO WIRING EXAMPLES -------------------------------------

@Service()
final class Common {
  @Autowired()
  @Qualifier("consoleLogger")
  late final Logger logger;

  @Autowired()
  @Qualifier("printLogger")
  late final Logger printLogger;

  @Autowired()
  @Qualifier("createHttpClient")
  late final HttpClient httpClient;

  @Value("#{banner.loc:banner.txt}")
  late final String bannerLocation;

  Common();

  void doSomething() {
    logger.log("Doing something...");
    logger.log("Http client $httpClient");
  }

  @EventListener()
  void onContextEvent(ContextRefreshedEvent event) {
    logger.log("Event received - $event");
    logger.log("Banner Location: $bannerLocation");
    printLogger.log("Doing something... $printLogger");
  }

  @EventListener(EventType<ContextClosedEvent>())
  void onContextClosedEvent(ContextClosedEvent event) {
    logger.log("Event received - $event");
  }

  @EventListener(EventType<ContextStartedEvent>())
  void onContextStartedEvent() {
    logger.log("Event received - Context Started");
  }

  @EventListener(EventType<ContextRefreshedEvent>())
  void onContextRefreshedEvent() {
    logger.log("Event received - Context Refreshed");
  }

  @OnApplicationStarting()
  void onStarting() {
    // logger.log("Application is starting from common...");
  }
}

@Service()
final class CommonClass {
  @Autowired()
  @Qualifier("consoleLogger")
  late final Logger logger;

  @Autowired()
  @Qualifier("printLogger")
  late final Logger printLogger;

  @Value("#{banner.location:banner.txt}")
  late final String bannerLocation;

  @Value("#{server.port}")
  late final int serverPort;

  @Value("@{createHttpClient}")
  late final HttpClient httpClientPod;

  @Autowired()
  @TargetType<HttpClient>()
  late final ObjectProvider<Object> httpClientProvider;

  @Autowired()
  @TargetType<Logger>()
  @Qualifier("consoleLogger")
  late final ObjectFactory<Object> loggerFactory;

  CommonClass();

  @EventListener()
  void onContextEvent(ContextRefreshedEvent event) async {
    logger.log("Doing something from common class...");
    logger.log("Event received - $event");
    logger.log("Banner Location: $bannerLocation");
    logger.log("HttpClient: $httpClientPod");
    printLogger.log("Doing something... $printLogger");
    logger.log("Server Port: $serverPort");

    final client = await httpClientProvider.getIfAvailable();
    logger.log("HttpClient: $client - ${client?.getValue()}");

    final fLogger = await loggerFactory.get();
    logger.log("Logger: $fLogger - ${fLogger.getValue()}");
  }
}

@Service()
@RequiredAll()
final class RequiredAllClass {
  @Qualifier("consoleLogger")
  late final Logger logger;

  @Qualifier("createHttpClient")
  late final HttpClient httpClient;

  late final Common common;

  RequiredAllClass();

  @EventListener()
  void doSomething() {
    logger.log("Doing something from required all...");
    logger.log("Http client $httpClient");

    common.doSomething();
  }
}