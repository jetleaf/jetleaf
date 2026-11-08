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

import 'naming_strategy.dart';

/// {@template snake_case_naming_strategy}
/// Converts field names from camelCase to snake_case and vice versa.
///
/// This strategy is commonly used when working with JSON APIs that follow
/// the snake_case convention, particularly in Python-based APIs or databases
/// that use snake_case column names.
///
/// ### Transformation Rules:
/// - **camelCase to snake_case**: Insert underscores before uppercase letters and convert to lowercase
/// - **snake_case to camelCase**: Remove underscores and capitalize following letters
///
/// ### Examples:
/// ```dart
/// final strategy = SnakeCaseNamingStrategy();
/// 
/// // camelCase to snake_case
/// strategy.toJsonName('userName');        // 'user_name'
/// strategy.toJsonName('HTTPRequest');     // 'http_request'
/// strategy.toJsonName('userId');          // 'user_id'
/// strategy.toJsonName('XMLParser');       // 'xml_parser'
/// strategy.toJsonName('createdAt');       // 'created_at'
/// 
/// // snake_case to camelCase
/// strategy.toDartName('user_name');       // 'userName'
/// strategy.toDartName('http_request');    // 'httpRequest'
/// strategy.toDartName('user_id');         // 'userId'
/// strategy.toDartName('xml_parser');      // 'xmlParser'
/// strategy.toDartName('created_at');      // 'createdAt'
/// ```
///
/// ### Edge Case Handling:
/// - Leading uppercase letters are handled correctly
/// - Consecutive uppercase letters are treated as acronyms
/// - Numbers are preserved without modification
/// - Multiple consecutive underscores are collapsed during conversion
///
/// ### Usage with JSON Serialization:
/// ```dart
/// @Serializable(namingStrategy: SnakeCaseNamingStrategy())
/// class User {
///   final String firstName;
///   final String lastName;
///   final DateTime createdAt;
///   final bool isActive;
/// 
///   User(this.firstName, this.lastName, this.createdAt, this.isActive);
/// }
/// 
/// // Serializes to: 
/// // {
/// //   "first_name": "John",
/// //   "last_name": "Doe", 
/// //   "created_at": "2023-01-01T10:00:00Z",
/// //   "is_active": true
/// // }
/// ```
///
/// ### Bidirectional Consistency:
/// The implementation ensures that:
/// ```dart
/// final strategy = SnakeCaseNamingStrategy();
/// final original = 'userName';
/// final converted = strategy.toDartName(strategy.toJsonName(original));
/// print(converted == original); // true
/// ```
///
/// See also:
/// - [NamingStrategy] for the base interface
/// - [KebabCaseNamingStrategy] for kebab-case transformation
/// - [CamelCaseNamingStrategy] for identity transformation
/// {@endtemplate}
class SnakeCaseNamingStrategy implements NamingStrategy {
  /// {@macro snake_case_naming_strategy}
  const SnakeCaseNamingStrategy();

  @override
  String toJsonName(String name) {
    return name.replaceAllMapped(RegExp(r'[A-Z]'), (match) => '_${match.group(0)!.toLowerCase()}',).replaceFirst(RegExp(r'^_'), '');
  }

  @override
  String toDartName(String name) {
    return name.replaceAllMapped(RegExp(r'_([a-z])'), (match) => match.group(1)!.toUpperCase());
  }
}

