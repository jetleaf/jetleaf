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

import 'package:jetleaf_env/env.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_utils/utils.dart';

import 'dart_config_parser.dart';
import 'models.dart';

/// {@template environment_parser}
/// Base interface for parsing configuration files into environment data.
/// 
/// Environment parsers extract configuration properties from various file formats
/// and return them as [ParsedEnvironmentSource] tuples containing the profile name
/// and properties map.
/// 
/// Unlike regular parsers that work with raw content, environment parsers:
/// - Extract profile information from file names or content
/// - Return structured data ready for environment loading
/// - Work with Asset objects containing file content
/// 
/// ## Example
/// ```dart
/// class MyEnvironmentParser extends EnvironmentParser {
///   @override
///   bool canParse(Asset asset) => asset.fileName.endsWith('.myformat');
///   
///   @override
///   EnvironmentLoadedData parse(Asset asset) {
///     final profile = extractProfileFromFileName(asset.fileName);
///     final properties = parseContent(asset.getContentAsString());
///     return (profile, properties);
///   }
/// }
/// ```
/// {@endtemplate}
abstract class EnvironmentParser extends Parser {
  /// Returns true if this parser can handle the given asset.
  bool canParse(Asset asset);
  
  /// Parses the asset and returns environment data.
  /// 
  /// Returns a tuple containing:
  /// - Profile name (e.g., "dev", "prod", "default")
  /// - Properties map with configuration key-value pairs
  ParsedEnvironmentSource load(Asset asset);
  
  /// Extracts profile name from a file name.
  /// 
  /// Common patterns:
  /// - application.dart -> "default"
  /// - application_dev.dart -> "dev"
  /// - .env -> "default"
  /// - .env.dev -> "dev"
  String extractProfileFromFileName(String fileName) {
    // Remove file extension
    String baseName = fileName;
    final lastDot = baseName.lastIndexOf('.');
    if (lastDot != -1) {
      baseName = baseName.substring(0, lastDot);
    }
    
    // Handle application_profile pattern
    if (baseName.startsWith('application_')) {
      return baseName.substring('application_'.length);
    }
    
    // Handle application -> default
    if (baseName == 'application') {
      return AbstractEnvironment.RESERVED_DEFAULT_PROFILE_NAME;
    }
    
    // Handle .env.profile pattern
    if (baseName.startsWith('.env.')) {
      return baseName.substring('.env.'.length);
    }
    
    // Handle .env -> default
    if (baseName == '.env') {
      return AbstractEnvironment.RESERVED_DEFAULT_PROFILE_NAME;
    }
    
    // Default fallback
    return AbstractEnvironment.RESERVED_DEFAULT_PROFILE_NAME;
  }
}

/// {@template env_environment_parser}
/// Environment parser for .env configuration files.
/// 
/// This parser handles environment variable files with profile support.
/// Profile names are extracted from file names:
/// 
/// - .env -> "default"
/// - .env.dev -> "dev"
/// - .env.development -> "development"
/// - .env.prod -> "prod"
/// - .env.production -> "production"
/// 
/// ## Example Usage
/// ```dart
/// final parser = EnvEnvironmentParser();
/// final asset = Asset.fromFile('.env.dev');
/// 
/// if (parser.canParse(asset)) {
///   final (profile, properties) = parser.parse(asset);
///   print('Profile: $profile'); // "dev"
///   print('Properties: $properties');
/// }
/// ```
/// {@endtemplate}
class EnvEnvironmentParser extends EnvParser implements EnvironmentParser {
  @override
  bool canParse(Asset asset) {
    final fileName = asset.getFileName();
    return fileName == '.env' || fileName.startsWith('.env.');
  }
  
  @override
  ParsedEnvironmentSource load(Asset asset) {
    final profile = extractProfileFromFileName(asset.getFileName());
    final content = Map<String, Object>.from(parseAsset(asset));
    
    return ParsedEnvironmentSource(asset.getPackageName() ?? "", profile, content);
  }
  
