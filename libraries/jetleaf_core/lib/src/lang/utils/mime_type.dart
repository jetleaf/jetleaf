import 'dart:collection';

import '../exceptions.dart';
import 'mime_type_utils.dart';

/// {@template mime_type}
/// An immutable, industry-standard value object representing a Multipurpose Internet Mail Extensions (MIME) 
/// type, as defined in RFC 2045 and RFC 2046.
///
/// `MimeType` serves as a core communication descriptor across serialization systems, data binding boundaries, 
/// and HTTP network infrastructure (e.g., managing the `Content-Type` header). It decomposes media format descriptors 
/// into a main [type], a localized [subtype], and an unmodifiable [parameters] map.
///
/// ### Structural Anatomy
/// ```text
///      application /  json  ;  charset = utf-8
///     |____.____|   |__.__|   |______.______|
///         type       subtype      parameters
/// ```
///
/// ### Precedence, Inclusions, and Compatibility Rules
/// This class encapsulates advanced framework routing logic to determine structural compatibility matching:
/// * **Inclusion ([includes]):** Evaluates whether a generic MIME expression fully spans another target structure (e.g., `text/*` includes `text/html`).
/// * **Compatibility ([isCompatibleWith]):** Evaluates whether two media envelopes intersect dynamically, taking wildcard definitions and vendor suffixes (`+xml`, `+json`) into account.
/// * **Specificity ([isMoreSpecific]):** Orders dynamic media types to resolve content negotiation loops, prioritizing fully concrete representations over loose wildcard structures.
///
/// ### Immutability & Thread Safety
/// Once constructed, a `MimeType` instance is functionally stateless and immutable. String representations are 
/// lazily calculated and cached inside [_toStringValue] using a safe thread-isolated layout to eliminate redundant 
/// allocations during repeated logging or serialization phases.
/// {@endtemplate}
class MimeType implements Comparable<MimeType> {
  /// Global structural constant identifier for wildcard or untyped catch-all tokens (`*`).
  static const String _wildcardType = '*';

  /// Standardized parameter tracking token identifier key assigned to regional character encodings.
  static const String _paramCharset = 'charset';

  /// The primary media segment identifier (e.g., `"text"`, `"application"`, `"image"`). Always lowercased.
  final String type;

  /// The secondary format resolution segment identifier (e.g., `"html"`, `"json"`, `"*"`). Always lowercased.
  final String subtype;

  /// An unmodifiable, case-insensitive mapping tracking secondary media payload attributes (e.g., `charset=utf-8`, `boundary=something`).
  final Map<String, String> parameters;

  /// Internal cached string state holding the fully serialized representation string.
  String? _toStringValue;

  /// Generates a validated [MimeType] entry by binding an explicit [type], an optional [subtype], and a [parameters] tracking map.
  ///
  /// Forces lowercase normalizations and verifies structural integrity checks against illegal control characters.
  ///
  /// ### Validation Rules & Failures
  /// * Throws an [IllegalArgumentException] if the [type] token is a blank string.
  /// * Throws an [IllegalArgumentException] if the [subtype] token is a blank string.
  /// * Interrogates [MimeTypeUtils.checkToken] to confirm both tokens omit illegal characters or RFC separator symbols.
  /// 
  /// {@macro mime_type}
  MimeType(String type, [String? subtype, Map<String, String>? parameters])
    : type = type.toLowerCase(),
      subtype = (subtype ?? _wildcardType).toLowerCase(),
      parameters = MimeTypeUtils.createParametersMap(parameters) 
  {
    if (this.type.isEmpty) {
      throw IllegalArgumentException("'type' must not be empty");
    }
    if (this.subtype.isEmpty) {
      throw IllegalArgumentException("'subtype' must not be empty");
    }
    MimeTypeUtils.checkToken(this.type);
    MimeTypeUtils.checkToken(this.subtype);
  }

  /// Specialized generative shortcut constructor binding an explicit [type] and [subtype] directly to a tracking [charset] property.
  /// 
  /// {@macro mime_type}
  MimeType.fromCharset(String type, String subtype, String charset)
    : this(type, subtype, {_paramCharset: charset});

  /// Assembles a fresh [MimeType] copy from an existing [other] baseline while selectively overriding or appending extra dictionary [parameters].
  /// 
  /// {@macro mime_type}
  MimeType.copyOf(MimeType other, {Map<String, String>? parameters})
    : type = other.type,
      subtype = other.subtype,
      parameters = MimeTypeUtils.createParametersMap(
        parameters != null ? {...other.parameters, ...parameters} : other.parameters,
      );

