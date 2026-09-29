import 'ansi_color.dart';

/// {@template ansi_output}
/// A utility class for formatting terminal output using ANSI colors and background styles.
///
/// This class provides static helper methods to apply foreground or background
/// ANSI styles to any string, making console logs more readable and expressive.
///
/// ---
///
/// ### ✅ Example Usage:
/// ```dart
/// print(AnsiOutput.green("✔ Success"));
/// print(AnsiOutput.red("✖ Error"));
/// print(AnsiOutput.onRed("🔥 CRITICAL"));
/// print(AnsiOutput.onYellow("⚠ Warning", AnsiColor.BLACK));
/// ```
///
/// You can also manually apply styles with:
/// ```dart
/// print(AnsiOutput.apply(AnsiColor.BOLD, "Important!"));
/// ```
///
/// ---
///
/// Typically used in CLI tools, startup banners, or colored logging.
///
/// {@endtemplate}
class AnsiOutput {
  /// {@macro ansi_output}
  const AnsiOutput._();

  /// Applies a foreground [color] to the given [text].
  ///
  /// Useful when working with custom color definitions.
  ///
  /// Example:
  /// ```dart
  /// print(AnsiOutput.apply(AnsiColor.UNDERLINE, "underlined"));
  /// ```
  static String apply(AnsiColor color, String text) => color(text);

  /// Foreground: bright green.
  ///
  /// Good for success messages.
  static String green(String text) => AnsiColor.GREEN(text);

  /// Foreground: bright red.
  ///
  /// Good for error or failure messages.
  static String red(String text) => AnsiColor.RED(text);

  /// Foreground: bright yellow.
  ///
  /// Commonly used for warning messages.
  static String yellow(String text) => AnsiColor.YELLOW(text);

  /// Foreground: bright blue.
  static String blue(String text) => AnsiColor.BLUE(text);

  /// Foreground: bright magenta.
  static String magenta(String text) => AnsiColor.MAGENTA(text);

  /// Foreground: bright cyan.
  static String cyan(String text) => AnsiColor.CYAN(text);

  /// Foreground: gray (mapped to white).
  static String gray(String text) => AnsiColor.GRAY(text);

  /// Foreground: bright white.
  static String white(String text) => AnsiColor.WHITE(text);

  /// Foreground: dark red.
  static String darkRed(String text) => AnsiColor.DARK_RED(text);

  /// Foreground: dark green.
  static String darkGreen(String text) => AnsiColor.DARK_GREEN(text);

  /// Applies a [background] color and optional [foreground] to the given [text].
  ///
  /// If [foreground] is provided, it wraps the background-colored text with the foreground style.
  ///
  /// Example:
  /// ```dart
  /// print(AnsiOutput.onBackground(AnsiColor.BG_BLUE, "Note", AnsiColor.WHITE));
  /// ```
  static String onBackground(AnsiColor background, String text, [AnsiColor? foreground]) {
    final base = background(text);
    return foreground != null ? foreground(base) : base;
  }

  /// Shorthand for white text on bright red background.
  ///
  /// Example:
  /// ```dart
  /// print(AnsiOutput.onRed("🔥 Fatal"));
  /// ```
  static String onRed(String text, [AnsiColor fg = AnsiColor.WHITE]) =>
      onBackground(AnsiColor.BG_BRIGHT_RED, text, fg);

  /// Shorthand for black text on bright yellow background.
  ///
  /// Example:
  /// ```dart
  /// print(AnsiOutput.onYellow("⚠ Warning"));
  /// ```
  static String onYellow(String text, [AnsiColor fg = AnsiColor.BLACK]) =>
      onBackground(AnsiColor.BG_BRIGHT_YELLOW, text, fg);
}