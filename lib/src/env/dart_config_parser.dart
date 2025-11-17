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

/// {@template dart_config_parser}
/// DartConfigParser - improved to accept any constructor/static factory that
/// produces a JetProperty (heuristic-based), not only JetProperty.custom.
///
/// Strategy:
/// 1. Remove comments (but preserve strings).
/// 2. Collect class names in the source that `extends JetProperty`.
/// 3. Find classes that `extends ConfigurationProperty` and extract the
///    `ConfigurationProperties({...})` block inside their `properties()` method.
/// 4. Parse the map content; accept any call expression whose callee looks like:
///      - 'JetProperty' (static factory)
///      - a declared subclass found in step 2
///      - an identifier that starts with uppercase or ends with 'Property'
///    and whose first argument is a string literal (the key).
/// 
/// ## Example
/// ```dart
/// class MyProperty extends JetProperty {
///   MyProperty(String key) : super(key);
/// }
/// 
/// class MyConfig {
///   final MyProperty myProperty;
///   MyConfig(this.myProperty);
/// }
/// ```
/// 
/// {@endtemplate}
final class DartConfigParser {
  /// {@macro dart_config_parser}
  DartConfigParser();

  /// Parses the given source code and returns a map of properties.
  /// 
  /// ## Example
  /// ```dart
  /// final parser = DartConfigParser();
  /// final properties = parser.parse('');
  /// ```
  Map<String, dynamic> parse(String source) {
    final clean = _removeComments(source);
    final declaredPropSubclasses = _findClassesExtendingJetProperty(clean);
    final out = <String, dynamic>{};

    final classRanges = _findClassesExtendingConfigurationProperty(clean);
    for (final range in classRanges) {
      final classBody = clean.substring(range.start, range.end);
      final propsBlock = _extractConfigurationPropertiesBlock(classBody);
      if (propsBlock == null) continue;
      final entries = _parsePropertiesMap(propsBlock, declaredPropSubclasses);
      out.addAll(entries);
    }

    return out;
  }

  // -------------------------
  // Step 1: remove comments (but preserve strings)
  // -------------------------
  String _removeComments(String s) {
    final out = StringBuffer();
    bool inSingle = false, inDouble = false;
    for (int i = 0; i < s.length; i++) {
      final ch = s.codeUnitAt(i);

      // handle escapes inside strings
      if (ch == 0x5C) { // backslash '\'
        if (i + 1 < s.length) {
          out.writeCharCode(ch);
          out.writeCharCode(s.codeUnitAt(i + 1));
          i++;
          continue;
        } else {
          out.writeCharCode(ch);
          continue;
        }
      }

      if (!inSingle && ch == 0x22) { // "
        inDouble = !inDouble;
        out.writeCharCode(ch);
        continue;
      }
      if (!inDouble && ch == 0x27) { // '
        inSingle = !inSingle;
        out.writeCharCode(ch);
        continue;
      }

      if (!inSingle && !inDouble) {
        // // single-line comment
        if (ch == 0x2F && i + 1 < s.length && s.codeUnitAt(i + 1) == 0x2F) {
          i += 2;
          while (i < s.length && s.codeUnitAt(i) != 0x0A) {
            i++;
          }
          if (i < s.length) out.writeCharCode(0x0A); // keep newline
          continue;
        }
        // /* ... */ multi-line comment
        if (ch == 0x2F && i + 1 < s.length && s.codeUnitAt(i + 1) == 0x2A) {
          i += 2;
          while (i + 1 < s.length && !(s.codeUnitAt(i) == 0x2A && s.codeUnitAt(i + 1) == 0x2F)) {
            i++;
          }
          i++; // skip '/'
          continue;
        }
      }

      out.writeCharCode(ch);
    }

    return out.toString();
  }

  // -------------------------
  // Step 1.5: find declared classes that extend JetProperty
  // -------------------------
  Set<String> _findClassesExtendingJetProperty(String s) {
    final out = <String>{};
    final classPattern = RegExp(r'\bclass\b');
    final matches = classPattern.allMatches(s);
    for (final m in matches) {
      int idx = m.start;
      final bracePos = _indexOfCharOutsideStrings(s, 0x7B /* '{' */, idx);
      if (bracePos < 0) continue;
      final header = s.substring(idx, bracePos);
      if (RegExp(r'\bextends\b\s+JetProperty\b').hasMatch(header)) {
        // Extract the class name token after 'class'
        final nameMatch = RegExp(r'\bclass\s+([A-Za-z_][A-Za-z0-9_]*)').firstMatch(header);
        if (nameMatch != null) {
          out.add(nameMatch.group(1)!);
        }
      }
    }
    return out;
  }