  /// Returns `true` if the core [type] segment matches the catch-all wildcard token value (`*`).
  bool get isWildcardType => _wildcardType == type;

  /// Returns `true` if the [subtype] segment matches a broad wildcard (`*`) or features a structured trailing wildcard suffix mapping (`*+json`).
  bool get isWildcardSubtype => _wildcardType == subtype || subtype.startsWith('*+');

  /// Returns `true` if this instance contains completely verified concrete components, lacking any wildcard markers.
  bool get isConcrete => !isWildcardType && !isWildcardSubtype;

  /// Extracts the structural suffix extension format out of structured custom subtypes (e.g., returning `"xml"` out of `"application/xhtml+xml"`).
  ///
  /// Returns `null` if the subtype string does not contain an active `+` delimiter separation point.
  String? get subtypeSuffix {
    final suffixIndex = subtype.lastIndexOf('+');
    if (suffixIndex != -1 && subtype.length > suffixIndex) {
      return subtype.substring(suffixIndex + 1);
    }
    return null;
  }

  /// Diagnostic getter checking the parameters map for the presence of a localized text `charset` option.
  String? get charset => parameters[_paramCharset];

  /// Direct parameter retrieval lookup helper sourcing data values straight out of the [parameters] context index map.
  String? getParameter(String name) => parameters[name];

  /// Core evaluation routine establishing whether this instance completely spans or encompasses the [other] mime boundary.
  ///
  /// ### Operational Inclusion Behaviors
  /// * `*/*` includes everything uniformly.
  /// * `text/*` includes `text/html` and `text/plain` but rejects `application/json`.
  /// * `application/*+xml` includes `application/soap+xml`.
  bool includes(MimeType? other) {
    if (other == null) return false;
    if (isWildcardType) return true;
    if (type != other.type) return false;
    if (subtype == other.subtype) return true;
    if (!isWildcardSubtype) return false;
    final thisPlusIdx = subtype.lastIndexOf('+');
    if (thisPlusIdx == -1) return true;
    final otherPlusIdx = other.subtype.lastIndexOf('+');
    if (otherPlusIdx != -1) {
      final thisSuffix = subtype.substring(thisPlusIdx + 1);
      final otherSuffix = other.subtype.substring(otherPlusIdx + 1);
      final thisNoSuffix = subtype.substring(0, thisPlusIdx);
      if (thisSuffix == otherSuffix && _wildcardType == thisNoSuffix) {
        return true;
      }
    }
    return false;
  }

  /// Structural evaluation routine verifying whether two MIME types intersect or can coexist within content exchange channels.
  ///
  /// Unlike [includes], compatibility checks behave symmetrically: `text/html` is compatible with `text/*`.
  bool isCompatibleWith(MimeType? other) {
    if (other == null) return false;
    if (isWildcardType || other.isWildcardType) return true;
    if (type != other.type) return false;
    if (subtype == other.subtype) return true;
    if (!isWildcardSubtype && !other.isWildcardSubtype) return false;
    final thisSuffix = subtypeSuffix;
    final otherSuffix = other.subtypeSuffix;
    if (subtype == _wildcardType || other.subtype == _wildcardType) return true;
    if (isWildcardSubtype && thisSuffix != null) {
      return thisSuffix == other.subtype || thisSuffix == otherSuffix;
    }
    if (other.isWildcardSubtype && otherSuffix != null) {
      return subtype == otherSuffix || otherSuffix == thisSuffix;
    }
    return false;
  }

  /// Shallow comparison checking segment matching keys exclusively, completely ignoring secondary [parameters] map weights.
  bool equalsTypeAndSubtype(MimeType? other) {
    if (other == null) return false;
    return type.toLowerCase() == other.type.toLowerCase() &&
        subtype.toLowerCase() == other.subtype.toLowerCase();
  }

  /// Iterates a dynamic collection of mime contexts to see if any element matches the explicit type and subtype of this instance.
  bool isPresentIn(Iterable<MimeType> mimeTypes) {
    for (final mimeType in mimeTypes) {
      if (mimeType.equalsTypeAndSubtype(this)) return true;
    }
    return false;
  }

  /// Advanced sorting algorithm tracking media priority weightings for resource routing systems.
  ///
  /// Highly specific entries override generic entries during execution matching cycles:
  /// 1. `text/html` is more specific than `text/*`.
  /// 2. `text/*` is more specific than `*/*`.
  /// 3. If types and subtypes match identically, the instance carrying the larger [parameters] definition count wins.
  bool isMoreSpecific(MimeType other) {
    final thisWildcard = isWildcardType;
    final otherWildcard = other.isWildcardType;
    if (thisWildcard && !otherWildcard) return false;
    if (!thisWildcard && otherWildcard) return true;
    final thisWildcardSub = isWildcardSubtype;
    final otherWildcardSub = other.isWildcardSubtype;
    if (thisWildcardSub && !otherWildcardSub) return false;
    if (!thisWildcardSub && otherWildcardSub) return true;
    if (type == other.type && subtype == other.subtype) {
      return parameters.length > other.parameters.length;
    }
    return false;
  }

