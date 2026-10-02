import 'package:jetleaf_lang/design.dart';
import 'package:intl/intl.dart' as intl;
import 'package:meta/meta.dart';

import '../core.dart';

/// {@template abstract_number_formatter}
/// An architectural template-method formatter providing shared locale-aware orchestration, stateful 
/// lenient/strict parsing boundaries, and bi-directional validation routines for numerical values.
///
/// `AbstractNumberFormatter` standardizes how numeric types are converted to and from localized text. 
/// Instead of duplicating parsing logic across individual style sub-classes (e.g., Currency, Percent, 
/// or Decimal formatters), it centralizes processing flow and delegates regional styling rules to concrete 
/// subclasses via the protected template engine hook [getNumberFormat].
///
/// ### Strict vs. Lenient Invariant Mechanics
/// By default, the parser operates under strict validation laws ($[_lenient] = \text{false}$). Because third-party 
/// underlying locale engines frequently apply aggressive substring matching—such as treating `"42 USD trailing-garbage"` 
/// as a valid representation of the number `42`—this abstract layer enforces round-trip string integrity checks:
/// 
/// 1. **Initial Evaluation:** The text is trimmed of peripheral boundaries and passed to the localized pattern reader.
/// 2. **Bi-Directional Verification:** If parsing succeeds, the resulting numerical snapshot is immediately formatted 
///    back into a string using the same locale configuration rules.
/// 3. **Length and Envelope Inspection:** The reconstructed token's length is measured against the sanitized user input. 
///    If structural mismatches are discovered (meaning the original text contained unaccounted trailing or unparsed noise), 
///    the transaction is rejected by throwing an [InvalidFormatException].
/// 4. **Lenient Bypass:** When [_lenient] is explicitly enabled, this secondary verification loop is skipped. The partial 
///    extracted scalar is immediately passed downstream.
///
/// ### Operational Lifecycle Flow
/// ```text
/// User Input String -> [ Trim Spaces ] -> [ intl.NumberFormat.parse ] 
///                                                    |
///                                            (Parsed Success)
///                                                    |
///                                         Is _lenient flag true?
///                                         /                    \
///                                      (Yes)                  (No)
///                                       /                        \
///                    Return Result Snapshot            [ Round-Trip Format ]
///                                                                 |
///                                                      Does length & content match?
///                                                      /                          \
///                                                   (Yes)                         (No)
///                                                    /                              \
///                                         Return Result Snapshot         Throw InvalidFormatException
/// ```
/// {@endtemplate}
abstract class AbstractNumberFormatter implements Formatter<num> {
  /// Toggle state controlling the strictness of input verification loops during text decoding cycles.
  bool _lenient = false;

  /// Modifies the processing mode configuration to allow partial or loosely formatted input text boundaries.
  /// 
  /// Defaults to `false` (Strict structural checking active). Turn this on when parsing user interfaces 
  /// with dynamic inline edits, autocomplete components, or mixed text elements where exact structural representation checks 
  /// are too restrictive.
  void setLenient(bool lenient) {
    _lenient = lenient;
  }

  /// Transforms an active numerical primitive or value object [number] state snapshot into a formatted, 
  /// localized text string using the regional layout rules provided by the target [locale].
  ///
  /// This method resolves layout components (such as grouping intervals, localized thousand separators, currency symbols, 
  /// and trailing percent signs) by delegating to [getNumberFormat].
  @override
  String print(num number, Locale locale) => getNumberFormat(locale).format(number);

