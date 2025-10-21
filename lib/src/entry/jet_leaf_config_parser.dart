import 'dart:convert';
import 'dart:typed_data';

import 'package:jetleaf_lang/lang.dart';

import '../jet_leaf_application.dart';

/// {@template jetLeafConfigParser}
/// Parser for JetLeaf configuration files with strict validation.
///
/// This parser handles YAML, JSON, and properties configuration files
/// with strict validation rules. Only specific top-level keys are allowed,
/// and values must be lists of strings with proper formatting.
///
/// **Supported Keys:**
/// - `${JetLeafApplication.ENABLE_AUTO_CONFIGURATION_PROPERTY}`
/// - `${JetLeafApplication.DISABLE_AUTO_CONFIGURATION_PROPERTY}`
///
/// **File Format Examples:**
///
/// **YAML:**
/// ```yaml
/// jetleaf.enable.auto.configuration:
///   - package:jetleaf_resource/src/.../SchedulingAutoConfiguration
///   - package:jetleaf_web/src/.../WebAutoConfiguration
///
/// jetleaf.disable.auto.configuration:
///   - jetleaf_web
///   - jetleaf_security
/// ```
///
/// **JSON:**
/// ```json
/// {
///   "jetleaf.enable.auto.configuration": [
///     "package:jetleaf_resource/src/.../SchedulingAutoConfiguration",
///     "package:jetleaf_web/src/.../WebAutoConfiguration"
///   ],
///   "jetleaf.disable.auto.configuration": [
///     "jetleaf_web",
///     "jetleaf_security"
///   ]
/// }
/// ```
///
/// **Properties:**
/// ```properties
/// jetleaf.enable.auto.configuration[0]=package:jetleaf_resource/src/.../SchedulingAutoConfiguration
/// jetleaf.enable.auto.configuration[1]=package:jetleaf_web/src/.../WebAutoConfiguration
/// jetleaf.disable.auto.configuration[0]=jetleaf_web
/// jetleaf.disable.auto.configuration[1]=jetleaf_security
/// ```
/// {@endtemplate}
final class JetLeafConfigParser {
  /// {@macro allowedConfigKeys}
  /// Set of allowed configuration keys for JetLeaf configuration files.
  static const _ALLOWED_KEYS = {
    JetLeafApplication.ENABLE_AUTO_CONFIGURATION_PROPERTY,
    JetLeafApplication.DISABLE_AUTO_CONFIGURATION_PROPERTY
  };

  /// {@macro parseConfigAsset}
  /// Parses a configuration asset and returns the configuration map.
  ///
  /// This method automatically detects the file format based on the file extension
  /// and delegates to the appropriate parser. Supported formats are YAML (.yaml, .yml),
  /// JSON (.json), and Properties (.properties).
  ///
  /// **Parameters:**
  /// - `asset`: The configuration file asset to parse
  ///
  /// **Returns:**
  /// - A map of configuration keys to lists of string values
  ///
  /// **Throws:**
  /// - `IllegalStateException` for unsupported file formats or parsing errors
  ///
  /// **Example:**
  /// ```dart
  /// final parser = JetLeafConfigParser();
  /// final asset = Asset.fromPath('config/jetleaf.yaml');
  /// 
  /// try {
  ///   final config = parser.parseAsset(asset);
  ///   final enabled = config[JetLeafApplication.ENABLE_AUTO_CONFIGURATION_PROPERTY];
  ///   final disabled = config[JetLeafApplication.DISABLE_AUTO_CONFIGURATION_PROPERTY];
  ///   
  ///   print('Enabled auto-configurations: $enabled');
  ///   print('Disabled auto-configurations: $disabled');
  /// } on IllegalStateException catch (e) {
  ///   print('Configuration parsing failed: $e');
  /// }
  /// ```
  Map<String, List<String>> parseAsset(Asset asset) {
    final path = asset.getFilePath().toLowerCase();
    final content = _decodeBytes(asset.getContentBytes());

    if (path.endsWith('.yaml') || path.endsWith('.yml')) {
      return _parseYamlConfig(content, asset.getFilePath());
    } else if (path.endsWith('.json')) {
      return _parseJsonConfig(content, asset.getFilePath());
    } else if (path.endsWith('.properties')) {
      return _parsePropertiesConfig(content, asset.getFilePath());
    } else {
      throw IllegalStateException('Unsupported config extension for: ${asset.getFilePath()}');
    }
  }