/// {@template kebab_case_naming_strategy}
/// Converts field names from camelCase to kebab-case and vice versa.
///
/// This strategy is commonly used when working with JSON APIs that follow
/// the kebab-case convention, particularly in URLs, HTML attributes, or
/// configuration files.
///
/// ### Transformation Rules:
/// - **camelCase to kebab-case**: Insert hyphens before uppercase letters and convert to lowercase
/// - **kebab-case to camelCase**: Remove hyphens and capitalize following letters
///
/// ### Examples:
/// ```dart
/// final strategy = KebabCaseNamingStrategy();
/// 
/// // camelCase to kebab-case
/// strategy.toJsonName('userName');        // 'user-name'
/// strategy.toJsonName('HTTPRequest');     // 'http-request'
/// strategy.toJsonName('userId');          // 'user-id'
/// strategy.toJsonName('XMLParser');       // 'xml-parser'
/// strategy.toJsonName('createdAt');       // 'created-at'
/// 
/// // kebab-case to camelCase
/// strategy.toDartName('user-name');       // 'userName'
/// strategy.toDartName('http-request');    // 'httpRequest'
/// strategy.toDartName('user-id');         // 'userId'
/// strategy.toDartName('xml-parser');      // 'xmlParser'
/// strategy.toDartName('created-at');      // 'createdAt'
/// ```
///
/// ### Edge Case Handling:
/// - Leading uppercase letters are handled correctly
/// - Consecutive uppercase letters are treated as acronyms
/// - Numbers are preserved without modification
/// - Multiple consecutive hyphens are collapsed during conversion
///
/// ### Usage with JSON Serialization:
/// ```dart
/// @Serializable(namingStrategy: KebabCaseNamingStrategy())
/// class ApiConfig {
///   final String baseUrl;
///   final int timeoutMs;
///   final bool enableCaching;
/// 
///   ApiConfig(this.baseUrl, this.timeoutMs, this.enableCaching);
/// }
/// 
/// // Serializes to: 
/// // {
/// //   "base-url": "https://api.example.com",
/// //   "timeout-ms": 5000,
/// //   "enable-caching": true
/// // }
/// ```
///
/// ### Bidirectional Consistency:
/// The implementation ensures that:
/// ```dart
/// final strategy = KebabCaseNamingStrategy();
/// final original = 'userName';
/// final converted = strategy.toDartName(strategy.toJsonName(original));
/// print(converted == original); // true
/// ```
///
/// See also:
/// - [NamingStrategy] for the base interface
/// - [SnakeCaseNamingStrategy] for snake_case transformation
/// - [CamelCaseNamingStrategy] for identity transformation
/// {@endtemplate}
class KebabCaseNamingStrategy implements NamingStrategy {
  /// {@macro kebab_case_naming_strategy}
  const KebabCaseNamingStrategy();

  @override
  String toJsonName(String name) {
    return name.replaceAllMapped(RegExp(r'[A-Z]'), (match) => '-${match.group(0)!.toLowerCase()}').replaceFirst(RegExp(r'^-'), '');
  }

  @override
  String toDartName(String name) {
    return name.replaceAllMapped(RegExp(r'-([a-z])'), (match) => match.group(1)!.toUpperCase());
  }
}

/// {@template camel_case_naming_strategy}
/// Leaves field names unchanged (camelCase).
///
/// This is the default Dart naming strategy where JSON field names are kept the same
/// as Dart field names. Use this strategy when your JSON API already uses camelCase
/// or when you want to preserve the exact field names without transformation.
///
/// ### Identity Transformation:
/// - **camelCase to camelCase**: No changes applied
/// - **camelCase from camelCase**: No changes applied
///
/// ### Examples:
/// ```dart
/// final strategy = CamelCaseNamingStrategy();
/// 
/// // Both directions preserve the original name
/// strategy.toJsonName('userName');        // 'userName'
/// strategy.toJsonName('HTTPRequest');     // 'HTTPRequest'
/// strategy.toJsonName('userId');          // 'userId'
/// strategy.toJsonName('XMLParser');       // 'XMLParser'
/// strategy.toJsonName('createdAt');       // 'createdAt'
/// 
/// strategy.toDartName('userName');        // 'userName'
/// strategy.toDartName('HTTPRequest');     // 'HTTPRequest'
/// strategy.toDartName('userId');          // 'userId'
/// strategy.toDartName('XMLParser');       // 'XMLParser'
/// strategy.toDartName('createdAt');       // 'createdAt'
/// ```
///
/// ### Usage with JSON Serialization:
/// ```dart
/// @Serializable(namingStrategy: CamelCaseNamingStrategy())
/// class User {
///   final String firstName;
///   final String lastName;
///   final DateTime createdAt;
///   final bool isActive;
/// 
///   User(this.firstName, this.lastName, this.createdAt, this.isActive);
/// }
/// 
/// // Serializes to: 
/// // {
/// //   "firstName": "John",
/// //   "lastName": "Doe", 
/// //   "createdAt": "2023-01-01T10:00:00Z",
/// //   "isActive": true
/// // }
/// ```
///
/// ### When to Use:
/// - When working with JavaScript/TypeScript APIs that use camelCase
/// - When the JSON schema matches your Dart class structure exactly
/// - When you want maximum performance (no string transformations)
/// - As a base class for composite naming strategies
///
/// ### Performance:
/// This strategy has minimal overhead since it performs no string
/// transformations, making it the most performant option.
///
/// See also:
/// - [NamingStrategy] for the base interface
/// - [SnakeCaseNamingStrategy] for snake_case transformation
/// - [KebabCaseNamingStrategy] for kebab-case transformation
/// - [NamingStrategy.identity] for the equivalent static method
/// {@endtemplate}
class CamelCaseNamingStrategy implements NamingStrategy {
  /// {@macro camel_case_naming_strategy}
  const CamelCaseNamingStrategy();

  @override
  String toJsonName(String name) => name;

  @override
  String toDartName(String name) => name;
}