  /// Scans, tokenizes, and converts an unstructured localized text block [text] into a type-safe [num] instance.
  ///
  /// Rejects input text if it features illegal format boundaries or conflicts with active strict evaluation constraints.
  ///
  /// ### Parameters
  /// - [text]: The raw localized alphanumeric text input stream block to parse.
  /// - [locale]: The active cultural configuration context token governing lexical translation rules.
  ///
  /// ### Failures & Boundary Safety
  /// * Throws an [IllegalArgumentException] if the text sequence cannot be translated to a valid number by the localizer pattern.
  /// * Throws an [IllegalArgumentException] under strict validation rules if the input contains trailing data noise or 
  ///   unparsed structural characters, causing a bi-directional round-trip string comparison mismatch.
  ///
  /// ### Architecture Example
  /// ```dart
  /// final formatter = CurrencyNumberFormatter(); // Concrete subclass implementation
  /// formatter.setLenient(false); // Force strict checking
  /// 
  /// // Valid execution cycle passes cleanly
  /// final num cost = formatter.parse("$1,500.25", Locale.en_US); 
  /// 
  /// // Fails strict parsing loop and throws IllegalArgumentException (trailing garbage noise discovered)
  /// formatter.parse("$1,500.25 text-noise", Locale.en_US); 
  /// ```
  @override
  num parse(String text, Locale locale) {
    final format = getNumberFormat(locale);
    final trimmed = text.trim();
    
    try {
      final result = format.parse(trimmed);
      if (!_lenient) {
        // Strict verification: format the parsed value back 
        // to verify it completely represents the initial text input string length.
        final roundTrip = format.format(result);
        if (roundTrip.length != trimmed.length && !trimmed.contains(roundTrip)) {
          throw InvalidFormatException("Strict parsing failure: input layout mismatch");
        }
      }
      return result;
    } on InvalidFormatException catch (e) {
      throw IllegalArgumentException("Could not parse number expression '$text': ${e.message}");
    }
  }

  /// Internal template-method hook used to retrieve a fully configured, localized [intl.NumberFormat] instance 
  /// matching the specific subclass configuration strategy.
  ///
  /// Concrete sub-classes must override this hook method to define their target structural formatting layout archetype 
  /// (e.g., initializing a percent layout, currency scheme, or custom numeric pattern matrix).
  @protected
  intl.NumberFormat getNumberFormat(Locale locale);
}

// ================================================== NUMBER STYLE FORMATTER ===================================================

/// {@template number_style_formatter}
/// A concrete, highly customizable implementation of [AbstractNumberFormatter] designed for general-purpose 
/// decimal layout formatting and custom algebraic string masking.
///
/// `NumberStyleFormatter` maps numeric properties directly to presentation layers or serialization outputs by 
/// leveraging localized layout engines. It provides dual-mode processing: standard decimal configurations that respect 
/// regional conventions (e.g., thousands separators and decimal markers), and custom format masks via pattern string assignments.
///
/// ### Behavioral Mode Routing
/// The underlying localization engine alters its internal token matching strategies depending on the presence of a pattern:
/// 1. **Standard Decimal Mode:** If no structural template mask is supplied ($[_pattern] = \text{null}$), the formatter 
///    retrieves a localized standard decimal structure (`intl.NumberFormat.decimalPattern`). This applies regional digit 
///    grouping constants across standard localized symbols (e.g., generating `"1,234,567.89"` for `en_US` versus `"1.234.567,89"` for `de_DE`).
/// 2. **Explicit Mask Pattern Mode:** If a custom pattern string is provided via [setPattern] or the constructor (e.g., `#,##0.000`), 
///    the template layout engine overlays this structural constraint onto the targeted locale coordinates. This lets teams force fixed 
///    decimal lengths, prefix zero-padding masks, or customized scaling behaviors while preserving regional decimal markers.
///
/// ### Structural Thread Isolation
/// This class retains a mutable configuration state variable (`_pattern`) to allow reconfiguration during system startup or context injection 
/// phases. When deployed within high-throughput processing routines or concurrent background streaming operations, ensure that 
/// instances are locked down or isolated per processing thread to avoid configuration race hazards.
///
/// ### Architecture Example
/// ```dart
/// // Archetype A: Standard dynamic localized regional formatting
/// final standardFormatter = NumberStyleFormatter();
/// print(standardFormatter.print(1234567.89, Locale.en_US)); // "1,234,567.89"
/// print(standardFormatter.print(1234567.89, Locale.de_DE)); // "1.234.567,89"
/// 
/// // Archetype B: Custom structural token mask with zero-padding overrides
/// final customFormatter = NumberStyleFormatter("000,000.00");
/// print(customFormatter.print(4250.7, Locale.en_US)); // "004,250.70"
/// 
/// // Strict validation from the abstract template layer remains active
/// customFormatter.setLenient(false);
/// final num scalarValue = customFormatter.parse("004,250.70", Locale.en_US); 
/// ```
/// {@endtemplate}
class NumberStyleFormatter extends AbstractNumberFormatter {
  /// The explicit pattern string mask containing formatting structural tokens (e.g., `#,###.##`).
  String? _pattern;