  /// {@macro decodeConfigBytes}
  /// Decodes UTF-8 bytes to string, handling BOM if present.
  String _decodeBytes(Uint8List bytes) {
    var s = utf8.decode(bytes);
    if (s.isNotEmpty && s.codeUnitAt(0) == 0xFEFF) s = s.substring(1);
    return s;
  }

  // -------------------------
  // YAML (strict subset) parser
  // -------------------------

  /// {@macro parseYamlConfig}
  /// Parses YAML configuration with strict validation.
  ///
  /// This parser only accepts top-level mappings with list values using
  /// either inline JSON arrays or YAML list syntax with '-' items.
  /// Indentation rules are strictly enforced.
  Map<String, List<String>> _parseYamlConfig(String content, String filePath) {
    // We'll accept only top-level mapping with list values using '-' items
    final lines = const LineSplitter().convert(content);
    final result = <String, List<String>>{};

    String? currentKey;
    int currentKeyIndent = 0;

    for (var raw in lines) {
      var line = raw.replaceAll('\t', '    '); // normalize tabs to spaces
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue; // skip blank
      if (trimmed.startsWith('#')) continue; // skip comments

      // --- FIRST: list item (must be evaluated before key detection)
      final listMatch = RegExp(r'^(\s*)-\s*(.+)$').firstMatch(line);
      if (listMatch != null) {
        // If there's no current key, it's a list item without a parent key => error
        if (currentKey == null) {
          throw IllegalStateException(_yamlError(filePath, 'Found list item without a parent top-level key. List items must follow a top-level key definition.'));
        }

        final indent = listMatch.group(1)!.length;
        // require list item indent greater than key indent (strict)
        if (indent <= currentKeyIndent) {
          throw IllegalStateException(_yamlError(filePath, 'List item indent must be greater than key indent for key "$currentKey".'));
        }

        final item = listMatch.group(2)!.trim();
        if (item.isEmpty) {
          throw IllegalStateException(_yamlError(filePath, 'Empty list item for key "$currentKey" is not allowed.'));
        }

        _addStringList(result, currentKey, [item]);
        continue;
      }

      // --- SECOND: top-level key line: 'key:' or 'key: value'
      // Note: We require keys be top-level (indent == 0)
      final keyMatch = RegExp(r'^(\s*)([^:][^:]*)\s*:\s*(.*)$').firstMatch(line);
      if (keyMatch != null) {
        final indent = keyMatch.group(1)!.length;
        final key = keyMatch.group(2)!.trim();
        final after = keyMatch.group(3)!.trim();

        // Strict: keys must be top level (indent == 0)
        if (indent != 0) {
          throw IllegalStateException(_yamlError(filePath, 'Keys must be defined at the top level with no indentation. Offending key: "$key"'));
        }

        if (!_ALLOWED_KEYS.contains(key)) {
          throw IllegalStateException(_yamlError(filePath, 'Unsupported key "$key". Only allowed keys are: $_ALLOWED_KEYS'));
        }

        currentKey = key;
        currentKeyIndent = indent;
        // initialize list if missing
        result.putIfAbsent(currentKey, () => <String>[]);

        // if after contains an inline array "[...]" use JSON decoder to parse
        if (after.isNotEmpty) {
          if (after.startsWith('[')) {
            try {
              final parsed = json.decode(after);
              if (parsed is! List) {
                throw IllegalStateException(_yamlError(filePath, 'Inline value for "$key" must be a list of strings.'));
              }
              final list = parsed.map((e) => e?.toString() ?? '').toList();
              _addStringList(result, key, list);
            } catch (e) {
              throw IllegalStateException(_yamlError(filePath, 'Failed to parse inline list for "$key": $e'));
            }
          } else {
            // Not an inline list — YAML strict subset: we require list values using '-'
            throw IllegalStateException(_yamlError(filePath, 'Invalid value for "$key". Expected a list using `- item` lines or an inline JSON array. Example:\n'
                'jetleaf.enableautoconfiguration:\n'
                '  - package:my_pkg/Config\n'));
          }
        }

        continue;
      }

      // --- OTHER: indented scalar under current key (rare case), accept as additional scalar
      if (currentKey != null) {
        final scalarMatch = RegExp(r'^\s+(.+)$').firstMatch(line);
        if (scalarMatch != null) {
          final indent = line.indexOf(scalarMatch.group(1)!);
          if (indent > currentKeyIndent) {
            final val = scalarMatch.group(1)!.trim();
            if (val.isEmpty) {
              throw IllegalStateException(_yamlError(filePath, 'Empty scalar under key "$currentKey" is not allowed.'));
            }
            _addStringList(result, currentKey, [val]);
            continue;
          }
        }
      }

      // Unknown/unexpected line
      throw IllegalStateException(_yamlError(filePath, 'Unexpected line in YAML: "$line". Expected top-level keys and list values using `- item`.'));
    }

    // Validate that each key has at least one value
    result.forEach((k, v) {
      if (v.isEmpty) {
        throw IllegalStateException(_yamlError(filePath,
            'Key "$k" must contain at least one entry. Example:\n'
            'jetleaf.enableautoconfiguration:\n'
            '  - package:my_pkg/Config\n')
        );
      }
    });

    return result;
  }