  // -------------------------
  // Step 2: find class blocks that extend ConfigurationProperty
  // -------------------------
  List<_Range> _findClassesExtendingConfigurationProperty(String s) {
    final out = <_Range>[];
    final classPattern = RegExp(r'\bclass\b');
    final matches = classPattern.allMatches(s);
    for (final m in matches) {
      int idx = m.start;
      final bracePos = _indexOfCharOutsideStrings(s, 0x7B /* '{' */, idx);
      if (bracePos < 0) continue;
      final header = s.substring(idx, bracePos);
      if (!RegExp(r'\bextends\b\s+ConfigurationProperty\b').hasMatch(header)) continue;
      final close = _findMatchingBrace(s, bracePos);
      if (close < 0) continue;
      out.add(_Range(bracePos + 1, close));
    }
    return out;
  }

  // Find position of char outside of strings (single/double) starting from `from`.
  int _indexOfCharOutsideStrings(String s, int charCode, int from) {
    bool inSingle = false, inDouble = false;
    for (int i = from; i < s.length; i++) {
      final ch = s.codeUnitAt(i);
      if (ch == 0x5C) { i++; continue; }
      if (!inSingle && ch == 0x22) { inDouble = !inDouble; continue; }
      if (!inDouble && ch == 0x27) { inSingle = !inSingle; continue; }
      if (!inSingle && !inDouble && ch == charCode) return i;
    }
    return -1;
  }

  // Find matching '}' for a '{' at pos `openIndex` (openIndex points at '{')
  int _findMatchingBrace(String s, int openIndex) {
    bool inSingle = false, inDouble = false;
    int depth = 0;
    for (int i = openIndex; i < s.length; i++) {
      final ch = s.codeUnitAt(i);
      if (ch == 0x5C) { i++; continue; }
      if (!inSingle && ch == 0x22) { inDouble = !inDouble; continue; }
      if (!inDouble && ch == 0x27) { inSingle = !inSingle; continue; }
      if (!inSingle && !inDouble) {
        if (ch == 0x7B) { depth++; }
        else if (ch == 0x7D) {
          depth--;
          if (depth == 0) return i;
        }
      }
    }
    return -1;
  }

  // -------------------------
  // Step 3: extract ConfigurationProperties({...}) block inside class body
  // -------------------------
  String? _extractConfigurationPropertiesBlock(String classBody) {
    final token = 'ConfigurationProperties';
    int pos = 0;
    while (true) {
      final idx = classBody.indexOf(token, pos);
      if (idx < 0) return null;
      final paren = _indexOfCharOutsideStrings(classBody, 0x28 /* '(' */, idx + token.length);
      if (paren < 0) { pos = idx + token.length; continue; }
      final brace = _indexOfCharOutsideStrings(classBody, 0x7B /* '{' */, paren + 1);
      if (brace < 0) { pos = idx + token.length; continue; }
      final closeBrace = _findMatchingBrace(classBody, brace);
      if (closeBrace < 0) { pos = idx + token.length; continue; }
      return classBody.substring(brace + 1, closeBrace);
    }
  }