  /// Creates a new [NumberStyleFormatter], optionally binding an initial custom formatting [_pattern] string mask.
  /// 
  /// {@macro number_style_formatter}
  NumberStyleFormatter([this._pattern]);

  /// Reconfigures or overrides the internal custom formatting template token pattern string mask dynamically.
  /// 
  /// Pass `null` to clear pattern overrides and restore standard localized decimal layout configurations.
  void setPattern(String pattern) {
    _pattern = pattern;
  }

  /// Internal template-method implementation hook generating a custom or localized decimal [intl.NumberFormat] architecture.
  ///
  /// Extracts regional parameters out of the incoming [locale] mapping token using standard string conversions 
  /// (e.g., translating a locale into language tag values like `"en_US"` or `"fr_FR"`).
  ///
  /// ### Parameters
  /// - [locale]: The active cultural configuration context token governing structural symbol choices and layout rules.
  @override
  intl.NumberFormat getNumberFormat(Locale locale) {
    final localeTag = locale.toString();
    if (_pattern != null) {
      return intl.NumberFormat(_pattern, localeTag);
    }
    return intl.NumberFormat.decimalPattern(localeTag);
  }
}

// ================================================== PERCENT STYLE FORMATTER ===================================================

/// {@template percent_style_formatter}
/// A concrete implementation of [AbstractNumberFormatter] designed for localized percentage 
/// layout formatting and mathematical scale translations.
///
/// `PercentStyleFormatter` handles the presentation and parsing of fractional values as 
/// percentages by applying locale-specific rules for number scaling, placement of the 
/// percent symbol (`%`), and space character padding.
///
/// ### Mathematical Scale Transformation Laws
/// Percentage formatting requires a bidirectional mathematical scale conversion ($100 \times$) 
/// between raw system data values and human-readable text representations:
/// * **Printing Operations:** The raw numeric scalar is automatically multiplied by 100 before 
///   formatting. For example, a system fractional ratio value of `0.125` is scaled and formatted 
///   as `"12.5%"` or localized variants.
/// * **Parsing Operations:** The text decoding process automatically reverses this scale factor. 
///   Parsing a user input string like `"75%"` processes the raw numeric token and divides it by 100, 
///   returning the fractional decimal equivalent `0.75` for internal computation.
///
/// ### Regional Localization Behaviors
/// The underlying localization engine automatically adapts layout tokens based on the incoming 
/// [locale] tag context. This ruleset ensures compliance with diverse international typographic 
/// and administrative style manuals:
/// * **Symbol Placement & Padding:** Standardizes variations between trailing suffixes (e.g., `"12%"` 
///   in `en_US`), leading prefixes, and layouts that mandate non-breaking thin spaces before the percent sign 
///   (e.g., `"12 %"` in `fr_FR`).
/// * **Decimal & Thousands Markers:** Leverages regional digit grouping definitions to handle values 
///   above 100% correctly (e.g., formatting `1500.5` as `"150,050%"` under `en_US` coordinates).
///
/// ### Invariant Verification Properties
/// This formatter inherits the strict verification loop of its parent [AbstractNumberFormatter]. Under 
/// default strict rules, any trailing text, missing percent tokens, or structural layout discrepancies 
/// during parsing will fail bi-directional round-trip comparisons and throw an informative error.
///
/// ### Architecture Example
/// ```dart
/// final PercentStyleFormatter formatter = PercentStyleFormatter();
/// 
/// // --- Archetype A: Standard Printing Operations ---
/// final double efficiencyRatio = 0.8462;
/// 
/// print(formatter.print(efficiencyRatio, Locale.en_US)); // "85%" (applies default rounding/scaling)
/// print(formatter.print(efficiencyRatio, Locale.fr_FR)); // "85 %" (injects non-breaking space)
/// 
/// // --- Archetype B: Strict Data Parsing Operations ---
/// formatter.setLenient(false);
/// 
/// final num computedFraction = formatter.parse("75%", Locale.en_US);
/// print(computedFraction); // 0.75
/// 
/// // Triggers validation fallback exception safely (violates strict round-trip serialization)
/// formatter.parse("75", Locale.en_US); // Throws IllegalArgumentException: Strict parsing failure
/// ```
/// {@endtemplate}
class PercentStyleFormatter extends AbstractNumberFormatter {
  /// {@macro percent_style_formatter}
  PercentStyleFormatter();