  // -------------------------
  // JSON parser (strict validation)
  // -------------------------

  /// {@macro parseJsonConfig}
  /// Parses JSON configuration with strict validation.
  ///
  /// This parser requires top-level objects with array values containing
  /// only string elements. All keys are validated against allowed keys.
  Map<String, List<String>> _parseJsonConfig(String content, String filePath) {
    dynamic decoded;
    try {
      decoded = json.decode(content);
    } catch (e) {
      throw IllegalStateException('Invalid JSON in $filePath: $e');
    }

    if (decoded is! Map) {
      throw IllegalStateException('Top-level JSON must be an object mapping keys to list values.');
    }

    final result = <String, List<String>>{};

    decoded.forEach((k, v) {
      final key = k.toString();
      if (!_ALLOWED_KEYS.contains(key)) {
        throw IllegalStateException('Unsupported key "$key" in $filePath. Only allowed keys: $_ALLOWED_KEYS');
      }
      if (v is! List) {
        throw IllegalStateException('Value for key "$key" in $filePath must be a JSON array of strings.');
      }
      final list = <String>[];
      for (final item in v) {
        if (item == null) {
          throw IllegalStateException('Null item found in array for key "$key" in $filePath.');
        }
        list.add(item.toString());
      }
      if (list.isEmpty) {
        throw IllegalStateException('Array for key "$key" must contain at least one element.');
      }
      _addStringList(result, key, list);
    });

    return result;
  }

  // -------------------------
  // .properties parser (strict)
  // -------------------------

  /// {@macro parsePropertiesConfig}
  /// Parses properties configuration with strict validation.
  ///
  /// This parser requires the specific format `key[index]=value` where
  /// indices must start at 0 and be contiguous without gaps.
  Map<String, List<String>> _parsePropertiesConfig(String content, String filePath) {
    final lines = const LineSplitter().convert(content);
    final temp = <String, Map<int, String>>{}; // key -> index -> value

    for (var raw in lines) {
      var line = raw;
      // strip BOM on first line if present
      if (line.isNotEmpty && line.codeUnitAt(0) == 0xFEFF) {
        line = line.substring(1);
      }
      // handle comments and blank
      final stripped = line.trim();
      if (stripped.isEmpty) continue;
      if (stripped.startsWith('#') || stripped.startsWith('!')) continue;

      // Expect: key[index]=value
      final match = RegExp(r'^([^\[\]=]+)\[(\d+)\]\s*=\s*(.*)$').firstMatch(line);
      if (match == null) {
        throw IllegalStateException(_propertiesError(filePath,
            'Invalid properties line. Expected format: key[index]=value\nOffending line: "$line"\n'
            'Example:\n'
            '${JetLeafApplication.ENABLE_AUTO_CONFIGURATION_PROPERTY}[0]=package:my_pkg/Config'));
      }

      final key = match.group(1)!.trim();
      final idx = int.parse(match.group(2)!);
      final value = match.group(3)!.trim();

      if (!_ALLOWED_KEYS.contains(key)) {
        throw IllegalStateException('Unsupported key "$key" in $filePath. Only allowed keys: $_ALLOWED_KEYS');
      }

      temp.putIfAbsent(key, () => <int, String>{});
      if (temp[key]!.containsKey(idx)) {
        throw IllegalStateException(_propertiesError(filePath, 'Duplicate index $idx for key "$key" in $filePath'));
      }
      temp[key]![idx] = value;
    }

    // Validate indices (must start at 0 and be contiguous)
    final result = <String, List<String>>{};
    temp.forEach((key, indexMap) {
      if (indexMap.isEmpty) {
        throw IllegalStateException(_propertiesError(filePath, 'No values found for key "$key"'));
      }
      final indices = indexMap.keys.toList()..sort();
      if (indices.first != 0) {
        throw IllegalStateException(_propertiesError(filePath, 'Indices for key "$key" must start at 0. Found first index ${indices.first}'));
      }
      for (var i = 0; i < indices.length; i++) {
        if (indices[i] != i) {
          throw IllegalStateException(_propertiesError(filePath, 'Indices for key "$key" must be contiguous starting at 0. Missing index $i'));
        }
      }

      final list = List<String>.generate(indices.length, (i) => indexMap[i]!);
      if (list.isEmpty) {
        throw IllegalStateException(_propertiesError(filePath, 'No values for key "$key"'));
      }
      result[key] = list;
    });

    return result;
  }