  // -------------------------
  // Step 4: parse the map literal content and extract constructor calls
  // -------------------------
  Map<String, dynamic> _parsePropertiesMap(String mapContent, Set<String> declaredSubclasses) {
    final out = <String, dynamic>{};
    int i = 0;

    while (i < mapContent.length) {
      // skip whitespace and commas
      while (i < mapContent.length && _isWhitespace(mapContent.codeUnitAt(i))) {
        i++;
      }
      if (i >= mapContent.length) break;
      if (mapContent.codeUnitAt(i) == 0x2C) { i++; continue; } // ','

      // Attempt to find a callee (Identifier or dotted Identifier) followed by '('
      int j = i;
      bool found = false;
      while (j < mapContent.length) {
        final ch = mapContent.codeUnitAt(j);
        if (ch == 0x28) { // '('
          found = true;
          break;
        }
        if (ch == 0x2C) break; // next top-level entry
        j++;
      }
      if (!found) break;

      // Backtrack from '(' to capture the callee token (dotted)
      final parenIndex = j;
      final calleeToken = _extractCalleeBeforeParen(mapContent, parenIndex);
      if (calleeToken == null) {
        // skip this '(' occurrence and continue scanning after it
        i = parenIndex + 1;
        continue;
      }

      // Determine candidate class name from calleeToken (take leftmost segment for dotted forms)
      final parts = calleeToken.split('.');
      final classCandidate = parts.length > 1 ? parts[0] : parts[0];

      final isLikelyPropertyCreator = _isLikelyPropertyCreator(calleeToken, classCandidate, declaredSubclasses);
      if (!isLikelyPropertyCreator) {
        // not a property constructor — move index past '(' and continue
        i = parenIndex + 1;
        continue;
      }

      // Find matching ')' for this parenIndex
      final parenClose = _findMatchingParen(mapContent, parenIndex);
      if (parenClose < 0) break;
      final argsContent = mapContent.substring(parenIndex + 1, parenClose);
      final args = _parseArgumentList(argsContent);

      if (args.isNotEmpty) {
        final key = args[0] is String ? args[0] as String : null;
        final value = args.length >= 2 ? args[1] : null;
        if (key != null) {
          out[key] = value;
        }
      }

      // Continue scanning after the parsed constructor call
      i = parenClose + 1;
    }

    return out;
  }

  // Extract callee token immediately before '(' at parenIndex.
  // Returns dotted token like 'JetProperty.custom' or 'MyProp' or 'pkg.MyProp'.
  String? _extractCalleeBeforeParen(String s, int parenIndex) {
    int i = parenIndex - 1;
    // Skip whitespace
    while (i >= 0 && _isWhitespace(s.codeUnitAt(i))) {
      i--;
    }
    if (i < 0) return null;

    // Collect identifier or dotted chain going left
    final end = i;
    while (i >= 0) {
      final c = s.codeUnitAt(i);
      if (_isIdentifierChar(c) || c == 0x2E /* '.' */) {
        i--;
        continue;
      }
      break;
    }
    final start = i + 1;
    if (start > end) return null;
    return s.substring(start, end + 1).trim();
  }

  bool _isIdentifierChar(int c) {
    // letters, digits, underscore
    return (c >= 0x30 && c <= 0x39) || (c >= 0x41 && c <= 0x5A) || (c >= 0x61 && c <= 0x7A) || c == 0x5F;
  }

  bool _isLikelyPropertyCreator(String calleeToken, String classCandidate, Set<String> declaredSubclasses) {
    // Heuristics:
    // - token begins with uppercase char (constructor/class style), or
    // - token ends with 'Property', or
    // - token is 'JetProperty', or
    // - token is among declared subclasses in this source
    final simple = classCandidate.split('.').last;
    if (simple == 'JetProperty') return true;
    if (declaredSubclasses.contains(simple)) return true;
    if (simple.endsWith('Property')) return true;
    if (simple.isNotEmpty && _isUppercase(simple.codeUnitAt(0))) return true;
    return false;
  }

  bool _isUppercase(int c) => c >= 0x41 && c <= 0x5A;

  // Find matching ')' for '(' at position openIndex
  int _findMatchingParen(String s, int openIndex) {
    bool inSingle = false, inDouble = false;
    int depth = 0;
    for (int i = openIndex; i < s.length; i++) {
      final ch = s.codeUnitAt(i);
      if (ch == 0x5C) { i++; continue; }
      if (!inSingle && ch == 0x22) { inDouble = !inDouble; continue; }
      if (!inDouble && ch == 0x27) { inSingle = !inSingle; continue; }
      if (!inSingle && !inDouble) {
        if (ch == 0x28) {
          depth++;
        } else if (ch == 0x29) {
          depth--;
          if (depth == 0) return i;
        }
      }
    }
    return -1;
  }