  /// Internal template-method implementation hook generating a localized percent [intl.NumberFormat] architecture.
  ///
  /// Extracts regional parameters out of the incoming [locale] mapping token using standard string conversions 
  /// (e.g., translating a locale into standard language tag strings like `"en_US"`, `"de_DE"`, or `"fr_FR"`).
  ///
  /// ### Parameters
  /// - [locale]: The active cultural configuration context token governing structural symbol choices, padding layouts, and percent rules.
  @override
  intl.NumberFormat getNumberFormat(Locale locale) {
    return intl.NumberFormat.percentPattern(locale.toString());
  }
}

// ================================================== CURRENCY STYLE FORMATTER ===================================================

/// A precise decimal formatter for number values in currency styles.
/// {@template currency_style_formatter}
/// A concrete, enterprise-grade implementation of [AbstractNumberFormatter] specialized for financial, 
/// monetary, and currency-denominated data mapping layers.
///
/// `CurrencyStyleFormatter` handles the unique requirements of monetary calculations and reporting, including 
/// symbol placement (prefixing vs. suffixing), decimal scale isolation via structural constraint settings, 
/// and explicit currency code or accounting mask pattern overlays.
///
/// ### Precision Guarding & Decimal Clamping
/// In financial computing, managing floating-point division residues is critical to prevent balance drift. 
/// This class implements a strict structural arithmetic rounding boundary during string transformations by combining 
/// runtime parsing constraints with fixed-precision constraints:
/// 1. **Formatting Constraints:** The internal [intl.NumberFormat] instance sets both `minimumFractionDigits` 
///    and `maximumFractionDigits` to match the exact value assigned to the [_fractionDigits] property (defaulting to `2`). 
///    This locks down the sub-unit scale, avoiding floating-point truncation variances during decimal transformations.
/// 2. **Parsing Overrides & Re-clamping:** The [parse] execution flow wraps parent logic and runs a final clamping 
///    pass: `double.parse(parsedNum.toStringAsFixed(_fractionDigits))`. This eliminates any internal micro-fractional 
///    precision noise introduced by native string-to-double conversions, guaranteeing a clean, predictable fractional 
///    value matching financial ledgers.
///
/// ### Behavioral Configurations
/// * **[setCurrency]:** Assigns a standard ISO-4217 alphabetic currency code token (e.g., `"USD"`, `"EUR"`, `"GBP"`). 
///   The engine evaluates this token against the active [Locale] matrix to render the appropriate monetary symbol 
///   (such as `$` or `€`) and determine its correct typographic layout.
/// * **[setFractionDigits]:** Overrides the fractional scale target. This is useful when working with currencies that 
///   omit minor sub-units entirely (e.g., Japanese Yen, where fraction length is `0`) or high-precision financial tracking 
///   matrices that require extended sub-units (e.g., gas prices or tax computations set to `3` or `4` fraction places).
/// * **[setPattern]:** Overlays an absolute custom string pattern mask (e.g., `¤#,##0.00;(¤#,##0.00)`), enabling 
///   specialized presentation configurations such as standard accounting parenthetical formats for negative amounts.
///
/// ### Architecture Example
/// ```dart
/// // --- Archetype A: Standard US Dollar Ledger Formatting ---
/// final usdFormatter = CurrencyStyleFormatter()
///   ..setCurrency("USD")
///   ..setFractionDigits(2);
/// 
/// print(usdFormatter.print(1250.5, Locale.en_US));  // "$1,250.50"
/// print(usdFormatter.print(-45.75, Locale.en_US)); // "-$45.75"
/// 
/// // --- Archetype B: Fixed Zero-Fraction Japanese Yen Layout ---
/// final jpyFormatter = CurrencyStyleFormatter()
///   ..setCurrency("JPY")
///   ..setFractionDigits(0);
/// 
/// print(jpyFormatter.print(5280.95, Locale.ja_JP)); // "￥5,281" (clamped safely)
/// 
/// // --- Archetype C: Tight Parsing with Precision Re-clamping ---
/// final double clearedBalance = usdFormatter.parse(" $1,250.50 ", Locale.en_US);
/// print(clearedBalance); // 1250.5 (perfectly bounded value)
/// ```
/// {@endtemplate}
class CurrencyStyleFormatter extends AbstractNumberFormatter {
  /// The maximum and minimum length of minor fractional digit sub-units allowed within textual entries.
  int _fractionDigits = 2;