  @override
  String extractProfileFromFileName(String fileName) {
    // Handle .env.profile pattern
    if (fileName.startsWith('.env.')) {
      return fileName.substring('.env.'.length);
    }
    
    // Handle .env -> default
    if (fileName == '.env') {
      return AbstractEnvironment.RESERVED_DEFAULT_PROFILE_NAME;
    }
    
    // Default fallback
    return AbstractEnvironment.RESERVED_DEFAULT_PROFILE_NAME;
  }
}

/// {@template json_environment_parser}
/// Environment parser for JSON configuration files.
/// 
/// This parser handles JSON files with profile support.
/// Profile names are extracted from file names:
/// 
/// - application.json -> "default"
/// - application-dev.json -> "dev"
/// - application_dev.json -> "dev"
/// - config-prod.json -> "prod"
/// 
/// ## Example Usage
/// ```dart
/// final parser = JsonEnvironmentParser();
/// final asset = Asset.fromFile('application-dev.json');
/// 
/// if (parser.canParse(asset)) {
///   final (profile, properties) = parser.parse(asset);
///   print('Profile: $profile'); // "dev"
///   print('Properties: $properties');
/// }
/// ```
/// {@endtemplate}
class JsonEnvironmentParser extends JsonParser implements EnvironmentParser {
  @override
  bool canParse(Asset asset) {
    return asset.getFileName().toLowerCase().endsWith('.json');
  }
  
  @override
  ParsedEnvironmentSource load(Asset asset) {
    final profile = extractProfileFromFileName(asset.getFileName());
    final properties = Map<String, Object>.from(parseAsset(asset));
    
    return ParsedEnvironmentSource(asset.getPackageName() ?? "", profile, properties);
  }
  
  @override
  String extractProfileFromFileName(String fileName) {
    // Remove file extension
    String baseName = fileName;
    if (baseName.endsWith('.json')) {
      baseName = baseName.substring(0, baseName.length - '.json'.length);
    }
    
    // Handle application-profile pattern
    if (baseName.contains('-')) {
      final parts = baseName.split('-');
      if (parts.length > 1) {
        return parts.last;
      }
    }
    
    // Handle application_profile pattern
    if (baseName.contains('_')) {
      final parts = baseName.split('_');
      if (parts.length > 1) {
        return parts.last;
      }
    }
    
    // Handle application -> default
    if (baseName == 'application' || baseName == 'config') {
      return AbstractEnvironment.RESERVED_DEFAULT_PROFILE_NAME;
    }
    
    // Default fallback
    return AbstractEnvironment.RESERVED_DEFAULT_PROFILE_NAME;
  }
}

/// {@template properties_environment_parser}
/// Environment parser for .properties configuration files.
/// 
/// This parser handles Java-style properties files with profile support.
/// Profile names are extracted from file names:
/// 
/// - application.properties -> "default"
/// - application-dev.properties -> "dev"
/// - application_dev.properties -> "dev"
/// - config-prod.properties -> "prod"
/// 
/// ## Example Usage
/// ```dart
/// final parser = PropertiesEnvironmentParser();
/// final asset = Asset.fromFile('application-dev.properties');
/// 
/// if (parser.canParse(asset)) {
///   final (profile, properties) = parser.parse(asset);
///   print('Profile: $profile'); // "dev"
///   print('Properties: $properties');
/// }
/// ```
/// {@endtemplate}
class PropertiesEnvironmentParser extends PropertiesParser implements EnvironmentParser {
  @override
  bool canParse(Asset asset) {
    return asset.getFileName().toLowerCase().endsWith('.properties');
  }
  
  @override
  ParsedEnvironmentSource load(Asset asset) {
    final profile = extractProfileFromFileName(asset.getFileName());
    final properties = Map<String, Object>.from(parseAsset(asset));
    
    return ParsedEnvironmentSource(asset.getPackageName() ?? "", profile, properties);
  }
  
