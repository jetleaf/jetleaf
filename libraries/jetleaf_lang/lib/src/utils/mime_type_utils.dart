import 'dart:collection';

import '../exceptions.dart';
import 'mime_type.dart';

/// {@template mime_type_utils}
/// A low-level parsing and validation engine providing stateless utilities for handling
/// MIME/Media Types according to RFC 2045, RFC 2046, and RFC 7231 structural rules.
///
/// `MimeTypeUtils` manages character token verification, parsing for nested parameters, 
/// and content-negotiation lookups. It isolates raw string manipulation from the rest of the 
/// framework, ensuring that only valid media types travel through type conversion networks or 
/// HTTP pipeline adapters.
///
/// ### RFC 7230 Token Definition Laws
/// Under HTTP/1.1 specifications, a US-ASCII token cannot feature Control Characters (`0x00` through `0x31`, 
/// and `0x7F`) or explicit Separator Characters (delimiters). This utility computes an unmodifiable bit-vector 
/// map ([_token]) at class initialization to enforce these structural lexical rules.
///
/// ### Thread Safety and Architectural State
/// This class is explicitly declared as an `abstract final` structure to block subclassing and 
/// initialization routines. All methods are deterministic algorithms that run without side effects 
/// on internal state, offering performance for high-throughput network routing environments.
/// {@endtemplate}
abstract final class MimeTypeUtils {
  /// The pre-computed boolean lookup mask identifying valid US-ASCII token characters.
  static final Set<int> _token = _buildToken();

  /// Computes the fast bit-mask tracking matching lexical rules defined inside RFC 2045.
  /// 
  /// It isolates valid elements by stripping all control points and 18 standard visual separators:
  /// `(`, `)`, `<`, `>`, `@`, `,`, `;`, `:`, `"`, `/`, `[`, `]`, `?`, `=`, `{`, `}`, ` `, and `\t`.
  static Set<int> _buildToken() {
    final ctl = List<bool>.filled(128, false);
    for (int i = 0; i <= 31; i++) {
      ctl[i] = true;
    }
    ctl[127] = true;

    final separators = List<bool>.filled(128, false);
    for (final ch in '()<>@,;:"/[]?={} \t'.codeUnits) {
      if (ch < 128) separators[ch] = true;
    }

    final token = Set<int>.from(List<int>.generate(128, (i) => i));
    for (int i = 0; i < 128; i++) {
      if (ctl[i] || separators[i]) {
        token.remove(i);
      }
    }
    return token;
  }

  /// Evaluates every character inside a [token] string sequence against the computed US-ASCII validity matrix.
  ///
  /// ### Failures & Validation Fallbacks
  /// Throws an [IllegalArgumentException] if an invalid control character or separator character 
  /// code is discovered (e.g., verifying a malformed token like `"text/html; boundary=space character"`).
  static void checkToken(String token) {
    for (int i = 0; i < token.length; i++) {
      final ch = token.codeUnitAt(i);
      if (!_token.contains(ch)) {
        throw IllegalArgumentException(
          "Invalid token character '${String.fromCharCode(ch)}' in token \"$token\"",
        );
      }
    }
  }

  /// Verifies whether a parameter value string is enclosed symmetrically within matching single or double quotes.
  static bool isQuotedString(String s) {
    if (s.length < 2) return false;
    return (s.startsWith('"') && s.endsWith('"')) ||
        (s.startsWith("'") && s.endsWith("'"));
  }

  /// Strips leading and trailing boundary quote wrappers out of text parameter records.
  static String unquote(String s) {
    return isQuotedString(s) ? s.substring(1, s.length - 1) : s;
  }

  /// Converts a raw dictionary of media attributes into a canonical, alphabetically sorted, unmodifiable map layout.
  ///
  /// Validates both keys and unquoted values to prevent protocol injection attempts.
  ///
  /// ### Parameters
  /// - [parameters]: The raw incoming map tracking transient string keys and attributes.
  /// 
  /// ### Design Constraints
  /// Returns a [SplayTreeMap] wrapped within an [UnmodifiableMapView]. This guarantees that 
  /// parameter iterations are consistently sorted (using [caseInsensitiveCompare]) regardless of the allocation 
  /// order in upstream payloads, reducing memory overhead and maintaining deterministic behavior.
  static Map<String, String> createParametersMap(Map<String, String>? parameters) {
    if (parameters == null || parameters.isEmpty) {
      return {};
    }
    final map = SplayTreeMap<String, String>(caseInsensitiveCompare);
    for (final entry in parameters.entries) {
      checkToken(entry.key);
      if (!isQuotedString(entry.value)) {
        checkToken(entry.value);
      }
      map[entry.key] = entry.value;
    }
    return UnmodifiableMapView(map);
  }

  /// A case-insensitive string comparison utility that falls back to case-sensitive evaluation 
  /// if lowercase values match exactly. This provides deterministic sorting across collection bounds.
  static int caseInsensitiveCompare(String a, String b) {
    final al = a.toLowerCase();
    final bl = b.toLowerCase();
    final cmp = al.compareTo(bl);
    if (cmp != 0) return cmp;
    return a.compareTo(b);
  }