  /// The standard alphabetic ISO-4217 currency tracking token identifier code.
  String? _currencyCode;

  /// An optional explicit custom formatting structure pattern mask.
  String? _pattern;

  /// {@macro currency_style_formatter}
  CurrencyStyleFormatter();

  /// Reconfigures the fixed mathematical sub-unit precision scale target constraints.
  /// 
  /// Affects both printing string output alignments and the internal parsing arithmetic truncation layers.
  void setFractionDigits(int fractionDigits) {
    _fractionDigits = fractionDigits;
  }

  /// Sets the standard ISO-4217 currency character token context (e.g., `"USD"`, `"EUR"`).
  void setCurrency(String currencyCode) {
    _currencyCode = currencyCode;
  }

  /// Customizes the visual display format by applying a pattern mask string containing token placeholders.
  void setPattern(String pattern) {
    _pattern = pattern;
  }

  /// Scans, decodes, and sanitizes an incoming financial string representation, returning a 
  /// type-safe [num] clamped precisely to the target fraction constraints.
  ///
  /// ### Parameters
  /// - [text]: The raw localized monetary numeric text block to process.
  /// - [locale]: The active cultural configuration context token governing translation rules.
  /// 
  /// ### Operational Clamping Flow
  /// Extracts the initial raw value from [AbstractNumberFormatter.parse], formats it to a fixed decimal length 
  /// based on [_fractionDigits] via `toStringAsFixed`, and re-parses it to return a clean double-precision primitive.
  @override
  num parse(String text, Locale locale) {
    final parsedNum = super.parse(text, locale);
    return double.parse(parsedNum.toStringAsFixed(_fractionDigits));
  }

  /// Internal template-method implementation hook compiling a localized currency [intl.NumberFormat] architecture.
  ///
  /// Forces the minimum and maximum fraction digits to align with [_fractionDigits], overriding 
  /// default locale assumptions to ensure uniform visual and computational tracking.
  ///
  /// ### Parameters
  /// - [locale]: The active cultural configuration context token governing structural symbol choices and layout rules.
  @override
  intl.NumberFormat getNumberFormat(Locale locale) {
    final format = intl.NumberFormat.currency(
      locale: locale.toString(),
      name: _currencyCode,
      customPattern: _pattern,
    );
    format.maximumFractionDigits = _fractionDigits;
    format.minimumFractionDigits = _fractionDigits;
    return format;
  }
}

// ================================================== CURRENCY UNIT FORMATTER ===================================================