  @override
  String extractProfileFromFileName(String fileName) {
    // Remove file extension
    String baseName = fileName;
    if (baseName.endsWith('.properties')) {
      baseName = baseName.substring(0, baseName.length - '.properties'.length);
    }
    
    // Handle application-profile pattern
    if (baseName.contains('-')) {
      final parts = baseName.split('-');
      if (parts.length > 1) {
        return parts.last;
      }
    }
    
    // Handle application_profile pattern
    if (baseName.contains('_')) {
      final parts = baseName.split('_');
      if (parts.length > 1) {
        return parts.last;
      }
    }
    
    // Handle application -> default
    if (baseName == 'application' || baseName == 'config') {
      return AbstractEnvironment.RESERVED_DEFAULT_PROFILE_NAME;
    }
    
    // Default fallback
    return AbstractEnvironment.RESERVED_DEFAULT_PROFILE_NAME;
  }
}

/// {@template yaml_environment_parser}
/// Environment parser for YAML configuration files.
/// 
/// This parser extends YAML parsing capabilities with profile support.
/// Profile names are extracted from file names following these patterns:
/// 
/// - application.yaml -> "default"
/// - application-dev.yaml -> "dev"
/// - application_dev.yaml -> "dev"
/// - config-prod.yml -> "prod"
/// 
/// ## Example Usage
/// ```dart
/// final parser = YamlEnvironmentParser();
/// final asset = Asset.fromFile('application-dev.yaml');
/// 
/// if (parser.canParse(asset)) {
///   final (profile, properties) = parser.parse(asset);
///   print('Profile: $profile'); // "dev"
///   print('Properties: $properties');
/// }
/// ```
/// {@endtemplate}
class YamlEnvironmentParser extends YamlParser implements EnvironmentParser {
  @override
  bool canParse(Asset asset) {
    final fileName = asset.getFileName().toLowerCase();
    return fileName.endsWith('.yaml') || fileName.endsWith('.yml');
  }
  
  @override
  ParsedEnvironmentSource load(Asset asset) {
    final profile = extractProfileFromFileName(asset.getFileName());
    final properties = Map<String, Object>.from(parseAsset(asset));
    
    return ParsedEnvironmentSource(asset.getPackageName() ?? "", profile, properties);
  }
  
  @override
  String extractProfileFromFileName(String fileName) {
    // Remove file extension
    String baseName = fileName;
    final lastDot = baseName.lastIndexOf('.');
    if (lastDot != -1) {
      baseName = baseName.substring(0, lastDot);
    }
    
    // Handle application-profile pattern
    if (baseName.contains('-')) {
      final parts = baseName.split('-');
      if (parts.length > 1) {
        return parts.last;
      }
    }
    
    // Handle application_profile pattern
    if (baseName.contains('_')) {
      final parts = baseName.split('_');
      if (parts.length > 1) {
        return parts.last;
      }
    }
    
    // Handle application -> default
    if (baseName == 'application' || baseName == 'config') {
      return AbstractEnvironment.RESERVED_DEFAULT_PROFILE_NAME;
    }
    
    // Default fallback
    return AbstractEnvironment.RESERVED_DEFAULT_PROFILE_NAME;
  }
}

/// {@template dart_environment_parser}
/// Environment parser for .dart configuration files.
/// 
/// This parser processes Dart files containing classes that extend
/// ConfigurationProperty and extracts their configuration data.
/// 
/// Profile extraction:
/// - application.dart -> "default"
/// - application_dev.dart -> "dev" 
/// - application_prod.dart -> "prod"
/// 
/// ## Example Usage
/// ```dart
/// final parser = DartEnvironmentParser();
/// final asset = Asset.fromFile('application_dev.dart');
/// 
/// if (parser.canParse(asset)) {
///   final (profile, properties) = parser.parse(asset);
///   print('Profile: $profile'); // "dev"
///   print('Properties: $properties');
/// }
/// ```
/// {@endtemplate}
class DartEnvironmentParser extends EnvironmentParser {
  @override
  bool canParse(Asset asset) {
    return asset.getFileName().endsWith('.dart') && asset.getFileName().startsWith('application');
  }
  
  @override
  ParsedEnvironmentSource load(Asset asset) {
    final profile = extractProfileFromFileName(asset.getFileName());
    final properties = Map<String, Object>.from(DartConfigParser().parse(asset.getContentAsString()));
    return ParsedEnvironmentSource(asset.getPackageName() ?? "", profile, properties);
  }
}