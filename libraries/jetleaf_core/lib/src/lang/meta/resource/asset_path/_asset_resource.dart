part of 'asset_resource.dart';

/// Private implementation of [AssetResource].
final class _AssetResource implements AssetResource {
  final Object _source;

  _AssetResource(this._source);

  @override
  Map<String, Object> toJson() {
    if (_source case Asset source) {
      return source.toJson();
    }
    
    return { 'source': _source };
  }

  @override
  Object getSource() => _source;
  
  @override
  Uint8List getContentBytes() {
    if (_source case Asset source) {
      return source.getContentBytes();
    }

    if (_source case Uint8List source) {
      return source;
    }
    
    return Uint8List.fromList(Closeable.DEFAULT_ENCODING.encode(_source.toString()));
  }
  
  @override
  String getFileName() {
    if (_source case Asset source) {
      return source.getFileName();
    }
    
    if (_source case String source) {
      return source;
    }
    
    return _source.toString();
  }
  
  @override
  String getFilePath() {
    if (_source case Asset source) {
      return source.getFilePath();
    }

    if (_source case String source) {
      return source;
    }
    
    return _source.toString();
  }
  
  @override
  String? getPackageName() {
    if (_source case Asset source) {
      return source.getPackageName();
    }
    
    return null;
  }
  
  @override
  String getUniqueName() {
    if (_source case Asset source) {
      return source.getUniqueName();
    }
    
    return _source.toString();
  }

  /// Determines the file extension from either a file path or content analysis
  /// 
  /// If [source] is a file path, uses endsWith to determine extension.
  /// If [source] is content, analyzes the content to determine the likely file type.
  /// 
  /// Returns the extension without the dot (e.g., 'json', 'xml', 'yaml', 'properties')
  static String? determineExtension(Object source) {
    if (source is String) {
      if (getIsContent(source)) {
        return _determineExtensionFromContent(source);
      } else {
        return _determineExtensionFromPath(source);
      }
    } else if (source is Asset) {
      final pathExtension = _determineExtensionFromPath(source.getFilePath()) ?? _determineExtensionFromPath(source.getFileName());
      if (pathExtension != null) {
        return pathExtension;
      }

      final content = source.getContentAsString();
      return _determineExtensionFromContent(content);
    }

    return null;
  }

  /// Verifies if the received source is string content or a file path
  /// 
  /// Returns true if [source] appears to be file content rather than a file path.
  /// Returns false if [source] is an Asset object or appears to be a file path.
  static bool getIsContent(Object source) {
    if (source is Asset) return false;
    if (source is! String) return false;

    final text = source;
    final trimmed = text.trimLeft();

    // If there are newlines -> likely content
    if (text.contains('\n')) return true;

    // If it starts with JSON / XML / YAML indicators -> content
    final lower = trimmed;
    if (lower.startsWith('{') || lower.startsWith('[') || lower.startsWith('<')) {
      return true;
    }

    // YAML common pattern or list items
    if (_looksLikeYaml(text)) return true;

    // properties lines (key=value)
    if (_looksLikeProperties(text)) return true;

    // Dart code heuristics
    if (_looksLikeDart(text)) return true;

    // If there are characters commonly found in content but not in filenames:
    // colon followed by space, or '{' or '<' anywhere -> content
    if (text.contains('{') || text.contains('<') || text.contains(': ')) return true;

    // Otherwise, treat as file path only if it matches strict filename pattern
    return false;
  }

  /// Determines extension from file path using endsWith
  static String? _determineExtensionFromPath(String path) {
    if (path.isEmpty) return null;
    final p = path.toLowerCase();
    if (p.endsWith('.json')) return 'json';
    if (p.endsWith('.xml')) return 'xml';
    if (p.endsWith('.yaml') || p.endsWith('.yml')) return 'yaml';
    if (p.endsWith('.properties')) return 'properties';
    if (p.endsWith('.dart')) return 'dart';

    // also support simple file names like "pods" with extension captured by regex
    final match = RegExp(r'\.([a-z0-9]+)$', caseSensitive: false).firstMatch(path);
    if (match != null) {
      final ext = match.group(1);
      if (ext != null) return ext;
    }

    return null;
  }