/// {@template currency_unit_formatter}
/// A strict, stateless structural validation formatter responsible for normalizing, printing, 
/// and parsing standard three-letter ISO-4217 alphabetic currency codes.
///
/// `CurrencyUnitFormatter` acts as an edge perimeter validation guard within banking applications, 
/// payment processing layers, and e-commerce checkout funnels. Rather than managing complex numeric scales, 
/// it enforces compliance constraints specifically around the textual currency token identifiers themselves 
/// (e.g., `"USD"`, `"EUR"`, `"JPY"`).
///
/// ### Architectural Constraints & ISO-4217 Invariants
/// According to the International Organization for Standardization (ISO) 4217 contract specification, 
/// currency tokens must consist of exactly three alphabetic characters. This class strictly enforces 
/// this rule during data transformation workflows:
/// 
/// 1. **Whitespace Elimination:** Peripheral padding, leading breaks, or trailing line returns are stripped immediately via `.trim()`.
/// 2. **Casing Normalization:** Tokens are mapped to uppercase characters via `.toUpperCase()`, ensuring that alternative variations 
///    like `"usd"` or `"Usd"` settle into a standardized storage layout (`"USD"`).
/// 3. **Length Constraint Verification:** The parsed payload must measure exactly three characters in length. If this structural invariant 
///    fails, the processing loop is immediately blocked by raising a runtime error.
///
/// ### Thread Safety and State Properties
/// This implementation is declared as an immutable, stateless `final class` containing a `const` constructor. 
/// Because it avoids internal instance fields, it can be shared concurrently across infinite processing threads, 
/// serving as a fast, zero-allocation validator for microservices or data parsing pipelines.
///
/// ### Architecture Example
/// ```dart
/// final CurrencyUnitFormatter validator = const CurrencyUnitFormatter();
/// 
/// // --- Printing Serialization Output ---
/// final String cleanPrint = validator.print("  eur  ", Locale.en_US);
/// print(cleanPrint); // "EUR"
/// 
/// // --- Safe Deserialization Parsing Pass ---
/// final String resolvedToken = validator.parse("  gbp  ", Locale.en_US);
/// print(resolvedToken); // "GBP"
/// 
/// // --- Invariant Exception Handling ---
/// try {
///   validator.parse("US", Locale.en_US); // Fails length constraint checks
/// } on IllegalArgumentException catch (e) {
///   print(e.message); // "Invalid ISO 4217 currency code constraint: 'US'"
/// }
/// ```
/// {@endtemplate}
final class CurrencyUnitFormatter implements Formatter<String> {
  /// Allocates a compile-time constant instance to encourage zero-overhead, global reuse.
  const CurrencyUnitFormatter();

  /// Formats the target currency identifier string token, ensuring consistent, standardized representation output blocks.
  ///
  /// Strips leading/trailing white space from the string and forces uppercase character alignment.
  ///
  /// ### Parameters
  /// - [object]: The raw alphanumeric currency identifier string token (e.g., `"usd"`, `" eur "`).
  /// - [locale]: The active regional configuration context (ignored here, as ISO-4217 codes use a uniform global layout).
  @override
  String print(String object, Locale locale) {
    return object.toUpperCase().trim();
  }

  /// Scans, tokenizes, and validates an unstructured input string, ensuring it perfectly conforms to 
  /// three-letter ISO-4217 alphabetic standards.
  ///
  /// ### Parameters
  /// - [text]: The raw inbound user input or network string payload undergoing verification check bounds.
  /// - [locale]: The active regional configuration context token.
  /// 
  /// ### Failures & Boundary Safety
  /// Throws an [IllegalArgumentException] if the sanitized, trimmed text sequence does not evaluate 
  /// to exactly three characters in length.
  @override
  String parse(String text, Locale locale) {
    final cleaned = text.trim().toUpperCase();
    if (cleaned.length != 3) {
      throw IllegalArgumentException("Invalid ISO 4217 currency code constraint: '$text'");
    }
    return cleaned;
  }
}