  // -------------------------
  // Argument list parser (commas outside nested structures)
  // -------------------------
  List<dynamic> _parseArgumentList(String s) {
    final out = <dynamic>[];
    int i = 0;
    while (i < s.length) {
      while (i < s.length && _isWhitespace(s.codeUnitAt(i))) {
        i++;
      }
      if (i >= s.length) break;
      final result = _parseValueFrom(s, i);
      out.add(result.value);
      i = result.nextIndex;
      while (i < s.length && _isWhitespace(s.codeUnitAt(i))) {
        i++;
      }
      if (i < s.length && s.codeUnitAt(i) == 0x2C) i++;
    }
    return out;
  }

  _ValueNext _parseValueFrom(String s, int start) {
    int i = start;
    while (i < s.length && _isWhitespace(s.codeUnitAt(i))) {
      i++;
    }
    if (i >= s.length) return _ValueNext(null, i);

    final ch = s.codeUnitAt(i);

    // String literal
    if (ch == 0x22 || ch == 0x27) {
      final strRes = _parseStringLiteral(s, i);
      return _ValueNext(strRes.value, strRes.nextIndex);
    }

    // List literal
    if (ch == 0x5B) { // '['
      final listRes = _parseListLiteral(s, i);
      return _ValueNext(listRes.value, listRes.nextIndex);
    }

    // number / bool / null / bareword
    final tokenBuffer = StringBuffer();
    while (i < s.length) {
      final c = s.codeUnitAt(i);
      if (_isWhitespace(c) || c == 0x2C || c == 0x29 || c == 0x5D || c == 0x7D) break;
      tokenBuffer.writeCharCode(c);
      i++;
    }
    final token = tokenBuffer.toString();
    final trimmed = token.trim();
    if (trimmed.isEmpty) return _ValueNext(null, i);

    if (trimmed == 'true') return _ValueNext(true, i);
    if (trimmed == 'false') return _ValueNext(false, i);
    if (trimmed == 'null') return _ValueNext(null, i);

    final intVal = int.tryParse(trimmed);
    if (intVal != null) return _ValueNext(intVal, i);
    final doubleVal = double.tryParse(trimmed);
    if (doubleVal != null) return _ValueNext(doubleVal, i);

    return _ValueNext(trimmed, i);
  }

  _ValueNext _parseStringLiteral(String s, int start) {
    final quote = s.codeUnitAt(start);
    final buf = StringBuffer();
    int i = start + 1;
    while (i < s.length) {
      final ch = s.codeUnitAt(i);
      if (ch == 0x5C) {
        if (i + 1 < s.length) {
          final next = s.codeUnitAt(i + 1);
          if (next == 0x6E) {
            buf.write('\n');
          } else if (next == 0x72) {
            buf.write('\r');
          } else if (next == 0x74) {
            buf.write('\t');
          } else if (next == 0x22) {
            buf.write('"');
          } else if (next == 0x27) {
            buf.write("'");
          } else if (next == 0x5C) {
            buf.write('\\');
          } else {
            buf.writeCharCode(next);
          }
          i += 2;
          continue;
        } else {
          i++;
          continue;
        }
      }
      if (ch == quote) {
        return _ValueNext(buf.toString(), i + 1);
      }
      buf.writeCharCode(ch);
      i++;
    }
    return _ValueNext(buf.toString(), i);
  }

  _ValueNext _parseListLiteral(String s, int start) {
    int i = start + 1;
    final items = <dynamic>[];
    while (i < s.length) {
      while (i < s.length && _isWhitespace(s.codeUnitAt(i))) {
        i++;
      }
      if (i >= s.length) break;
      if (s.codeUnitAt(i) == 0x5D) { i++; break; } // closing ']'
      final itemRes = _parseValueFrom(s, i);
      items.add(itemRes.value);
      i = itemRes.nextIndex;
      while (i < s.length && _isWhitespace(s.codeUnitAt(i))) {
        i++;
      }
      if (i < s.length && s.codeUnitAt(i) == 0x2C) i++;
    }
    return _ValueNext(items, i);
  }

  bool _isWhitespace(int c) => c == 0x20 || c == 0x09 || c == 0x0A || c == 0x0D;
}

// -------------------------
// Small helper classes
// -------------------------
class _Range {
  final int start;
  final int end;
  _Range(this.start, this.end);
}
class _ValueNext {
  final dynamic value;
  final int nextIndex;
  _ValueNext(this.value, this.nextIndex);
}