  // -------------------------
  // Helpers
  // -------------------------

  /// {@macro addStringList}
  /// Adds a string list to the configuration map, avoiding duplicates.
  void _addStringList(Map<String, List<String>> map, String key, List<String> list) {
    final existing = map[key];
    if (existing == null) {
      map[key] = List<String>.from(list);
    } else {
      for (final v in list) {
        if (!existing.contains(v)) existing.add(v);
      }
    }
  }

  /// {@macro yamlError}
  /// Creates a formatted YAML parsing error message.
  String _yamlError(String filePath, String reason) =>
      'Invalid YAML structure in $filePath: $reason\nExpected example:\n'
      '${JetLeafApplication.ENABLE_AUTO_CONFIGURATION_PROPERTY}:\n'
      '  - package:jetleaf_resource/src/…/SchedulingAutoConfiguration\n\n'
      '${JetLeafApplication.DISABLE_AUTO_CONFIGURATION_PROPERTY}:\n'
      '  - package:jetleaf_resource/src/…/SchedulingAutoConfiguration\n'
      '  - jetleaf_web\n';

  /// {@macro propertiesError}
  /// Creates a formatted properties parsing error message.
  String _propertiesError(String filePath, String reason) =>
      'Invalid .properties structure in $filePath: $reason\nExpected example:\n'
      '${JetLeafApplication.ENABLE_AUTO_CONFIGURATION_PROPERTY}[0]=package:jetleaf_resource/src/…/SchedulingAutoConfiguration\n'
      '${JetLeafApplication.DISABLE_AUTO_CONFIGURATION_PROPERTY}[0]=package:jetleaf_resource/src/…/SchedulingAutoConfiguration\n'
      '${JetLeafApplication.DISABLE_AUTO_CONFIGURATION_PROPERTY}[1]=jetleaf_web\n';
}

/// {@template allowedConfigKeys}
/// Allowed configuration keys for JetLeaf configuration files.
///
/// This template documents the restricted set of configuration keys
/// that are permitted in JetLeaf configuration files.
/// {@endtemplate}

/// {@template parseConfigAsset}
/// Configuration asset parsing operation.
///
/// This template documents the multi-format configuration parsing
/// functionality with automatic format detection.
/// {@endtemplate}

/// {@template decodeConfigBytes}
/// Byte decoding with BOM handling.
///
/// This template documents the byte-to-string decoding process
/// that handles UTF-8 BOM markers.
/// {@endtemplate}

/// {@template parseYamlConfig}
/// Strict YAML configuration parsing.
///
/// This template documents the YAML parsing process with strict
/// validation of structure, indentation, and allowed keys.
/// {@endtemplate}

/// {@template parseJsonConfig}
/// Strict JSON configuration parsing.
///
/// This template documents the JSON parsing process with strict
/// validation of structure and allowed keys.
/// {@endtemplate}

/// {@template parsePropertiesConfig}
/// Strict properties configuration parsing.
///
/// This template documents the properties file parsing process
/// with strict validation of index format and contiguity.
/// {@endtemplate}

/// {@template addStringList}
/// Configuration list merging operation.
///
/// This template documents the list merging functionality
/// that avoids duplicate entries in configuration lists.
/// {@endtemplate}

/// {@template yamlError}
/// YAML parsing error formatting.
///
/// This template documents the YAML error message formatting
/// that provides helpful examples and context.
/// {@endtemplate}

/// {@template propertiesError}
/// Properties parsing error formatting.
///
/// This template documents the properties error message formatting
/// that provides helpful examples and context.
/// {@endtemplate}