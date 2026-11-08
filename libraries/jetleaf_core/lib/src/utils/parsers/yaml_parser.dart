import 'dart:convert';

import 'package:jetleaf_core/lang.dart';
import 'package:yaml/yaml.dart';

import 'parser.dart';
import '../exceptions.dart';

/// {@template yaml_parser}
/// A parser for YAML configuration files.
/// 
/// Supports YAML syntax including nested structures, lists, and comments.
/// Preserves special property values like #{} and @{} for later resolution.
/// 
/// #{} and @{} are used to preserve special property values like #{} and @{} for later resolution.
/// 
/// ### Example usage:
/// ```dart
/// void main() {
///   final parser = YamlParser();
/// 
///   final config = parser.parse('key: value');
///   print(config['key']); // Output: value
/// 
///   final config = parser.parseAsset(asset);
///   print(config['key']); // Output: value
/// 
///   final config = parser.parseFile('config.yaml');
///   print(config['key']); // Output: value
/// }
/// ```
/// {@endtemplate}
class YamlParser extends Parser {
  /// {@macro yaml_parser}
  YamlParser();

  @override
  Map<String, dynamic> parse(String source) {
    try {
      final yaml = loadYaml(source);

      if (yaml == null) {
        return const <String, dynamic>{};
      } else if (yaml is YamlMap) {
        return yaml.asJson();
      } else if (yaml is YamlScalar) {
        return yaml.value == null ? const <String, dynamic>{} : {"value": yaml.value};
      } else if (yaml is YamlList) {
        return {"value": yaml.value};
      } else {
        final decoded = jsonDecode(yaml.toString());
        if (decoded is Map<String, dynamic>) {
          return decoded;
        } else if (decoded == null) {
          return const <String, dynamic>{};
        } else {
          return {"value": decoded};
        }
      }
    } catch (e) {
      throw ParserException('Failed to parse YAML: $e');
    }
  }

  @override
  Map<String, dynamic> parseAsset(Asset asset) {
    try {
      return super.parseAsset(asset);
    } catch (e) {
      throw ParserException('Failed to parse YAML asset ${asset.getFileName()}: $e');
    }
  }

  @override
  Map<String, dynamic> parseFile(String path) {
    try {
      return super.parseFile(path);
    } catch (e) {
      if (e is ParserException) rethrow;
      throw ParserException('Failed to parse YAML file $path: $e');
    }
  }
}