  /// Inverse logic proxy matching for specific priority weight calculations. Delegates directly to [isMoreSpecific].
  bool isLessSpecific(MimeType other) => other.isMoreSpecific(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MimeType &&
        type.toLowerCase() == other.type.toLowerCase() &&
        subtype.toLowerCase() == other.subtype.toLowerCase() &&
        _parametersAreEqual(other);
  }

  /// Evaluates dictionary parameters symmetrically across two distinct targets.
  bool _parametersAreEqual(MimeType other) {
    if (parameters.length != other.parameters.length) return false;
    for (final entry in parameters.entries) {
      if (!other.parameters.containsKey(entry.key)) return false;
      if (_paramCharset == entry.key) {
        if (charset != other.charset) return false;
      } else if (entry.value != other.parameters[entry.key]) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode {
    int result = type.toLowerCase().hashCode;
    result = 31 * result + subtype.toLowerCase().hashCode;
    for (final entry in parameters.entries) {
      result = 31 * result + entry.key.toLowerCase().hashCode;
      result = 31 * result + entry.value.hashCode;
    }
    result = 31 * result + parameters.length;
    return result;
  }

  /// Serializes the entire configuration state into a canonical, lowercase structural string layout.
  ///
  /// Caches the generated string token in an internal state layer (`_toStringValue`) to avoid building 
  /// repetitive string buffers on future diagnostic calls.
  @override
  String toString() {
    final value = _toStringValue;
    if (value != null) return value;
    final buffer = StringBuffer();
    _appendTo(buffer);
    _toStringValue = buffer.toString();
    return _toStringValue!;
  }

  /// Appends standard string segments down to a shared application logging buffer stream.
  void _appendTo(StringBuffer buffer) {
    buffer
      ..write(type)
      ..write('/')
      ..write(subtype);
    for (final entry in parameters.entries) {
      buffer
        ..write(';')
        ..write(entry.key)
        ..write('=')
        ..write(entry.value);
    }
  }

  /// Standard sorting implementation to arrange media lists alphabetically by type, subtype, and attributes.
  ///
  /// Organizes keys using an alphanumeric [SplayTreeSet] with case-insensitive comparisons to guarantee 
  /// deterministic formatting layouts, regardless of internal map generation order.
  @override
  int compareTo(MimeType other) {
    var comp = type.toLowerCase().compareTo(other.type.toLowerCase());
    if (comp != 0) return comp;
    comp = subtype.toLowerCase().compareTo(other.subtype.toLowerCase());
    if (comp != 0) return comp;
    comp = parameters.length.compareTo(other.parameters.length);
    if (comp != 0) return comp;

    final thisKeys = SplayTreeSet<String>(MimeTypeUtils.caseInsensitiveCompare)
      ..addAll(parameters.keys);
    final otherKeys = SplayTreeSet<String>(MimeTypeUtils.caseInsensitiveCompare)
      ..addAll(other.parameters.keys);
    final thisIter = thisKeys.iterator;
    final otherIter = otherKeys.iterator;

    while (thisIter.moveNext() && otherIter.moveNext()) {
      final thisAttr = thisIter.current;
      final otherAttr = otherIter.current;
      comp = thisAttr.toLowerCase().compareTo(otherAttr.toLowerCase());
      if (comp != 0) return comp;
      if (_paramCharset == thisAttr) {
        final thisCharset = charset;
        final otherCharset = other.charset;
        if (thisCharset != otherCharset) {
          if (thisCharset == null) return -1;
          if (otherCharset == null) return 1;
          comp = thisCharset.compareTo(otherCharset);
          if (comp != 0) return comp;
        }
      } else {
        final thisValue = parameters[thisAttr] ?? '';
        final otherValue = other.parameters[otherAttr] ?? '';
        comp = thisValue.compareTo(otherValue);
        if (comp != 0) return comp;
      }
    }
    return 0;
  }

  /// Global factory method parsing an un-tokenized string directly into a fully configured [MimeType] instance.
  /// Delegates processing logic to [MimeTypeUtils.parseMimeType].
  static MimeType valueOf(String value) => MimeTypeUtils.parseMimeType(value);
}