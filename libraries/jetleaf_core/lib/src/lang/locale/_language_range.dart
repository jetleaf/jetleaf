part of 'language_range.dart';

/// Implementation of LanguageRange RFC 4647 compliance.
class _LanguageRange implements LanguageRange {
  final String _range;
  final double _weight;
  late final List<String> _subtags;
  late final bool _isWildcard;

  _LanguageRange(this._range, this._weight) : assert(_weight >= 0.0 && _weight <= 1.0, 'Weight must be between 0.0 and 1.0') {
    if (_range.isEmpty) {
      throw InvalidFormatException('Language range cannot be empty');
    }

    // Validate and parse the range
    _parseRange();
  }

  /// Parse and validate the language range format.
  void _parseRange() {
    // Check for invalid characters
    if (!RegExp(r'^[a-zA-Z0-9*\-]+$').hasMatch(_range)) {
      throw InvalidFormatException('Invalid language range format: $_range');
    }

    // Split by hyphen
    final parts = _range.toLowerCase().split('-');

    if (parts.isEmpty || parts[0].isEmpty) {
      throw InvalidFormatException('Invalid language range format: $_range');
    }

    // Check for wildcard
    if (parts.last == '*') {
      _isWildcard = true;
      _subtags = parts.sublist(0, parts.length - 1);
    } else {
      _isWildcard = false;
      _subtags = parts;
    }

    // Validate subtags
    for (final subtag in _subtags) {
      if (subtag.isEmpty || subtag.length > 8) {
        throw InvalidFormatException('Invalid subtag: $subtag in range $_range');
      }
      if (!RegExp(r'^[a-z0-9]+$').hasMatch(subtag)) {
        throw InvalidFormatException('Invalid subtag: $subtag in range $_range');
      }
    }

    // First subtag must be 2-8 characters (language)
    if (!RegExp(r'^[a-z]{2,8}$').hasMatch(_subtags[0])) {
      throw InvalidFormatException('Invalid language subtag: ${_subtags[0]} in range $_range');
    }
  }

  @override
  String getRange() {
    final buffer = StringBuffer();
    buffer.writeAll(_subtags, '-');
    if (_isWildcard) buffer.write('-*');
    return buffer.toString();
  }

  @override
  double getWeight() => _weight;

  @override
  bool isWildcard() => _isWildcard;

  @override
  bool matches(dynamic languageTag) {
    String tag;
    if (languageTag is Locale) {
      tag = languageTag.getLanguageTag().toLowerCase();
    } else if (languageTag is String) {
      tag = languageTag.toLowerCase();
    } else {
      throw ArgumentError('languageTag must be String or Locale');
    }

    final tagSubtags = tag.split('-');

    // Wildcard matching: must match all subtags up to wildcard
    if (_isWildcard) {
      if (tagSubtags.length < _subtags.length) return false;
      for (int i = 0; i < _subtags.length; i++) {
        if (tagSubtags[i] != _subtags[i]) return false;
      }
      return true;
    }

    // Exact matching: tag must equal range or have range as prefix
    if (tag == getRange()) return true;

    if (tagSubtags.length > _subtags.length) {
      for (int i = 0; i < _subtags.length; i++) {
        if (tagSubtags[i] != _subtags[i]) return false;
      }
      return true;
    }

    return false;
  }

  @override
  List<String> getMatchingSubtags() => List.unmodifiable(_subtags);

  @override
  LanguageRange? getPrefixRange() {
    if (_subtags.length <= 1) return null;
    final shorterRange = _subtags.sublist(0, _subtags.length - 1).join('-');
    return _LanguageRange(shorterRange, _weight);
  }

  @override
  String? lookup(List<String> availableTags, {String? defaultLocale}) {
    // Try exact match first
    for (final tag in availableTags) {
      if (matches(tag)) {
        return tag.toLowerCase();
      }
    }

    // Try progressively shorter prefixes
    LanguageRange? prefix = getPrefixRange();
    while (prefix != null) {
      for (final tag in availableTags) {
        if (prefix.matches(tag)) {
          return tag.toLowerCase();
        }
      }
      prefix = prefix.getPrefixRange();
    }

    return defaultLocale;
  }

  @override
  List<String> filter(List<String> availableTags) {
    final result = <String>[];
    for (final tag in availableTags) {
      if (matches(tag)) {
        result.add(tag.toLowerCase());
      }
    }
    return result;
  }

  @override
  Locale toLocale() {
    if (_subtags.isEmpty) {
      throw InvalidFormatException('Cannot convert empty language range to Locale');
    }

    final language = _subtags[0];
    final country = _subtags.length > 1 ? _subtags[1] : null;

    return Locale(language, country);
  }

  /// Parse a language range string with optional weight.
  /// Format: "language-range[;q=weight]"
  static _LanguageRange parse(String rangeString) {
    if (rangeString.isEmpty) {
      throw InvalidFormatException('Language range string cannot be empty');
    }

    // Split by semicolon to separate range and weight
    final parts = rangeString.split(';');
    final range = parts[0].trim();

    double weight = 1.0;
    if (parts.length > 1) {
      // Parse weight from "q=0.9" format
      final weightPart = parts[1].trim();
      if (weightPart.startsWith('q=')) {
        try {
          weight = double.parse(weightPart.substring(2));
          if (weight < 0.0 || weight > 1.0) {
            throw FormatException('Weight must be between 0.0 and 1.0');
          }
        } catch (e) {
          throw InvalidFormatException('Invalid weight format: $weightPart');
        }
      }
    }

    return _LanguageRange(range, weight);
  }

  /// Parse comma-separated list of language ranges (from Accept-Language header).
  /// Automatically sorts by weight descending.
  static List<LanguageRange> parseList(String rangeListString) {
    if (rangeListString.isEmpty) return [];

    final ranges = <_LanguageRange>[];
    final parts = rangeListString.split(',');

    for (final part in parts) {
      final trimmed = part.trim();
      if (trimmed.isNotEmpty) {
        ranges.add(parse(trimmed));
      }
    }

    // Sort by weight descending (higher preference first)
    ranges.sort((a, b) => b.getWeight().compareTo(a.getWeight()));

    return ranges;
  }

  @override
  String toString() => getRange();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _LanguageRange &&
          other.getRange() == getRange() &&
          other.getWeight() == _weight;

  @override
  int get hashCode => Object.hash(getRange(), _weight);
}