  /// Scans and tokenizes an unparsed text block into a fully hydrated [MimeType] data payload envelope.
  ///
  /// ### Processing Steps
  /// 1. **Primary Slicing:** Splits the string on the primary forward-slash delimiter (`/`) into main media type and sub-type components.
  /// 2. **Subtype Boundary Isolation:** Scans the second half of the split for a semicolon separator (`;`) to check for the presence of secondary parameter fields.
  /// 3. **Sub-Lexer Routing:** Delegates any extra characters found after the semicolon to the internal state processor `_parseParameters`.
  ///
  /// ### Parameters
  /// - [mimeType]: The raw incoming un-tokenized textual string to translate.
  ///
  /// ### Failures & Boundary Safety
  /// * Throws an [IllegalArgumentException] if the source string text parameter is blank.
  /// * Throws an [IllegalArgumentException] if the string lacks a slash, has too many slashes, or missing type/subtype definitions.
  static MimeType parseMimeType(String mimeType) {
    if (mimeType.isEmpty) {
      throw IllegalArgumentException("'mimeType' must not be empty");
    }

    final parts = mimeType.split('/');
    if (parts.length != 2 || parts[0].isEmpty || parts[1].isEmpty) {
      throw IllegalArgumentException("Invalid MIME type: $mimeType");
    }

    final type = parts[0].trim();
    final subtypeAndParams = parts[1];

    final paramStart = subtypeAndParams.indexOf(';');
    final subtype = (paramStart == -1 ? subtypeAndParams : subtypeAndParams.substring(0, paramStart)).trim();

    final parameters = <String, String>{};
    if (paramStart != -1) {
      final paramString = subtypeAndParams.substring(paramStart + 1);
      _parseParameters(paramString, parameters);
    }

    return MimeType(type, subtype, parameters);
  }

  /// Low-level iterative lexical parsing engine decoding complex HTTP parameter strings.
  ///
  /// This parser handles quoted parameters and respects character escaping laws inside parameter bounds.
  static void _parseParameters(String paramString, Map<String, String> parameters) {
    int index = 0;
    while (index < paramString.length) {
      index = _skipWhitespace(paramString, index);
      if (index >= paramString.length) break;

      final nameEnd = _indexOfAny(paramString, index, '=;');
      if (nameEnd == -1 || paramString[nameEnd] != '=') {
        throw IllegalArgumentException("Invalid parameter syntax in: $paramString");
      }

      final name = paramString.substring(index, nameEnd).trim();
      index = nameEnd + 1;

      index = _skipWhitespace(paramString, index);
      if (index >= paramString.length) {
        throw IllegalArgumentException("Invalid parameter syntax in: $paramString");
      }

      final String value;
      if (paramString[index] == '"') {
        final endQuote = _findClosingQuote(paramString, index);
        value = paramString.substring(index, endQuote + 1);
        index = endQuote + 1;
      } else {
        final valueEnd = _indexOfAny(paramString, index, ';');
        value = (valueEnd == -1
                ? paramString.substring(index)
                : paramString.substring(index, valueEnd))
            .trim();
        index = valueEnd == -1 ? paramString.length : valueEnd;
      }

      parameters[name] = value;

      index = _skipWhitespace(paramString, index);
      if (index < paramString.length && paramString[index] == ';') {
        index++;
      }
    }
  }

  /// Increments an internal string pointer index to skip layout spaces and horizontal tabs.
  static int _skipWhitespace(String s, int start) {
    int i = start;
    while (i < s.length && (s[i] == ' ' || s[i] == '\t')) {
      i++;
    }
    return i;
  }

  /// Linear search utility locating the primary positional coordinate index of any target character within a token sequence.
  static int _indexOfAny(String s, int start, String chars) {
    for (int i = start; i < s.length; i++) {
      if (chars.contains(s[i])) return i;
    }
    return -1;
  }

  /// Advanced sub-lexer scanning loop tracking balanced quotes and skipping backslash-escaped characters (`\"`).
  ///
  /// ### Failures & State Handling
  /// Throws an [IllegalArgumentException] if the text sequence terminates without a closing quote boundary match.
  static int _findClosingQuote(String s, int openQuote) {
    final quote = s[openQuote];
    int i = openQuote + 1;
    while (i < s.length) {
      if (s[i] == '\\' && i + 1 < s.length) {
        i += 2; // Jump index ahead to bypass escaped character points safely
        continue;
      }
      if (s[i] == quote) return i;
      i++;
    }
    throw IllegalArgumentException("Unterminated quoted string in: $s");
  }

  /// Splits a comma-separated list of media type strings, trims individual items, and parses them 
  /// into an array list of [MimeType] records.
  ///
  /// Typically utilized when parsing the `Accept` header from HTTP request records to resolve 
  /// server-side content negotiation rules.
  static List<MimeType> parseMimeTypes(String mimeTypes) {
    if (mimeTypes.isEmpty) return [];
    return mimeTypes.split(',').where((s) => s.trim().isNotEmpty).map((s) => parseMimeType(s.trim())).toList();
  }

  /// Checks if a targeted [mimeType] string is structurally compatible with any item in a list of [supportedTypes].
  ///
  /// ### Architecture Example
  /// ```dart
  /// final acceptedTypes = ["application/json", "text/*"];
  /// 
  /// bool canRenderHtml = MimeTypeUtils.supportsMimeType("text/html", acceptedTypes);
  /// print(canRenderHtml); // true (matches via wildcard routing laws)
  /// 
  /// bool canRenderXml = MimeTypeUtils.supportsMimeType("application/xml", acceptedTypes);
  /// print(canRenderXml); // false
  /// ```
  static bool supportsMimeType(String mimeType, List<String> supportedTypes) {
    final parsed = parseMimeType(mimeType);
    for (final supported in supportedTypes) {
      if (parsed.isCompatibleWith(parseMimeType(supported))) {
        return true;
      }
    }
    return false;
  }
}