  /// Analyzes content to determine likely file type
  static String? _determineExtensionFromContent(String content) {
    final trimmed = content.trim();

    // JSON detection: starts with { or [ and contains common JSON tokens
    if ((trimmed.startsWith('{') && trimmed.endsWith('}')) ||
        (trimmed.startsWith('[') && trimmed.endsWith(']'))) {
      // quick sanity check for JSON keys/structure
      if (trimmed.contains('"') && (trimmed.contains(':') || trimmed.contains('"pods"') || trimmed.contains('"name"'))) {
        return 'json';
      }
    }

    // XML detection: starts with <?xml or starts with < and has a closing tag
    if (trimmed.startsWith('<?xml') || (trimmed.startsWith('<') && trimmed.contains('</'))) {
      return 'xml';
    }

    // also accept simple <pods> ... </pods>
    if (trimmed.startsWith('<pods') || trimmed.startsWith('<pod')) {
      return 'xml';
    }

    // YAML detection (look for "key: val" or "- item" patterns)
    if (_looksLikeYaml(trimmed)) {
      return 'yaml';
    }

    // Properties detection (lines with key=value)
    if (_looksLikeProperties(trimmed)) {
      return 'properties';
    }

    // Dart detection (code patterns)
    if (_looksLikeDart(trimmed)) {
      return 'dart';
    }

    return null;
  }

  /// Checks if content looks like YAML
  static bool _looksLikeYaml(String content) {
    final lines = content.split('\n');
    int yamlMatches = 0;

    // Use raw triple-quoted strings so the regex can include both ' and " safely.
    final keyValueRegex = RegExp(r'''^[\w\-\.\[\]'"]+\s*:\s*''');
    final listItemRegex = RegExp(r'^\s*-\s+');

    for (final raw in lines) {
      final line = raw.trim();
      if (line.isEmpty || line.startsWith('#')) continue;

      if (keyValueRegex.hasMatch(line)) yamlMatches++;
      if (listItemRegex.hasMatch(line)) yamlMatches++;
    }

    if (yamlMatches > 0) return true;
    if (content.contains('pods:') || content.contains('- name:')) return true;
    return false;
  }

  /// Checks if content looks like properties
  static bool _looksLikeProperties(String content) {
    final lines = content.split('\n').where((l) => l.trim().isNotEmpty && !l.trim().startsWith('#') && !l.trim().startsWith('!')).toList();
    if (lines.isEmpty) return false;
    int propLines = 0;
    for (final l in lines) {
      final trimmed = l.trim();
      // key=value or key: value (tolerate both but prefer '=')
      if (trimmed.contains('=') && !trimmed.startsWith('=')) propLines++;
    }
    // If a decent fraction of lines look like properties, classify as properties
    return propLines > 0 && (propLines / lines.length) > 0.3;
  }

  /// Checks if content looks like Dart code
  static bool _looksLikeDart(String content) {
    final dartKeywords = [
      'class ', 'import ', 'library ', 'part ', 'export ',
      'void ', 'String ', 'int ', 'double ', 'bool ',
      'final ', 'const ', 'var ', 'dynamic ',
      'if (', 'for (', 'while (', 'switch (',
      '=>', 'async ', 'await ', 'Future<'
    ];

    for (final kw in dartKeywords) {
      if (content.contains(kw)) return true;
    }

    if (content.contains('//') || content.contains('/*')) return true;
    return false;
  }

  // Default strategies are private helpers for initial behavior.
  static String? _defaultExtensionStrategy(Object source) {
    if (source is String) {
      if (getIsContent(source)) {
        return _AssetResource._determineExtensionFromContent(source);
      } else {
        return _AssetResource._determineExtensionFromPath(source);
      }
    }

    if (source is Asset) {
      final pathExt = _AssetResource._determineExtensionFromPath(source.getFilePath()) ??
          _AssetResource._determineExtensionFromPath(source.getFileName());
      if (pathExt != null) return pathExt;
      return _AssetResource._determineExtensionFromContent(source.getContentAsString());
    }

    return null;
  }

  static bool _defaultContentDetector(Object source) {
    // Asset objects are *not* content here.
    if (source is Asset) return false;
    if (source is! String) return false;

    final text = source;

    // Quick heuristics: newlines, JSON/XML/YAML openers, or characters
    // unlikely to appear in filenames.
    if (text.contains('\n')) return true;
    final trimmed = text.trimLeft();

    if (trimmed.startsWith('{') || trimmed.startsWith('[') || trimmed.startsWith('<')) {
      return true;
    }

    if (text.contains('{') || text.contains('<') || text.contains(': ')) return true;

    // Defer to the richer heuristics in _AssetResource.
    return _AssetResource._looksLikeYaml(text) ||
        _AssetResource._looksLikeProperties(text) ||
        _AssetResource._looksLikeDart(text);
  }
  
  @override
  List<Object?> equalizedProperties() {
    if (_source case Asset source) {
      return source.equalizedProperties();
    }

    return [_source];
  }
  
  @override
  String getContentAsString() {
    if (_source case Asset source) {
      return source.getContentAsString();
    }

    return _source.toString();
  }

  @override
  void serialize(BinaryBuilder builder) { }
}